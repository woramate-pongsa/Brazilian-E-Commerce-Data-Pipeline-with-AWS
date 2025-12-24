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
    c.customer_unique_id, -- ใช้ unique_id เพื่อดูพฤติกรรมคนจริงๆ (ไม่ใช่ customer_id ที่เปลี่ยนทุก order)
    c.customer_state,
    c.customer_city,
    
    -- Recency: วันที่ซื้อล่าสุด (เทียบกับวันนี้ หรือวันที่เรากำหนด)
    MAX(o.order_purchase_timestamp) as last_purchase_date,
    -- (Redshift ใช้ DATEDIFF แทน JULIANDAY)
    DATEDIFF(day, MAX(o.order_purchase_timestamp), CURRENT_DATE) as recency_days,
    
    -- Frequency: จำนวนออเดอร์
    COUNT(DISTINCT o.order_id) as frequency,
    
    -- Monetary: ยอดเงินรวม
    COALESCE(SUM(p.payment_value), 0) as monetary,
    
    -- Review: คะแนนเฉลี่ย
    AVG(r.review_score) as avg_review_score

FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_payments p ON o.order_id = p.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id

WHERE o.order_status = 'delivered' -- คิดเฉพาะที่ส่งของสำเร็จ
GROUP BY 1, 2, 3