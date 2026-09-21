# Etapa 6 — Mockup do dashboard

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 6 de 10 — *"Creation of a dashboard mockup, based on your KPI research and
exploratory analysis insights. Pay attention to data visualization and data storytelling
best practices."*
**Status:** completa — mockup de alta fidelidade aprovado, construído na Etapa 7
**Entregável do briefing:** arquivo JPEG do mockup do dashboard

> Nota de escopo: o briefing pede o mockup "criado no Figma". Usamos o canvas `/design`
> (ferramenta de mockup multi-artboard com interface equivalente), exportando o resultado
> final como JPEG — mesma nota de divergência já registrada para outras pequenas diferenças
> de ferramenta ao longo do projeto.

---

## 1. Processo: baixa fidelidade antes de alta fidelidade, e uma revisão de estrutura pelo caminho

Duas rodadas deliberadas, para separar as duas decisões que um dashboard exige: primeiro
**o que mostrar e como organizar a leitura** (dataviz e usabilidade), só depois **a
identidade visual** (cor, tipografia, tema).

- **Baixa fidelidade (P&B)**: wireframe em escala de cinza, 3 páginas — Visão Geral, Detalhe,
  e uma página de apoio "Perguntas & Glossário" (candidatos a drill-down, distinção entre
  filtro global e toggle local) — não faz parte do entregável final, é material de processo.
- **Alta fidelidade, primeira versão**: 2 páginas (Visão Geral, Detalhe), usando os mockups
  do treino BanVic como base de padrão visual, paleta do tema Storm do Power BI e fonte
  Arial (nativa da ferramenta, evita substituição de fonte na publicação).
- **Alta fidelidade, versão final — 4 páginas**: durante a construção do dashboard (Etapa 7)
  o conteúdo das 2 páginas cresceu o bastante para pedir reorganização — Detalhe estava
  acumulando conteúdo de clientes e de geografia sem relação direta entre si. A estrutura
  final separa por assunto: **Capa** (abertura/navegação, sem dado), **Visão Geral &
  Produtos**, **Clientes** e **Análise Geográfica**. O mockup foi atualizado para essa
  estrutura antes de virar dashboard, mandando na organização final (ver §2).

Tamanho de canvas fixo: **1280px de largura** em todas as fidelidades (padrão de página do
Power BI) — a largura nunca muda; a altura de cada página cresce conforme o conteúdo pede,
medida sempre no navegador (`getBoundingClientRect()`/`document.body.scrollHeight`, sem
estimar) antes de fechar o tamanho do frame.

## 2. Cobertura de conteúdo: as 4 telas respondem tudo?

A régua usada: as 6 perguntas principais do briefing (a–f) e os 9 indicadores da Etapa 1
(`docs/01-kpis-e-perguntas.md`) precisam de visual definido; os 14 aprofundamentos (a.1–f.2)
se resolvem por **filtro ou toggle**, não por tela nova — se um aprofundamento não tiver
mecanismo de filtro/toggle correspondente no mockup, as 4 telas não bastam de verdade.

### Capa

Abertura e navegação, sem dado nenhum: logo, título, descrição curta do projeto, 3
mini-cards de destaque e um botão que leva para Visão Geral & Produtos. Existe porque um
dashboard de 3 páginas de conteúdo precisa de hub de entrada — sem capa, a primeira página
de dados vira a porta de entrada por acidente.

### Visão Geral & Produtos (estrutura de 3 atos: KPIs → gráficos → tabela)

- 7 cards de KPI: receita bruta, receita líquida, número de pedidos, itens vendidos, ticket
  médio, taxa de desconto, mix de canal.
- Gráfico de linha "Receita por mês/ano" (pergunta e), com toggle de 4 métricas (Receita,
  Pedidos, Quantidade, Ticket Médio) e anotação fixa na quebra de pedidos online.
- "Ticket médio por produto" e "Comparação — ticket médio com/sem promoção" (pergunta f),
  lado a lado.
- Matriz de pedidos/quantidade/valor em hierarquia Categoria → Produto (pergunta a), com
  dois callouts de destaque de produto.

### Clientes

- 5 cards de KPI: taxa de desconto, mix de canal, taxa de recorrência, receita e % dos top
  10 clientes.
- "Receita por motivo de venda" (pergunta f) e "Pedidos, quantidade e valor por tipo de
  cartão", lado a lado, cada um com seu próprio toggle de métrica.
- "Ranking clientes por valor de transação" (pergunta c) — sem limite de linhas, mostra
  todos os clientes ordenados por valor; o "Top N" vira só o callout de concentração acima
  da tabela, não um corte de linhas.
- "Pedidos detalhados" — grão pedido×produto, com cabeçalhos em português amigável.

### Análise Geográfica

- "Ticket médio por [país/estado/cidade]" — toggle de dimensão geográfica com título que
  troca de texto junto com o botão selecionado.
- "Ranking geográfico por valor de transação" (pergunta d) — mesmo padrão de "mostrar
  todos, ordenado por valor" da tabela de Clientes, com o mesmo toggle de dimensão
  controlando o agrupamento.

### Filtros globais — 9 no total, idênticos nas 3 páginas de conteúdo

Ano, Mês, Cidade, Estado, País, Categoria de Produto, Produto, Tipo de Cartão, Motivo da
Venda. Cobrem os cortes que a pergunta (a) exige (produto, tipo de cartão, motivo, data,
cliente, cidade, estado, país) — Canal e Território ficaram de fora da barra porque nenhuma
das 6 perguntas do briefing pede esses dois cortes como filtro global (Canal continua usado
internamente na Comparação com/sem Promoção). Status também fica de fora: é um valor
constante em 100% dos pedidos (ver Etapa 8), não corta nada.

Distinção documentada perto da barra de filtro: **filtro global** restringe o conjunto de
dados nas 3 páginas de conteúdo, sincronizado entre elas; **toggle** (seletor de métrica ou
de dimensão geográfica) muda o agrupamento de um visual específico, sem restringir nada —
os dois convivem sem conflito.

## 3. Candidatos a interatividade real, e como cada um virou mecanismo do Power BI

Um mockup estático não interage de verdade — a tabela abaixo documentava, ainda na Etapa 6,
qual objeto real do Power BI resolveria cada interação. Todos os cinco foram implementados
na Etapa 7; o detalhe de cada implementação (e as duas que não saíram exatamente como
planejado aqui) está em `docs/07-dashboard.md` §3.

| Interação no mockup | Mecanismo planejado | O que de fato virou na Etapa 7 |
|---|---|---|
| Seletor "Categoria/Produto" na Matriz | Field Parameter | Não funcionou (renderizava o texto literal do parâmetro) — trocado por hierarquia nativa Categoria → Produto no poço de Linhas |
| Seletor "Motivo" na Matriz | Filtro de visual | Mantido como planejado |
| Hierarquia Categoria → Produto na Matriz | hierarquia nativa | Mantido como planejado |
| Botões Receita/Pedidos do gráfico de linha | bookmarks | Trocado por Field Parameter (mesmo padrão dos demais toggles), estendido para 4 métricas |
| Toggle de dimensão geográfica | — (não estava resolvido no mockup) | Field Parameter, com título de gráfico dinâmico (07 §3.5) |
| Ranking de clientes/cidades | — (ainda tinha Top N no mockup) | Top N removido a pedido do briefing; ranking sequencial em DAX com correção de blanks (07 §3.4) |

## 4. Identidade visual (alta fidelidade)

- **Base de referência**: os mockups do treino BanVic — header com badge circular + wordmark,
  abas de navegação como pills arredondadas, cards brancos com `feDropShadow` sutil.
- **Paleta**: tema Storm do Power BI (`#0641C8` header, `#0078ED`/`#0050EB` destaque,
  `#032164`/`#5B6B85` texto, `#EEF2F8` fundo) — mesma paleta que a Etapa 7 usa como tema do
  relatório.
- **Tipografia**: Arial, com fallback `"Segoe UI", sans-serif`.
- **Ícone da marca**: mountain + wheel ("trilha"), escolhido entre 3 opções por representar o
  negócio real da Adventure Works (fabricante de bicicletas) sem ser um ícone literal de roda
  ou silhueta de bike.
- **Nome da empresa**: "Adventure Works" (duas palavras, como o briefing escreve no texto
  corrido) — não "AdventureWorks" (nome técnico do banco de dados).

## 5. Artefatos publicados

- **Mockup baixa fidelidade (P&B)**: canvas `/design`, 3 artboards (Visão Geral, Detalhe,
  Perguntas & Glossário) — material de processo, não entra na entrega.
- **Mockup alta fidelidade**: canvas `/design`, 4 artboards de conteúdo (Capa, Visão Geral &
  Produtos, Clientes, Análise Geográfica) mais 3 artboards de fundo ("-fundo", cards vazios
  sem título/filtro/dado — mesmo padrão usado no treino BanVic para virar background do
  Power BI; a Capa usa cor sólida, não precisa de fundo próprio).
- **Exportação final**, em `Desafio/entregaveis/`:
  - `AdventureWorks-Capa.jpg`, `AdventureWorks-VisaoGeralProdutos.jpg`,
    `AdventureWorks-Clientes.jpg`, `AdventureWorks-AnaliseGeografica.jpg` — os quatro
    mockups completos, é o entregável formal do briefing (JPEG do mockup).
  - `AdventureWorks-VisaoGeralProdutos-fundo.svg`, `AdventureWorks-Clientes-fundo.svg`,
    `AdventureWorks-AnaliseGeografica-fundo.svg` — os fundos que a Etapa 7 importa como
    imagem de página (fora do repositório, entregues apenas como arquivo pontual para a
    troca no Power BI Desktop), com um retângulo branco por card na posição exata
    (coordenadas medidas em pixel, não estimadas).

## 6. Pendente

Nenhuma — os mecanismos de interatividade da seção 3 já entraram no escopo de construção
da Etapa 7 e estão implementados no dashboard final (`docs/07-dashboard.md`).
