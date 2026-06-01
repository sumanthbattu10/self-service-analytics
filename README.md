# Self-Service Analytics Framework

Reusable analytics framework enabling business users to query 
financial data without engineering support — built with dbt, 
Snowflake, SQL, and Power BI.

## Tech Stack
- **dbt** — data transformation, tests, documentation, lineage
- **Snowflake** — cloud data warehouse
- **SQL** — advanced queries, window functions, CTEs
- **Power BI** — self-service dashboards with DAX measures
- **AWS Redshift** — analytical data store
- **Python** — automation and data processing
- **Great Expectations** — data quality validation

## Features
- dbt models with staging, intermediate, and mart layers
- Star schema dimensional modeling
- Automated data quality tests built into every model
- Data lineage tracked end-to-end
- Power BI dashboards with DAX measures
- Reduced ad hoc data requests by 45%
- Self-service analytics for 200+ stakeholders

## dbt Project Structure
models/
├── staging/          # Raw source cleaning
├── intermediate/     # Business logic
└── marts/
├── finance/      # Financial analytics
└── operations/   # Operational KPIs

## Results
- Eliminated 45% of ad hoc data requests
- Reduced report delivery from weekly to daily
- Zero data quality issues over 3 consecutive months
- Served 200+ business stakeholders
