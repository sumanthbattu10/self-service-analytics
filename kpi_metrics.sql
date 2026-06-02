-- Self-Service Analytics KPI Metrics
-- Author: Sumanth Battu
-- Description: Reusable SQL metrics for business self-service

-- ============================================
-- 1. Customer Retention Cohort Analysis
-- ============================================
WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(transaction_date)) AS cohort_month
    FROM financial_transactions
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        t.customer_id,
        c.cohort_month,
        DATE_TRUNC('month', t.transaction_date)    AS activity_month,
        DATEDIFF('month', c.cohort_month,
            DATE_TRUNC('month',
            t.transaction_date))                   AS month_number
    FROM financial_transactions t
    JOIN cohort_base c
        ON t.customer_id = c.customer_id
)
SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id)                    AS active_customers,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 /
        FIRST_VALUE(COUNT(DISTINCT customer_id))
        OVER (PARTITION BY cohort_month
        ORDER BY month_number), 2)                 AS retention_rate
FROM cohort_activity
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;


-- ============================================
-- 2. Revenue Trend Analysis
-- ============================================
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)      AS month,
        SUM(amount)                                AS revenue,
        COUNT(DISTINCT customer_id)                AS customers,
        COUNT(transaction_id)                      AS transactions
    FROM financial_transactions
    WHERE status = 'completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)
SELECT
    month,
    revenue,
    customers,
    transactions,
    ROUND(AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                          AS rolling_3mo_avg,
    ROUND((revenue - LAG(revenue)
        OVER (ORDER BY month)) /
        NULLIF(LAG(revenue)
        OVER (ORDER BY month), 0) * 100, 2)        AS mom_growth_pct
FROM monthly_revenue
ORDER BY month DESC;


-- ============================================
-- 3. Product Performance Dashboard
-- ============================================
SELECT
    category,
    COUNT(transaction_id)                          AS total_transactions,
    ROUND(SUM(amount), 2)                          AS total_revenue,
    ROUND(AVG(amount), 2)                          AS avg_order_value,
    COUNT(DISTINCT customer_id)                    AS unique_customers,
    ROUND(SUM(amount) * 100.0 /
        SUM(SUM(amount)) OVER (), 2)               AS revenue_share_pct,
    RANK() OVER (
        ORDER BY SUM(amount) DESC
    )                                              AS revenue_rank
FROM financial_transactions
WHERE status = 'completed'
GROUP BY category
ORDER BY total_revenue DESC;


-- ============================================
-- 4. Customer Lifetime Value Model
-- ============================================
WITH customer_metrics AS (
    SELECT
        customer_id,
        MIN(transaction_date)                      AS first_purchase,
        MAX(transaction_date)                      AS last_purchase,
        COUNT(transaction_id)                      AS total_orders,
        SUM(amount)                                AS total_revenue,
        AVG(amount)                                AS avg_order_value,
        DATEDIFF('day',
            MIN(transaction_date),
            MAX(transaction_date))                 AS customer_lifespan_days
    FROM financial_transactions
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_orders,
    ROUND(total_revenue, 2)                        AS lifetime_value,
    ROUND(avg_order_value, 2)                      AS avg_order_value,
    customer_lifespan_days,
    ROUND(total_revenue /
        NULLIF(customer_lifespan_days, 0)
        * 365, 2)                                  AS annual_value,
    NTILE(4) OVER (
        ORDER BY total_revenue
    )                                              AS ltv_quartile
FROM customer_metrics
ORDER BY lifetime_value DESC;
