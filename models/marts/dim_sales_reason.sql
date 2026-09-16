-- Dimensao de motivo de venda, pronta para o Power BI. Seleciona do int_,
-- que ja acrescentou o membro "Nao informado".

with

int_sales_reason as (

    select * from {{ ref('int_adventure_works__salesreason') }}

)

, final as (

    select
        sales_reason_id as sales_reason_key
        , sales_reason_name as reason_name
        , sales_reason_type as reason_type
    from int_sales_reason

)

select * from final