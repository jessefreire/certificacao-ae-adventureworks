-- Item de pedido enriquecido com o cabecalho, pronto para virar a fato. As
-- duas metricas de receita nascem aqui, nao na staging: gross_revenue e o
-- numero que o CEO acompanha (12.646.112,1607 em 2011), e a origem so traz
-- a liquida (net_revenue).
--
-- credit_card_id e sales_person_id usam coalesce(-1) para casar com o
-- membro sintetico das dimensoes — sem isso, um pedido sem cartao ou sem
-- vendedor ficaria com FK nula, o que a maioria das ferramentas de BI trata
-- mal em relacionamento.
--
-- has_promotion_reason e o atalho para a pergunta (f): responde sem
-- atravessar a bridge, verificando se o pedido tem algum motivo cuja
-- categoria e 'Promotion'.

with

items as (

    select * from {{ ref('stg_adventure_works__salesorderdetail') }}

)

, headers as (

    select * from {{ ref('stg_adventure_works__salesorderheader') }}

)

, bridge as (

    select * from {{ ref('bridge_order_sales_reason') }}

)

, sales_reasons as (

    select * from {{ ref('dim_sales_reason') }}

)

, promotion_orders as (

    select distinct bridge.sales_order_id
    from bridge
    inner join sales_reasons
        on bridge.sales_reason_key = sales_reasons.sales_reason_key
    where sales_reasons.reason_type = 'Promotion'

)

, joined as (

    select
        items.sales_order_detail_id
        , items.sales_order_id
        , headers.sales_order_number
        , items.product_id
        , headers.customer_id
        , headers.bill_to_address_id
        , headers.territory_id
        , items.special_offer_id
        , headers.order_status
        , items.unit_price
        , items.unit_price_discount_rate
        , items.order_quantity
        , items.net_revenue
        , cast(headers.order_date as date) as order_date
        , coalesce(headers.credit_card_id, -1) as credit_card_id
        , coalesce(headers.sales_person_id, -1) as sales_person_id
        , case
            when headers.is_online_order then 'online'
            else 'revenda'
        end as channel
        , (promotion_orders.sales_order_id is not null) as has_promotion_reason
        , items.order_quantity * items.unit_price as gross_revenue
        , (items.order_quantity * items.unit_price) - items.net_revenue as discount_amount
    from items
    inner join headers
        on items.sales_order_id = headers.sales_order_id
    left join promotion_orders
        on items.sales_order_id = promotion_orders.sales_order_id

)

select * from joined