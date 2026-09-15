-- Vendedores. O salespersonid do pedido e nulo em 27.659 dos 31.465 pedidos
-- (87,9%), e coincide EXATAMENTE com os pedidos online — nao e dado faltante,
-- e o significado do canal. O membro "sem vendedor" entra no intermediate,
-- nao aqui.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'salesperson') }}

)

, renamed as (

    select
        businessentityid as business_entity_id
        , territoryid as territory_id
        , salesquota as sales_quota
        , bonus
        , commissionpct as commission_pct
        , salesytd as sales_year_to_date
        , saleslastyear as sales_last_year
        , modifieddate as modified_at
    from source

)

select * from renamed