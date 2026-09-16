-- Dimensao de datas, pronta para o Power BI. Seleciona direto do int_, sem
-- transformacao adicional.

with

dates as (

    select * from {{ ref('int_adventure_works__dates') }}

)

select * from dates