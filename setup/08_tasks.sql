/*=============================================================
  08 - Tasks
  Scheduled ingestion and processing pipeline
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

-- Parent task: ingest data every 2 minutes
CREATE OR REPLACE TASK INGEST_CRYPTO_TASK
  WAREHOUSE = INSIGHT_WH
  SCHEDULE = '2 MINUTE'
AS
  CALL INGEST_CRYPTO_FROM_API();

-- Fallback task: use simulator if API is unavailable (manual trigger)
CREATE OR REPLACE TASK SIMULATE_CRYPTO_TASK
  WAREHOUSE = INSIGHT_WH
  SCHEDULE = '2 MINUTE'
AS
  CALL GENERATE_CRYPTO_TICKS(5);

-- Resume the primary ingestion task (choose one)
-- For live API data:
ALTER TASK INGEST_CRYPTO_TASK RESUME;

-- For simulated data (comment out the above and use this instead):
-- ALTER TASK SIMULATE_CRYPTO_TASK RESUME;
