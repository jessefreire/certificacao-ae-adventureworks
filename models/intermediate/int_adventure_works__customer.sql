-- Cliente enriquecido com o nome resolvido e o eixo de canal. Loja tem
-- prioridade sobre pessoa fisica no nome: coalesce(store.store_name, person).
-- customer_type nasce aqui, nao na staging.

with

customers as (

    select * from {{ ref('stg_adventure_works__customer') }}

)

, people as (

    select * from {{ ref('stg_adventure_works__person') }}

)

, stores as (

    select * from {{ ref('stg_adventure_works__store') }}

)

, joined as (

    select
        customers.customer_id
        , customers.account_number
        , customers.territory_id
        , coalesce(stores.store_name, people.first_name || ' ' || people.last_name)
            as customer_name
        , case when customers.store_id is not null then 'revenda' else 'pessoa fisica' end
            as customer_type
    from customers
    left join people
        on customers.person_id = people.business_entity_id
    left join stores
        on customers.store_id = stores.business_entity_id

)

select * from joined