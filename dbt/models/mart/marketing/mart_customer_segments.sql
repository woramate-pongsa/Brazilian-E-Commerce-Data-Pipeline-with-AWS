WITH rfm_metrics AS (
    SELECT * FROM {{ ref('int_customer_rfm_metrics') }}
),

rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) as r_score, 
        NTILE(5) OVER (ORDER BY frequency ASC) as f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) as m_score
    FROM rfm_metrics
),

final_segments AS (
    SELECT 
        *,
        (COALESCE(avg_review_score, 0) * m_score) / 2.0 as sm_score
    FROM rfm_scores
)

SELECT
    *,
    CASE
        WHEN sm_score >= 5 AND r_score BETWEEN 4 AND 5 THEN 'Champion'
        WHEN sm_score BETWEEN 4 AND 5 AND r_score BETWEEN 3 AND 5 THEN 'Loyal'
        WHEN sm_score BETWEEN 2 AND 3 AND r_score BETWEEN 4 AND 5 THEN 'Promising'
        WHEN sm_score = 1 AND r_score = 5 THEN 'New Customers'
        WHEN sm_score BETWEEN 0 AND 1 AND r_score BETWEEN 4 AND 5 THEN 'Abandoned Checkouts / Callback Requests'
        WHEN sm_score = 1 AND r_score  = 4 THEN 'Warm Leads'
        WHEN sm_score = 1 AND r_score  = 3 THEN 'Cold Leads'
        WHEN sm_score BETWEEN 2 AND 3 AND r_score BETWEEN 2 AND 3 THEN 'Need Attention'
        WHEN sm_score >= 5 AND r_score BETWEEN 1 AND 3 THEN 'Should not Lose'
        WHEN sm_score BETWEEN 3 AND 4 AND r_score BETWEEN 1 AND 2 THEN 'Sleepers'
        WHEN sm_score BETWEEN 0 AND 2 AND r_score BETWEEN 0 AND 3 THEN 'Lost'
    END AS customer_segment
FROM final_segments