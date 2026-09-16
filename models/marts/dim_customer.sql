-- Dimensao de cliente, pronta para o Power BI. Seleciona do int_, que ja
-- resolveu o nome e o tipo de canal.

with

int_customer as (

    select * from {{ ref('int_adventure_works__customer') }}

)

, final as (

    select
        customer_id as customer_key
        , customer_name
        , customer_type
        , account_number
    from int_customer

)

select * from final