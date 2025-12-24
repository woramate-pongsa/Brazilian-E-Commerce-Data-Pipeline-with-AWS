WITH source AS (
    SELECT * FROM {{ source("raw_data", "leads_qualified") }}
),

leads_qualified_transformed AS (
    SELECT
        mql_id,
        CAST(first_contact_date AS TIMESTAMP) AS first_contact_date,
        landing_page_id,
        origin
    FROM source
)

SELECT * FROM leads_qualified_transformed