-- Dimensao de geografia de cobranca (bill-to), pronta para o Power BI.
-- Seleciona do int_, que ja resolveu estado, pais e o city_label.

with

int_geography as (

    select * from {{ ref('int_adventure_works__geography') }}

)

, final as (

    select
        address_id as bill_to_geography_key
        , city
        , state_province_id
        , city_label
        , state_province_name as state_province
        , country_region_name as billing_country
        , postal_code
    from int_geography

)

select * from final