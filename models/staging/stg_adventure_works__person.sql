-- Pessoas fisicas. Alimenta o nome do cliente em dim_customer quando nao ha loja
-- associada (coalesce prioriza store.name).
--
-- rowguid, additionalcontactinfo e demographics ficam de fora: replicacao e XML
-- cru, sem uso em nenhuma das seis perguntas do briefing.

with

source as (

    select * from {{ source('adventure_works', 'person') }}

)

, renamed as (

    select
        businessentityid as business_entity_id
        , persontype as person_type
        , namestyle as is_name_western_style
        , title
        , firstname as first_name
        , middlename as middle_name
        , lastname as last_name
        , suffix
        , emailpromotion as email_promotion_level
        , modifieddate as modified_at
    from source

)

select * from renamed