"""
Automated Insight Pipeline - Crypto Anomaly Detection Dashboard
Streamlit in Snowflake application
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.set_page_config(page_title="Crypto Anomaly Detection", layout="wide")
st.title("Crypto Anomaly Detection Pipeline")
st.caption("Real-time monitoring powered by Snowflake Streams, Dynamic Tables & Alerts")

# --- Sidebar filters ---
st.sidebar.header("Filters")
tickers = ["ALL", "BTC", "ETH", "SOL", "XRP", "ADA"]
selected_ticker = st.sidebar.selectbox("Coin", tickers)
time_range = st.sidebar.selectbox("Time Range", ["Last 1 Hour", "Last 6 Hours", "Last 24 Hours", "All Time"])

time_filter_map = {
    "Last 1 Hour": "DATEADD('HOUR', -1, CURRENT_TIMESTAMP())",
    "Last 6 Hours": "DATEADD('HOUR', -6, CURRENT_TIMESTAMP())",
    "Last 24 Hours": "DATEADD('HOUR', -24, CURRENT_TIMESTAMP())",
    "All Time": "'2000-01-01'"
}
time_clause = f"ingested_at > {time_filter_map[time_range]}"
ticker_clause = f"AND ticker = '{selected_ticker}'" if selected_ticker != "ALL" else ""

# --- Summary Metrics ---
st.subheader("Current Market Summary")
metrics_df = session.sql(f"""
    SELECT 
        ticker,
        ROUND(price_usd, 2) AS latest_price,
        ROUND(price_change_pct_1h, 2) AS change_1h,
        ROUND(price_change_pct_24h, 2) AS change_24h
    FROM RAW_CRYPTO_TICKS
    WHERE ingested_at = (SELECT MAX(ingested_at) FROM RAW_CRYPTO_TICKS)
    ORDER BY market_cap DESC
""").to_pandas()

if not metrics_df.empty:
    cols = st.columns(len(metrics_df))
    for i, row in metrics_df.iterrows():
        with cols[i]:
            st.metric(
                label=row["TICKER"],
                value=f"${row['LATEST_PRICE']:,.2f}",
                delta=f"{row['CHANGE_1H']:.2f}% (1h)"
            )

# --- Price Chart ---
st.subheader("Price History")
price_df = session.sql(f"""
    SELECT ticker, ingested_at, price_usd
    FROM RAW_CRYPTO_TICKS
    WHERE {time_clause} {ticker_clause}
    ORDER BY ingested_at
""").to_pandas()

if not price_df.empty:
    import altair as alt
    price_chart = alt.Chart(price_df).mark_line().encode(
        x=alt.X("INGESTED_AT:T", title="Time"),
        y=alt.Y("PRICE_USD:Q", title="Price (USD)", scale=alt.Scale(zero=False)),
        color="TICKER:N"
    ).properties(height=350)

    # Overlay anomaly points
    anomaly_df = session.sql(f"""
        SELECT ticker, ingested_at, price_usd, anomaly_type, direction, price_zscore
        FROM CRYPTO_ANOMALIES
        WHERE {time_clause} {ticker_clause}
    """).to_pandas()

    if not anomaly_df.empty:
        anomaly_points = alt.Chart(anomaly_df).mark_circle(size=100, opacity=0.8).encode(
            x="INGESTED_AT:T",
            y="PRICE_USD:Q",
            color=alt.Color("ANOMALY_TYPE:N", scale=alt.Scale(
                domain=["CRITICAL", "WARNING", "VOLUME_SPIKE"],
                range=["red", "orange", "purple"]
            )),
            tooltip=["TICKER", "ANOMALY_TYPE", "DIRECTION", "PRICE_ZSCORE"]
        )
        st.altair_chart(price_chart + anomaly_points, use_container_width=True)
    else:
        st.altair_chart(price_chart, use_container_width=True)
else:
    st.info("No price data available yet. Run the data generator or start the ingestion task.")

# --- Volume Chart ---
st.subheader("Volume (24h)")
volume_df = session.sql(f"""
    SELECT ticker, ingested_at, volume_24h
    FROM RAW_CRYPTO_TICKS
    WHERE {time_clause} {ticker_clause}
    ORDER BY ingested_at
""").to_pandas()

if not volume_df.empty:
    volume_chart = alt.Chart(volume_df).mark_bar(opacity=0.6).encode(
        x="INGESTED_AT:T",
        y=alt.Y("VOLUME_24H:Q", title="Volume (USD)"),
        color="TICKER:N"
    ).properties(height=250)
    st.altair_chart(volume_chart, use_container_width=True)

# --- Anomaly Log ---
st.subheader("Anomaly Detection Log")
anomaly_log_df = session.sql(f"""
    SELECT 
        ticker,
        ingested_at,
        anomaly_type,
        direction,
        ROUND(price_usd, 4) AS price,
        ROUND(price_zscore, 2) AS z_score,
        ROUND(volume_ratio, 2) AS vol_ratio
    FROM CRYPTO_ANOMALIES
    WHERE {time_clause} {ticker_clause}
    ORDER BY ingested_at DESC
    LIMIT 50
""").to_pandas()

if not anomaly_log_df.empty:
    st.dataframe(anomaly_log_df, use_container_width=True)
else:
    st.success("No anomalies detected in the selected time range.")

# --- Pipeline Status ---
st.subheader("Pipeline Status")
col1, col2 = st.columns(2)

with col1:
    st.markdown("**Data Freshness**")
    freshness_df = session.sql("""
        SELECT 
            MAX(ingested_at) AS last_ingestion,
            DATEDIFF('SECOND', MAX(ingested_at), CURRENT_TIMESTAMP()) AS seconds_ago,
            COUNT(*) AS total_ticks
        FROM RAW_CRYPTO_TICKS
    """).to_pandas()
    if not freshness_df.empty:
        st.write(f"Last data: {freshness_df['SECONDS_AGO'].iloc[0]}s ago")
        st.write(f"Total ticks: {freshness_df['TOTAL_TICKS'].iloc[0]:,}")

with col2:
    st.markdown("**Anomaly Summary**")
    summary_df = session.sql("""
        SELECT anomaly_type, COUNT(*) AS count
        FROM CRYPTO_ANOMALIES
        GROUP BY anomaly_type
        ORDER BY count DESC
    """).to_pandas()
    if not summary_df.empty:
        st.dataframe(summary_df)
    else:
        st.write("No anomalies recorded.")
