-- Paises. Renomeia e tipa, sem regra de negocio: staging que ja agrega ou ja
-- junta e desvio de camada.

with

source as (

    select * from {{ source('adventure_works', 'countryregion') }}

)

, renamed as (

    select
        countryregioncode as country_region_code
        , name as country_region_name
        , modifieddate as modified_at
    from source

)

select * from renamed