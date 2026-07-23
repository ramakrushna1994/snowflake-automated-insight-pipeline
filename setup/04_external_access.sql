/*=============================================================
  04 - External Access Integration
  Allows Snowflake to call the CoinGecko API
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

-- Network rule to allow outbound HTTPS to CoinGecko
CREATE OR REPLACE NETWORK RULE COINGECKO_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('api.coingecko.com:443');

-- External access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION COINGECKO_ACCESS_INTEGRATION
  ALLOWED_NETWORK_RULES = (COINGECKO_NETWORK_RULE)
  ENABLED = TRUE;
