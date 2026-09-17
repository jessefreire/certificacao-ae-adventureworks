# Etapa 6 — Mockup do dashboard

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 6 de 10 — *"Creation of a dashboard mockup, based on your KPI research and
exploratory analysis insights. Pay attention to data visualization and data storytelling
best practices."*
**Status:** completa — mockup de alta fidelidade aprovado, pronto para a Etapa 7
**Entregável do briefing:** arquivo JPEG do mockup do dashboard

> Nota de escopo: o briefing pede o mockup "criado no Figma". Usamos o canvas `/design`
> (ferramenta de mockup multi-artboard com interface equivalente), exportando o resultado
> final como JPEG — mesma nota de divergência já registrada para outras pequenas diferenças
> de ferramenta ao longo do projeto.

---

## 1. Processo: baixa fidelidade antes de alta fidelidade

Duas rodadas deliberadas, para separar as duas decisões que um dashboard exige: primeiro
**o que mostrar e como organizar a leitura** (dataviz e usabilidade), só depois **a
identidade visual** (cor, tipografia, tema).

- **Baixa fidelidade (P&B)**: wireframe em escala de cinza, 3 páginas — Visão Geral, Detalhe,
  e uma página de apoio "Perguntas & Glossário" (candidatos a drill-down, distinção entre
  filtro global e toggle local) — não faz parte do entregável final, é material de processo.
- **Alta fidelidade (colorida)**: 2 páginas — Visão Geral e Detalhe — usando os mockups do
  treino BanVic como base de padrão visual, paleta do tema Storm do Power BI e fonte Arial
  (nativa da ferramenta, evita substituição de fonte na publicação).

Tamanho de canvas fixo: **1280px de largura** nas duas fidelidades (padrão de página do Power
BI) — a largura nunca muda; a altura de cada página cresce conforme o conteúdo pede (874px na
Visão Geral, 1021px no Detalhe), medida sempre no navegador (`getBoundingClientRect()`, sem
estimar) antes de fechar o tamanho do frame.

## 2. Cobertura de conteúdo: as 2 telas respondem tudo?

A régua usada: as 6 perguntas principais do briefing (a–f) e os 9 indicadores da Etapa 1
(`docs/01-kpis-e-perguntas.md`) precisam de visual definido; os 14 aprofundamentos (a.1–f.2)
se resolvem por **filtro ou toggle**, não por tela nova — se um aprofundamento não tiver
mecanismo de filtro/toggle correspondente no mockup, as 2 telas não bastam de verdade.

### Visão Geral (estrutura de 3 atos: KPIs → gráficos → tabela)

- 8 cards de KPI (2 linhas de 4): receita bruta, receita líquida, número de pedidos, ticket
  médio, itens vendidos, e o mix de canal.
- Gráfico de linha "Receita por mês/ano" (pergunta e), com toggle Receita/Pedidos.
- Gráfico de barras "Receita por motivo de venda" (pergunta f).
- Painel de contexto "Receita por grupo de território" (achado da EDA, `territory_group`).

### Detalhe

- Tabela "Top 10 Clientes por valor de transação" (pergunta c), com % de participação, canal
  predominante e motivo mais frequente.
- "Ranking de Cidades por valor de transação" (pergunta d), mesmo tratamento de colunas.
- Matriz de pedidos/quantidade/valor em hierarquia Categoria → Produto (pergunta a), com
  seletor de dimensão e filtro local de motivo.
- Painel "Comparação — ticket médio com/sem promoção" (pergunta f / aprofundamento f.2).

### Filtros globais — 9 no total, idênticos nas duas páginas

Duas linhas: **Período · Canal · Território · Estado · País** e **Categoria de Produto ·
Produto · Tipo de Cartão · Motivo da Venda**. Cobrem os cortes que a pergunta (a) exige
(produto, tipo de cartão, motivo, data, cliente, status, cidade, estado, país) — Cidade
ficou de fora do filtro global (558 valores, ruim como dropdown sem busca) e continua
acessível pela interação no Ranking de Cidades.

Distinção documentada perto da barra de filtro: **filtro global** restringe o conjunto de
dados nas duas telas; **toggle** (seletor de dimensão da Matriz, Receita/Pedidos do gráfico
de linha) muda o agrupamento de um visual específico, sem restringir nada — os dois convivem
sem conflito.

## 3. Candidatos a drill-down / interatividade real (documentados, não implementados no mockup estático)

Um mockup estático não interage de verdade — os mecanismos abaixo estão documentados para
implementação na Etapa 7, com o objeto real do Power BI por trás de cada um:

| Visual | Interação no mockup | Mecanismo real no Power BI |
|---|---|---|
| Matriz (Detalhe) | seletor "Categoria" | **Field Parameter**, alternando entre `dim_product[category]` e `dim_product[product_name]` |
| Matriz (Detalhe) | seletor "Motivo" | **Filtro de visual** ("Filtros neste visual") sobre `dim_sales_reason[reason_name]` |
| Matriz (Detalhe) | hierarquia Categoria → Produto | hierarquia nativa da Matriz (Categoria e Produto no mesmo well de Linhas) |
| Gráfico de linha (Visão Geral) | botões Receita/Pedidos | **bookmarks** alternando a medida exibida |
| Contexto território (Visão Geral) | — | candidato a drillthrough grupo → território individual (3 → 10) |
| Ranking de Cidades (Detalhe) | — | candidato a drillthrough país → estado → cidade |

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
- **Mockup alta fidelidade**: canvas `/design`, 2 artboards completos (Visão Geral, Detalhe)
  mais 2 artboards de fundo ("-fundo", cards vazios sem título/filtro/dado — mesmo padrão
  usado no treino BanVic para virar background do Power BI).
- **Exportação final**, em `Desafio/entregaveis/`:
  - `AdventureWorks-VisaoGeral.jpg`, `AdventureWorks-Detalhe.jpg` — os dois mockups completos,
    é o entregável formal do briefing (JPEG do mockup).
  - `AdventureWorks-VisaoGeral-fundo.svg`, `AdventureWorks-Detalhe-fundo.svg` — os fundos que
    a Etapa 7 importa como imagem de página, com um retângulo branco por card na posição
    exata (coordenadas medidas em pixel, não estimadas).

## 6. Pendente

Nenhuma — os 3 mecanismos de interatividade da seção 3 entram no escopo de construção da
Etapa 7 (decisão registrada em `docs/07-*.md`, a produzir junto com o dashboard).
