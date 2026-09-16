-- Dimensao de territorio de venda, pronta para o Power BI. Seleciona direto
-- do staging, sem regra de negocio.
--
-- territory_country_region_code (staging) e diferente do pais de
-- dim_geography — descrevem a mesma venda por angulos diferentes.

with

territories as (

    select * from {{ ref('stg_adventure_works__salesterritory') }}

)

, final as (

    select
        territory_id as territory_key
        , territory_name
        , territory_country_region_code as territory_country
        , territory_group
    from territories

)

select * from final