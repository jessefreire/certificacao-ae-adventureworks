-- Item de pedido, o grao da futura fact_sales. Renomeia e tipa, sem regra de
-- negocio: staging que ja agrega ou ja junta e desvio de camada.
--
-- gross_revenue e discount_amount nao nascem aqui: sao metrica derivada, nao
-- rename. Entram no int_adventure_works__salesorderdetail, na branch da fato.

with

source as (

    select * from {{ source('adventure_works', 'salesorderdetail') }}

)

, renamed as (

    select
        salesorderdetailid as sales_order_detail_id
        , salesorderid as sales_order_id
        , productid as product_id
        , specialofferid as special_offer_id
        , orderqty as order_quantity
        , unitprice as unit_price
        , unitpricediscount as unit_price_discount_rate
        , linetotal as net_revenue
        , modifieddate as modified_at
    from source

)

select * from renamed
