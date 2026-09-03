-- GB Cancelado por Método de Pago
-- Query 05 | Filtra solo Cancelado, agrupa por mes y payment_method

SELECT
    "source"."month"             AS month,
    "source"."transaction_status" AS transaction_status,
    "source"."payment_methods"   AS payment_method,
    "source"."sum"               AS gb_usd
FROM (
    SELECT
        "source"."month",
        "source"."transaction_status",
        "source"."payment_methods",
        SUM("source"."gb") AS sum
    FROM (
        select
            YEAR(bi.creation_date)*100+month(bi.creation_date) as month,
            bi.transaction_status,
            bi.gb,
            product.payment_methods
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
    GROUP BY source.month, source.transaction_status, source.payment_methods
    ORDER BY source.month ASC, source.transaction_status ASC, source.payment_methods ASC
) AS source
WHERE LOWER(source.transaction_status) LIKE '%cancelado%'
ORDER BY source.month ASC
LIMIT 1048575
