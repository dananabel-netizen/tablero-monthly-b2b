-- GB HotelDo — GB confirmado por fecha, país, producto, canal
-- Query 01 | Fuente: analytics.bi_sales_fact_sales_recognition

select
    bi.creation_date as date,
    YEAR(bi.creation_date)*100+week(bi.creation_date) as week,
    YEAR(bi.creation_date)*100+month(bi.creation_date) as month,
    bi.country_code as country,
    case
        when bi.buy_type_code = 'Bundles'
            then 'Carrito'
        else bi.buy_type_code
        end as product_sale,
    case
        when bi.product in ('Busch Gardens','Espectáculos','Excursiones','SeaWorld')
            then bi.buy_type_code
        when bi.product = 'Bundles'
            then 'Carrito'
        else bi.product
        end as product,
    bi.channel,
    bi.partner_id,
    bi.trip_type_code as routetype,
    bi.destination as destino_city,
    case
        when (LOWER(user_agent) like'%mobile%' or LOWER(user_agent) like '%android%' or LOWER(user_agent) like '%iphone%' or LOWER(user_agent) like '%ipad%' or LOWER(user_agent) like '%ios%')
            then 'Site-Mobile'
        else 'Site-Desktop'
        end as plataforma,
    bi.transaction_code as reserva,
    bi.gb,
    product.payment_methods
from analytics.bi_sales_fact_sales_recognition bi
left join lake.chewie_reservation c
    ON bi.transaction_code = cast(c.id as bigint) and c.last_version = true
left JOIN lake.channels_bo_product product
    ON bi.origin_product_id = product.transaction_id
where 1=1
    and bi.channel IN (
        'hoteldo-html-platinum',
        'hoteldo-html-gold',
        'hoteldo-html-silver',
        'hoteldo-html-classic'
    )
    and bi.creation_date > date '2025-01-01'
    and transaction_status = 'Confirmado'
    and bi.partition_period >= '2025-01'
