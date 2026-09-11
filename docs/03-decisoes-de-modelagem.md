# Decisões de modelagem — Etapa 3

Registrado **antes** de qualquer contato com material de avaliação. As duas decisões saem
de três fontes, todas legítimas: o briefing do desafio, o
[`indicium-code-style`](https://github.com/indiciumtech/indicium-code-style) (público), o
referencial de processos da Indicium, e medição direta nos CSVs da base.

## Decisão 1 — grão da tabela fato

**Uma `fact_vendas`, no grão do item de pedido.** PK `salesorderdetailid`.

| Evidência | Fonte |
|---|---|
| O briefing diz **"a tabela fato"**, no singular, nas quatro vezes em que a menciona — no item 3 e três vezes na lista de demonstrações do vídeo | briefing, itens 3 e 9 |
| Exige **teste de PK** na fato; o item tem PK natural, o pedido só serve à outra fato | briefing, item 5 |
| O número de aceite do CEO, **US$ 12.646.112,16**, é `orderqty * unitprice` — receita **bruta**, que só existe no item. O `subtotal` do pedido é a líquida, `12.641.672,2130` | medido nos CSVs |
| A pergunta (b) define `receita bruta − descontos de produto / nº de pedidos` — as duas parcelas são colunas do item | briefing, pergunta (b) |
| Nenhuma das seis perguntas usa `freight`, `taxamt` ou `totaldue` | briefing, perguntas (a)–(f) |

**Fora da fato, deliberadamente:** `freight`, `taxamt` e `totaldue` são do pedido e valem
10,9% do `totaldue` (US$ 13,4 mi). Ficam de fora porque nenhuma pergunta os usa — não por
esquecimento. Documentar na Etapa 8.

**Consequência operacional:** a contagem de pedidos é `count(distinct salesorderid)` sobre a
fato de item.

### Por que não duas fatos

Cabeçalho e linha foi a primeira recomendação, e foi retirada. O briefing pede uma; e duas
fatos compartilhando `dim_produto`, `dim_data` e `dim_cliente` criariam o relacionamento
circular que o documento `5.4) Boas práticas envolvendo tabelas bridges` do referencial
descreve como problema a evitar no Power BI. Uma fato elimina o problema inteiro.

## Decisão 2 — tratamento de `SalesReason`

**`dim_motivo_venda` + `bridge_venda_motivo`**, ligada por `salesorderid`, mais
`tem_promocao` degenerada na fato.

O que o dado é, medido nos CSVs:

| Fato | Número |
|---|---|
| Pedidos com motivo | 23.012 de 31.465 (73,1%) |
| Com 1 motivo / 2 / 3 | 80,5% / 18,8% / 0,7% |
| Cobertura no online | 83,2% |
| Cobertura na revenda | **0%** — nenhum dos 3.806 pedidos |
| Receita da revenda | 73% do total |
| Inflação ao somar receita através da ponte | **US$ 8.426.399,95** (+29%) |

**Por que ponte e não um motivo por pedido:** para 4.482 pedidos seria preciso inventar uma
regra de prioridade que a origem não oferece — não há coluna de ordem, peso ou "principal".
A informação descartada não volta.

**Por que `tem_promocao` também:** a pergunta (f) é a única das seis que é *sobre* motivo, e
assim ela se responde sem atravessar a ponte — que é o que se demonstra no vídeo.

**Membro "Não informado" é obrigatório** em `dim_motivo_venda`: sem ele, os 26,9% sem motivo
e os 100% da revenda somem de qualquer visual filtrado por motivo, e somem justamente no
dashboard, onde ninguém confere.

**Regra que precisa estar escrita:** receita mora na fato; a ponte filtra e fatia, nunca se
soma através dela.

## Nomenclatura

`bridge_`, conforme `dbt_coding_conventions.md` (linha 218), que é o repositório normativo
que o briefing manda seguir. O referencial usa `bdg_` no documento `5.4)` — há divergência
entre os dois documentos da casa, e esta é a escolha, não um descuido.

Vale notar que o `bdg_` do referencial descreve **outra coisa**: uma ponte entre múltiplas
fatos para resolver relacionamento circular no BI, construída com `full outer join`. O que
esta decisão usa é a ponte de "muitos para muitos" entre fato e dimensão.
