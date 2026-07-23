/*=============================================================
  11 - Cortex AI Integration
  LLM-powered anomaly summarization + ML anomaly detection
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

-- ============================================================
-- PART 1: LLM Anomaly Summarizer
-- Uses Cortex COMPLETE to generate natural-language insights
-- ============================================================

CREATE OR REPLACE PROCEDURE SUMMARIZE_ANOMALIES()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_anomaly_data VARCHAR;
    v_summary VARCHAR;
BEGIN
    SELECT LISTAGG(
        ticker || ': price=$' || ROUND(price_usd, 2) || 
        ', change_1h=' || ROUND(price_change_pct_1h, 2) || '%' ||
        ', z_score=' || ROUND(price_zscore, 2) ||
        ', volume_ratio=' || ROUND(volume_ratio, 2) || 'x' ||
        ', type=' || anomaly_type ||
        ', direction=' || direction,
        ' | '
    ) INTO :v_anomaly_data
    FROM CRYPTO_ANOMALIES
    WHERE ingested_at > DATEADD('HOUR', -1, CURRENT_TIMESTAMP())
    LIMIT 10;

    IF (v_anomaly_data IS NULL) THEN
        RETURN 'No anomalies detected in the last hour.';
    END IF;

    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'You are a crypto market analyst. Analyze these detected anomalies and provide a brief, actionable insight summary (3-4 sentences). Include what happened, possible causes, and recommended actions. Data: ' || :v_anomaly_data
    ) INTO :v_summary;

    RETURN v_summary;
END;
$$;

-- View to get LLM-generated insights for each anomaly
CREATE OR REPLACE VIEW CRYPTO_ANOMALY_INSIGHTS AS
SELECT
    ticker,
    ingested_at,
    price_usd,
    anomaly_type,
    direction,
    price_zscore,
    volume_ratio,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'In one sentence, explain this crypto anomaly for a trader: ' ||
        ticker || ' price=$' || ROUND(price_usd, 2) ||
        ', 1h change=' || ROUND(price_change_pct_1h, 2) || '%' ||
        ', z-score=' || ROUND(price_zscore, 2) ||
        ', volume=' || ROUND(volume_ratio, 2) || 'x normal' ||
        ', type=' || anomaly_type
    ) AS ai_insight
FROM CRYPTO_ANOMALIES
WHERE ingested_at > DATEADD('HOUR', -1, CURRENT_TIMESTAMP());

-- ============================================================
-- PART 2: ML Anomaly Detection (Cortex ML)
-- Trains an unsupervised anomaly detection model on price data
-- ============================================================

-- Create training view with required timestamp and value columns
CREATE OR REPLACE VIEW CRYPTO_ML_TRAINING_DATA AS
SELECT
    ticker,
    ingested_at AS timestamp,
    price_usd AS value
FROM RAW_CRYPTO_TICKS
ORDER BY ingested_at;

-- Train anomaly detection model per ticker (BTC as primary)
-- Note: Requires sufficient historical data. Run after seeding data.
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION CRYPTO_PRICE_ANOMALY_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'CRYPTO_ML_TRAINING_DATA'),
    SERIES_COLNAME => 'TICKER',
    TIMESTAMP_COLNAME => 'TIMESTAMP',
    TARGET_COLNAME => 'VALUE',
    LABEL_COLNAME => ''
);

-- View to get ML model predictions on latest data
CREATE OR REPLACE VIEW CRYPTO_ML_ANOMALIES AS
SELECT * FROM TABLE(
    CRYPTO_PRICE_ANOMALY_MODEL!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'CRYPTO_ML_TRAINING_DATA'),
        SERIES_COLNAME => 'TICKER',
        TIMESTAMP_COLNAME => 'TIMESTAMP',
        TARGET_COLNAME => 'VALUE'
    )
);
