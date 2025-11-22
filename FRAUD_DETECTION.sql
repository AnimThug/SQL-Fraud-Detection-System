/*
Project: Financial Fraud Detection System
Description: End-to-End SQL project to detect money laundering and suspicious patterns using PaySim dataset.
Tools: PostgreSQL
*/

-- ==============================================
-- PHASE 1: DATABASE SETUP & DATA IMPORT
-- ==============================================

-- 1. Create Schema
CREATE SCHEMA IF NOT EXISTS fraud_project;

-- 2. Create Transactions Table
DROP TABLE IF EXISTS fraud_project.transactions;

CREATE TABLE fraud_project.transactions (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(15, 2),
    nameOrig VARCHAR(50),
    oldbalanceOrg DECIMAL(15, 2),
    newbalanceOrig DECIMAL(15, 2),
    nameDest VARCHAR(50),
    oldbalanceDest DECIMAL(15, 2),
    newbalanceDest DECIMAL(15, 2),
    isFraud INT,
    isFlaggedFraud INT
);

-- 3. Import Data (Update the path below before running)
COPY fraud_project.transactions
FROM 'C:/path/to/your/dataset.csv' 
DELIMITER ',' 
CSV HEADER;

-- ==============================================
-- PHASE 2: DETECTION RULES (VIEWS)
-- ==============================================

-- Rule 1: Zero Balance Anomaly (Account emptied immediately)
CREATE OR REPLACE VIEW fraud_project.rule_1_zero_balance AS
SELECT step, nameOrig, type, amount, oldbalanceOrg, newbalanceOrig, isFraud
FROM fraud_project.transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
  AND oldbalanceOrg > 0
  AND newbalanceOrig = 0;

-- Rule 2: High Velocity Activity (>3 transactions in 1 hour)
CREATE OR REPLACE VIEW fraud_project.rule_2_high_velocity AS
SELECT 
    nameOrig, 
    step, 
    COUNT(*) as tx_count, 
    SUM(amount) as total_moved
FROM fraud_project.transactions
GROUP BY nameOrig, step
HAVING COUNT(*) > 3;

-- Rule 3: Money Laundering Loop (Transfer followed by Cash Out with commission logic)
CREATE OR REPLACE VIEW fraud_project.rule_3_laundering_chain AS
SELECT 
    t1.step,
    t1.nameOrig AS victim_account,
    t1.nameDest AS mule_account,
    t2.nameDest AS final_dest,
    t1.amount AS transfer_amt,
    t2.amount AS cashout_amt,
    (t1.amount - t2.amount) AS commission_taken
FROM fraud_project.transactions t1
JOIN fraud_project.transactions t2 
    ON t1.nameDest = t2.nameOrig 
    AND t2.step >= t1.step 
    AND t2.step <= t1.step + 1 
WHERE t1.type = 'TRANSFER' 
  AND t2.type = 'CASH_OUT'
  AND ABS(t1.amount - t2.amount) < 1000;

-- ==============================================
-- PHASE 3: FINAL REPORTING & RISK SCORING
-- ==============================================

-- Create Final Alert Dashboard
DROP TABLE IF EXISTS fraud_project.suspicious_activity_report;

CREATE TABLE fraud_project.suspicious_activity_report AS
SELECT 
    t.nameOrig AS customer_id,
    t.step,
    t.amount,
    t.type,
    CASE WHEN r1.nameOrig IS NOT NULL THEN 1 ELSE 0 END AS flag_zero_balance,
    CASE WHEN r2.nameOrig IS NOT NULL THEN 1 ELSE 0 END AS flag_velocity,
    CASE WHEN r3.victim_account IS NOT NULL THEN 1 ELSE 0 END AS flag_laundering,
    (
        CASE WHEN r1.nameOrig IS NOT NULL THEN 30 ELSE 0 END +
        CASE WHEN r2.nameOrig IS NOT NULL THEN 20 ELSE 0 END +
        CASE WHEN r3.victim_account IS NOT NULL THEN 50 ELSE 0 END
    ) AS risk_score
FROM fraud_project.transactions t
LEFT JOIN fraud_project.rule_1_zero_balance r1 
    ON t.nameOrig = r1.nameOrig AND t.step = r1.step
LEFT JOIN fraud_project.rule_2_high_velocity r2 
    ON t.nameOrig = r2.nameOrig AND t.step = r2.step
LEFT JOIN fraud_project.rule_3_laundering_chain r3 
    ON t.nameOrig = r3.victim_account AND t.step = r3.step
WHERE r1.nameOrig IS NOT NULL 
   OR r2.nameOrig IS NOT NULL 
   OR r3.victim_account IS NOT NULL;

-- Final Output: Top 20 Risky Accounts
SELECT * FROM fraud_project.suspicious_activity_report
ORDER BY risk_score DESC, amount DESC
LIMIT 20;