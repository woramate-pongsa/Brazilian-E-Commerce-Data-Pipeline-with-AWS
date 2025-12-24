{{
    config(
        materialized="incremental",
        unique_key="order_id"
    )
}}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

order_payments AS (
    SELECT * FROM {{ ref('stg_order_payments') }}
)

SELECT
    -- Key สำหรับเชื่อม Dimension
    o.order_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    
    -- Date/Time สำหรับ Analysis
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    
    -- Status
    o.order_status,
    
    -- Measures (ตัวเลขที่คำนวณได้)
    oi.price AS item_price,
    oi.freight_value,
    op.payment_value,
    op.payment_type,
    op.payment_installments,
    
    -- Derived Metrics (คำนวณเพิ่ม)
    (oi.price + oi.freight_value) AS total_order_item_value

FROM orders o
-- Join กับ Items (1 Order มีหลาย Item)
JOIN order_items oi ON o.order_id = oi.order_id
-- Join กับ Payments (1 Order มีหลาย Payment)
LEFT JOIN order_payments op ON o.order_id = op.order_id


{% if is_incremental() %}
    WHERE order_purchase_timestamp > (SELECT MAX(order_purchase_timestamp) FROM {{ this }})
{% endif %}