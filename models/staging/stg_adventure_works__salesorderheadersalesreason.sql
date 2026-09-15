-- Ponte de origem entre pedido e motivo. So tem linha para os 23.012 pedidos
-- QUE TEM motivo — os outros 8.453 (26,9%, incluindo 100% da revenda) nao
-- existem aqui. A bridge real, com cobertura completa e allocation_factor,
-- e construida no intermediate a partir deste model.

with

source as (

    select * from {{ source('adventure_works', 'salesorderheadersalesreason') }}

)

, renamed as (

    select
        salesorderid as sales_order_id
        , salesreasonid as sales_reason_id
        , modifieddate as modified_at
    from source

)

select * from renamed