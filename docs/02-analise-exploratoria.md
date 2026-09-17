# Etapa 2 — Análise exploratória de dados

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 2 de 10 — *"Creation of an exploratory data analysis, generating insights and a
presentation explaining how these insights help to understand the dataset."*
**Status:** completa — notebook publicado em `notebooks/02-analise-exploratoria.py`
**Entregável do briefing:** notebook (Python ou SQL) com código, gráficos e comentário por
insight

> Este documento resume o processo e as decisões da Etapa 2. O entregável avaliado é o
> próprio notebook — aqui fica o "porquê" por trás dele, para retomar o trabalho sem
> reapurar o que já foi medido.

---

## 1. Escopo de ingestão: camada bruta completa, camada modelada de 17 tabelas

Duas decisões diferentes, tomadas separadamente:

- **Ingestão**: a camada bruta sobe completa — das 68 tabelas do `install.sql`, 65 carregam.
  Três ficam de fora por defeito de origem, não por escolha: `Document` e `ProductPhoto` têm
  coluna binária, que não atravessa um arquivo de texto; `ProductReview` está quebrado na
  origem (sete campos onde o DDL declara oito, com quebra de linha dentro de campo). Custo de
  subir o resto: 79 MB, 759 mil linhas.
- **Modelagem**: apenas 17 tabelas seguem para o dbt como `source` — as 16 que as 6 perguntas
  e os 14 aprofundamentos exigem, mais `salesperson` (existe em 3.806 pedidos, exatamente os
  de revenda, e casa com o eixo de canal). Declarar uma tabela como source é assumir teste e
  documentação dela — separar ingestão de modelagem evita ter que reabrir a etapa de carga se
  o escopo de análise crescer depois.

Verificado nos arquivos antes de carregar: as 7 junções que a análise depende (pedido↔endereço,
pedido↔cliente, pedido↔território, pedido↔cartão, cliente↔nome, item↔produto, item↔oferta) —
todas com zero órfão em 31.465 pedidos e 121.317 itens.

## 2. Setup do Databricks

Ordem executada (schema fixo `adventure_works`, exigido pelo briefing; volume gerenciado
`raw_adventure_works` no catálogo `workspace`, porque o briefing não deixa nomear o schema por
camada):

1. Criar o schema `adventure_works` no Unity Catalog.
2. Criar um Volume gerenciado (`raw_adventure_works`) dentro do schema, para os arquivos brutos.
3. Subir a pasta `AdventureWorks/` inteira para o volume (preserva estrutura — o caminho que o
   script de carga espera).
4. Criar um SQL Warehouse (o menor disponível).
5. Rodar `databricks/01-ingestao-adventure-works.sql` (81 células: 17 tabelas do escopo de
   análise, 48 restantes da camada bruta, e 6 conferências).

A carga usa `create or replace table ... as select` sobre `read_files`, não `copy into` — cada
tabela é uma instrução só, e repetir substitui em vez de somar. Essa troca eliminou o erro mais
caro do processo (ver §4).

## 3. As seis conferências de carga

Rodadas antes de qualquer análise — se uma falhar, todo número da exploração fica suspeito:

| Conferência | Resultado |
|---|---|
| Contagem por tabela vs. arquivo de origem | 17/17 batem (`salesorderdetail` 121.317, `salesorderheader` 31.465, `person` 19.972, `customer` 19.820, `address` 19.614, `creditcard` 19.118, `store` 701, `product` 504) |
| As 7 junções da análise | zero órfão em todas |
| Sobrevivência do NULL | 27.659 pedidos sem vendedor aparecem como `NULL`, não como vendedor `0` — sem o `nullValue` na carga, o corte por canal ficaria errado em silêncio |
| Teste de aceite do CEO | soma exata **12.646.112,1607**, que arredondada bate com os 12.646.112,16 do briefing (a diferença de casas decimais vem de `unitprice` ter 4 casas; `decimal(19,4)` evita resíduo binário que `double` acumularia) |
| Integridade do `linetotal` | 121.317 linhas, zero fora de um centavo — `unitprice × (1 − desconto) × quantidade` reproduz o valor gravado |
| Tipo do dinheiro | colunas monetárias em `DECIMAL(19,4)`, não `DOUBLE` |

## 4. Erros encontrados e corrigidos

Registrados porque cada um custou tempo e mudaria conclusões se não fosse pego:

- **Compute errado**: `RESOURCE_EXHAUSTED` mascarado como erro de cliente gRPC. Causa real:
  rodar `COPY INTO` em compute de notebook (Spark Connect) em vez do SQL Warehouse. Corrigido
  trocando de superfície de execução.
- **`force = true` não protege contra duplicação**: hipótese errada registrada em 9 arquivos —
  `COPY INTO` é idempotente por padrão e `force` desliga essa proteção, então repetir o comando
  depois de uma falha soma a carga de novo (`address` chegou a 3×, `employeepayhistory` a 5×).
  Sinal de reconhecimento: contagem sendo múltiplo exato do esperado. Corrigido migrando para
  `create or replace table` (substitui, nunca soma).
- **Teste de aceite reprovando base correta**: comparar `12.646.112,1607` contra o literal
  arredondado `12.646.112,16` com igualdade exata nunca fecharia — o teste tinha o bug, não a
  carga.
- **Linter com falso sucesso**: sqlfluff 1.4.5 pula em silêncio arquivo acima de 20.000 bytes
  (o DDL cresceu e saiu do lint sem aviso) e falhou silenciosamente ao lintar entre drives
  diferentes (relatou 0 violações onde havia 78). Os dois só apareceram com teste negativo.

Nenhum dos erros de carga tocou as 17 tabelas do escopo de análise — verificado antes de
corrigir.

## 5. O notebook

`notebooks/02-analise-exploratoria.py` — 76 células (40 markdown, 31 SQL em células `%sql`,
5 de gráfico), linguagem padrão Python (os gráficos exigem) com SQL onde o code style da
Indicium AI se aplica e é avaliado. Estrutura: perfil do dado → reconciliação com o número do
CEO → uma seção por pergunta do briefing (a–f), cada uma com consulta, evidência e comentário
do que ela revela, seguindo os mesmos 14 aprofundamentos definidos na Etapa 1
(`docs/01-kpis-e-perguntas.md`).

Cada célula de código leva título curto no formato `<seção>.<sequência> <rótulo>` (ex.
`3.2 Cartão discrimina?`), com o número igual ao do cabeçalho de markdown correspondente — sem
isso, o painel do Databricks mostra "Cell 37" e ninguém acha a consulta de novo.

### Os 5 gráficos, um por achado forte

1. Série mensal de receita, com a quebra estrutural de jul/2013 anotada.
2. Barras de tipo de cartão, mostrando as quatro bandeiras em fatias praticamente iguais.
3. Pareto dos 266 produtos que efetivamente vendem (de 504 no catálogo).
4. Ticket médio por país.
5. Promoção vs. não-promoção, facetado por canal — o gráfico que evita a leitura errada (ver
   §6).

### Os quatro avisos que evitam leitura errada

- Motivo de venda só existe no canal online — qualquer gráfico de motivo descreve um quarto da
  empresa, não a empresa inteira.
- Ticket médio por país varia 3,4× por mistura de canal, não por diferença de mercado.
- As cinco maiores cidades somam 11% da receita — não concentram nada, ao contrário do que uma
  leitura rápida sugeriria.
- A série mensal tem quebra estrutural em jul/2013 — qualquer leitura de tendência sem essa
  anotação está errada.

## 6. Dois erros da Etapa 1 corrigidos durante a Etapa 2

Registrados dentro do próprio notebook, porque os dois inverteriam a recomendação de negócio:

- **Coluna errada de endereço**: usar a coluna errada de cidade deu 39,7% de concentração nas
  5 maiores cidades (recomendaria "concentre esforço em cinco praças"); o número certo é 11,0%
  e diz o contrário.
- **Comparação de promoção sem controlar canal**: deu 2,10 contra 9,57 (pareceria que promoção
  destrói o valor do pedido); na verdade comparava varejo com atacado — controlando por canal,
  a leitura muda.

## 7. Sobre o MCP do Databricks

Avaliado e descartado nesta etapa: os MCP gerenciados do Databricks servem Unity Catalog,
Genie e vector search — nenhum roda SQL exploratório, que é o que a EDA precisa. O
`databricks-sql-connector` do Python serviu para iterar consultas fora do notebook antes de
colá-las nele. O MCP do Genie fica reservado para a Etapa 7, se o dashboard AI/BI existir e
valer testar perguntas em linguagem natural.

## 8. Pendências desta etapa

- Carregar as 48 tabelas restantes da camada bruta quando a cota da Free Edition renovar (não
  afeta nenhuma das 6 perguntas do briefing).
- Nenhuma pendência bloqueia a Etapa 3 em diante — as 17 tabelas do escopo de análise estão
  íntegras e conferidas.
