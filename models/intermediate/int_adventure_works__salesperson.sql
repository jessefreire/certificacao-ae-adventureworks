-- Vendedor com o nome resolvido (join com person) e o membro "Sem vendedor"
-- (-1) acrescentado por union all. Cobre os 27.659 pedidos online que nao
-- tem salespersonid — 87,9% do total, e coincide exatamente com o canal.

with

salespeople as (

    select * from {{ ref('stg_adventure_works__salesperson') }}

)

, people as (

    select * from {{ ref('stg_adventure_works__person') }}

)

, joined as (

    select
        salespeople.business_entity_id
        , people.first_name || ' ' || people.last_name as salesperson_name
        , salespeople.sales_quota
        , salespeople.commission_pct
    from salespeople
    left join people
        on salespeople.business_entity_id = people.business_entity_id

)

, com_membro_desconhecido as (

    select * from joined

    union all

    select
        -1 as business_entity_id
        , 'Sem vendedor' as salesperson_name
        , cast(null as decimal(19, 4)) as sales_quota
        , cast(null as decimal(19, 4)) as commission_pct

)

select * from com_membro_desconhecido