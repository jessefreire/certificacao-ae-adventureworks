-- Ofertas e descontos aplicados ao item de pedido.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'specialoffer') }}

)

, renamed as (

    select
        specialofferid as special_offer_id
        , description as offer_description
        , discountpct as discount_pct
        , type as offer_type
        , category as offer_category
        , startdate as start_date
        , enddate as end_date
        , minqty as min_quantity
        , maxqty as max_quantity
        , modifieddate as modified_at
    from source

)

select * from renamed