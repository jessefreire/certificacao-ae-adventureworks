# Etapa 7 — Desenvolvimento do dashboard

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 7 de 10 — *"Development of the dashboard, following the logic established
in the mockup. The dashboard should answer the questions raised in the objective of
the challenge."*
**Status:** completo — 2 páginas, seguindo o mockup de alta fidelidade da Etapa 6
**Entregável do briefing:** dashboard em Power BI (PBIX com todas as medidas DAX
documentadas dentro do arquivo)

> O projeto é versionado como **PBIP** (pasta de texto, git-friendly), não como `.pbix`
> binário — mesma decisão já usada no treino BanVic. O `.pbix` final é exportado a
> partir do PBIP só na hora da entrega.

---

## 1. Modelo semântico

### 1.1 Fonte de dados

Import (não DirectQuery/Dual) do schema `dbt_jessefreire_marts` no catálogo `workspace`
do Databricks — decisão já justificada na Etapa 5/documento de arquitetura: base de
treino sem necessidade de tempo real, Import é o padrão correto.

### 1.2 Relações — 10 no total

As 8 relações diretas dimensão→fato (`dim_product`, `dim_customer`, `dim_geography`,
`dim_credit_card`, `dim_territory`, `dim_special_offer`, `dim_salesperson`,
`dim_dates` → `fact_sales`) foram autodetectadas pelo Power BI ao carregar os dados —
todas 1:N, filtro único, cardinalidade correta.

Duas relações exigiram atenção manual:

- **`dim_dates` marcada como tabela de datas** (`Mark as Date Table`), habilitando
  time intelligence de verdade sobre `date_day`.
- **`bridge_order_sales_reason` ↔ `fact_sales`**: a única M:M do modelo, porque
  `sales_order_id` não é único em nenhum dos dois lados (grão do item na fato, grão
  pedido×motivo na ponte). Criada como M:M com **filtro bidirecional** — testado com
  `COUNTROWS` antes e depois pra confirmar que o filtro de motivo realmente atravessa
  pra fato (a primeira tentativa, com filtro de uma via, propagava a direção errada:
  a fato filtrava a ponte, não o contrário).

### 1.3 Medidas — 11 no total, todas com descrição no TMDL

| Medida | Tabela | Fórmula |
|---|---|---|
| Receita Bruta | fact_sales | `SUM(gross_revenue)` |
| Receita Líquida | fact_sales | `SUM(net_revenue)` |
| Número de Pedidos | fact_sales | `DISTINCTCOUNT(sales_order_id)` |
| Itens Vendidos | fact_sales | `SUM(order_quantity)` |
| Ticket Médio | fact_sales | `DIVIDE([Receita Líquida], [Número de Pedidos])` |
| Taxa de Desconto | fact_sales | `DIVIDE(SUM(discount_amount), [Receita Bruta])` |
| Receita por Motivo de Venda | bridge_order_sales_reason | `SUMX` na ponte, multiplicando `allocation_factor` pela receita do pedido — nunca soma direto |
| Receita Top 10 Clientes | dim_customer | `SUMX(TOPN(10, ...))` |
| % Receita Top 10 Clientes | dim_customer | `DIVIDE` contra o total sem filtro de cliente |
| % da Receita Líquida | dim_customer | participação do cliente/contexto atual no total (usada na tabela Top 10) |
| % da Receita Líquida (Geografia) | dim_geography | mesma lógica, por cidade (usada no Ranking de Cidades) |

Todas documentadas via comentário `///` no TMDL (equivalente ao `description:`),
cumprindo a exigência do briefing de medidas documentadas dentro do arquivo.

**Validação**: Receita Bruta filtrada em 2011 = **R$ 12.646.112,1607**, batendo exato
com o teste de aceite do CEO já validado no dbt (Etapa 5). Receita por Motivo de Venda
somada sem filtro nenhum = Receita Líquida total, provando que a fórmula com
`allocation_factor` não infla o resultado atravessando a ponte.

### 1.4 Correção de modelagem feita durante o build

Nove colunas de chave/atributo (`sales_order_detail_id`, `sales_order_id`, `status`,
`unit_price`, `unit_price_discount_rate` na fato; `sales_order_id` na ponte; `year`,
`month`, `quarter` em `dim_dates`) vieram com `summarizeBy: Sum` por padrão do Power BI
— contrariando a regra "atributo vs. métrica" da Etapa 8. Corrigidas para
`summarizeBy: None`.

`dim_dates.month_name` recebeu `sortByColumn: month`, pra o nome do mês (Janeiro,
Fevereiro...) ordenar cronologicamente em vez de alfabeticamente nos eixos de gráfico.

### 1.5 Tema

Tema **Storm** (o mesmo do treino BanVic) registrado como tema customizado do relatório,
substituindo o Fluent2 padrão do Power BI Desktop — guardrail do projeto ("Fluent2
quebra cards").

---

## 2. Páginas

Duas páginas, 1280px de largura fixa (padrão Power BI), altura variável — mesma régua
do mockup da Etapa 6.

### 2.1 Visão Geral (1280×874)

Fundo SVG importado do mockup (`AdventureWorks-VisaoGeral-fundo.svg`, cards vazios
posicionados em pixel exato) com visuais nativos sobrepostos:

- **9 filtros globais** (`slicer`, modo Dropdown): Período, Canal, Território, Estado,
  País, Categoria de Produto, Produto, Tipo de Cartão, Motivo da Venda — mesmo texto e
  ordem do mockup.
- **8 cards de KPI** (`cardVisual`): Receita Bruta, Receita Líquida, Número de Pedidos,
  Ticket Médio, Itens Vendidos, Taxa de Desconto, Receita Top 10 Clientes, % Receita
  Top 10 Clientes.
- **Gráfico de linha** "Receita por mês/ano" (`lineChart`), eixo Y ligado a um **Field
  Parameter** "Métrica (Receita/Pedidos)" — o segmentador de botão ao lado troca
  dinamicamente entre Receita Líquida e Número de Pedidos (ver §3 sobre como isso foi
  implementado).
- **Gráfico de barras** "Receita por motivo de venda" (`clusteredColumnChart`).
- **Gráfico de barras horizontais** "Receita por grupo de território" (`clusteredBarChart`).

### 2.2 Detalhe (1280×1021)

Mesmos 9 filtros globais, fundo SVG próprio (`AdventureWorks-Detalhe-fundo.svg`):

- **Top 10 Clientes por Valor de Transação** (`tableEx`): cliente, receita líquida, %
  do total — filtro `TopN` no visual, ranking por `SUM(net_revenue)`.
- **Ranking de Cidades por Valor de Transação** (`tableEx`): mesma estrutura, `TopN`
  por `city_label` (não por endereço individual — ver nota de correção abaixo).
- **Matriz — Pedidos, Quantidade e Valor** (`pivotTable`): hierarquia nativa
  Categoria → Produto (as duas colunas de `dim_product` no mesmo poço de Linhas),
  colapsada por padrão, com ícone de expandir por categoria.
- **Comparação — Ticket Médio com/sem promoção** (`clusteredBarChart`): categoria
  `has_promotion_reason`.

Todas as tabelas com `rowPadding` ajustado pra as linhas preencherem a altura do card
proporcionalmente (não existe uma opção nativa de "auto-fill", foi calibrado por
tentativa: Ranking de Cidades e Matriz precisavam de padding bem maior que o Top 10,
que já tinha linhas suficientes pra preencher o card no padrão default).

---

## 3. O que funcionou, o que não funcionou, e por quê

Esta seção existe porque duas tentativas de interatividade avançada bateram em
comportamento do Power BI que não está documentado nas skills do projeto — registrado
aqui pra não repetir a mesma investigação depois.

### 3.1 Field Parameter como filtro de linha de Matriz — não funciona

Tentativa original (mockup Etapa 6): um seletor "Categoria/Produto" que troca
dinamicamente o que a Matriz agrupa. Um Field Parameter foi criado e ligado ao poço de
Linhas da Matriz — validou sem erro, mas **renderizou o texto literal do parâmetro**
("Categoria", "Produto") em vez dos valores reais da coluna escolhida. Substituído pela
solução mais simples e nativa: as duas colunas (`category`, `product_name`) direto no
poço de Linhas, formando uma hierarquia real com expand/collapse — resultado mais
próximo do mockup original, que já mostrava justamente esse padrão de hierarquia.

### 3.2 Field Parameter como métrica de eixo Y — funciona, mas precisa ser feito no Desktop

Tentativa de ligar o Field Parameter direto no papel de valor (Y) de um `lineChart` via
edição de PBIR à mão falhou na validação (`Column expression in Measure-only role "Y"`)
— o papel Y só aceita `Measure`/`Aggregation`, e a "mágica" de troca de medida do Field
Parameter não é uma `Column` comum, é um mecanismo interno que o **Power BI Desktop
gera ao arrastar o campo pela interface**, sem documentação pública no formato PBIR.

A solução: o usuário arrastou o campo Métrica pro poço Y manualmente no Desktop. O JSON
resultante revelou a estrutura real — um bloco `fieldParameters` (irmão de
`projections`, dentro do papel `Y`) com `parameterExpr`, `index` e `length` — que não
está em nenhuma referência da skill `powerbi-report-authoring` usada neste projeto.
Registrado aqui como conhecimento novo.

### 3.3 O segmentador de botão (`advancedSlicerVisual`) funciona

O seletor visual Receita/Pedidos é um `advancedSlicerVisual` (estilo "Cards", 1 linha,
2 colunas, cantos arredondados) ligado à mesma tabela Field Parameter — esse sim é uma
ligação padrão (`Column` no papel `Values`, kind `Grouping`), então validou e funcionou
de primeira via PBIR.

### 3.4 Ordenação do eixo reseta ao trocar a métrica via Field Parameter

Quando a métrica ativa no gráfico de linha muda (Receita ↔ Pedidos), o Power BI
recalcula um sort padrão "pelo valor do eixo Y, descendente" — sobrescrevendo qualquer
`sortDefinition` fixado no arquivo para o estado que não está ativo no momento do save.
Um `sortDefinition` explícito (ano/mês ascendente, usando `month_name` com
`sortByColumn: month`) resolve o estado "Receita" (o default), mas o estado "Pedidos"
**precisa ser fixado manualmente uma vez pela interface** (botão direito no gráfico →
Ordenar por → ano/mês ascendente) — ficou registrado como pendência aberta, não afeta
os números, só a ordem visual do eixo nesse estado específico.

### 3.5 Duas vezes se perdeu trabalho não salvo

Duas medidas criadas via MCP (`% da Receita Líquida`, `% da Receita Líquida
(Geografia)`) e o campo Métrica no eixo Y foram perdidos porque o Power BI Desktop foi
fechado ou recarregado antes de salvar — o MCP mantém o modelo só na memória do
processo do Desktop até `Ctrl+S`. Lição operacional: **salvar imediatamente após
qualquer lote de mudança via MCP**, antes de continuar qualquer outra ação (é o mesmo
guardrail que já estava registrado no `CLAUDE.md`, reforçado na prática).

Também aconteceu um susto separado: o Power BI Desktop, ao encontrar uma propriedade
inválida (`subheader` num lugar errado do VCO), abriu um diálogo de "reparo automático"
que, ao ser aceito, **descartou os visuais problemáticos da memória** — que ficou
temporariamente diferente do que estava salvo em disco. Resolvido fechando o Desktop
sem salvar e reabrindo (voltando ao estado correto do disco).

---

## 4. Pendências conhecidas (não bloqueantes)

- Ordenação do eixo do gráfico de linha no estado "Pedidos" (ver §3.4) — precisa de um
  clique manual de "Ordenar por" na interface.
- Filtro de Motivo isolado só na Matriz (documentado no mockup como "filtro de visual")
  não foi implementado — o filtro global "Motivo da Venda" já cobre esse caso na
  prática, e isolar exigiria editar interações visual-a-visual pra cada outro visual da
  página.
- Cabeçalhos de coluna nas tabelas (`customer_name`, `city_label`) mostram o nome
  técnico da coluna em vez de um rótulo amigável ("Cliente", "Cidade") — cosmético.
- Tabela Field Parameter "Dimensão (Categoria/Produto)" (tentativa abandonada, §3.1)
  ainda existe no modelo, sem uso — candidata a remoção (ver auditoria, `_review/`).
- Bookmarks do toggle Receita/Pedidos não foram criados (o segmentador de botão com
  Field Parameter cumpre a mesma função, por caminho mais simples).

## 5. Auditoria do modelo

Rodada em `_review/relatorio.md` e `_review/index.html` (`/pbi-modelo-review`): score
95/100, zero críticos, 5 issues de portabilidade/limpeza (conexão Databricks hardcoded,
chaves de negócio sem `isKey`, tabela Field Parameter órfã, tabelas sem descrição, nomes
de tabela verbosos no painel de campos). Nenhum afeta a correção dos números.
