# Automated Insight Pipeline — Crypto Anomaly Detection

Real-time cryptocurrency anomaly detection pipeline built on Snowflake.

## Architecture

```
CoinGecko API ──► Raw Table ──► Stream ──► Dynamic Tables (Anomaly Detection)
       ▲                                          │
       │                                          ▼
   Scheduled Task                          Snowflake Alert
                                                  │
                                                  ▼
                                      Streamlit Dashboard
```

## Snowflake Features Used

- **Streams** — Change data capture on raw ingestion table
- **Tasks** — Scheduled data ingestion every 2 minutes
- **Dynamic Tables** — Rolling aggregations and Z-score anomaly detection
- **Alerts** — Automated notifications when anomalies are detected
- **Streamlit** — Interactive monitoring dashboard

## Setup

Run the SQL scripts in `setup/` in order (01 through 10):

```sql
-- Execute each file in sequence
-- 01_database_and_schema.sql
-- 02_raw_tables.sql
-- 03_data_generator.sql
-- 04_external_access.sql
-- 05_api_ingestion.sql
-- 06_stream.sql
-- 07_dynamic_tables.sql
-- 08_tasks.sql
-- 09_alerts.sql
-- 10_grants.sql
```

## Data Source

- **Primary**: CoinGecko free API (no API key required)
- **Fallback**: Built-in data generator stored procedure for demo/testing

> **Note:** Snowflake Trial accounts do not support External Access Integrations, so the CoinGecko API connection (scripts 04 and 05) will not work on trial accounts. Use the built-in data simulator (`CALL GENERATE_CRYPTO_TICKS(50)`) instead. The simulator injects realistic price movements with random anomalies (flash crashes, pump spikes, volume surges) for a full demo experience.

## Coins Tracked

BTC, ETH, SOL, XRP, ADA

## Anomaly Detection

Uses Z-score method:
- Price anomaly: price change > 2σ from rolling 1-hour mean
- Volume anomaly: volume spike > 3x rolling 1-hour average

## Teardown

Run `teardown/cleanup.sql` to remove all objects.
