# Auditoria · Dashboard de Vendas Adventure Works

> **Score: 95/100 — BOM**
> Gerado por Claude Code + `/pbi-modelo-review` em 18 set 2026 · 19:40

**Modelo:** 13 tabelas (11 do dbt + 2 de suporte) · 11 medidas · 9 relacionamentos · PBIP (sem `.pbix` exportado ainda)

---

## Veredicto

Modelo em star schema limpo: 1 fato, 8 dimensões diretas, 1 ponte para motivo de venda — zero referência circular, zero tabela plana, zero bidirecional desnecessário. O único M:M do modelo (ponte↔fato) é intencional e já documentado em `docs/08-regras-de-negocio.md`, não conta como anti-pattern. As 11 medidas usam `DIVIDE` em toda divisão (nenhum `/` cru) e todas têm descrição via comentário `///` no TMDL — cobre a exigência do briefing de "medidas documentadas dentro do arquivo". Os 5 issues encontrados são de portabilidade e limpeza, não de correção de dado.

| Métrica | Valor |
|---|---|
| Issues totais | **5** |
| Críticos | **0** |
| Tempo estimado de correção | **~1h** |

---

## Severidade

| Nível | Quantidade | Quando resolver |
|---|---|---|
| ▲ **Crítico** | 0 | — |
| ● **Médio** | 3 | Antes de entregar/publicar — afetam portabilidade e limpeza do modelo |
| ○ **Leve** | 2 | Quando der tempo — usabilidade do painel de campos |

---

## Distribuição por categoria

| Categoria | Issues |
|---|---|
| Documentação | 2 |
| Performance | 1 |
| Naming | 1 |
| Modelagem | 1 |
| Relacionamentos | 0 |
| DAX | 0 |

---

## Issues priorizados

### [MÉDIO] · DOCUMENTAÇÃO · Nenhuma dimensão tem chave de negócio marcada explicitamente (`isKey: true`)

**Onde:** todas as 9 dimensões + a ponte, em `SemanticModel/definition/tables/*.tmdl` — ex. `dim_customer.customer_key`, `dim_product.product_key`, `dim_territory.territory_key`

**Por que importa:** as relações funcionam hoje porque foram criadas manualmente com a coluna certa dos dois lados, mas sem a chave marcada explicitamente o Power BI escolhe a chave "por inferência" se algum relacionamento precisar ser recriado — e nem sempre acerta. Chave de negócio marcada também é o que dá o ícone de chave no painel de campos, sinal visual rápido de qual coluna é o grão da dimensão.

**Como corrigir:** marcar `isKey: true` na coluna que já é a chave natural de cada dimensão (a mesma usada no relacionamento). Não muda nenhum dado, só declara explicitamente o que já é verdade.

```tmdl
column customer_key
    dataType: int64
    isKey: true
    summarizeBy: none
```

---

### [MÉDIO] · MODELAGEM · Conexão com o Databricks hardcoded em texto puro nas 11 partições, incluindo o schema pessoal (`dbt_jessefreire_marts`)

**Onde:** toda partição M de toda tabela, ex. `Fonte = Databricks.Catalogs("dbc-2f14373c-ae6c.cloud.databricks.com", "/sql/1.0/warehouses/845ae824dc279622", [Catalog="workspace", Database="dbt_jessefreire_marts", ...])`

**Por que importa:** o schema `dbt_jessefreire_marts` é o schema pessoal do candidato no Databricks. Se esse PBIP for aberto por outra pessoa (avaliador, colega, você mesmo numa segunda conta), a atualização quebra na hora — o schema não existe pra ninguém além de quem o criou. Isso é exatamente o cenário que vira "funciona só na minha máquina".

**Como corrigir:** para este desafio específico (entrega individual, um schema só), não é obrigatório resolver — mas se o modelo for reaproveitado como referência/portfolio, vale trocar host/catálogo/schema por **parâmetros do modelo** (`Parâmetros de consulta` no Power Query), assim quem abrir só precisa trocar 3 valores em vez de editar M em 11 lugares.

```tmdl
expression HostDatabricks = "dbc-2f14373c-ae6c.cloud.databricks.com" meta [
    IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true
]
```

---

### [MÉDIO] · PERFORMANCE · Tabela Field Parameter "Dimensão (Categoria/Produto)" criada mas não usada em nenhum visual visível

**Onde:** `SemanticModel/definition/tables/Dimensão (Categoria%2FProduto).tmdl`; referenciada apenas por um slicer escondido fora da área visível da página Detalhe (`Report/definition/pages/detalhe0001/visuals/33eebe04175dbcbb215e`)

**Por que importa:** foi a primeira tentativa de seletor de dimensão da Matriz, abandonada em favor da hierarquia nativa Categoria→Produto (que funcionou melhor e é mais simples). A tabela e o slicer ficaram no modelo/relatório como peso morto — não quebra nada, mas confunde quem abrir o arquivo depois e vir esse objeto sem função aparente.

**Como corrigir:** remover a tabela `Dimensão (Categoria/Produto)` do modelo (via MCP `table_operations Delete`) e o visual de slicer escondido, já que a Matriz resolve isso nativamente agora. Ação de limpeza simples, sem risco.

---

### [LEVE] · DOCUMENTAÇÃO · Nenhuma das 13 tabelas tem descrição de tabela

**Onde:** todas as tabelas em `SemanticModel/definition/tables/*.tmdl` — só as medidas têm descrição (via `///`), as tabelas em si não

**Por que importa:** quem abrir o modelo pela primeira vez (avaliador, ou você mesmo em 6 meses) precisa adivinhar a granularidade e a origem de cada tabela só pelo nome. Uma frase por tabela economiza esse trabalho.

**Como corrigir:** adicionar `description:` no nível da tabela, uma frase curta com origem + grão. O conteúdo já existe pronto em `docs/08-regras-de-negocio.md` — é só copiar a frase certa pra cada tabela.

```tmdl
table '`workspace` `dbt_jessefreire_marts` `fact_sales`'
    description: "Fato no grao do item de pedido (sales_order_detail_id). Uma linha por item vendido."
```

---

### [LEVE] · NAMING · Nome de tabela no painel de campos mostra o caminho completo do catálogo

**Onde:** todas as 11 tabelas do dbt aparecem no Power BI como `` `workspace` `dbt_jessefreire_marts` `fact_sales` `` em vez de só `fact_sales`

**Por que importa:** é decisão consciente de rastreabilidade (o nome bate exatamente com a origem no Databricks, fica fácil auditar de onde vem cada tabela) — mas pesa na leitura do painel de campos no dia a dia de quem usa o relatório, não de quem o mantém. Não é erro, é trade-off.

**Como corrigir:** se a rastreabilidade 1:1 com o nome físico não for essencial pro uso diário, renomear via `table_operations Rename` para o nome curto (`fact_sales`, `dim_product`, etc.) — o nome físico de origem continua registrado na expressão M de cada partição, só o rótulo no relatório fica mais limpo. Avaliar se vale o retrabalho de revalidar todos os visuais que referenciam essas tabelas antes de decidir.

---

## Como rodar de novo

Quando quiser re-auditar (depois de aplicar correções, ou pra acompanhar evolução):

```
claude code  # na pasta raiz do projeto Power BI
> /pbi-modelo-review
```

A skill **sobrescreve** este relatório a cada execução. Para acompanhar evolução, commite cada versão no Git e use `git diff _review/relatorio.md` para ver o que mudou entre auditorias.

---

## Sobre essa skill

Auditoria gerada por **`/pbi-modelo-review`** — uma skill open-source da **Xperiun**, parte do toolkit Claude Code para Power BI.

- Operação 100% local · zero rede · zero XMLA · LGPD-compatível
- Lê apenas arquivos `.tmdl` (texto puro do PBIP)
- Não modifica nada em `SemanticModel/` ou `Report/` — somente leitura

Saiba mais: **[pages.xperiun.com](https://pages.xperiun.com)**

---

*XPERIUN · O Sistema Operacional dos Incomparáveis*
