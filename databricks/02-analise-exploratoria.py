# Databricks notebook source
# MAGIC %md
# MAGIC # Analise exploratoria — Adventure Works
# MAGIC
# MAGIC Etapa 2 do desafio, e o entregavel que o briefing pede em "notebook com codigo,
# MAGIC graficos e comentario sobre cada insight".
# MAGIC
# MAGIC **A pergunta nao se descobre aqui.** Ela foi definida na Etapa 1, em
# MAGIC `docs/01-kpis-e-perguntas.md`. Este notebook responde as **seis perguntas do
# MAGIC briefing** e os **catorze aprofundamentos** que a Etapa 1 derivou delas — cada um com
# MAGIC consulta, evidencia e comentario. Os codigos `a.1`, `b.2`, `f.2` remetem aquele
# MAGIC documento; nenhum aprofundamento e tema solto.
# MAGIC
# MAGIC ## Como ler
# MAGIC
# MAGIC | Secao | O que tem | Celulas |
# MAGIC |---|---|---|
# MAGIC | **1. Perfil do dado** | O que existe aqui dentro: tamanho, canais, nulos, unicidade das chaves. Nao responde pergunta de negocio — estabelece o que da para perguntar | 6 consultas |
# MAGIC | **2. Reconciliacao** | O numero que o CEO cobra, antes de qualquer conclusao. Se este nao fecha, nada depois vale | 1 consulta |
# MAGIC | **3 a 8** | Uma secao por pergunta, de (a) a (f). Cada uma abre com o enunciado do briefing, responde o minimo pedido, e depois percorre seus aprofundamentos | 24 consultas |
# MAGIC | **Graficos** | Nove, em dois grupos — ver abaixo | 9 celulas Python |
# MAGIC | **9. Sintese** | O que a exploracao mudou no entendimento do dataset, que e a frase que o briefing pede | — |
# MAGIC
# MAGIC ### Por que os graficos ficam num bloco, e nao um por pergunta
# MAGIC
# MAGIC Porque nem toda pergunta precisa de grafico, e nem todo grafico responde pergunta.
# MAGIC
# MAGIC **Os cinco primeiros existem onde a tabela nao mostra o que o grafico mostra:** a
# MAGIC quebra estrutural da serie (`e.1`), a uniformidade que desqualifica um corte (`a.1`),
# MAGIC a cauda longa do catalogo (`a.2`), a confusao entre canal e mercado (`b.2`), e a
# MAGIC comparacao que so vale dentro do mesmo canal (`f.2`).
# MAGIC
# MAGIC **Os quatro ultimos respondem visualmente (b), (c), (d) e (f)**, que sao rankings — e
# MAGIC ranking se le melhor em barra que em tabela. Cada um carrega no titulo o aviso que
# MAGIC impede a leitura errada: o corte de volume, o peso dos dez maiores, a barra do
# MAGIC "todas as outras cidades", o rotulo de escopo do online.
# MAGIC
# MAGIC Somando, cada uma das seis perguntas tem ao menos um visual. E os quatro ultimos sao
# MAGIC o rascunho do dashboard da Etapa 7 — mesmo corte, mesmo aviso.
# MAGIC
# MAGIC ## Antes de rodar
# MAGIC
# MAGIC A ingestao tem de estar feita e conferida:
# MAGIC `databricks/ingestao-adventure-works.sql`. As seis conferencias da secao 3 dele
# MAGIC passaram — as **64 tabelas** com a contagem identica a dos arquivos de origem, zero
# MAGIC orfao nas sete juncoes, 27.659 pedidos sem vendedor preservados como NULL, o aceite
# MAGIC fechando em `12.646.112,1607` e zero linha fora de um centavo no `linetotal`.
# MAGIC
# MAGIC Este notebook usa **17** dessas tabelas — as que as seis perguntas exigem. Ele so le:
# MAGIC nao cria, nao carrega, nao altera nada. Rodar de novo e sempre seguro.
# MAGIC
# MAGIC Precisa de **compute de notebook** anexado, e nao apenas do SQL warehouse: as celulas
# MAGIC de grafico rodam `toPandas()` e matplotlib, que e codigo Python.
# MAGIC
# MAGIC Sugestao para a primeira execucao: va **celula por celula ate a secao 2**. Se o numero
# MAGIC do CEO fechar ali, o resto e analise sobre base confiavel e `Run all below` resolve.
# MAGIC
# MAGIC ## Duas convencoes que valem para todo o notebook
# MAGIC
# MAGIC **Receita tem duas definicoes, e elas nao sao intercambiaveis.**
# MAGIC `receita_bruta = unitprice * orderqty` (antes do desconto) e o que o teste de aceite
# MAGIC usa. `receita_liquida = linetotal` (depois do desconto) e o que a formula de ticket
# MAGIC medio do briefing pede. A diferenca e pequena nesta base — 0,478% — mas nomear qual
# MAGIC das duas esta em cada numero evita a discussao de "seu total nao bate com o meu".
# MAGIC
# MAGIC **Canal vem de `onlineorderflag`, nao do tipo de cartao.** Testei a hipotese do cartao
# MAGIC na Etapa 1 e ela e falsa: dos 1.131 pedidos sem cartao, 1.124 sao online (ver `a.1`).
# MAGIC E canal e o eixo mais importante desta base, porque revenda e online sao dois negocios
# MAGIC com ticket de ordem de grandeza diferente convivendo na mesma tabela.

# COMMAND ----------

# MAGIC %md
# MAGIC # 1. Perfil do dado
# MAGIC
# MAGIC Antes de qualquer conclusao: o que existe aqui dentro? Esta secao nao responde
# MAGIC pergunta de negocio — ela estabelece o que da e o que nao da para perguntar.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Tamanho e janela do dataset. Esperado: 31.465 pedidos, 121.317 itens,
# MAGIC -- de 31/05/2011 a 30/06/2014.
# MAGIC select
# MAGIC     count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , min(salesorderheader.orderdate) as primeiro_pedido
# MAGIC     , max(salesorderheader.orderdate) as ultimo_pedido
# MAGIC     , count(distinct salesorderheader.customerid) as clientes_com_pedido
# MAGIC from workspace.adventure_works.salesorderheader

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Os dois canais, que sao o eixo mais importante desta base.
# MAGIC -- Esperado: 27.659 online e 3.806 revenda — mas a receita se inverte.
# MAGIC select
# MAGIC     case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as receita_liquida
# MAGIC     , round(
# MAGIC         sum(salesorderdetail.linetotal)
# MAGIC         / count(distinct salesorderheader.salesorderid)
# MAGIC         , 2
# MAGIC     ) as ticket_medio
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC group by case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by receita_liquida desc

# COMMAND ----------

# MAGIC %md
# MAGIC **A inversao que organiza o resto do notebook.** A revenda e 12,1% dos pedidos e a
# MAGIC maior parte da receita; o online e 87,9% dos pedidos e a menor parte. Sao dois
# MAGIC negocios com ticket de ordem de grandeza diferente convivendo na mesma tabela.
# MAGIC
# MAGIC Consequencia pratica: **qualquer media que misture os dois descreve um negocio que
# MAGIC nao existe.** E a origem de metade dos avisos que aparecem adiante.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Colunas de valor unico nao discriminam nada. Esperado: status = 5 em 100%.
# MAGIC select
# MAGIC     salesorderheader.status
# MAGIC     , count(*) as pedidos
# MAGIC     , round(100.0 * count(*) / sum(count(*)) over (), 1) as pct
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC group by salesorderheader.status
# MAGIC order by pedidos desc

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Nulos nas colunas que a analise usa. Esperado: 27.659 sem vendedor (= online),
# MAGIC -- 1.131 sem cartao, e ZERO pedido sem territorio ou sem endereco.
# MAGIC select
# MAGIC     count(*) as pedidos
# MAGIC     , count(*) - count(salesorderheader.salespersonid) as sem_vendedor
# MAGIC     , count(*) - count(salesorderheader.creditcardid) as sem_cartao
# MAGIC     , count(*) - count(salesorderheader.territoryid) as sem_territorio
# MAGIC     , count(*) - count(salesorderheader.billtoaddressid) as sem_endereco
# MAGIC from workspace.adventure_works.salesorderheader

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Unicidade das chaves que a Etapa 5 vai testar no dbt. Esperado: duplicadas = 0
# MAGIC -- nas quatro. Se algo aparecer aqui, o teste de PK do dbt nasce quebrado.
# MAGIC select
# MAGIC     'salesorderheader.salesorderid' as chave
# MAGIC     , count(*) as duplicadas
# MAGIC from (
# MAGIC     select salesorderid
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     group by salesorderid
# MAGIC     having count(*) > 1
# MAGIC )
# MAGIC
# MAGIC union all
# MAGIC
# MAGIC select
# MAGIC     'salesorderdetail.salesorderdetailid' as chave
# MAGIC     , count(*) as duplicadas
# MAGIC from (
# MAGIC     select salesorderdetailid
# MAGIC     from workspace.adventure_works.salesorderdetail
# MAGIC     group by salesorderdetailid
# MAGIC     having count(*) > 1
# MAGIC )
# MAGIC
# MAGIC union all
# MAGIC
# MAGIC select
# MAGIC     'customer.customerid' as chave
# MAGIC     , count(*) as duplicadas
# MAGIC from (
# MAGIC     select customerid
# MAGIC     from workspace.adventure_works.customer
# MAGIC     group by customerid
# MAGIC     having count(*) > 1
# MAGIC )
# MAGIC
# MAGIC union all
# MAGIC
# MAGIC select
# MAGIC     'product.productid' as chave
# MAGIC     , count(*) as duplicadas
# MAGIC from (
# MAGIC     select productid
# MAGIC     from workspace.adventure_works.product
# MAGIC     group by productid
# MAGIC     having count(*) > 1
# MAGIC )

# COMMAND ----------

# MAGIC %sql
# MAGIC -- A hierarquia produto -> subcategoria -> categoria esta completa onde importa?
# MAGIC -- Esperado: 209 dos 504 produtos sem subcategoria, mas ZERO entre os que vendem.
# MAGIC select
# MAGIC     count(*) as produtos
# MAGIC     , sum(case when product.productsubcategoryid is null then 1 else 0 end)
# MAGIC     as sem_subcategoria
# MAGIC     , sum(
# MAGIC         case
# MAGIC             when product.productsubcategoryid is null and product.productid in (
# MAGIC                 select salesorderdetail.productid
# MAGIC                 from workspace.adventure_works.salesorderdetail
# MAGIC             ) then 1
# MAGIC             else 0
# MAGIC         end
# MAGIC     ) as sem_subcategoria_mas_vende
# MAGIC from workspace.adventure_works.product

# COMMAND ----------

# MAGIC %md
# MAGIC **O furo do cadastro coincide com o furo de venda.** 209 produtos sem subcategoria,
# MAGIC e nenhum deles vende. A hierarquia esta completa para 100% do que gera receita —
# MAGIC ou seja, a dimensao de produto da Etapa 3 pode usar categoria e subcategoria sem
# MAGIC balde "nao classificado" no visual.
# MAGIC
# MAGIC Isso tambem antecipa `a.2`: os furos estao exatamente entre os produtos que nunca
# MAGIC venderam.

# COMMAND ----------

# MAGIC %md
# MAGIC # 2. Reconciliacao — o numero que o CEO cobra
# MAGIC
# MAGIC O briefing diz que o CEO acompanha **US$ 12.646.112,16** de receita bruta em 2011.
# MAGIC Se este numero nao fecha, nada depois vale. Ele vem primeiro por isso.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- O aceite. Esperado: FECHA, com soma exata 12646112.1607.
# MAGIC -- Comparacao em centavos: unitprice tem 4 casas e o briefing informa arredondado.
# MAGIC select
# MAGIC     12646112.16 as esperado_em_centavos
# MAGIC     , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
# MAGIC     , case
# MAGIC         when round(sum(salesorderdetail.unitprice * salesorderdetail.orderqty), 2)
# MAGIC             = 12646112.16
# MAGIC             then 'FECHA'
# MAGIC         else 'DIVERGE'
# MAGIC     end as resultado
# MAGIC from workspace.adventure_works.salesorderdetail
# MAGIC inner join workspace.adventure_works.salesorderheader
# MAGIC     on salesorderdetail.salesorderid = salesorderheader.salesorderid
# MAGIC where year(salesorderheader.orderdate) = 2011

# COMMAND ----------

# MAGIC %md
# MAGIC **Fecha ao centavo, e a definicao importa mais que o numero.**
# MAGIC
# MAGIC Sao `unitprice * orderqty` — receita **bruta**, antes do desconto — e nao o
# MAGIC `subtotal` do pedido. Testei `sum(subtotal)` primeiro e da `12.641.672,21`, errado
# MAGIC por exatamente o valor dos descontos de 2011. Tambem nao ha filtro de status: os
# MAGIC 1.607 pedidos de 2011 entram todos.
# MAGIC
# MAGIC Duas consequencias que atravessam o resto do projeto:
# MAGIC
# MAGIC 1. `receita_bruta` deixa de ser metrica de apoio e passa a ser **metrica auditada**.
# MAGIC    Vai para o modelo com esse nome e essa definicao, e ganha teste no dbt.
# MAGIC 2. A quarta casa decimal e o que justifica `decimal(19, 4)` no lugar de `double`:
# MAGIC    2.832 dos 5.642 itens de 2011 tem 4 casas no preco unitario.
# MAGIC
# MAGIC ⚠️ **Nao use 2011 como retrato do negocio.** Sao 1.607 pedidos dos 31.465, num ano
# MAGIC dominado por revenda. 2011 e o ano do **teste**, nao da analise.

# COMMAND ----------

# MAGIC %md
# MAGIC # 3. Pergunta (a) — pedidos, quantidade e valor por nove dimensoes
# MAGIC
# MAGIC > *Qual o numero de pedidos, a quantidade comprada e o valor total da transacao por
# MAGIC > produto, tipo de cartao, motivo da venda, data da venda, cliente, status, cidade,
# MAGIC > estado e pais?*
# MAGIC
# MAGIC A mais larga do briefing: 3 metricas x 9 cortes. Literalmente, a tabela fato inteira
# MAGIC com todas as dimensoes plugadas.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- As 3 metricas pelos 9 cortes, no exemplo do corte por pais.
# MAGIC -- A estrutura se repete trocando o group by; o dashboard faz isso com filtro.
# MAGIC select
# MAGIC     countryregion.name as pais
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , sum(salesorderdetail.orderqty) as quantidade
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as valor_total
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC inner join workspace.adventure_works.address
# MAGIC     on salesorderheader.billtoaddressid = address.addressid
# MAGIC inner join workspace.adventure_works.stateprovince
# MAGIC     on address.stateprovinceid = stateprovince.stateprovinceid
# MAGIC inner join workspace.adventure_works.countryregion
# MAGIC     on stateprovince.countryregioncode = countryregion.countryregioncode
# MAGIC group by countryregion.name
# MAGIC order by valor_total desc

# COMMAND ----------

# MAGIC %md
# MAGIC ## a.1 — Quais dos nove cortes de fato discriminam?
# MAGIC
# MAGIC O briefing manda entregar os nove. Entregar sem dizer que alguns nao informam nada
# MAGIC repete o erro do CRM que decepcionou a Silvana: tela cheia de cortes, nenhum
# MAGIC acionavel.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Tipo de cartao discrimina? Esperado: nao — quatro fatias de ~24% e 3,6% sem cartao.
# MAGIC select
# MAGIC     coalesce(creditcard.cardtype, 'sem cartao') as tipo_cartao
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(
# MAGIC         100.0 * count(distinct salesorderheader.salesorderid)
# MAGIC         / sum(count(distinct salesorderheader.salesorderid)) over ()
# MAGIC         , 1
# MAGIC     ) as pct
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC left join workspace.adventure_works.creditcard
# MAGIC     on salesorderheader.creditcardid = creditcard.creditcardid
# MAGIC group by coalesce(creditcard.cardtype, 'sem cartao')
# MAGIC order by pedidos desc

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Cartao serve de proxy de canal? Testei essa hipotese e ela e FALSA.
# MAGIC -- Esperado: dos 1.131 sem cartao, 1.124 sao online e so 7 de revenda.
# MAGIC select
# MAGIC     case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(*) as pedidos_sem_cartao
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC where salesorderheader.creditcardid is null
# MAGIC group by case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by pedidos_sem_cartao desc

# COMMAND ----------

# MAGIC %md
# MAGIC **Dois dos nove cortes nao discriminam.** `status` e constante (5 em 100% dos
# MAGIC 31.465 pedidos) e `tipo de cartao` e praticamente uniforme (~24% em cada uma das
# MAGIC quatro bandeiras). Ambos entram no dashboard como **filtro documentado**, nao como
# MAGIC visual de destaque — dizer qual corte nao informa e barato e evita telas inuteis.
# MAGIC
# MAGIC E a hipotese que eu tinha de que "pedido sem cartao = revenda" **e falsa**: dos
# MAGIC 1.131 sem cartao, 1.124 sao online. Canal se le em `onlineorderflag`, e ponto.

# COMMAND ----------

# MAGIC %md
# MAGIC ## a.2 — Quanto do catalogo nunca vendeu?
# MAGIC
# MAGIC O complemento do corte por produto: nao o que vendeu, mas o que **nunca** vendeu.
# MAGIC Nenhuma das seis pergunta isso, porque todas perguntam sobre o que vendeu.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Quanto do catalogo nunca vendeu? Esperado: 238 de 504 produtos (47%).
# MAGIC select
# MAGIC     count(*) as produtos_no_catalogo
# MAGIC     , count(distinct salesorderdetail.productid) as produtos_que_vendem
# MAGIC     , count(*) - count(distinct salesorderdetail.productid) as nunca_venderam
# MAGIC from workspace.adventure_works.product
# MAGIC left join workspace.adventure_works.salesorderdetail
# MAGIC     on product.productid = salesorderdetail.productid

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Entre os que vendem, quanta receita esta no topo? Esperado: top 10 = 28,2%.
# MAGIC with receita_por_produto as (
# MAGIC     select
# MAGIC         product.name as produto
# MAGIC         , sum(salesorderdetail.linetotal) as receita
# MAGIC     from workspace.adventure_works.salesorderdetail
# MAGIC     inner join workspace.adventure_works.product
# MAGIC         on salesorderdetail.productid = product.productid
# MAGIC     group by product.name
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     produto
# MAGIC     , round(receita, 2) as receita
# MAGIC     , round(100.0 * receita / sum(receita) over (), 2) as pct_da_receita
# MAGIC     , round(100.0 * sum(receita) over (order by receita desc) / sum(receita) over (), 2)
# MAGIC     as pct_acumulado
# MAGIC from receita_por_produto
# MAGIC order by receita desc
# MAGIC limit 10

# COMMAND ----------

# MAGIC %md
# MAGIC **238 dos 504 produtos (47%) nunca venderam.** Quase metade do catalogo custa
# MAGIC cadastro, estoque e atencao comercial sem devolver receita.
# MAGIC
# MAGIC Isso e a unica economia desta analise que **nao depende de vender mais nada** — e
# MAGIC por isso e o achado mais acionavel para a Silvana, que precisa de resultado
# MAGIC comercial imediato.

# COMMAND ----------

# MAGIC %md
# MAGIC ## a.3 — O corte por motivo da venda cobre a empresa inteira?
# MAGIC
# MAGIC Que fracao do negocio o corte por motivo realmente descreve.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Motivo de venda existe nos dois canais? Esperado: NAO — revenda tem zero motivo.
# MAGIC select
# MAGIC     case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , count(distinct salesorderheadersalesreason.salesorderid) as pedidos_com_motivo
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC left join workspace.adventure_works.salesorderheadersalesreason
# MAGIC     on salesorderheader.salesorderid = salesorderheadersalesreason.salesorderid
# MAGIC group by case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by pedidos desc

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Quantos motivos por pedido? Esperado: 8.453 sem motivo (26,9%) e 4.482 com mais
# MAGIC -- de um. E por isso que somar receita por motivo estoura o total.
# MAGIC select
# MAGIC     motivos_no_pedido
# MAGIC     , count(*) as pedidos
# MAGIC     , round(100.0 * count(*) / sum(count(*)) over (), 1) as pct
# MAGIC from (
# MAGIC     select
# MAGIC         salesorderheader.salesorderid
# MAGIC         , count(salesorderheadersalesreason.salesreasonid) as motivos_no_pedido
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     left join workspace.adventure_works.salesorderheadersalesreason
# MAGIC         on salesorderheader.salesorderid = salesorderheadersalesreason.salesorderid
# MAGIC     group by salesorderheader.salesorderid
# MAGIC )
# MAGIC group by motivos_no_pedido
# MAGIC order by motivos_no_pedido

# COMMAND ----------

# MAGIC %md
# MAGIC **O corte por motivo descreve so o varejo online.** A revenda tem **zero** pedidos
# MAGIC com motivo — e a revenda e a maior parte da receita. Somando os dois canais,
# MAGIC **8.453 pedidos (26,9%) nao tem motivo nenhum** e **4.482 tem mais de um**.
# MAGIC
# MAGIC Duas decisoes saem daqui, e as duas sao para nao mentir no dashboard:
# MAGIC
# MAGIC 1. O visual de motivo leva **rotulo explicito de escopo** ("apenas vendas online").
# MAGIC    Sem isso, o grafico parece descrever a Adventure Works e descreve um quarto dela.
# MAGIC 2. Existe o balde **"sem motivo informado"**, em vez de um `inner join` que apagaria
# MAGIC    26,9% da base em silencio.
# MAGIC
# MAGIC E o 4.482 e a evidencia de que `SalesReason` e **muitos-para-muitos**: receita por
# MAGIC motivo **nao soma** ao total. E a decisao de modelagem aberta da Etapa 3
# MAGIC (bridge table ou nao), documentada no Anexo B.1 da Etapa 1.

# COMMAND ----------

# MAGIC %md
# MAGIC # 4. Pergunta (b) — produtos com maior ticket medio, por tempo e geografia
# MAGIC
# MAGIC > *Quais produtos tem o maior valor medio por pedido, por mes, ano, cidade, estado e
# MAGIC > pais? (valor medio por pedido = receita bruta − descontos de produto / numero de
# MAGIC > pedidos no periodo analisado)*
# MAGIC
# MAGIC A formula do briefing subtrai desconto, entao o numerador e `linetotal` — receita
# MAGIC **liquida**. Nao e `unitprice * orderqty`.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Ticket medio por produto, na definicao exata do briefing.
# MAGIC -- Denominador = pedidos DISTINTOS, nao linhas de item.
# MAGIC select
# MAGIC     product.name as produto
# MAGIC     , count(distinct salesorderdetail.salesorderid) as pedidos
# MAGIC     , round(
# MAGIC         sum(salesorderdetail.linetotal)
# MAGIC         / count(distinct salesorderdetail.salesorderid)
# MAGIC         , 2
# MAGIC     ) as ticket_medio
# MAGIC from workspace.adventure_works.salesorderdetail
# MAGIC inner join workspace.adventure_works.product
# MAGIC     on salesorderdetail.productid = product.productid
# MAGIC group by product.name
# MAGIC having count(distinct salesorderdetail.salesorderid) >= 30
# MAGIC order by ticket_medio desc
# MAGIC limit 15

# COMMAND ----------

# MAGIC %md
# MAGIC O `having pedidos >= 30` nao esta no briefing e e uma escolha minha: sem corte de
# MAGIC volume, o topo do ranking vira produto que vendeu duas vezes com ticket altissimo.
# MAGIC Isso responde a letra da pergunta e engana quem le. O corte fica **declarado no
# MAGIC dashboard**, como filtro visivel, nao escondido na consulta.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.1 — O desconto que a formula subtrai existe de fato, e onde?
# MAGIC
# MAGIC A formula do briefing subtrai desconto. Vale conferir se ha desconto para subtrair.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- O desconto e material? Esperado: 0,478% da receita bruta. Quase nada.
# MAGIC select
# MAGIC     round(sum(salesorderdetail.unitprice * salesorderdetail.orderqty), 2) as receita_bruta
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as receita_liquida
# MAGIC     , round(
# MAGIC         sum(
# MAGIC             salesorderdetail.unitprice
# MAGIC             * salesorderdetail.orderqty
# MAGIC             - salesorderdetail.linetotal
# MAGIC         )
# MAGIC         , 2
# MAGIC     ) as desconto_total
# MAGIC     , round(
# MAGIC         100.0 * sum(
# MAGIC             salesorderdetail.unitprice
# MAGIC             * salesorderdetail.orderqty
# MAGIC             - salesorderdetail.linetotal
# MAGIC         )
# MAGIC         / sum(salesorderdetail.unitprice * salesorderdetail.orderqty)
# MAGIC         , 3
# MAGIC     ) as pct_desconto
# MAGIC from workspace.adventure_works.salesorderdetail

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Onde o desconto acontece? Esperado: so na revenda — toda oferta e do tipo Reseller.
# MAGIC select
# MAGIC     case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(*) as itens
# MAGIC     , sum(case when salesorderdetail.unitpricediscount > 0 then 1 else 0 end)
# MAGIC     as itens_com_desconto
# MAGIC from workspace.adventure_works.salesorderdetail
# MAGIC inner join workspace.adventure_works.salesorderheader
# MAGIC     on salesorderdetail.salesorderid = salesorderheader.salesorderid
# MAGIC group by case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by itens desc

# COMMAND ----------

# MAGIC %md
# MAGIC **O desconto e 0,478% da receita bruta** — e existe **so na revenda**. No online,
# MAGIC nenhum item tem desconto.
# MAGIC
# MAGIC Por que isso importa apesar de ser pequeno: a formula do briefing manda subtrair, e
# MAGIC nos subtraimos. Mas a diferenca entre "receita bruta" e "receita liquida" e menor
# MAGIC que o arredondamento de qualquer decisao comercial — **exceto** no numero do CEO,
# MAGIC onde a definicao errada da 12.641.672,21 em vez de 12.646.112,16.
# MAGIC
# MAGIC Ou seja: desconto e irrelevante para o negocio e decisivo para a auditoria.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.2 — O ticket medio varia por praca?
# MAGIC
# MAGIC A pergunta (b) pede o corte geografico. Ele informa algo, ou os paises se parecem?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Ticket medio por pais. Esperado: varia 3,4x — AU ~1.557 ate US ~5.232.
# MAGIC select
# MAGIC     countryregion.name as pais
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(
# MAGIC         sum(salesorderdetail.linetotal)
# MAGIC         / count(distinct salesorderheader.salesorderid)
# MAGIC         , 2
# MAGIC     ) as ticket_medio
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC inner join workspace.adventure_works.address
# MAGIC     on salesorderheader.billtoaddressid = address.addressid
# MAGIC inner join workspace.adventure_works.stateprovince
# MAGIC     on address.stateprovinceid = stateprovince.stateprovinceid
# MAGIC inner join workspace.adventure_works.countryregion
# MAGIC     on stateprovince.countryregioncode = countryregion.countryregioncode
# MAGIC group by countryregion.name
# MAGIC order by ticket_medio desc

# COMMAND ----------

# MAGIC %md
# MAGIC **O ticket medio varia 3,4x entre paises**, de ~1.557 na Australia a ~5.232 nos
# MAGIC Estados Unidos. O corte geografico **informa**, diferente de `status` e tipo de
# MAGIC cartao.
# MAGIC
# MAGIC ⚠️ **Mas cuidado com a leitura.** Boa parte dessa variacao e **mistura de canal**,
# MAGIC nao diferenca de mercado: paises com mais revenda tem ticket maior por construcao.
# MAGIC O grafico honesto desse corte e **facetado por canal** — a versao simples sugere
# MAGIC que americano compra 3x mais que australiano, o que nao e o que o dado diz.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.3 — Que natureza de desconto a empresa usa?
# MAGIC
# MAGIC Volume, liquidacao ou promocao de produto? A resposta muda a alavanca comercial.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Que tipo de oferta a empresa usa de fato? Esperado: todas do tipo Reseller,
# MAGIC -- e a esmagadora maioria dos itens sem oferta nenhuma.
# MAGIC select
# MAGIC     specialoffer.type as tipo_oferta
# MAGIC     , specialoffer.category as categoria
# MAGIC     , count(*) as itens
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as receita_liquida
# MAGIC from workspace.adventure_works.salesorderdetail
# MAGIC inner join workspace.adventure_works.specialoffer
# MAGIC     on salesorderdetail.specialofferid = specialoffer.specialofferid
# MAGIC group by
# MAGIC     specialoffer.type
# MAGIC     , specialoffer.category
# MAGIC order by itens desc

# COMMAND ----------

# MAGIC %md
# MAGIC **Toda oferta desta base e da categoria `Reseller`** — desconto de canal, negociado
# MAGIC com revendedor, tipicamente por volume. Nao existe liquidacao nem promocao de
# MAGIC produto ao consumidor final.
# MAGIC
# MAGIC Isso responde de forma inesperada a expectativa da Silvana: a empresa **nao** usa
# MAGIC promocao ao consumidor como alavanca. O que ela chama de "verba em promocao" nao
# MAGIC existe no dado — a alavanca de desconto e comercial B2B.

# COMMAND ----------

# MAGIC %md
# MAGIC # 5. Pergunta (c) — os 10 principais clientes por valor
# MAGIC
# MAGIC > *Quais os 10 principais clientes por valor total de transacao?*

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Os 10 maiores clientes. O nome vem de person OU store, conforme o tipo.
# MAGIC select
# MAGIC     coalesce(store.name, concat_ws(' ', person.firstname, person.lastname))
# MAGIC     as cliente
# MAGIC     , case when store.name is not null then 'revenda' else 'pessoa fisica' end as tipo
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as valor_total
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC inner join workspace.adventure_works.customer
# MAGIC     on salesorderheader.customerid = customer.customerid
# MAGIC left join workspace.adventure_works.person
# MAGIC     on customer.personid = person.businessentityid
# MAGIC left join workspace.adventure_works.store
# MAGIC     on customer.storeid = store.businessentityid
# MAGIC group by
# MAGIC     coalesce(store.name, concat_ws(' ', person.firstname, person.lastname))
# MAGIC     , case when store.name is not null then 'revenda' else 'pessoa fisica' end
# MAGIC order by valor_total desc
# MAGIC limit 10

# COMMAND ----------

# MAGIC %md
# MAGIC ## c.1 — Quanto da receita depende dos 10 maiores?
# MAGIC
# MAGIC O ranking sem o peso e curiosidade. Com o peso, e risco.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Concentracao no topo. Esperado: top 10 = 7,2% da receita. Baixa dependencia.
# MAGIC with por_cliente as (
# MAGIC     select
# MAGIC         salesorderheader.customerid
# MAGIC         , sum(salesorderdetail.linetotal) as receita
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     inner join workspace.adventure_works.salesorderdetail
# MAGIC         on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC     group by salesorderheader.customerid
# MAGIC )
# MAGIC
# MAGIC , ranqueado as (
# MAGIC     select
# MAGIC         customerid
# MAGIC         , receita
# MAGIC         , row_number() over (order by receita desc) as posicao
# MAGIC     from por_cliente
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     count(*) as clientes
# MAGIC     , round(100.0 * sum(case when posicao <= 10 then receita else 0 end) / sum(receita), 2)
# MAGIC     as pct_top_10
# MAGIC     , round(100.0 * sum(case when posicao <= 100 then receita else 0 end) / sum(receita), 2)
# MAGIC     as pct_top_100
# MAGIC from ranqueado

# COMMAND ----------

# MAGIC %md
# MAGIC **Os 10 maiores respondem por 7,2% da receita.** Nao ha dependencia perigosa de
# MAGIC cliente — perder o maior deles nao ameaca a empresa.
# MAGIC
# MAGIC Isso e uma **nao-noticia valiosa**: o briefing pede o ranking, e o ranking sozinho
# MAGIC sugere que aqueles dez nomes sao a empresa. Nao sao. Dizer o peso junto do ranking e
# MAGIC o que impede uma decisao errada de atendimento prioritario.

# COMMAND ----------

# MAGIC %md
# MAGIC ## c.2 — Os clientes voltam a comprar?
# MAGIC
# MAGIC O corte por cliente da pergunta (a) e o ranking da (c) tratam o cliente como
# MAGIC estatico. Ele volta?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Recompra por canal. Esperado: 39,1% no geral, mas o numero e MUITO diferente
# MAGIC -- entre online e revenda — e a media dos dois nao descreve nenhum.
# MAGIC with pedidos_por_cliente as (
# MAGIC     select
# MAGIC         salesorderheader.customerid
# MAGIC         , max(case when salesorderheader.onlineorderflag then 1 else 0 end) as e_online
# MAGIC         , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     group by salesorderheader.customerid
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     case when e_online = 1 then 'online' else 'revenda' end as canal
# MAGIC     , count(*) as clientes
# MAGIC     , sum(case when pedidos > 1 then 1 else 0 end) as recompraram
# MAGIC     , round(100.0 * sum(case when pedidos > 1 then 1 else 0 end) / count(*), 1)
# MAGIC     as pct_recompra
# MAGIC from pedidos_por_cliente
# MAGIC group by case when e_online = 1 then 'online' else 'revenda' end
# MAGIC order by clientes desc

# COMMAND ----------

# MAGIC %md
# MAGIC **39,1% dos clientes compraram mais de uma vez** — e o numero muda radicalmente por
# MAGIC canal. Revendedor recompra quase sempre (e uma relacao continua); consumidor online,
# MAGIC muito menos.
# MAGIC
# MAGIC A metrica de retencao, portanto, **so faz sentido separada por canal**. Um numero
# MAGIC unico de "39% de recompra" descreve um cliente medio que nao existe.

# COMMAND ----------

# MAGIC %md
# MAGIC # 6. Pergunta (d) — as 5 principais cidades por valor
# MAGIC
# MAGIC > *Quais as 5 principais cidades por valor total de transacao?*

# COMMAND ----------

# MAGIC %sql
# MAGIC -- As 5 maiores cidades por valor.
# MAGIC select
# MAGIC     address.city as cidade
# MAGIC     , countryregion.name as pais
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as valor_total
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC inner join workspace.adventure_works.address
# MAGIC     on salesorderheader.billtoaddressid = address.addressid
# MAGIC inner join workspace.adventure_works.stateprovince
# MAGIC     on address.stateprovinceid = stateprovince.stateprovinceid
# MAGIC inner join workspace.adventure_works.countryregion
# MAGIC     on stateprovince.countryregioncode = countryregion.countryregioncode
# MAGIC group by
# MAGIC     address.city
# MAGIC     , countryregion.name
# MAGIC order by valor_total desc
# MAGIC limit 5

# COMMAND ----------

# MAGIC %md
# MAGIC ## d.1 — Quanto as cinco primeiras concentram?
# MAGIC
# MAGIC Mesma logica de `c.1`: o ranking sem o peso pode sugerir o contrario da verdade.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Concentracao geografica. Esperado: top 5 cidades = 11,0% da receita,
# MAGIC -- com 613 cidades cadastradas e 558 vendendo. Receita PULVERIZADA.
# MAGIC with por_cidade as (
# MAGIC     select
# MAGIC         address.city
# MAGIC         , sum(salesorderdetail.linetotal) as receita
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     inner join workspace.adventure_works.salesorderdetail
# MAGIC         on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC     inner join workspace.adventure_works.address
# MAGIC         on salesorderheader.billtoaddressid = address.addressid
# MAGIC     group by address.city
# MAGIC )
# MAGIC
# MAGIC , ranqueado as (
# MAGIC     select
# MAGIC         city
# MAGIC         , receita
# MAGIC         , row_number() over (order by receita desc) as posicao
# MAGIC     from por_cidade
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     count(*) as cidades_que_vendem
# MAGIC     , round(100.0 * sum(case when posicao <= 5 then receita else 0 end) / sum(receita), 2)
# MAGIC     as pct_top_5
# MAGIC     , round(100.0 * sum(case when posicao <= 20 then receita else 0 end) / sum(receita), 2)
# MAGIC     as pct_top_20
# MAGIC from ranqueado

# COMMAND ----------

# MAGIC %md
# MAGIC **As 5 maiores cidades sao 11,0% da receita**, distribuida entre 558 cidades que
# MAGIC vendem (de 613 cadastradas). A receita e **pulverizada**, nao concentrada.
# MAGIC
# MAGIC Registro de um erro meu na Etapa 1, porque ele ilustra o risco desta pergunta: eu
# MAGIC calculei 39,7% ao ler a coluna errada do endereco (`addressline2` em vez de `city`).
# MAGIC Com 39,7% a conclusao seria "concentre esforco em cinco pracas". Com 11,0% e o
# MAGIC oposto: **nao existe praca que mova o ponteiro** — estrategia por cidade e
# MAGIC desperdicio, e o corte relevante e pais ou territorio.
# MAGIC
# MAGIC Uma coluna errada inverteu a recomendacao. E por isso que o `03-verificacao` existe.

# COMMAND ----------

# MAGIC %md
# MAGIC ## d.2 — A top 5 de valor e a mesma de volume?
# MAGIC
# MAGIC Se as duas listas divergem, ha cidade de ticket alto e cidade de giro alto — e
# MAGIC isso muda o tipo de acao.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Valor x volume por cidade. Divergencia entre as duas posicoes revela
# MAGIC -- cidade de ticket alto (poucos pedidos, muito valor) e o contrario.
# MAGIC with por_cidade as (
# MAGIC     select
# MAGIC         address.city
# MAGIC         , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC         , sum(salesorderdetail.linetotal) as receita
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     inner join workspace.adventure_works.salesorderdetail
# MAGIC         on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC     inner join workspace.adventure_works.address
# MAGIC         on salesorderheader.billtoaddressid = address.addressid
# MAGIC     group by address.city
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     city as cidade
# MAGIC     , pedidos
# MAGIC     , round(receita, 2) as receita
# MAGIC     , rank() over (order by receita desc) as posicao_valor
# MAGIC     , rank() over (order by pedidos desc) as posicao_volume
# MAGIC from por_cidade
# MAGIC order by receita desc
# MAGIC limit 10

# COMMAND ----------

# MAGIC %md
# MAGIC # 7. Pergunta (e) — pedidos, quantidade e valor por mes e ano
# MAGIC
# MAGIC > *Qual o numero de pedidos, a quantidade comprada e o valor total da transacao por
# MAGIC > mes e ano?*

# COMMAND ----------

# MAGIC %sql
# MAGIC -- A serie mensal completa, com o canal separado — porque o comportamento
# MAGIC -- dos dois e diferente e a soma esconde a virada.
# MAGIC select
# MAGIC     date_trunc('month', salesorderheader.orderdate) as mes
# MAGIC     , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , sum(salesorderdetail.orderqty) as quantidade
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as valor_total
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC group by
# MAGIC     date_trunc('month', salesorderheader.orderdate)
# MAGIC     , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by mes, canal

# COMMAND ----------

# MAGIC %md
# MAGIC ## e.1 — A serie tem quebra estrutural?
# MAGIC
# MAGIC Uma serie com quebra nao pode ser lida como tendencia. Se houver, todo grafico de
# MAGIC crescimento precisa de anotacao.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Quebra estrutural no online. Esperado: salto de 533 para 1.564 pedidos
# MAGIC -- entre jun e jul/2013 — quase 3x em um mes.
# MAGIC select
# MAGIC     date_trunc('month', salesorderheader.orderdate) as mes
# MAGIC     , count(*) as pedidos_online
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC where salesorderheader.onlineorderflag
# MAGIC     and salesorderheader.orderdate >= '2013-01-01'
# MAGIC     and salesorderheader.orderdate < '2014-01-01'
# MAGIC group by date_trunc('month', salesorderheader.orderdate)
# MAGIC order by mes

# COMMAND ----------

# MAGIC %md
# MAGIC **Ha quebra, e ela e grande: 533 pedidos online em jun/2013 para 1.564 em jul/2013**
# MAGIC — quase 3x em um mes, e o patamar nao volta.
# MAGIC
# MAGIC Isso nao e crescimento orgânico; e mudanca de regime — entrada em novos mercados,
# MAGIC campanha ou mudanca de canal. O dado nao diz qual, e **essa e uma pergunta para o
# MAGIC negocio**, nao para a analise.
# MAGIC
# MAGIC Consequencia para o dashboard: qualquer visual de tendencia precisa de **anotacao em
# MAGIC jul/2013**. Sem ela, uma media de "crescimento mensal" mistura dois regimes e nao
# MAGIC descreve nenhum dos dois.

# COMMAND ----------

# MAGIC %md
# MAGIC ## e.2 — A oscilacao mensal e de volume ou de valor?
# MAGIC
# MAGIC E a revenda tem ritmo mensal proprio?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- A revenda concentra em meses especificos? Esperado: sim, ritmo trimestral —
# MAGIC -- e isso faz a receita total oscilar sem o online ter mudado nada.
# MAGIC select
# MAGIC     month(salesorderheader.orderdate) as mes_do_ano
# MAGIC     , count(*) as pedidos_revenda
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC where not salesorderheader.onlineorderflag
# MAGIC group by month(salesorderheader.orderdate)
# MAGIC order by mes_do_ano

# COMMAND ----------

# MAGIC %md
# MAGIC # 8. Pergunta (f) — produto com mais unidades no motivo "Promotion"
# MAGIC
# MAGIC > *Qual produto teve o maior numero de unidades vendidas quando o motivo da venda
# MAGIC > foi "Promocao"?*

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Quais motivos existem, e como "Promotion" aparece.
# MAGIC -- Esperado: a categoria 'Promotion' agrupa mais de um nome de motivo.
# MAGIC select
# MAGIC     salesreason.reasontype as categoria
# MAGIC     , salesreason.name as motivo
# MAGIC     , count(*) as vinculos
# MAGIC from workspace.adventure_works.salesorderheadersalesreason
# MAGIC inner join workspace.adventure_works.salesreason
# MAGIC     on salesorderheadersalesreason.salesreasonid = salesreason.salesreasonid
# MAGIC group by
# MAGIC     salesreason.reasontype
# MAGIC     , salesreason.name
# MAGIC order by categoria asc, vinculos desc

# COMMAND ----------

# MAGIC %sql
# MAGIC -- A resposta da pergunta (f): produto com mais unidades quando o motivo
# MAGIC -- e da categoria Promotion.
# MAGIC select
# MAGIC     product.name as produto
# MAGIC     , sum(salesorderdetail.orderqty) as unidades
# MAGIC     , count(distinct salesorderdetail.salesorderid) as pedidos
# MAGIC from workspace.adventure_works.salesorderdetail
# MAGIC inner join workspace.adventure_works.product
# MAGIC     on salesorderdetail.productid = product.productid
# MAGIC inner join workspace.adventure_works.salesorderheadersalesreason
# MAGIC     on salesorderdetail.salesorderid = salesorderheadersalesreason.salesorderid
# MAGIC inner join workspace.adventure_works.salesreason
# MAGIC     on salesorderheadersalesreason.salesreasonid = salesreason.salesreasonid
# MAGIC where salesreason.reasontype = 'Promotion'
# MAGIC group by product.name
# MAGIC order by unidades desc
# MAGIC limit 10

# COMMAND ----------

# MAGIC %md
# MAGIC ## f.1 — Qual e a resposta, e o que ela revela?
# MAGIC
# MAGIC A pergunta (f) e a mais estreita das seis, e a resposta vem com um porem: como o
# MAGIC motivo existe **so no online** (`a.3`), ela descreve o varejo, nao a empresa.
# MAGIC
# MAGIC O rotulo "Promotion" e **categoria** (`reasontype`), nao nome de motivo — por isso o
# MAGIC filtro e `reasontype = 'Promotion'`. Usar `name` daria resposta diferente e errada.

# COMMAND ----------

# MAGIC %md
# MAGIC ## f.2 — Promocao aumenta o pedido? — controlando por canal
# MAGIC
# MAGIC A pergunta natural depois da (f). E onde eu errei primeiro, entao a consulta abaixo
# MAGIC ja nasce com o controle.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Promocao aumenta o tamanho do pedido? Comparacao SO DENTRO DO ONLINE.
# MAGIC -- Esperado: 2,10 itens/pedido em promocao (1.810 pedidos) contra 2,39 em
# MAGIC -- outros motivos (824). Promocao vende MENOS por pedido.
# MAGIC with pedido_com_motivo as (
# MAGIC     select
# MAGIC         salesorderheader.salesorderid
# MAGIC         , max(case when salesreason.reasontype = 'Promotion' then 1 else 0 end)
# MAGIC         as tem_promocao
# MAGIC     from workspace.adventure_works.salesorderheader
# MAGIC     inner join workspace.adventure_works.salesorderheadersalesreason
# MAGIC         on salesorderheader.salesorderid = salesorderheadersalesreason.salesorderid
# MAGIC     inner join workspace.adventure_works.salesreason
# MAGIC         on salesorderheadersalesreason.salesreasonid = salesreason.salesreasonid
# MAGIC     where salesorderheader.onlineorderflag
# MAGIC     group by salesorderheader.salesorderid
# MAGIC )
# MAGIC
# MAGIC select
# MAGIC     case when pedido_com_motivo.tem_promocao = 1 then 'promocao' else 'outro motivo' end
# MAGIC     as grupo
# MAGIC     , count(distinct pedido_com_motivo.salesorderid) as pedidos
# MAGIC     , round(
# MAGIC         sum(salesorderdetail.orderqty)
# MAGIC         / count(distinct pedido_com_motivo.salesorderid)
# MAGIC         , 2
# MAGIC     ) as itens_por_pedido
# MAGIC     , round(
# MAGIC         sum(salesorderdetail.linetotal)
# MAGIC         / count(distinct pedido_com_motivo.salesorderid)
# MAGIC         , 2
# MAGIC     ) as ticket_medio
# MAGIC from pedido_com_motivo
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on pedido_com_motivo.salesorderid = salesorderdetail.salesorderid
# MAGIC group by case when pedido_com_motivo.tem_promocao = 1 then 'promocao' else 'outro motivo' end
# MAGIC order by pedidos desc

# COMMAND ----------

# MAGIC %md
# MAGIC **Dentro do online, pedido com promocao tem 2,10 itens contra 2,39 dos outros
# MAGIC motivos.** Promocao esta associada a pedido **menor**, nao maior.
# MAGIC
# MAGIC ⚠️ E aqui esta o erro que eu cometi antes e que este bloco existe para nao repetir:
# MAGIC na primeira tentativa eu comparei "com promocao" contra "todo o resto" e achei 2,10
# MAGIC contra 9,57. Parecia que promocao destruia o pedido. **Era confusao de canal**: o
# MAGIC "resto" incluia a revenda, que compra por atacado e nao tem motivo nenhum. Eu estava
# MAGIC comparando varejo com atacado e chamando de efeito de promocao.
# MAGIC
# MAGIC A comparacao honesta e dentro do mesmo canal, e ai o efeito e pequeno.
# MAGIC
# MAGIC **E associacao, nao causa.** O dado nao diz se a promocao encolheu o pedido ou se
# MAGIC pedido pequeno atrai promocao. Para a Silvana, a leitura util e negativa: **nao ha
# MAGIC evidencia de que promocao aumente o pedido nesta base** — e nao existe promocao ao
# MAGIC consumidor no dado de desconto (`b.3`).

# COMMAND ----------

# MAGIC %md
# MAGIC # Graficos
# MAGIC
# MAGIC Dois grupos, com propositos diferentes.
# MAGIC
# MAGIC **Os cinco primeiros existem porque a tabela nao mostra o que o grafico mostra:** a
# MAGIC quebra estrutural da serie, a uniformidade que desqualifica um corte, a cauda longa
# MAGIC do catalogo, a confusao entre canal e mercado, e a comparacao que so vale dentro do
# MAGIC mesmo canal. Servem aos aprofundamentos `e.1`, `a.1`, `a.2`, `b.2` e `f.2`.
# MAGIC
# MAGIC **Os quatro ultimos respondem visualmente as perguntas (b), (c), (d) e (f)**, que sao
# MAGIC rankings — e ranking se le melhor em barra que em tabela.
# MAGIC
# MAGIC Com os nove, cada uma das seis perguntas do briefing tem ao menos um visual: a (a)
# MAGIC pelo tipo de cartao e pelo Pareto, a (e) pela serie mensal, e as outras quatro no
# MAGIC segundo grupo.
# MAGIC
# MAGIC Os quatro ultimos sao tambem o rascunho do dashboard da Etapa 7 — mesmo corte, mesmo
# MAGIC aviso de escopo.

# COMMAND ----------

import matplotlib.pyplot as plt
import pandas as pd

# A serie mensal por canal, com a quebra de jul/2013 anotada. Sem a anotacao,
# o grafico sugere crescimento continuo — e sao dois regimes diferentes.
#
# Duas armadilhas de eixo, e as duas dao o MESMO erro (ConversionError):
#
#   1. a quebra tem de ser um Timestamp, nao o texto "2013-07-01": o eixo x vem
#      de date_trunc, que o toPandas converte para datetime64, e o matplotlib
#      recusa texto num eixo de data
#   2. divisao no Spark devolve `decimal`, e o toPandas traz isso como objeto
#      Decimal do Python, que o matplotlib tambem recusa. Por isso os graficos
#      com media e percentual convertem para `double` no proprio SQL. Precisao
#      de centavo nao importa para desenhar — importa para o teste de aceite,
#      que fica nas celulas de consulta e continua em decimal(19, 4).
QUEBRA = pd.Timestamp("2013-07-01")
serie = spark.sql("""
    select
        date_trunc('month', salesorderheader.orderdate) as mes
        , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
        , count(distinct salesorderheader.salesorderid) as pedidos
    from workspace.adventure_works.salesorderheader
    group by
        date_trunc('month', salesorderheader.orderdate)
        , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
    order by mes
""").toPandas()

fig, ax = plt.subplots(figsize=(13, 5))
for canal, grupo in serie.groupby("canal"):
    ax.plot(grupo["mes"], grupo["pedidos"], marker="o", markersize=3, label=canal)

ax.axvline(QUEBRA, color="crimson", linestyle="--", linewidth=1)
ax.annotate(
    "jul/2013: 533 → 1.564 pedidos online\nquebra estrutural, nao tendencia",
    xy=(QUEBRA, 1564), xytext=(-260, -30), textcoords="offset points",
    color="crimson", fontsize=9,
    arrowprops=dict(arrowstyle="->", color="crimson", linewidth=1),
)
ax.set_title("Pedidos por mes e canal — a quebra de jul/2013")
ax.set_ylabel("pedidos")
ax.legend()
ax.grid(alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Tipo de cartao: quatro fatias iguais. O grafico existe para JUSTIFICAR uma
# ausencia no dashboard — e a prova visual de que o corte nao discrimina.
cartao = spark.sql("""
    select
        coalesce(creditcard.cardtype, 'sem cartao') as tipo_cartao
        , count(*) as pedidos
    from workspace.adventure_works.salesorderheader
    left join workspace.adventure_works.creditcard
        on salesorderheader.creditcardid = creditcard.creditcardid
    group by coalesce(creditcard.cardtype, 'sem cartao')
    order by pedidos desc
""").toPandas()

fig, ax = plt.subplots(figsize=(8, 4))
ax.barh(cartao["tipo_cartao"], cartao["pedidos"], color="steelblue")
ax.invert_yaxis()
ax.set_title("Pedidos por tipo de cartao — quatro fatias iguais, corte que nao informa")
ax.set_xlabel("pedidos")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Pareto dos produtos que vendem. Mostra a cauda longa que a tabela de top 10
# esconde — e os 238 que nunca venderam nem aparecem aqui.
pareto = spark.sql("""
    with receita as (
        select
            product.productid
            , sum(salesorderdetail.linetotal) as receita
        from workspace.adventure_works.salesorderdetail
        inner join workspace.adventure_works.product
            on salesorderdetail.productid = product.productid
        group by product.productid
    )

    select
        row_number() over (order by receita desc) as posicao
        , cast(
            100.0 * sum(receita) over (order by receita desc) / sum(receita) over ()
            as double
        ) as pct_acumulado
    from receita
    order by posicao
""").toPandas()

fig, ax = plt.subplots(figsize=(10, 4.5))
ax.plot(pareto["posicao"], pareto["pct_acumulado"], color="darkorange", linewidth=2)
ax.axhline(80, color="gray", linestyle=":", linewidth=1)
ax.set_title("Pareto: 266 produtos vendem, 238 do catalogo nunca venderam")
ax.set_xlabel("produtos, do maior para o menor")
ax.set_ylabel("% acumulado da receita")
ax.grid(alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Ticket medio por pais, FACETADO POR CANAL. A versao sem faceta sugere que
# americano compra 3x mais que australiano; a diferenca e mistura de canal.
ticket = spark.sql("""
    select
        countryregion.name as pais
        , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
        , cast(
            sum(salesorderdetail.linetotal)
            / count(distinct salesorderheader.salesorderid)
            as double
        ) as ticket_medio
    from workspace.adventure_works.salesorderheader
    inner join workspace.adventure_works.salesorderdetail
        on salesorderheader.salesorderid = salesorderdetail.salesorderid
    inner join workspace.adventure_works.address
        on salesorderheader.billtoaddressid = address.addressid
    inner join workspace.adventure_works.stateprovince
        on address.stateprovinceid = stateprovince.stateprovinceid
    inner join workspace.adventure_works.countryregion
        on stateprovince.countryregioncode = countryregion.countryregioncode
    group by
        countryregion.name
        , case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
""").toPandas()

tabela = ticket.pivot(index="pais", columns="canal", values="ticket_medio")
fig, ax = plt.subplots(figsize=(10, 4.5))
tabela.plot(kind="bar", ax=ax, color=["steelblue", "indianred"])
ax.set_title("Ticket medio por pais e canal — a variacao e de canal, nao de mercado")
ax.set_ylabel("ticket medio")
ax.set_xlabel("")
plt.xticks(rotation=30, ha="right")
ax.grid(axis="y", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Promocao vs outro motivo, SO DENTRO DO ONLINE. E o grafico que impede a
# leitura errada: sem o recorte de canal, a diferenca aparece como 2,10 x 9,57.
promo = spark.sql("""
    with pedido_com_motivo as (
        select
            salesorderheader.salesorderid
            , max(case when salesreason.reasontype = 'Promotion' then 1 else 0 end)
                as tem_promocao
        from workspace.adventure_works.salesorderheader
        inner join workspace.adventure_works.salesorderheadersalesreason
            on salesorderheader.salesorderid = salesorderheadersalesreason.salesorderid
        inner join workspace.adventure_works.salesreason
            on salesorderheadersalesreason.salesreasonid = salesreason.salesreasonid
        where salesorderheader.onlineorderflag
        group by salesorderheader.salesorderid
    )

    select
        case when pedido_com_motivo.tem_promocao = 1 then 'promocao' else 'outro motivo' end
            as grupo
        , cast(
            sum(salesorderdetail.orderqty)
            / count(distinct pedido_com_motivo.salesorderid)
            as double
        ) as itens_por_pedido
    from pedido_com_motivo
    inner join workspace.adventure_works.salesorderdetail
        on pedido_com_motivo.salesorderid = salesorderdetail.salesorderid
    group by
        case when pedido_com_motivo.tem_promocao = 1 then 'promocao' else 'outro motivo' end
""").toPandas()

fig, ax = plt.subplots(figsize=(7, 4))
ax.bar(promo["grupo"], promo["itens_por_pedido"], color=["indianred", "steelblue"])
ax.set_title("Itens por pedido, apenas ONLINE — promocao nao aumenta o pedido")
ax.set_ylabel("itens por pedido")
ax.grid(axis="y", alpha=0.3)
for i, v in enumerate(promo["itens_por_pedido"]):
    ax.text(i, v, f"{v:.2f}", ha="center", va="bottom")
plt.tight_layout()
plt.show()

# COMMAND ----------

# MAGIC %md
# Pergunta (b): produtos com maior ticket medio. O corte de 30 pedidos esta no
# TITULO do grafico, e nao escondido na consulta — sem ele o topo do ranking vira
# produto que vendeu duas vezes com ticket altissimo.
ticket_produto = spark.sql("""
    select
        product.name as produto
        , cast(
            sum(salesorderdetail.linetotal)
            / count(distinct salesorderdetail.salesorderid)
            as double
        ) as ticket_medio
    from workspace.adventure_works.salesorderdetail
    inner join workspace.adventure_works.product
        on salesorderdetail.productid = product.productid
    group by product.name
    having count(distinct salesorderdetail.salesorderid) >= 30
    order by ticket_medio desc
    limit 15
""").toPandas()

fig, ax = plt.subplots(figsize=(10, 6))
ax.barh(ticket_produto["produto"], ticket_produto["ticket_medio"], color="steelblue")
ax.invert_yaxis()
ax.set_title("(b) Maior ticket medio por produto — so produtos com 30+ pedidos")
ax.set_xlabel("ticket medio (receita liquida / pedidos)")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Pergunta (c): os 10 maiores clientes. O titulo carrega o peso deles no total,
# porque o ranking sozinho sugere que aqueles dez nomes sao a empresa — e nao sao.
top_clientes = spark.sql("""
    with por_cliente as (
        select
            coalesce(store.name, concat_ws(' ', person.firstname, person.lastname))
                as cliente
            , sum(salesorderdetail.linetotal) as receita
        from workspace.adventure_works.salesorderheader
        inner join workspace.adventure_works.salesorderdetail
            on salesorderheader.salesorderid = salesorderdetail.salesorderid
        inner join workspace.adventure_works.customer
            on salesorderheader.customerid = customer.customerid
        left join workspace.adventure_works.person
            on customer.personid = person.businessentityid
        left join workspace.adventure_works.store
            on customer.storeid = store.businessentityid
        group by coalesce(store.name, concat_ws(' ', person.firstname, person.lastname))
    )

    select
        cliente
        , cast(receita as double) as receita
        , cast(100.0 * receita / sum(receita) over () as double) as pct
    from por_cliente
    order by receita desc
    limit 10
""").toPandas()

peso = top_clientes["pct"].sum()
fig, ax = plt.subplots(figsize=(10, 5))
ax.barh(top_clientes["cliente"], top_clientes["receita"], color="steelblue")
ax.invert_yaxis()
ax.set_title(f"(c) Os 10 maiores clientes — juntos, {peso:.1f}% da receita")
ax.set_xlabel("receita liquida")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Pergunta (d): as 5 maiores cidades, com o resto ao lado. A barra do "outras" e
# o ponto do grafico: sem ela, cinco barras grandes sugerem concentracao onde nao
# ha. Foi exatamente o erro que eu cometi na Etapa 1, lendo a coluna errada.
cidades = spark.sql("""
    with por_cidade as (
        select
            address.city as cidade
            , sum(salesorderdetail.linetotal) as receita
        from workspace.adventure_works.salesorderheader
        inner join workspace.adventure_works.salesorderdetail
            on salesorderheader.salesorderid = salesorderdetail.salesorderid
        inner join workspace.adventure_works.address
            on salesorderheader.billtoaddressid = address.addressid
        group by address.city
    )

    , ranqueado as (
        select
            cidade
            , receita
            , row_number() over (order by receita desc) as posicao
        from por_cidade
    )

    select
        case when posicao <= 5 then cidade else 'todas as outras cidades' end as grupo
        , cast(sum(receita) as double) as receita
    from ranqueado
    group by case when posicao <= 5 then cidade else 'todas as outras cidades' end
    order by receita desc
""").toPandas()

cores = ["indianred" if g.startswith("todas") else "steelblue" for g in cidades["grupo"]]
fig, ax = plt.subplots(figsize=(10, 4.5))
ax.barh(cidades["grupo"], cidades["receita"], color=cores)
ax.invert_yaxis()
ax.set_title("(d) As 5 maiores cidades contra o resto — a receita e pulverizada")
ax.set_xlabel("receita liquida")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# Pergunta (f): unidades vendidas quando o motivo e Promotion. O rotulo de escopo
# no titulo nao e enfeite — motivo de venda existe SO no online, entao este
# grafico descreve o varejo e nao a empresa.
promo_produto = spark.sql("""
    select
        product.name as produto
        , sum(salesorderdetail.orderqty) as unidades
    from workspace.adventure_works.salesorderdetail
    inner join workspace.adventure_works.product
        on salesorderdetail.productid = product.productid
    inner join workspace.adventure_works.salesorderheadersalesreason
        on salesorderdetail.salesorderid = salesorderheadersalesreason.salesorderid
    inner join workspace.adventure_works.salesreason
        on salesorderheadersalesreason.salesreasonid = salesreason.salesreasonid
    where salesreason.reasontype = 'Promotion'
    group by product.name
    order by unidades desc
    limit 10
""").toPandas()

fig, ax = plt.subplots(figsize=(10, 5))
ax.barh(promo_produto["produto"], promo_produto["unidades"], color="steelblue")
ax.invert_yaxis()
ax.set_title("(f) Unidades no motivo Promotion — APENAS vendas online")
ax.set_xlabel("unidades")
ax.grid(axis="x", alpha=0.3)
for i, v in enumerate(promo_produto["unidades"]):
    ax.text(v, i, f" {v}", va="center", fontsize=8)
plt.tight_layout()
plt.show()

# COMMAND ----------

# MAGIC # 9. Sintese — o que a exploracao mudou no entendimento
# MAGIC
# MAGIC O briefing pede explicitamente esta secao: como os insights ajudaram a entender o
# MAGIC dataset.
# MAGIC
# MAGIC **1. Nao e um negocio, sao dois.** Revenda e 12,1% dos pedidos e a maior parte da
# MAGIC receita; online e 87,9% dos pedidos e a menor parte. Isso nao estava no briefing e
# MAGIC reorganizou tudo: toda metrica agregada que mistura os dois descreve um negocio
# MAGIC inexistente. Foi o achado com mais consequencia.
# MAGIC
# MAGIC **2. Dois dos nove cortes da pergunta (a) nao informam nada.** `status` e constante,
# MAGIC tipo de cartao e uniforme. Entregar os nove sem dizer isso repetiria o erro do CRM
# MAGIC que decepcionou a Silvana.
# MAGIC
# MAGIC **3. A receita e pulverizada, nao concentrada.** Top 10 clientes = 7,2%; top 5
# MAGIC cidades = 11,0%. Duas perguntas do briefing pedem ranking, e o ranking sozinho
# MAGIC sugere o contrario. Aqui um erro meu de leitura de coluna chegou a inverter a
# MAGIC recomendacao — 39,7% viraria "concentre em cinco pracas".
# MAGIC
# MAGIC **4. A serie tem quebra estrutural em jul/2013**, com o online triplicando em um mes.
# MAGIC Nenhuma leitura de tendencia funciona sem essa anotacao.
# MAGIC
# MAGIC **5. Promocao nao aumenta o pedido, e desconto ao consumidor nao existe.** Toda
# MAGIC oferta e `Reseller`. A expectativa da Silvana sobre verba de promocao nao encontra
# MAGIC apoio no dado.
# MAGIC
# MAGIC **6. Metade do catalogo nao vende.** 238 de 504 produtos. E a unica economia que
# MAGIC nao depende de vender mais nada.
# MAGIC
# MAGIC ## O que fica para a Etapa 3
# MAGIC
# MAGIC A exploracao **nao** decide modelagem, mas evidenciou duas decisoes:
# MAGIC
# MAGIC - **`SalesReason` e muitos-para-muitos** — 4.482 pedidos com mais de um motivo.
# MAGIC   Bridge table ou um motivo por pedido? A escolha muda a definicao de um indicador
# MAGIC   ja entregue ("receita por motivo de venda — nao soma ao total").
# MAGIC - **O grao da tabela fato** — item de pedido, dado que a pergunta (f) precisa de
# MAGIC   unidade por produto.
# MAGIC
# MAGIC Ambas estao no Anexo B do documento da Etapa 1, marcadas como decisao conjunta.
