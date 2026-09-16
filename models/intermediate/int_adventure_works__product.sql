-- Produto enriquecido com a hierarquia de categoria. E aqui que o "Sem
-- subcategoria" nasce: 209 dos 504 produtos nao tem productsubcategoryid, e
-- um inner join os eliminaria — a constatacao de catalogo ocioso (238 nunca
-- venderam) deixaria de ser respondivel. Left join preserva todos os 504.

with

products as (

    select * from {{ ref('stg_adventure_works__product') }}

)

, subcategories as (

    select * from {{ ref('stg_adventure_works__productsubcategory') }}

)

, categories as (

    select * from {{ ref('stg_adventure_works__productcategory') }}

)

, joined as (

    select
        products.product_id
        , products.product_name
        , products.product_number
        , products.color
        , products.product_line
        , products.product_class
        , products.product_style
        , products.list_price
        , products.is_finished_good
        , products.sell_start_date
        , products.sell_end_date
        , products.discontinued_date
        , coalesce(subcategories.product_subcategory_name, 'Sem subcategoria')
            as product_subcategory_name
        , coalesce(categories.product_category_name, 'Sem categoria')
            as product_category_name
    from products
    left join subcategories
        on products.product_subcategory_id = subcategories.product_subcategory_id
    left join categories
        on subcategories.product_category_id = categories.product_category_id

)

select * from joined