-- Ponte final entre pedido e motivo, pronta para o Power BI. Seleciona do
-- int_, que ja cobre os 31.465 pedidos com allocation_factor.

with

int_bridge as (

    select * from {{ ref('int_adventure_works__order_sales_reason') }}

)

, final as (

    select
        sales_order_id
        , sales_reason_id as sales_reason_key
        , allocation_factor
    from int_bridge

)

select * from final