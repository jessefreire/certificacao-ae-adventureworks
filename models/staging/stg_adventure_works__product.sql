-- Produtos. Sao 504, dos quais 266 vendem e 238 nunca apareceram em pedido — a
-- dimensao mantem todos, e a marcacao "Sem subcategoria" acontece no intermediate,
-- nao aqui.
--
-- rowguid fica de fora: replicacao, sem uso analitico.

with

source as (

    select * from {{ source('adventure_works', 'product') }}

)

, renamed as (

    select
        productid as product_id
        , name as product_name
        , productnumber as product_number
        , makeflag as is_make_flag
        , finishedgoodsflag as is_finished_good
        , color
        , safetystocklevel as safety_stock_level
        , reorderpoint as reorder_point
        , standardcost as standard_cost
        , listprice as list_price
        , size as product_size
        , sizeunitmeasurecode as size_unit_measure_code
        , weightunitmeasurecode as weight_unit_measure_code
        , weight
        , daystomanufacture as days_to_manufacture
        , productline as product_line
        , class as product_class
        , style as product_style
        , productsubcategoryid as product_subcategory_id
        , productmodelid as product_model_id
        , sellstartdate as sell_start_date
        , sellenddate as sell_end_date
        , discontinueddate as discontinued_date
        , modifieddate as modified_at
    from source

)

select * from renamed