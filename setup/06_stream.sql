/*=============================================================
  06 - Stream
  Captures new inserts into RAW_CRYPTO_TICKS via CDC
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

CREATE OR REPLACE STREAM CRYPTO_TICKS_STREAM
  ON TABLE RAW_CRYPTO_TICKS
  APPEND_ONLY = TRUE;
