-- Item de pedido, o grao da futura fact_sales. Renomeia e tipa, sem regra de negocio:
-- staging que ja agrega ou ja junta e desvio de camada.
--
-- As duas colunas calculadas existem porque a origem so traz o linetotal, que e a receita
-- LIQUIDA. A bruta — orderqty * unitprice — e o numero que o CEO acompanha, e sem ela o
-- teste de aceite nao teria de onde sair. Elas vem por ultimo porque o code style pede
-- colunas simples antes das calculadas (regra L034).

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
        , orderqty * unitprice as gross_revenue
        , orderqty * unitprice - linetotal as discount_amount
    from source

)

select * from renamed
