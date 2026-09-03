-- GB Cancelado por Tipo de Error (cancel_type)
-- Query 03 | Filtra solo status Cancelado, agrupa por mes y tipo de cancelación

SELECT
    "source"."month"             AS month,
    "source"."transaction_status" AS transaction_status,
    "source"."type"              AS cancel_type,
    "source"."sum"               AS gb_usd
FROM (
    SELECT
        "source"."month",
        "source"."transaction_status",
        "source"."type",
        SUM("source"."gb") AS sum
    FROM (
        select
            YEAR(bi.creation_date)*100+month(bi.creation_date) as month,
            bi.transaction_status,
            bi.gb,
            cc.reason_error_type,
            cc.type,
            cc.stage,
            c.status
        from analytics.bi_sales_fact_sales_recognition bi
        join lake.chewie_product p ON p.reference_id = bi.origin_product_id
        join lake.chewie_reservation c ON p.reservation_id = c.oid AND c.last_version = true
        left join lake.channels_bo_product product ON bi.origin_product_id = product.transaction_id
        left join lake.chewie_cancelation cc ON c.oid = cc.reservation_id
        where 1=1
            and bi.channel IN (
                'hoteldo-html-platinum',
                'hoteldo-html-gold',
                'hoteldo-html-silver',
                'hoteldo-html-classic'
            )
            and bi.creation_date >= date('2025-01-01')
            and bi.partition_period >= '2025-01'
            and bi.product not in ('Seguros de Autos')
            and p.status <> 'NO'
            and bi.gb > 0
    ) AS source
    GROUP BY source.month, source.transaction_status, source.type
    ORDER BY source.month ASC, source.transaction_status ASC, source.type ASC
) AS source
WHERE source.month >= 202501
    AND source.transaction_status LIKE '%Cancelado%'
ORDER BY source.month ASC
LIMIT 1048575
