-- Clientes. O grao de dim_customer: liga person (pessoa fisica) ou store
-- (revenda) a um customerid, e nasce aqui a distincao de canal.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'customer') }}

)

, renamed as (

    select
        customerid as customer_id
        , personid as person_id
        , storeid as store_id
        , territoryid as territory_id
        , accountnumber as account_number
        , modifieddate as modified_at
        , case when storeid is not null then 'revenda' else 'pessoa fisica' end
            as customer_type
    from source

)

select * from renamed