WITH source AS (
    SELECT * FROM {{ source("raw_data", "leads_closed") }}
),

leads_closed_transformed AS (
    SELECT
        mql_id,
        seller_id,
        sdr_id,
        sr_id,
        CAST(won_date AS TIMESTAMP) AS won_date,
        business_segment,
        lead_type,
        lead_behaviour_profile,
        CASE
            WHEN has_company::FLOAT = 1.0 THEN TRUE
            ELSE FALSE
        END AS has_company,
        CASE
            WHEN has_gtin::FLOAT = 1.0 THEN TRUE
            ELSE FALSE
        END AS has_gtin,
        average_stock,
        business_type,
        CAST(declared_product_catalog_size AS INTEGER) AS declared_product_catalog_size,
        CAST(declared_monthly_revenue AS INTEGER) AS declared_monthly_revenue
    FROM source
)

SELECT * FROM leads_closed_transformed