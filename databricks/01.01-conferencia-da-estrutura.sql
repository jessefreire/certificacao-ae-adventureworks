-- Conferencia da estrutura: roda DEPOIS do 01-ddl e ANTES do 02-carga.
-- Tres consultas baratas que evitam descobrir problema no meio de 65 cargas.


-- 1. As tabelas nasceram? Tem de dar 65.
--    O install.sql tem 68; tres ficam de fora por defeito de origem.
select count(*) as tabelas_criadas
from workspace.information_schema.tables
where table_catalog = 'workspace'
    and table_schema = 'adventure_works';


-- 2. Dinheiro nao virou ponto flutuante? Tem de vir DECIMAL nas tres.
--    Com double, o teste de aceite do briefing sai arredondado.
select
    column_name
    , data_type
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal');


-- 3. A precisao esta certa? Tem de dar 19 e 4 nas tres.
--    data_type mostra so o tipo base; escala e precisao ficam em outras colunas.
--    unitpricediscount guarda percentual (0.0200 = 2%): com escala menor que 4,
--    o desconto arredonda e desaparece do calculo.
select
    column_name
    , data_type
    , numeric_precision
    , numeric_scale
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal');
