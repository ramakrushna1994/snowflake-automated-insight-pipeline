/*=============================================================
  02 - Raw Tables
  Stores raw cryptocurrency tick data from API or simulator
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

CREATE OR REPLACE TABLE RAW_CRYPTO_TICKS (
    ticker          VARCHAR(10)     NOT NULL,
    price_usd       FLOAT           NOT NULL,
    volume_24h      FLOAT,
    market_cap      FLOAT,
    price_change_pct_1h  FLOAT,
    price_change_pct_24h FLOAT,
    source          VARCHAR(20)     DEFAULT 'SIMULATOR',  -- 'COINGECKO' or 'SIMULATOR'
    ingested_at     TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);
