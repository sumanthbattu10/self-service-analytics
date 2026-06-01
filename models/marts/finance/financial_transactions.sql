sql-- Financial Transactions Mart Model
-- Author: Sumanth Battu
-- Description: Core financial transactions mart for analytics consumption

{{ config(
    materialized='incremental',
    unique_key='transaction_id',
    on_schema_change='sync_all_columns'
) }}

with source_transactions as (
    select * from {{ ref('stg_transactions') }}
),

customer_aggregates as (
    select
        customer_id,
        count(transaction_id)           as total_transactions,
        sum(amount)                     as total_spend,
        avg(amount)                     as avg_transaction_amount,
        min(transaction_date)           as first_transaction_date,
        max(transaction_date)           as last_transaction_date,
        sum(case when status = 'completed' 
            then amount else 0 end)     as completed_spend,
        sum(case when category = 'refund' 
            then amount else 0 end)     as total_refunds
    from source_transactions
    group by customer_id
),

enriched_transactions as (
    select
        t.transaction_id,
        t.customer_id,
        t.amount,
        t.transaction_date,
        t.category,
        t.status,
        -- Date dimensions
        date_trunc('month', t.transaction_date)     as transaction_month,
        date_trunc('quarter', t.transaction_date)   as transaction_quarter,
        extract(year from t.transaction_date)       as transaction_year,
        -- Amount segmentation
        case
            when t.amount < 100     then 'low'
            when t.amount < 500     then 'medium'
            when t.amount < 1000    then 'high'
            else                         'very_high'
        end                                         as amount_segment,
        -- High value flag
        case when t.amount > 1000 then true 
             else false end                         as is_high_value,
        -- Customer metrics
        c.total_transactions,
        c.total_spend,
        c.avg_transaction_amount,
        c.first_transaction_date,
        c.last_transaction_date,
        -- Customer segmentation
        case
            when c.total_spend > 50000  then 'premium'
            when c.total_spend > 10000  then 'high_value'
            when c.total_spend > 1000   then 'standard'
            else                             'low_value'
        end                                         as customer_segment,
        -- Metadata
        current_timestamp                           as dbt_updated_at
    from source_transactions t
    left join customer_aggregates c
        on t.customer_id = c.customer_id
)

select * from enriched_transactions

{% if is_incremental() %}
    where transaction_date > (select max(transaction_date) from {{ this }})
{% endif %}
