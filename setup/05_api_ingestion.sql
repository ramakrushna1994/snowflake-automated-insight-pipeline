/*=============================================================
  05 - API Ingestion Procedure
  Fetches live crypto data from CoinGecko free API
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

CREATE OR REPLACE PROCEDURE INGEST_CRYPTO_FROM_API()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests', 'snowflake-snowpark-python')
HANDLER = 'run'
EXTERNAL_ACCESS_INTEGRATIONS = (COINGECKO_ACCESS_INTEGRATION)
AS
$$
import requests
import json
from datetime import datetime

def run(session):
    url = "https://api.coingecko.com/api/v3/coins/markets"
    params = {
        "vs_currency": "usd",
        "ids": "bitcoin,ethereum,solana,ripple,cardano",
        "order": "market_cap_desc",
        "per_page": 5,
        "page": 1,
        "sparkline": "false",
        "price_change_percentage": "1h,24h"
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        return f"API call failed: {str(e)}"

    ticker_map = {
        "bitcoin": "BTC",
        "ethereum": "ETH",
        "solana": "SOL",
        "ripple": "XRP",
        "cardano": "ADA"
    }

    rows_inserted = 0
    for coin in data:
        ticker = ticker_map.get(coin["id"], coin["symbol"].upper())
        price = coin.get("current_price", 0)
        volume = coin.get("total_volume", 0)
        market_cap = coin.get("market_cap", 0)
        change_1h = coin.get("price_change_percentage_1h_in_currency", 0) or 0
        change_24h = coin.get("price_change_percentage_24h", 0) or 0

        session.sql(f"""
            INSERT INTO RAW_CRYPTO_TICKS (ticker, price_usd, volume_24h, market_cap, price_change_pct_1h, price_change_pct_24h, source)
            VALUES ('{ticker}', {price}, {volume}, {market_cap}, {change_1h}, {change_24h}, 'COINGECKO')
        """).collect()
        rows_inserted += 1

    return f"Ingested {rows_inserted} rows from CoinGecko API"
$$;
