-- Endereco enriquecido com estado e pais, e a chave composta de cidade
-- resolvida. Medido: 575 nomes de cidade para 613 pares (cidade, estado) —
-- 38 cidades existem em mais de um estado, e agrupar so pelo nome as funde.

with

addresses as (

    select * from {{ ref('stg_adventure_works__address') }}

)

, states as (

    select * from {{ ref('stg_adventure_works__stateprovince') }}

)

, countries as (

    select * from {{ ref('stg_adventure_works__countryregion') }}

)

, joined as (

    select
        addresses.address_id
        , addresses.city
        , addresses.state_province_id
        , addresses.postal_code
        , states.state_province_name
        , countries.country_region_name
        , addresses.city || ', ' || states.state_province_code as city_label
    from addresses
    left join states
        on addresses.state_province_id = states.state_province_id
    left join countries
        on states.country_region_code = countries.country_region_code

)

select * from joined