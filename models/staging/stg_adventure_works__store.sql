-- Lojas revendedoras. Tem prioridade sobre person no nome do cliente em
-- dim_customer (coalesce(store.name, person)).
--
-- rowguid e demographics ficam de fora: replicacao e XML cru, sem uso em
-- nenhuma das seis perguntas do briefing.

with

source as (

    select * from {{ source('adventure_works', 'store') }}

)

, renamed as (

    select
        businessentityid as business_entity_id
        , name as store_name
        , salespersonid as sales_person_id
        , modifieddate as modified_at
    from source

)

select * from renamed