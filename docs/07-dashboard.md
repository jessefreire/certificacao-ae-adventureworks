# Etapa 7 — Desenvolvimento do dashboard

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 7 de 10 — *"Development of the dashboard, following the logic established
in the mockup. The dashboard should answer the questions raised in the objective of
the challenge."*
**Status:** completo — 4 páginas, seguindo o mockup de alta fidelidade (artifact
"Mockup AdventureWorks - Alta Fidelidade", fonte em `mockup-assets/`)
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

### 1.3 Tabelas de field parameter — 6 no total, uma órfã

Os toggles de métrica/dimensão do mockup (os botões "Receita / Pedidos / Quantidade",
"País / Estado / Cidade") são implementados como **field parameters**: tabelas
calculadas e desconectadas (sem relação com o resto do modelo), cada uma com 2-4
opções que apontam pra uma medida ou coluna real via `NAMEOF`.

| Field parameter | Onde é usado | Opções |
|---|---|---|
| `Métrica (Receita/Pedidos)` | Visão Geral & Produtos — gráfico "Receita por mês/ano" | Receita, Pedidos, Quantidade, Ticket Médio |
| `Métrica (Motivo)` | Clientes — "Receita por motivo de venda" | Receita, Pedidos, Quantidade |
| `Métrica (Cartão)` | Clientes — "Pedidos, quantidade e valor por tipo de cartão" | Receita, Pedidos, Quantidade |
| `Dimensão Geográfica (Ticket Médio)` | Análise Geográfica — "Ticket médio por [país/estado/cidade]" | País, Estado, Cidade |
| `Dimensão Geográfica (Ranking)` | Análise Geográfica — "Ranking geográfico por valor de transação" | País, Estado, Cidade |
| `Dimensão (Categoria/Produto)` | **nenhum** — tentativa abandonada (ver §3.1) | Categoria, Produto |

O botão visual de cada toggle é um `advancedSlicerVisual` (estilo "Cards") ligado à
tabela do field parameter — ligação padrão, `Column` no papel `Values`. O gráfico/tabela
que o toggle controla usa o field parameter no papel de categoria ou de valor (`Y`),
dependendo do caso (ver §3.2 sobre como isso é montado no PBIR).

`Dimensão (Categoria/Produto)` continua no modelo sem uso — candidata a remoção antes
da entrega final (ver §4).

### 1.4 Medidas — 45 no total, todas com descrição no TMDL

Espalhadas em 6 tabelas, não só na fato — cada família de medida mora perto do que
descreve (ex. os textos de callout de produto ficam em `dim_product`, não em
`fact_sales`):

| Tabela | Nº de medidas | Exemplos |
|---|---:|---|
| `fact_sales` | 14 | Receita Bruta, Receita Líquida, Número de Pedidos, Ticket Médio, Taxa de Desconto, Mix de Canal, Taxa de Recorrência, títulos dinâmicos de gráfico |
| `dim_product` | 12 | Produtos Nunca Venderam, Produto Destaque, Produto Maior Ticket Médio — cada um com uma medida "(Texto)"/"(Legenda)" companheira pra callout |
| `dim_geography` | 8 | Ranking Cidade, % da Receita Líquida (Geografia), título dinâmico "Ticket médio por [dimensão]" |
| `bridge_order_sales_reason` | 5 | Receita/Pedidos/Quantidade por Motivo de Venda — todas via `allocation_factor`, nunca soma direta na ponte |
| `dim_customer` | 5 | Receita Top 10 Clientes, % Receita Top 10 Clientes, Ranking Cliente |
| `Atualização do Modelo` | 1 | Última Atualização (timestamp do refresh, mostrado no header) |

Todas documentadas via comentário `///` no TMDL (equivalente ao `description:`),
cumprindo a exigência do briefing de medidas documentadas dentro do arquivo.

**Validação**: Receita Bruta filtrada em 2011 = **R$ 12.646.112,1607**, batendo exato
com o teste de aceite do CEO já validado no dbt (Etapa 5). Receita por Motivo de Venda
somada sem filtro nenhum = Receita Líquida total, provando que a fórmula com
`allocation_factor` não infla o resultado atravessando a ponte.

**Padrão "(Texto)"/"(Legenda)"**: todo callout de destaque (produto que mais vende,
cidade que mais vende, etc.) tem duas medidas irmãs — uma com nome+valor numa linha só
("(Texto)"), outra só com a frase descritiva ("(Legenda)") — pra virar dois cards lado a
lado no mockup, um em negrito e um cinza menor.

### 1.5 Correção de modelagem feita durante o build

Nove colunas de chave/atributo (`sales_order_detail_id`, `sales_order_id`, `status`,
`unit_price`, `unit_price_discount_rate` na fato; `sales_order_id` na ponte; `year`,
`month`, `quarter` em `dim_dates`) vieram com `summarizeBy: Sum` por padrão do Power BI
— contrariando a regra "atributo vs. métrica" da Etapa 8. Corrigidas para
`summarizeBy: None`.

`dim_dates.month_name` recebeu `sortByColumn: month`, pra o nome do mês (Janeiro,
Fevereiro...) ordenar cronologicamente em vez de alfabeticamente nos eixos de gráfico.

### 1.6 Tema

Tema **Storm** (o mesmo do treino BanVic) registrado como tema customizado do relatório,
substituindo o Fluent2 padrão do Power BI Desktop — guardrail do projeto ("Fluent2
quebra cards").

---

## 2. Páginas

Quatro páginas, 1280px de largura fixa (padrão Power BI), altura variável conforme o
conteúdo — mesma régua do mockup de alta fidelidade. Header e menu de navegação (4
botões: Início, Visão Geral & Produtos, Clientes, Análise Geográfica) ficam **embutidos
no SVG/PNG de fundo** de cada página — só o timestamp "Atualizado em..." é um card vivo
sobreposto, porque precisa ser dinâmico.

### 2.1 Capa

Página de abertura, sem dados: logo, título "Dashboard de Vendas Adventure Works",
descrição curta do projeto, 3 mini-cards de destaque e um botão "Iniciar" que navega
pra Visão Geral & Produtos (`actionButton` com ação de navegação de página).

### 2.2 Visão Geral & Produtos (1280×1319)

9 filtros globais sincronizados (ver §2.5) + fundo próprio com header/nav embutidos:

- **7 cards de KPI**: Receita Bruta, Receita Líquida, Número de Pedidos, Itens
  Vendidos, Ticket Médio, Taxa de Desconto, Mix de Canal.
- **Gráfico de linha** "Receita por mês/ano", com toggle de 4 métricas (Receita,
  Pedidos, Quantidade, Ticket Médio) via field parameter, e anotação fixa em jun/2013
  marcando a quebra de ~3x nos pedidos online.
- **"Ticket médio por produto"** (`clusteredBarChart`, Top 20, scroll nativo) e
  **"Comparação — ticket médio com/sem promoção"** (`clusteredBarChart`, controlando por
  canal — ver Etapa 8 §5).
- **Matriz — Pedidos, Quantidade e Valor** (`pivotTable`): hierarquia nativa Categoria
  → Produto (as duas colunas de `dim_product` no mesmo poço de Linhas), colapsada por
  padrão, sem totais (já cobertos pelos KPIs), com título e dois callouts próprios
  ("238 de 504 produtos nunca venderam" / produto destaque no filtro atual).

### 2.3 Clientes (1280×1406)

Mesmos 9 filtros globais:

- **5 cards de KPI**: Taxa de Desconto, Mix de Canal, Taxa de Recorrência, Receita Top
  10 Clientes, % Receita Top 10 Clientes.
- **"Receita por motivo de venda"** e **"Pedidos, quantidade e valor por tipo de
  cartão"** (`clusteredBarChart`, lado a lado), cada um com seu próprio toggle de
  métrica.
- **Ranking clientes por valor de transação** (`tableEx`, largura cheia, sem Top N —
  mostra todos, ordenado por valor decrescente): ranking sequencial calculado em DAX
  (ver §3.4), callout de concentração acima ("soma dos top 10 = X% da receita").
- **Pedidos detalhados** (`tableEx`, sem Top N, scroll nativo): grão pedido×produto,
  cabeçalhos com nomes amigáveis (Pedido, Data, Cliente, Produto, Cartão, Status,
  Cidade, Estado, País, Qtd., Valor) em vez do nome técnico da coluna.

### 2.4 Análise Geográfica (1280×992)

Mesmos 9 filtros globais:

- **"Ticket médio por [país/estado/cidade]"** (`clusteredBarChart`): toggle de
  dimensão geográfica, com **título dinâmico** que troca de texto junto com o botão
  selecionado (ver §3.5).
- **Ranking geográfico por valor de transação** (`tableEx`, largura cheia, sem Top N):
  mesmo padrão de ranking sequencial da tabela de Clientes, com o mesmo toggle de
  dimensão geográfica controlando a coluna de agrupamento.

### 2.5 Filtros globais e navegação

9 filtros idênticos nas 3 páginas de conteúdo — Ano, Mês, Cidade, Estado, País,
Categoria de Produto, Produto, Tipo de Cartão, Motivo da Venda — sincronizados via
**Sincronizar Slicers** nativo do Power BI (`syncGroup` por campo, ex.
`barraFiltrosGlobal_Ano`), não visuais de slicer duplicados por página. Um botão
"Limpar filtros" (bookmark de reset) e o menu de navegação de 4 abas completam a barra
superior, replicados nas 3 páginas.

Canal e Território **não** entram na barra de filtros — nenhuma das 6 perguntas do
briefing pede essas dimensões como corte, e Canal continua usado internamente como eixo
de controle (Etapa 8 §5).

---

## 3. O que funcionou, o que não funcionou, e por quê

Esta seção existe porque várias tentativas de interatividade avançada bateram em
comportamento do Power BI que não está documentado nas skills do projeto — registrado
aqui pra não repetir a mesma investigação depois.

### 3.1 Field Parameter como filtro de linha de Matriz — não funciona

Tentativa original (mockup): um seletor "Categoria/Produto" que troca dinamicamente o
que a Matriz agrupa. Um Field Parameter foi criado e ligado ao poço de Linhas da
Matriz — validou sem erro, mas **renderizou o texto literal do parâmetro** ("Categoria",
"Produto") em vez dos valores reais da coluna escolhida. Substituído pela solução mais
simples e nativa: as duas colunas (`Categoria`, `Produto`) direto no poço de Linhas,
formando uma hierarquia real com expand/collapse — resultado mais próximo do mockup
original, que já mostrava justamente esse padrão de hierarquia. A tabela do field
parameter ficou no modelo, sem uso (ver §1.3, §4).

### 3.2 Field Parameter como métrica de eixo Y — funciona, mas precisa ser feito no Desktop uma vez

Ligar o Field Parameter direto no papel de valor (Y) de um gráfico via edição de PBIR à
mão falha na validação (`Column expression in Measure-only role "Y"`) — o papel Y só
aceita `Measure`/`Aggregation`, e a "mágica" de troca de medida do Field Parameter não é
uma `Column` comum, é um mecanismo interno que o **Power BI Desktop gera ao arrastar o
campo pela interface**, sem documentação pública no formato PBIR.

A solução, usada nos 5 field parameters ativos deste relatório: arrastar o campo Métrica
(ou Dimensão) pro poço certo manualmente no Desktop uma vez. O JSON resultante revela a
estrutura real — um bloco `fieldParameters` (irmão de `projections`, dentro do papel
alvo) com `parameterExpr`, `index` e `length` — que depois pode ser copiado/adaptado à
mão pra outros visuais parecidos sem precisar repetir o passo manual.

### 3.3 O segmentador de botão (`advancedSlicerVisual`) funciona de primeira

O seletor visual de toggle (estilo "Cards", cantos arredondados) ligado à tabela do
Field Parameter é uma ligação padrão (`Column` no papel `Values`, kind `Grouping`) —
valida e funciona de primeira via PBIR, sem precisar de passo manual no Desktop.

### 3.4 `RANKX` sobre `ALLSELECTED` de uma dimensão inteira rankeia registros sem venda

As tabelas de ranking (clientes e geográfico), depois de perder o `TopN` do visual (pra
mostrar todos os registros, não só os 10/5 melhores), passaram a mostrar ranks
gigantes e repetidos (`19120`, `502`, `19120`...) em vez de `1, 2, 3...` sequencial. A
causa: `RANKX(ALLSELECTED(dim_customer), CALCULATE([Receita Líquida]), , DESC)` rankeia
**todo mundo**, inclusive clientes/cidades sem nenhuma venda no filtro atual — que
entram na comparação como `BLANK`, e o `RANKX` não ignora blanks por padrão. A correção:
embrulhar com `FILTER(..., CALCULATE([medida]) <> BLANK())` pra só comparar contra quem
de fato tem valor, e um `IF(NOT ISBLANK(...))` externo pra a própria linha também virar
`BLANK` quando não há venda — em vez de um número sem sentido. O `sortDefinition` do
visual também precisou trocar de "ordenar pela coluna de nome" (alfabético) para
"ordenar pela medida de valor" (decrescente), senão o rank correto aparecia fora de
ordem na tela.

### 3.5 Título dinâmico de visual: bindar a medida funciona, mas `SELECTEDVALUE` na coluna do Field Parameter não

Pra o título do gráfico trocar de texto junto com o toggle ("Ticket médio por país" →
"...por estado" → "...por cidade"), a técnica é bindar `visualContainerObjects.title.text`
a uma **medida** em vez de um texto fixo (`"expr": {"Measure": {...}}` no lugar de
`"expr": {"Literal": {...}}`) — funciona, é a mesma mecânica usada em "field value" de
formatação condicional, só que aplicada ao título do visual inteiro.

A armadilha: a medida por trás não pode usar `SELECTEDVALUE` direto na coluna visível do
Field Parameter (ex. `'Dimensão Geográfica (Ticket Médio)'[Dimensão Geográfica (Ticket
Médio)]`) — o Power BI recusa em runtime com *"a coluna faz parte da chave composta, mas
nem todas as colunas da chave composta são incluídas na expressão"*, porque essa coluna
tem uma relação de `sortByColumn`/`groupByColumn` com a coluna oculta "Fields" da mesma
tabela. A correção: usar `SELECTEDVALUE` na coluna oculta **"Fields"** (que guarda o
`NAMEOF` da coluna real por trás da opção) e comparar contra `NAMEOF('tabela'[coluna])`
num `SWITCH` — evita tocar na coluna com chave composta.

### 3.6 Visual de imagem local usa uma estrutura de `objects` diferente do fundo de página

Pra uma imagem local (`imageUrl`) num visual do tipo `image`, a referência ao arquivo
registrado é **plana**: `objects.general[].properties.imageUrl.expr.ResourcePackageItem`.
A estrutura aninhada `image.image.{name, url, scaling}` — que é a certa pra fundo de
página (`page.json`) e pra `plotArea.image` de gráfico — não funciona aqui e produz
ícone de imagem quebrada. As duas estruturas parecem intercambiáveis, mas não são.

### 3.7 Objetos com seletor `id` às vezes precisam de duas entradas no array

Alguns objetos de formatação (`fillCustom` de card, os 12 objetos de botão de
navegação, os 5 objetos de estado de slicer) só aplicam de verdade quando têm **duas**
entradas no array: uma sem seletor e outra com `selector: {id: "default"}` — faltando a
entrada estática, a propriedade valida sem erro mas não tem efeito visual nenhum (o caso
mais visto: texto de botão continua invisível mesmo com `show: true` e cor certa no
JSON). `formatting describe-object` da CLI acusa isso via um campo `_selectorHint`.

### 3.8 Card de texto sozinho herda o "tile" branco do tema por padrão

Um `cardVisual` usado só como callout de texto (sem número grande, ex. os textos
"(Legenda)") ainda recebe o preenchimento branco padrão do tema Storm por trás — porque
o VCO `background.show: false` desliga o fundo do *container*, mas o objeto interno
`fillCustom` do card precisa do próprio `show: false` separadamente pra desligar o
preenchimento do *cartão em si*.

### 3.9 Altura da página é um limite físico, não estético

Um visual cujo `y + height` passa da `height` do `page.json` fica **cortado de
verdade** — não some com scroll, o Power BI simplesmente não renderiza a parte que
sobra do canvas. Aconteceu duas vezes (Ranking geográfico, Ranking de clientes) depois
de trocar o `TopN` fixo por "mostrar todos", já que a lista cresceu mas a altura da
página não acompanhou. A correção sempre exigiu medir a altura real do conteúdo
(`document.body.scrollHeight` num navegador local servindo o mockup) e ajustar
`page.json.height` junto com o fundo.

### 3.10 Duas vezes se perdeu trabalho não salvo

Medidas criadas via MCP foram perdidas mais de uma vez porque o Power BI Desktop foi
fechado ou recarregado antes de salvar — o MCP mantém o modelo só na memória do
processo do Desktop até `Ctrl+S`. Lição operacional, reforçada na prática: **salvar
imediatamente após qualquer lote de mudança via MCP**, antes de continuar qualquer
outra ação (guardrail já registrado no `CLAUDE.md`).

---

## 4. Pendências conhecidas (não bloqueantes)

- **`Dimensão (Categoria/Produto)`** (tentativa abandonada, §3.1) ainda existe no
  modelo, sem uso — candidata a remoção antes da entrega final.
- Os botões do menu de navegação (`navMenu*`), embutidos visualmente no fundo de cada
  página, ainda têm o texto do `actionButton` original visível/fantasma por baixo —
  precisam virar transparentes na interface do Desktop (ajuste manual pendente do
  usuário, não um problema de dado).
- A auditoria de modelo (§5) é de uma versão anterior do relatório — vale rodar de
  novo (`/pbi-modelo-review`) antes da entrega final, já que o modelo cresceu de 11
  para 45 medidas e ganhou 6 tabelas novas desde a última rodada.

## 5. Auditoria do modelo

> ⚠️ Rodada em `_review/relatorio.md` e `_review/index.html` (`/pbi-modelo-review`)
> numa versão anterior do modelo (11 medidas, 2 páginas) — os números abaixo estão
> desatualizados e a auditoria deve ser refeita antes da entrega (ver §4).

Última rodada conhecida: score 95/100, zero críticos, 5 issues de
portabilidade/limpeza (conexão Databricks hardcoded, chaves de negócio sem `isKey`,
tabela Field Parameter órfã, tabelas sem descrição, nomes de tabela verbosos no painel
de campos). Nenhum afetava a correção dos números.
