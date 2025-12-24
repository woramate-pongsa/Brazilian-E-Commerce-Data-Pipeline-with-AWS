WITH source AS (
    SELECT * FROM {{ source("raw_data", "geolocation") }}
),

geolocation_transformed AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM source
)

SELECT * FROM geolocation_transformed