-- Medios de Pago — GB y orders por método, país, viaje e is_scheduler (HotelDo)
-- Query 12 | Fuente: analytics.prd_payment_methods_fact + bi_transactional_fact_transactions
-- Nivel: transacción (una fila por reserva). Para el build script usar q12_medios_pago.sql (agrupado).

WITH scheduler_agg AS (
    SELECT
        sc_ps.transaction_id,
        SUM(CASE WHEN cc.type = 'CARD'                THEN 1 ELSE 0 END) AS card_cnt,
        SUM(CASE WHEN cc.channel_id = 'ITAU_PIX'      THEN 1 ELSE 0 END) AS pix_cnt,
        SUM(CASE WHEN cc.channel_id = 'MERCADO_PAGO'  THEN 1 ELSE 0 END) AS mp_cnt
    FROM raw.scheduler_confirmed_payment_schedule sc_ps
    INNER JOIN raw.scheduler_confirmed_payment_intention sc_pi
        ON sc_ps.id = sc_pi.payment_schedule_id
    INNER JOIN raw.scheduler_confirmed_collection sc
        ON sc.payment_intention_id = sc_pi.id
    INNER JOIN data.lake.chewie_collection cc
        ON sc.collectionId = cc.cobra_id
    INNER JOIN data.lake.chewie_reservation r
        ON r.OID = cc.RESERVATION_ID
    WHERE r.last_version = TRUE
      AND sc_pi.status  = 'COLLECTED'
      AND sc_ps.status  = 'CLOSED'
      AND r.channel IN (
          'hoteldo-html-classic',
          'hoteldo-html-gold',
          'hoteldo-html-silver',
          'hoteldo-html-platinum'
      )
    GROUP BY sc_ps.transaction_id
)

SELECT DISTINCT
    tr.transaction_code,
    mdp.reservation_date,
    YEAR(mdp.reservation_date)*100 + MONTH(mdp.reservation_date)         AS year_month,
    mdp.payment_method_ch_ev                                              AS payment_method,
    mdp.country_code,
    tr.channel,
    tr.partner_data_id,
    mdp.purchase_type,
    tr.shopping_flow_source,
    m.currency_code,
    p.viaje,
    mdp.is_confirmed_flg                                                  AS emision,
    tr.status                                                             AS reservation_status,
    tr.cancel_type                                                        AS cancel_type,
    tr.buy_failure_segment                                                AS buy_failure_segment,
    mdp.gross_booking,
    CASE WHEN sch.transaction_id IS NOT NULL THEN 1 ELSE 0 END           AS is_scheduler,
    CASE
        WHEN sch.transaction_id IS NULL THEN 'No Scheduler'
        ELSE array_join(
            filter(
                array[
                    CASE WHEN sch.card_cnt > 0 THEN 'CARD x' || CAST(sch.card_cnt AS VARCHAR) END,
                    CASE WHEN sch.pix_cnt  > 0 THEN 'PIX x'  || CAST(sch.pix_cnt  AS VARCHAR) END,
                    CASE WHEN sch.mp_cnt   > 0 THEN 'MP x'   || CAST(sch.mp_cnt   AS VARCHAR) END
                ],
                x -> x IS NOT NULL
            ),
            ' + '
        )
    END                                                                   AS scheduler_payment_mix

FROM analytics.bi_transactional_fact_transactions tr

LEFT JOIN analytics.prd_payment_methods_fact mdp
    ON tr.transaction_code = mdp.transaction_code

LEFT JOIN (
    SELECT DISTINCT
        transaction_code,
        currency_code
    FROM analytics.bi_transactional_fact_charges
    WHERE reservation_year_month >= DATE('2025-01-01')
) m
    ON m.transaction_code = tr.transaction_code

LEFT JOIN (
    SELECT
        transaction_code,
        IF(
            ANY_MATCH(ARRAY_AGG(UPPER(trip_type)), x -> x = 'INT'),
            'INT',
            'NAC'
        ) AS viaje
    FROM analytics.bi_transactional_fact_products
    WHERE reservation_year_month >= DATE('2025-01-01')
    GROUP BY 1
) p
    ON p.transaction_code = tr.transaction_code

LEFT JOIN scheduler_agg sch
    ON sch.transaction_id = CAST(tr.transaction_code AS VARCHAR)

WHERE mdp.reservation_date       >= DATE('2025-01-01')
  AND mdp.reservation_year_month >= DATE('2025-01-01')
  AND tr.reservation_year_month  >= DATE('2025-01-01')
  AND tr.channel IN (
      'hoteldo-html-classic',
      'hoteldo-html-gold',
      'hoteldo-html-platinum',
      'hoteldo-html-silver'
  )

ORDER BY 2

--Limit 200
