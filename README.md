# 🕵️‍♂️ Financial Fraud Detection System (SQL)

## 📌 Project Overview
This project involves building a rule-based fraud detection system using **PostgreSQL**. The goal was to analyze a dataset of **6.3 Million** financial transactions to identify suspicious patterns like money laundering and high-velocity fraud.

## 🛠️ Tools Used
* **Database:** PostgreSQL (pgAdmin 4)
* **Query Language:** SQL (Advanced)
* **Dataset:** PaySim (Synthetic Financial Dataset)

## 🔍 Key Findings & Methodology
We implemented three specific detection rules using SQL Views:

1.  **The "Zero Balance" Anomaly:** Identified 1.1M+ transactions where the account was emptied immediately after a transfer.
2.  **High-Velocity Check:** Filtered accounts creating >3 transactions within 1 hour (No hits in this sample, indicating "Sniper" behavior over "Machine Gun" behavior).
3.  **Money Mule Chains:** Used `SELF JOIN` to track funds moving from *Victim -> Mule -> Cash Out* with a small commission difference.

## 📊 Final Outcome
A **Risk Scoring System** was built to assign a risk score (0-100) to every customer based on their activity.
* **Rule 1 Violation:** +30 Points
* **Rule 2 Violation:** +20 Points
* **Rule 3 Violation:** +50 Points

## 📂 How to Use
1.  Download the `fraud_detection_project.sql` file.
2.  Import your dataset using the `COPY` command line provided in the script.
3.  Run the queries sequentially to generate the Risk Report.
