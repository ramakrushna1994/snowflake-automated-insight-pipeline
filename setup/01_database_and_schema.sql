/*=============================================================
  01 - Database, Schema, and Warehouse Setup
  Automated Insight Pipeline — Crypto Anomaly Detection
=============================================================*/

USE ROLE SYSADMIN;

-- Database
CREATE DATABASE IF NOT EXISTS INSIGHT_PIPELINE;

-- Schema
CREATE SCHEMA IF NOT EXISTS INSIGHT_PIPELINE.CRYPTO;

-- Warehouse for pipeline workloads
CREATE WAREHOUSE IF NOT EXISTS INSIGHT_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Set context
USE DATABASE INSIGHT_PIPELINE;
USE SCHEMA CRYPTO;
USE WAREHOUSE INSIGHT_WH;
