WITH source AS (
    SELECT * FROM {{ source("raw_data", "products") }}
),

products_transformed AS (
    SELECT
        product_id,
        "product_category_name",
        "product_name_lenght",
        "product_description_lenght",
        COALESCE("product_photos_qty", 0) AS product_photos_qty,
        COALESCE("product_weight_g", 0) AS product_weight_g,
        COALESCE("product_length_cm", 0) AS product_length_cm,
        COALESCE("product_height_cm", 0) AS product_height_cm,
        COALESCE("product_width_cm", 0) AS product_width_cm
    FROM source
)

SELECT * FROM products_transformed