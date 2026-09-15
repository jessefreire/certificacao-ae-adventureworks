-- Categorias de produto. Nivel mais alto da hierarquia de produto.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'productcategory') }}

)

, renamed as (

    select
        productcategoryid as product_category_id
        , name as product_category_name
        , modifieddate as modified_at
    from source

)

select * from renamed