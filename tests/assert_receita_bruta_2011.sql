-- Aceite do CEO: receita bruta de 2011 tem que bater com o numero que ele
-- acompanha (12.646.112,1607), com margem de 1 centavo para arredondamento.

with

receita as (

    select sum(gross_revenue) as receita_bruta_2011
    from {{ ref('fact_sales') }}
    where extract(year from order_date) = 2011

)

select *
from receita
where abs(receita_bruta_2011 - 12646112.1607) > 0.01