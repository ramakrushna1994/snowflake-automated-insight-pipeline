/*=============================================================
  09 - Alerts
  Fires when critical anomalies are detected
=============================================================*/

USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;

-- Alert: fires when new CRITICAL anomalies appear in the last 5 minutes
CREATE OR REPLACE ALERT CRYPTO_ANOMALY_ALERT
  WAREHOUSE = INSIGHT_WH
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 
    FROM CRYPTO_ANOMALIES
    WHERE anomaly_type = 'CRITICAL'
      AND ingested_at > DATEADD('MINUTE', -5, CURRENT_TIMESTAMP())
  ))
  THEN
    CALL SYSTEM$SEND_EMAIL(
      'CRYPTO_ALERT_INTEGRATION',
      'your-email@example.com',
      'CRYPTO ANOMALY ALERT',
      (SELECT LISTAGG(ticker || ': ' || anomaly_type || ' (' || direction || ') - $' || ROUND(price_usd, 2) || ' | Z-score: ' || ROUND(price_zscore, 2), '\n')
       FROM CRYPTO_ANOMALIES
       WHERE anomaly_type = 'CRITICAL'
         AND ingested_at > DATEADD('MINUTE', -5, CURRENT_TIMESTAMP()))
    );

-- Resume the alert
ALTER ALERT CRYPTO_ANOMALY_ALERT RESUME;

/*
  NOTE: To use email alerts, you need a notification integration:
  
  CREATE OR REPLACE NOTIFICATION INTEGRATION CRYPTO_ALERT_INTEGRATION
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('your-email@example.com');
    
  Alternatively, you can replace the THEN action with any other 
  notification method (webhook, Slack, etc.)
*/
