-- Territorios de venda.
--
-- Cuidado ao consumir: o pais daqui (territory_country_region_code) NAO e o
-- mesmo pais de dim_geography — sao dois "pais" que descrevem a mesma venda
-- de angulos diferentes, e por isso o nome carrega o prefixo territory_.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'salesterritory') }}

)

, renamed as (

    select
        territoryid as territory_id
        , name as territory_name
        , countryregioncode as territory_country_region_code
        , `group` as territory_group
        , salesytd as sales_year_to_date
        , saleslastyear as sales_last_year
        , costytd as cost_year_to_date
        , costlastyear as cost_last_year
        , modifieddate as modified_at
    from source

)

select * from renamed