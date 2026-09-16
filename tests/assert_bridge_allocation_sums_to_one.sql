-- Confere que o allocation_factor soma exatamente 1 por pedido. Esperado:
-- nenhuma linha retornada — se aparecer, o rateio esta errado e a receita
-- por motivo diverge do total do pedido.

select
    sales_order_id
    , sum(allocation_factor) as soma_allocation_factor
from {{ ref('bridge_order_sales_reason') }}
group by sales_order_id
having abs(sum(allocation_factor) - 1.0) > 0.0001