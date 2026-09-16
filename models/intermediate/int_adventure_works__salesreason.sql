-- Motivo de venda com o membro "Nao informado" (-1) acrescentado por union
-- all. Cobre os 8.453 pedidos sem motivo — 26,9% do total, incluindo 100%
-- da revenda.

with

sales_reasons as (

    select * from {{ ref('stg_adventure_works__salesreason') }}

)

, com_membro_desconhecido as (

    select
        sales_reason_id
        , sales_reason_name
        , sales_reason_type
    from sales_reasons

    union all

    select
        -1 as sales_reason_id
        , 'Nao informado' as sales_reason_name
        , 'Nao informado' as sales_reason_type

)

select * from com_membro_desconhecido