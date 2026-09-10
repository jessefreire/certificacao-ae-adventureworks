-- Conferencia da estrutura, entre o DDL e a carga
--
-- Roda DEPOIS do 01-ddl e ANTES do 02-carga. Sao tres perguntas baratas que
-- evitam erro caro: descobrir que faltou uma tabela depois de 65 cargas, ou que
-- dinheiro virou double depois de a analise inteira estar escrita.
--
-- Cada consulta abaixo declara o que se espera ver. Se a coluna `resultado`
-- disser DIVERGE, pare: corrija o DDL e rode o 01 de novo antes de carregar.


/* ------------------------------------------------------------------------
   1. Todas as tabelas nasceram?

   O que conferimos: quantas tabelas existem no schema de destino.
   O que esperamos: exatamente 65.
   Por que importa: o install.sql tem 68 tabelas e tres ficam de fora por
     defeito de origem (Document e ProductPhoto tem coluna binaria;
     ProductReview esta quebrado no arquivo). Qualquer numero diferente de 65
     significa que o DDL nao rodou inteiro — e uma tabela faltando so
     apareceria no meio da carga, depois de dezenas de comandos.
   ------------------------------------------------------------------------ */
select
    65 as esperado
    , count(*) as tabelas_criadas
    , case
        when count(*) = 65 then 'ok'
        else 'DIVERGE'
    end as resultado
from workspace.information_schema.tables
where table_catalog = 'workspace'
    and table_schema = 'adventure_works';


/* ------------------------------------------------------------------------
   2. Dinheiro ficou exato?

O que conferimos: tipo, precisao e escala das tres colunas de valor do
salesorderdetail, que e a tabela onde a receita e calculada.
O que esperamos: decimal com precisao 19 e escala 4 nas tres.
Por que importa: e a conferencia mais importante desta etapa. Se a carga
tivesse inferido tipo, dinheiro viria como double, e o teste de aceite do
briefing (US$ 12.646.112,16) sairia arredondado — o numero nao fecharia e
a causa estaria escondida no tipo, nao na consulta.
Detalhe da escala: unitpricediscount guarda percentual (0.0200 para 2%).
Com escala menor que 4 o desconto arredonda e desaparece do calculo.
Atencao ao ler: a coluna data_type traz so o tipo base (DECIMAL). Precisao
e escala vivem em colunas separadas — por isso as tres aparecem juntas.
------------------------------------------------------------------------ */
select
    column_name
    , data_type
    , numeric_precision
    , numeric_scale
    , case
        when data_type = 'DECIMAL' and numeric_precision = 19 and numeric_scale = 4
            then 'ok'
        else 'DIVERGE'
    end as resultado
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal')
order by column_name asc;


/* ------------------------------------------------------------------------
   3. Sobrou alguma coluna numerica em ponto flutuante?

O que conferimos: qualquer coluna do schema declarada como double ou float.
O que esperamos: zero linhas. Resultado vazio e sucesso aqui.
Por que importa: a consulta 2 olha tres colunas de uma tabela. Esta olha o
schema inteiro, e pega o caso que a 2 nao veria — uma coluna de valor em
outra tabela (subtotal, standardcost, listprice, salesytd) que tenha
escapado da lista de dinheiro do gerador.
O que fazer se aparecer alguma: conferir se a coluna e mesmo de valor
monetario. Se for, ela precisa entrar na lista DINHEIRO do gerador do DDL
e o 01 roda de novo. Peso e medida de dimensao fisica podem ficar em
ponto flutuante sem prejuizo.
------------------------------------------------------------------------ */
select
    table_name
    , column_name
    , data_type
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and lower(data_type) in ('double', 'float', 'real')
order by table_name asc, column_name asc;
