# Etapa 8 — Documentação das regras de negócio

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 8 de 10 — documentação das regras de negócio do modelo de dados
**Status:** completa
**Fonte**: consolida decisões já registradas em `docs/03-decisoes-de-modelagem.md` e nos
arquivos `.yml` de `models/marts/` — este documento existe para reunir as regras num só
lugar, como entregável autônomo.

---

## 1. Grão e o que cada linha da fato significa

`fact_sales` está no grão do **item de pedido** (`sales_order_detail_id`, chave primária,
121.317 linhas) — não no grão do pedido. Um pedido com 3 itens gera 3 linhas na fato.

**Por que este grão, e não o do pedido**: o teste de aceite do CEO (receita bruta de 2011 =
US$ 12.646.112,1607) só fecha com `orderqty × unitprice`, que só existe no nível do item. O
subtotal do pedido é a receita líquida e fecha em 12.641.672,21 — uma fato no grão do pedido
erraria o aceite em US$ 4.439,95 sem forma de corrigir. A fórmula da pergunta (b) do briefing
também pede bruta e desconto separados, as mesmas duas colunas do item.

**O que fica fora de propósito**: frete, imposto e `totaldue` do pedido não entram na fato —
são atributos do pedido (não do item), valem 10,9% do total, e nenhuma das 6 perguntas do
briefing os usa.

**Contagem de pedidos**: como o grão é o item, "número de pedidos" nunca é `COUNT(*)` na
fato — é sempre `COUNT(DISTINCT sales_order_id)`.

## 2. Colunas que parecem métrica e não são (atributos)

Regra geral: uma coluna é métrica se **somar** ela responde a uma pergunta de negócio; caso
contrário, é atributo — mesmo sendo numérica.

| Coluna | Tabela | Por que não é métrica |
|---|---|---|
| `unit_price` | `fact_sales` | preço unitário — somar preços de itens diferentes não significa nada |
| `unit_price_discount_rate` | `fact_sales` | taxa (0 a 1) — soma de taxas não é uma taxa válida |
| `discount_pct` | `dim_special_offer` | percentual da oferta, atributo descritivo da dimensão |

Métricas de verdade na fato: `order_quantity`, `gross_revenue`, `discount_amount`,
`net_revenue`.

## 3. Motivo de venda: ponte, não relação direta

Um pedido pode ter até 3 motivos de venda (`SalesReason` na origem não tem coluna de ordem,
peso ou "principal" — escolher um só exigiria inventar critério para 4.482 pedidos). Por
isso, `dim_sales_reason` se relaciona com `fact_sales` através de `bridge_order_sales_reason`,
não por uma FK direta na fato.

**Regra que precisa estar sempre visível para quem usa o modelo**: **a receita mora na
fato — a ponte serve para filtrar e fatiar, nunca para somar através dela.** Somar receita
atravessando a ponte sem cuidado infla o resultado em ~29% (pedidos com 2 ou 3 motivos
contam a receita 2 ou 3 vezes). Quando uma métrica de fato precisa ser quebrada por motivo
(ex. "receita por motivo de venda"), o cálculo correto multiplica pela coluna
`allocation_factor` da ponte (`1 / número de motivos do pedido`) antes de somar — nunca soma
direto.

**Cobertura do motivo**: 23.012 dos 31.465 pedidos têm motivo registrado — 83,2% no canal
online e **zero** na revenda (nenhum dos 3.806 pedidos de revenda tem motivo). Como a
revenda é 73% da receita, `dim_sales_reason` tem um membro sintético explícito `-1` = "Nao
informado" — sem ele, a maior parte do faturamento desapareceria de qualquer visual filtrado
por motivo.

**Atalho degenerado**: `fact_sales.has_promotion_reason` responde à pergunta (f) — "qual
produto tem mais unidades vendidas pelo motivo Promotion" — sem precisar atravessar a ponte,
porque só existe um motivo da categoria "Promotion" no catálogo (nenhum pedido casa duas
vezes com esse filtro; detalhe em §9).

## 4. Membros sintéticos (`-1`) — onde existem e o que significam

Quatro dimensões têm um membro artificial de chave `-1`, sempre com o mesmo propósito: um
pedido sem aquele atributo não pode desaparecer de uma agregação por causa de um `NULL` não
tratado.

| Dimensão | Chave -1 significa |
|---|---|
| `dim_credit_card` | "Sem cartao" — pedido sem cartão de crédito |
| `dim_sales_reason` | "Nao informado" — pedido sem motivo de venda registrado (ver §3) |
| `dim_salesperson` | "Sem vendedor" — venda online, sem vendedor associado (27.659 pedidos) |

Nos três casos, colunas de atributo do membro sintético (ex. `sales_quota`,
`commission_pct` em `dim_salesperson`) ficam `NULL` — não zero — porque zero seria um valor
de negócio válido para outro vendedor.

## 5. `channel` — eixo de controle, não dimensão de corte do briefing

`fact_sales.channel` (`online` / `revenda`) não está entre as dimensões que as 6 perguntas do
briefing pedem, mas atravessa a análise inteira como variável de controle: são duas empresas
na mesma base — 27.659 pedidos online (1-2 itens cada) contra 3.806 de revenda (56 itens por
pedido, ticket de R$ 21.148). Comparações que não controlam por canal produzem leitura
invertida (ex.: "promoção reduz o ticket médio" quando na verdade a comparação estava
misturando varejo com atacado).

## 6. Duas dimensões que não são a mesma coisa

`dim_territory` (território comercial responsável pela venda: `territory_name`,
`territory_country`, `territory_group`) e `dim_geography` (endereço de cobrança do cliente:
`city`, `state_province`, `billing_country`) são conceitos diferentes, sem hierarquia entre
si — cidade/estado/país **não estão "dentro" de território**. Não confundir
`dim_territory.territory_country` com `dim_geography.billing_country`.

## 7. Chaves primárias e naturais

Todas as dimensões reaproveitam a chave natural da origem como chave primária do mart (ex.
`product_key` = `product_id` da origem), exceto `dim_dates` (gerada via `date_spine`, chave é
a própria data) e `dim_geography` (`bill_to_geography_key` = `address_id` da origem, porque
cidade sozinha não é única — 38 cidades existem em mais de um estado; para exibição, usar
`city_label`, no formato "Cidade, UF").

## 8. Vendas brutas vs. líquidas — o desconto já embutido no `linetotal`

`gross_revenue` (`unitprice × orderqty`, **antes** do desconto) é a métrica auditada pelo
CEO — bate exato com o teste de aceite de 2011 (US$ 12.646.112,1607). `net_revenue` é o
`linetotal` da origem, e `linetotal` **já sai com o desconto aplicado**:

```
linetotal = unitprice * (1 - unitpricediscount) * orderqty
gross_revenue = unitprice * orderqty
discount_amount = gross_revenue - net_revenue
```

**Armadilha real, não hipotética**: a fórmula do briefing para ticket médio é *"gross
revenue − product discounts / number of orders"*. Quem lê "gross revenue" como
`sum(linetotal)` e **ainda** subtrai o desconto de novo desconta duas vezes — o ticket médio
sai baixo demais. `linetotal` já é `gross_revenue − discount_amount`; não subtrair `discount`
de novo em cima dele.

## 9. "Promotion" na pergunta (f) — motivo específico, não categoria ambígua

A pergunta (f) pede o produto com mais unidades vendidas pelo motivo **"Promotion"**. O
catálogo de motivos tem duas colunas que pareciam ambíguas entre si — `name` e `reason_type`
— mas na prática só existe **um** motivo com `reason_type = 'Promotion'`: `On Promotion`
(id 2), entre os 10 motivos cadastrados. Não é uma categoria com vários membros, é um motivo
único — por isso `fact_sales.has_promotion_reason` (ver §3) pode responder a pergunta (f)
direto na fato, sem atravessar a ponte `bridge_order_sales_reason`.

## 11. `status` é constante — não vale slicer nem gráfico dedicado

`fact_sales.status` é `5` ("Shipped"/"Faturado") em **100% dos 31.465 pedidos**, sem uma
única exceção — não existe tabela de origem para ele, o rótulo é mapeado direto no modelo.
Não discrimina nada: um slicer ou gráfico de status sempre mostraria uma única barra. A
decisão de desenho é deixá-lo **só como coluna** na tabela "Pedidos detalhados" (rotulado
"Faturado"), sem visual dedicado — ele existe pra ser citado (ex. no vídeo de entrega), não
pra ser filtrado.

## 12. Regra de teste (herdada da Etapa 5)

Toda tabela mart tem teste `unique` + `not_null` na chave primária, e toda FK da fato tem
teste `relationships` apontando para a dimensão correspondente — 234/234 testes verdes,
conferido na Etapa 5 (`docs/05-plano-de-entrega-dbt.md`). Regra de negócio derivada: nenhum
relatório deve tratar uma FK da fato como opcional — todas são `not_null` por desenho, os
casos "sem valor" viram membro sintético `-1` (ver §4), nunca `NULL` solto na fato.
