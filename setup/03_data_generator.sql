/*=============================================================
  03 - Data Generator (Fallback / Demo Mode)
  Generates synthetic crypto price ticks with random walks
  and injected anomalies (flash crashes, pump spikes)
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

CREATE OR REPLACE PROCEDURE GENERATE_CRYPTO_TICKS(NUM_TICKS INT DEFAULT 5)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    i INT DEFAULT 0;
    v_ticker VARCHAR;
    v_base_price FLOAT;
    v_price FLOAT;
    v_volume FLOAT;
    v_market_cap FLOAT;
    v_change_1h FLOAT;
    v_change_24h FLOAT;
    v_anomaly_roll FLOAT;
BEGIN
    WHILE (i < NUM_TICKS) DO
        -- Rotate through coins
        CASE MOD(i, 5)
            WHEN 0 THEN v_ticker := 'BTC';  v_base_price := 67000;
            WHEN 1 THEN v_ticker := 'ETH';  v_base_price := 3500;
            WHEN 2 THEN v_ticker := 'SOL';  v_base_price := 150;
            WHEN 3 THEN v_ticker := 'XRP';  v_base_price := 0.55;
            WHEN 4 THEN v_ticker := 'ADA';  v_base_price := 0.45;
        END CASE;

        -- Random walk: normal variation +/- 2%
        v_change_1h := (RANDOM() / 9223372036854775807::FLOAT) * 4 - 2;
        v_change_24h := (RANDOM() / 9223372036854775807::FLOAT) * 10 - 5;

        -- 10% chance of anomaly injection
        v_anomaly_roll := ABS(RANDOM() / 9223372036854775807::FLOAT);
        IF (v_anomaly_roll < 0.05) THEN
            -- Flash crash: -8% to -15%
            v_change_1h := -8 - (ABS(RANDOM() / 9223372036854775807::FLOAT) * 7);
        ELSEIF (v_anomaly_roll < 0.10) THEN
            -- Pump spike: +8% to +15%
            v_change_1h := 8 + (ABS(RANDOM() / 9223372036854775807::FLOAT) * 7);
        END IF;

        v_price := v_base_price * (1 + v_change_1h / 100);
        v_volume := v_base_price * 1000000 * (1 + ABS(RANDOM() / 9223372036854775807::FLOAT));
        
        -- Volume spike for anomalies
        IF (ABS(v_change_1h) > 7) THEN
            v_volume := v_volume * (3 + ABS(RANDOM() / 9223372036854775807::FLOAT) * 2);
        END IF;

        v_market_cap := v_price * v_volume * 10;

        INSERT INTO RAW_CRYPTO_TICKS (ticker, price_usd, volume_24h, market_cap, price_change_pct_1h, price_change_pct_24h, source)
        VALUES (:v_ticker, :v_price, :v_volume, :v_market_cap, :v_change_1h, :v_change_24h, 'SIMULATOR');

        i := i + 1;
    END WHILE;

    RETURN 'Generated ' || NUM_TICKS || ' crypto ticks';
END;
$$;
