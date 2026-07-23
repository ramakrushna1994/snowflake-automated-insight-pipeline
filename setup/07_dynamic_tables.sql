/*=============================================================
  07 - Dynamic Tables
  Rolling aggregations and Z-score anomaly detection
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

-- 5-minute price/volume aggregation per coin
CREATE OR REPLACE DYNAMIC TABLE CRYPTO_5MIN_AGG
  TARGET_LAG = '1 minute'
  WAREHOUSE = INSIGHT_WH
AS
SELECT
    ticker,
    TIME_SLICE(ingested_at, 5, 'MINUTE') AS window_start,
    COUNT(*)                              AS tick_count,
    AVG(price_usd)                        AS avg_price,
    MIN(price_usd)                        AS low_price,
    MAX(price_usd)                        AS high_price,
    FIRST_VALUE(price_usd) OVER (
        PARTITION BY ticker, TIME_SLICE(ingested_at, 5, 'MINUTE')
        ORDER BY ingested_at
    )                                     AS open_price,
    LAST_VALUE(price_usd) OVER (
        PARTITION BY ticker, TIME_SLICE(ingested_at, 5, 'MINUTE')
        ORDER BY ingested_at
    )                                     AS close_price,
    AVG(volume_24h)                       AS avg_volume,
    MAX(ABS(price_change_pct_1h))         AS max_abs_change_1h
FROM RAW_CRYPTO_TICKS
GROUP BY ticker, TIME_SLICE(ingested_at, 5, 'MINUTE');

-- Anomaly detection using Z-score method
CREATE OR REPLACE DYNAMIC TABLE CRYPTO_ANOMALIES
  TARGET_LAG = '1 minute'
  WAREHOUSE = INSIGHT_WH
AS
WITH rolling_stats AS (
    SELECT
        ticker,
        ingested_at,
        price_usd,
        volume_24h,
        price_change_pct_1h,
        AVG(price_usd) OVER (
            PARTITION BY ticker
            ORDER BY ingested_at
            RANGE BETWEEN INTERVAL '1 HOUR' PRECEDING AND CURRENT ROW
        ) AS rolling_avg_price,
        STDDEV(price_usd) OVER (
            PARTITION BY ticker
            ORDER BY ingested_at
            RANGE BETWEEN INTERVAL '1 HOUR' PRECEDING AND CURRENT ROW
        ) AS rolling_stddev_price,
        AVG(volume_24h) OVER (
            PARTITION BY ticker
            ORDER BY ingested_at
            RANGE BETWEEN INTERVAL '1 HOUR' PRECEDING AND CURRENT ROW
        ) AS rolling_avg_volume
    FROM RAW_CRYPTO_TICKS
)
SELECT
    ticker,
    ingested_at,
    price_usd,
    volume_24h,
    price_change_pct_1h,
    rolling_avg_price,
    rolling_stddev_price,
    rolling_avg_volume,
    -- Price Z-score
    CASE 
        WHEN rolling_stddev_price > 0 
        THEN (price_usd - rolling_avg_price) / rolling_stddev_price
        ELSE 0 
    END AS price_zscore,
    -- Volume ratio
    CASE 
        WHEN rolling_avg_volume > 0 
        THEN volume_24h / rolling_avg_volume
        ELSE 1 
    END AS volume_ratio,
    -- Anomaly classification
    CASE
        WHEN ABS((price_usd - rolling_avg_price) / NULLIF(rolling_stddev_price, 0)) > 3 THEN 'CRITICAL'
        WHEN ABS((price_usd - rolling_avg_price) / NULLIF(rolling_stddev_price, 0)) > 2 THEN 'WARNING'
        WHEN volume_24h / NULLIF(rolling_avg_volume, 0) > 3 THEN 'VOLUME_SPIKE'
        ELSE NULL
    END AS anomaly_type,
    -- Direction
    CASE
        WHEN price_change_pct_1h > 0 THEN 'PUMP'
        WHEN price_change_pct_1h < 0 THEN 'DUMP'
        ELSE 'NEUTRAL'
    END AS direction
FROM rolling_stats
WHERE 
    ABS((price_usd - rolling_avg_price) / NULLIF(rolling_stddev_price, 0)) > 2
    OR volume_24h / NULLIF(rolling_avg_volume, 0) > 3;
