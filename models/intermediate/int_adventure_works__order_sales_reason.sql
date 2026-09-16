-- Ponte real entre pedido e motivo, cobrindo TODOS os 31.465 pedidos — nao
-- so os 23.012 com motivo registrado. Os 8.453 sem motivo (26,9%, 100% da
-- revenda) recebem sales_reason_id = -1, senao esse membro fica
-- inalcancavel em dim_sales_reason.
--
-- allocation_factor = 1 / (motivos do pedido). Pedido com 1 motivo tem
-- fator 1; com 2 ou 3, o fator reparte para a soma continuar batendo com
-- o total do pedido. Sem isso, somar receita por motivo infla o resultado
-- em US$ 8.426.399,95 (+29%).

with

orders as (

    select sales_order_id from {{ ref('stg_adventure_works__salesorderheader') }}

)

, order_reasons as (

    select sales_order_id, sales_reason_id
    from {{ ref('stg_adventure_works__salesorderheadersalesreason') }}

)

, orders_sem_motivo as (

    select
        orders.sales_order_id
        , -1 as sales_reason_id
    from orders
    left join order_reasons
        on orders.sales_order_id = order_reasons.sales_order_id
    where order_reasons.sales_order_id is null

)

, cobertura_completa as (

    select sales_order_id, sales_reason_id from order_reasons

    union all

    select sales_order_id, sales_reason_id from orders_sem_motivo

)

, com_allocation_factor as (

    select
        sales_order_id
        , sales_reason_id
        , 1.0 / count(*) over (partition by sales_order_id) as allocation_factor
    from cobertura_completa

)

select * from com_allocation_factor