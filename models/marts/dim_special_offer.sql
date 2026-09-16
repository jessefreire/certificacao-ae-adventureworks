-- Dimensao de oferta e desconto, pronta para o Power BI. Seleciona direto
-- do staging, sem regra de negocio.

with

special_offers as (

    select * from {{ ref('stg_adventure_works__specialoffer') }}

)

, final as (

    select
        special_offer_id as special_offer_key
        , offer_description
        , offer_type
        , offer_category
        , discount_pct
    from special_offers

)

select * from final