WITH products AS (
    -- ใช้ ref() เพื่ออ้างอิงถึง staging model ที่เราทำไว้ (ไม่ใช่ raw table)
    SELECT * FROM {{ ref('stg_products') }}
),

category_translation AS (
    SELECT * FROM {{ ref('stg_product_category_name_translation') }}
)

SELECT
    p.product_id,
    -- ใช้ COALESCE เพื่อจัดการค่า NULL หรือใช้ชื่อภาษาอังกฤษถ้ามี
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM products p
LEFT JOIN category_translation t 
    ON p.product_category_name = t.product_category_name