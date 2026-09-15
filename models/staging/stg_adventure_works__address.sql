-- Enderecos, no grao de address. E o endereco de COBRANCA do pedido
-- (billtoaddressid) que vai alimentar dim_geography.
--
-- rowguid e spatiallocation ficam de fora: o primeiro e artefato de replicacao
-- do SQL Server sem uso analitico; o segundo e geometria do SQL Server, sem
-- representacao limpa em CSV e sem uso em nenhuma das seis perguntas do briefing.

with

source as (

    select * from {{ source('adventure_works', 'address') }}

)

, renamed as (

    select
        addressid as address_id
        , addressline1 as address_line_1
        , addressline2 as address_line_2
        , city
        , stateprovinceid as state_province_id
        , postalcode as postal_code
        , modifieddate as modified_at
    from source

)

select * from renamed