-- Agencias Compradoras por mes
-- Query 07 | COUNT DISTINCT partner_id con transaction_code en canal HotelDo

SELECT
    SUBSTR(CAST(date AS VARCHAR), 1, 7) AS month,
    COUNT(DISTINCT partner_id)           AS compradoras
FROM data.lake.bi_web_traffic
WHERE channel LIKE '%hoteldo%'
    AND line_of_business = 'B2B'
    AND transaction_code IS NOT NULL
    AND CAST(date AS DATE) >= DATE '2025-01-01'
    AND CAST(date AS DATE) <= DATE '2026-12-31'
GROUP BY 1
ORDER BY 1
