# Automated Insight Pipeline — Crypto Anomaly Detection

> **DISCLAIMER: This project is for educational and learning purposes only. It is NOT financial advice. Do NOT use this pipeline, its outputs, or any AI-generated insights to make real trading or investment decisions. Cryptocurrency markets are highly volatile and speculative. The authors assume no liability for any financial losses incurred from using or misusing this project. Always consult a qualified financial advisor before making investment decisions.**

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
- **Cortex LLM (AI)** — Natural-language anomaly summaries using `mistral-large2`
- **Cortex ML** — Unsupervised anomaly detection model (`SNOWFLAKE.ML.ANOMALY_DETECTION`)

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
-- 11_cortex_ai.sql
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

## Cortex AI Integration

### LLM-Powered Insights (Cortex Complete)
- **Anomaly Summarizer**: A stored procedure (`SUMMARIZE_ANOMALIES()`) that uses `mistral-large2` to generate natural-language market analysis of detected anomalies
- **Per-Anomaly Explanations**: A view (`CRYPTO_ANOMALY_INSIGHTS`) that generates one-sentence trader-friendly explanations for each anomaly in real-time

### ML Anomaly Detection (Cortex ML)
- **Unsupervised Model**: Uses `SNOWFLAKE.ML.ANOMALY_DETECTION` trained on historical price data
- **Multi-Series Support**: Trains across all tracked coins (BTC, ETH, SOL, XRP, ADA) simultaneously
- **Complements Z-Score**: ML model catches patterns that statistical thresholds miss (trend-aware, seasonality-aware)

## Teardown

Run `teardown/cleanup.sql` to remove all objects.

## License & Purpose

This project was built as a learning exercise to demonstrate Snowflake's real-time data pipeline capabilities. It is intended solely for:
- Learning Snowflake features (Streams, Tasks, Dynamic Tables, Alerts, Cortex AI)
- Demonstrating end-to-end data pipeline architecture
- Educational workshops and hackathons

It is **not** intended for production use, live trading, or financial decision-making.
