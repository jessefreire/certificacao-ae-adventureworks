-- Dimensao de produto, pronta para o Power BI. Seleciona do int_, que ja
-- resolveu a hierarquia de categoria com "Sem subcategoria"/"Sem categoria".

with

int_product as (

    select * from {{ ref('int_adventure_works__product') }}

)

, final as (

    select
        product_id as product_key
        , product_name
        , product_number
        , product_subcategory_name as subcategory
        , product_category_name as category
        , list_price
        , color
        , product_line
    from int_product

)

select * from final