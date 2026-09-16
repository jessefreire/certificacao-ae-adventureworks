-- Dimensao de vendedor, pronta para o Power BI. Seleciona do int_, que ja
-- resolveu o nome e acrescentou o membro "Sem vendedor".

with

int_salesperson as (

    select * from {{ ref('int_adventure_works__salesperson') }}

)

, final as (

    select
        business_entity_id as salesperson_key
        , salesperson_name
        , sales_quota
        , commission_pct
    from int_salesperson

)

select * from final