WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
order_payments AS (
    SELECT * FROM {{ ref('stg_order_payments') }}
),
order_reviews AS (
    SELECT * FROM {{ ref('stg_order_reviews') }}
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
)

SELECT
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    MAX(o.order_purchase_timestamp) as last_purchase_date,
    DATEDIFF(day, MAX(o.order_purchase_timestamp), CURRENT_DATE) as recency_days,
    COUNT(DISTINCT o.order_id) as frequency,
    COALESCE(ROUND(SUM(p.payment_value), 1), 0) as monetary,
    AVG(r.review_score) as avg_review_score

FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_payments p ON o.order_id = p.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
GROUP BY 1, 2, 3