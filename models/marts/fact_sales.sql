-- Fato de vendas, pronta para o Power BI. Seleciona do int_, so renomeando
-- as chaves estrangeiras para o padrao _key das dimensoes.

with

int_sales as (

    select * from {{ ref('int_adventure_works__sales') }}

)

, final as (

    select
        sales_order_detail_id
        , sales_order_id
        , sales_order_number
        , order_date
        , product_id as product_key
        , customer_id as customer_key
        , bill_to_address_id as bill_to_geography_key
        , credit_card_id as credit_card_key
        , territory_id as territory_key
        , special_offer_id as special_offer_key
        , sales_person_id as salesperson_key
        , order_status as status
        , channel
        , has_promotion_reason
        , unit_price
        , unit_price_discount_rate
        , order_quantity
        , gross_revenue
        , discount_amount
        , net_revenue
    from int_sales

)

select * from final
