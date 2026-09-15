-- Subcategorias de produto. 209 dos 504 produtos nao tem subcategoria, e
-- nenhum deles vende — dim_product mantem esses produtos com membro "Sem
-- subcategoria" em vez de descarta-los.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'productsubcategory') }}

)

, renamed as (

    select
        productsubcategoryid as product_subcategory_id
        , productcategoryid as product_category_id
        , name as product_subcategory_name
        , modifieddate as modified_at
    from source

)

select * from renamed