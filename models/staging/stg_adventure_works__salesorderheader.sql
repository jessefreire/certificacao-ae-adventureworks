-- Cabecalho do pedido. Uma linha por pedido, 31.465 no total, mai/2011 a
-- jun/2014. onlineorderflag e o eixo de controle de toda a analise: revenda
-- e 12,1% dos pedidos e 73% da receita.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'salesorderheader') }}

)

, renamed as (

    select
        salesorderid as sales_order_id
        , revisionnumber as revision_number
        , orderdate as order_date
        , duedate as due_date
        , shipdate as ship_date
        , status as order_status
        , onlineorderflag as is_online_order
        , salesordernumber as sales_order_number
        , purchaseordernumber as purchase_order_number
        , accountnumber as account_number
        , customerid as customer_id
        , salespersonid as sales_person_id
        , territoryid as territory_id
        , billtoaddressid as bill_to_address_id
        , shiptoaddressid as ship_to_address_id
        , shipmethodid as ship_method_id
        , creditcardid as credit_card_id
        , creditcardapprovalcode as credit_card_approval_code
        , currencyrateid as currency_rate_id
        , subtotal
        , taxamt as tax_amount
        , freight as freight_amount
        , totaldue as total_due_amount
        , comment as order_comment
        , modifieddate as modified_at
    from source

)

select * from renamed