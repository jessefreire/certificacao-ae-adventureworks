# Databricks notebook source
# MAGIC %md
# MAGIC # Análise exploratoria de dados (EDA) — Adventure Works
# MAGIC
# MAGIC Etapa 2 do desafio, e o entregavel que o briefing pede em "notebook com código,
# MAGIC gráficos e comentario sobre cada insight". O briefing chama de **análise
# MAGIC exploratoria**, e usa a sigla **EDA** uma vez, no critério de aprovacao — as duas
# MAGIC formas se referem a este notebook.
# MAGIC
# MAGIC **A pergunta não se descobre aqui.** Ela foi definida na Etapa 1 do desafio, e este
# MAGIC notebook responde. São as **seis perguntas do briefing**:
# MAGIC
# MAGIC | | Pergunta |
# MAGIC |---|---|
# MAGIC | **(a)** | Pedidos, quantidade e valor por produto, tipo de cartão, motivo da venda, data, cliente, status, cidade, estado e pais |
# MAGIC | **(b)** | Quais produtos tem o maior valor médio por pedido, por mês, ano, cidade, estado e pais |
# MAGIC | **(c)** | Os 10 principais clientes por valor total |
# MAGIC | **(d)** | As 5 principais cidades por valor total |
# MAGIC | **(e)** | Pedidos, quantidade e valor por mês e ano |
# MAGIC | **(f)** | Qual produto vendeu mais unidades quando o motivo da venda foi promocao |
# MAGIC
# MAGIC Cada uma tem sua própria seção, que abre com o enunciado do briefing e responde o que
# MAGIC ele pede.
# MAGIC
# MAGIC Ao apurar os dados na Etapa 1, cada pergunta abriu desdobramentos — coisas que a
# MAGIC pergunta original não cobre mas que mudam a leitura da resposta. Por exemplo: a (a)
# MAGIC pede nove cortes, e dois deles não separam nada; a (f) pergunta sobre promocao, e
# MAGIC promocao existe apenas no varejo online. Esses desdobramentos aparecem como
# MAGIC subsecoes ao longo do notebook, identificados por código (`a.1`, `b.2`, `f.2`), e
# MAGIC **nenhum deles e tema solto** — cada um nasceu de uma das seis.
# MAGIC
# MAGIC O documento completo da Etapa 1, com o catálogo de indicadores e a justificativa de
# MAGIC cada pergunta, esta no repositorio do projeto:
# MAGIC <https://github.com/jessefreire/formacao-analytics-engineering/tree/master/Desafio/desafio-adventureworks/docs>
# MAGIC
# MAGIC ## Como ler
# MAGIC
# MAGIC | Seção | O que tem | Celulas |
# MAGIC |---|---|---|
# MAGIC | **1. Perfil do dado** | O que existe aqui dentro: tamanho, canais, nulos, unicidade das chaves. Não responde pergunta de negocio — estabelece o que da para perguntar | 7 consultas |
# MAGIC | **2. Reconciliação** | O número que o CEO cobra, antes de qualquer conclusão. Se este não fecha, nada depois vale | 1 consulta |
# MAGIC | **3 a 8** | Uma seção por pergunta, de (a) a (f). Cada uma abre com o enunciado do briefing, responde o mínimo pedido, e depois percorre seus aprofundamentos | 25 consultas |
# MAGIC | **9. Gráficos** | Nove, em dois grupos — ver abaixo | 9 celulas Python |
# MAGIC | **10. Síntese** | O que a exploração mudou no entendimento do dataset, que e a frase que o briefing pede | — |
# MAGIC
# MAGIC ### Por que os gráficos ficam num bloco, e não um por pergunta
# MAGIC
# MAGIC Porque nem toda pergunta precisa de gráfico, e nem todo gráfico responde pergunta.
# MAGIC
# MAGIC **Os cinco primeiros existem onde a tabela não mostra o que o gráfico mostra:** a
# MAGIC quebra estrutural da série (`e.1`), a uniformidade que desqualifica um corte (`a.1`),
# MAGIC a cauda longa do catálogo (`a.2`), a confusao entre canal e mercado (`b.2`), e a
# MAGIC comparacao que só vale dentro do mesmo canal (`f.2`).
# MAGIC
# MAGIC **Os quatro últimos respondem visualmente (b), (c), (d) e (f)**, que são rankings — e
# MAGIC ranking se le melhor em barra que em tabela. Cada um carrega no titulo o aviso que
# MAGIC impede a leitura errada: o corte de volume, o peso dos dez maiores, a barra do
# MAGIC "todas as outras cidades", o rotulo de escopo do online.
# MAGIC
# MAGIC Somando, cada uma das seis perguntas tem ao menos um visual. E os quatro últimos são
# MAGIC o rascunho do dashboard da Etapa 7 — mesmo corte, mesmo aviso.
# MAGIC
# MAGIC ## Antes de rodar
# MAGIC
# MAGIC A ingestão tem de estar feita e conferida:
# MAGIC `databricks/ingestao-adventure-works.sql`. As seis conferências da seção 3 dele
# MAGIC passaram — as **64 tabelas** com a contagem idêntica a dos arquivos de origem, zero
# MAGIC órfão nas sete juncoes, 27.659 pedidos sem vendedor preservados como NULL, o aceite
# MAGIC fechando em `12.646.112,1607` e zero linha fora de um centavo no `linetotal`.
# MAGIC
# MAGIC Este notebook le **16** tabelas. O escopo declarado da análise tem 17, e a que
# MAGIC sobra e `salesperson`: canal vem de `onlineorderflag`, não do vendedor, entao ela
# MAGIC não e usada aqui e entra na Etapa 3 como dimensão. Vale dizer isso em vez de
# MAGIC arredondar para 17 — a diferença entre o que se declara e o que se usa e
# MAGIC exatamente o que o dbt vai cobrar na Etapa 5, quando cada `source` declarado
# MAGIC passa a exigir teste e documentação.
# MAGIC
# MAGIC Ele só **le**: não cria, não carrega, não altera nada. Rodar de novo e sempre seguro.
# MAGIC
# MAGIC Precisa de **compute de notebook** anexado, e não apenas do SQL warehouse: as celulas
# MAGIC de gráfico rodam `toPandas()` e matplotlib, que e código Python.
# MAGIC
# MAGIC Sugestao para a primeira execução: va **celula por celula ate a seção 2**. Se o número
# MAGIC do CEO fechar ali, o resto e análise sobre base confiável e `Run all below` resolve.
# MAGIC
# MAGIC ## Duas convencoes que valem para todo o notebook
# MAGIC
# MAGIC **Receita tem duas definições, e elas não são intercambiaveis.**
# MAGIC `receita_bruta = unitprice * orderqty` (antes do desconto) e o que o teste de aceite
# MAGIC usa. `receita_liquida = linetotal` (depois do desconto) e o que a formula de ticket
# MAGIC médio do briefing pede. A diferença e pequena nesta base — 0,478% — mas nomear qual
# MAGIC das duas esta em cada número evita a discussao de "seu total não bate com o meu".
# MAGIC
# MAGIC **Canal vem de `onlineorderflag`, não do tipo de cartão.** Testei a hipotese do cartão
# MAGIC na Etapa 1 e ela e falsa: dos 1.131 pedidos sem cartão, 1.124 são online (ver `a.1`).
# MAGIC E canal e o eixo mais importante desta base, porque revenda e online são dois negocios
# MAGIC com ticket de ordem de grandeza diferente convivendo na mesma tabela.

# COMMAND ----------

# MAGIC %md
# MAGIC # 1. Perfil do dado
# MAGIC
# MAGIC Antes de qualquer conclusão: o que existe aqui dentro? Esta seção não responde
# MAGIC pergunta de negocio — ela estabelece o que da e o que não da para perguntar.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,1.1 Tamanho e janela
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
# DBTITLE 1,1.2 Canais e receita
# MAGIC -- Os dois canais, que são o eixo mais importante desta base.
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
# MAGIC **A inversão que organiza o resto do notebook.** A revenda e 12,1% dos pedidos e a
# MAGIC maior parte da receita; o online e 87,9% dos pedidos e a menor parte. São dois
# MAGIC negocios com ticket de ordem de grandeza diferente convivendo na mesma tabela.
# MAGIC
# MAGIC Consequência prática: **qualquer média que misture os dois descreve um negocio que
# MAGIC não existe.** E a origem de metade dos avisos que aparecem adiante.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,1.3 Status constante
# MAGIC -- Colunas de valor único não discriminam nada. Esperado: status = 5 em 100%.
# MAGIC select
# MAGIC     salesorderheader.status
# MAGIC     , count(*) as pedidos
# MAGIC     , round(100.0 * count(*) / sum(count(*)) over (), 1) as pct
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC group by salesorderheader.status
# MAGIC order by pedidos desc

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,1.4 Nulos por coluna
# MAGIC -- Nulos nas colunas que a análise usa. Esperado: 27.659 sem vendedor (= online),
# MAGIC -- 1.131 sem cartão, e ZERO pedido sem território ou sem endereco.
# MAGIC select
# MAGIC     count(*) as pedidos
# MAGIC     , count(*) - count(salesorderheader.salespersonid) as sem_vendedor
# MAGIC     , count(*) - count(salesorderheader.creditcardid) as sem_cartao
# MAGIC     , count(*) - count(salesorderheader.territoryid) as sem_territorio
# MAGIC     , count(*) - count(salesorderheader.billtoaddressid) as sem_endereco
# MAGIC from workspace.adventure_works.salesorderheader

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,1.5 Unicidade das PKs
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
# DBTITLE 1,1.6 Produto sem subcat
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
# MAGIC A checagem anterior olhou o elo produto -> subcategoria. Esta olha o de cima,
# MAGIC subcategoria -> categoria, porque afirmar que "a hierarquia esta completa" sem
# MAGIC conferir os dois níveis e afirmar o que não se mediu.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,1.7 Subcat sem categoria
# MAGIC -- A hierarquia fecha de ponta a ponta? Tem de dar ZERO órfão nos dois níveis,
# MAGIC -- e 4 categorias com 37 subcategorias.
# MAGIC select
# MAGIC     count(distinct productcategory.productcategoryid) as categorias
# MAGIC     , count(distinct productsubcategory.productsubcategoryid) as subcategorias
# MAGIC     , sum(
# MAGIC         case when productcategory.productcategoryid is null then 1 else 0 end
# MAGIC     ) as subcategoria_sem_categoria
# MAGIC from workspace.adventure_works.productsubcategory
# MAGIC left join workspace.adventure_works.productcategory
# MAGIC     on productsubcategory.productcategoryid = productcategory.productcategoryid

# COMMAND ----------

# MAGIC %md
# MAGIC **O furo do cadastro coincide com o furo de venda.** 209 produtos sem subcategoria,
# MAGIC e nenhum deles vende. A hierarquia esta completa para 100% do que gera receita —
# MAGIC ou seja, a dimensão de produto da Etapa 3 pode usar categoria e subcategoria sem
# MAGIC balde "não classificado" no visual.
# MAGIC
# MAGIC Isso também antecipa `a.2`: os furos estão exatamente entre os produtos que nunca
# MAGIC venderam.

# COMMAND ----------

# MAGIC %md
# MAGIC # 2. Reconciliação — o número que o CEO cobra
# MAGIC
# MAGIC O briefing diz que o CEO acompanha **US$ 12.646.112,16** de receita bruta em 2011.
# MAGIC Se este número não fecha, nada depois vale. Ele vem primeiro por isso.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,2.1 Aceite do CEO
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
# MAGIC **Fecha ao centavo, e a definição importa mais que o número.**
# MAGIC
# MAGIC São `unitprice * orderqty` — receita **bruta**, antes do desconto — e não o
# MAGIC `subtotal` do pedido. Testei `sum(subtotal)` primeiro e da `12.641.672,21`, errado
# MAGIC por exatamente o valor dos descontos de 2011. Também não ha filtro de status: os
# MAGIC 1.607 pedidos de 2011 entram todos.
# MAGIC
# MAGIC Duas consequências que atravessam o resto do projeto:
# MAGIC
# MAGIC 1. `receita_bruta` deixa de ser métrica de apoio e passa a ser **métrica auditada**.
# MAGIC    Vai para o modelo com esse nome e essa definição, e ganha teste no dbt.
# MAGIC 2. A quarta casa decimal e o que justifica `decimal(19, 4)` no lugar de `double`:
# MAGIC    2.832 dos 5.642 itens de 2011 tem 4 casas no preço unitario.
# MAGIC
# MAGIC ⚠️ **Não use 2011 como retrato do negocio.** São 1.607 pedidos dos 31.465, num ano
# MAGIC dominado por revenda. 2011 e o ano do **teste**, não da análise.

# COMMAND ----------

# MAGIC %md
# MAGIC # 3. Pergunta (a) — pedidos, quantidade e valor por nove dimensões
# MAGIC
# MAGIC > *Qual o número de pedidos, a quantidade comprada e o valor total da transação por
# MAGIC > produto, tipo de cartão, motivo da venda, data da venda, cliente, status, cidade,
# MAGIC > estado e pais?*
# MAGIC
# MAGIC A mais larga do briefing: 3 métricas x 9 cortes. Literalmente, a tabela fato inteira
# MAGIC com todas as dimensões plugadas.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,3.1 Métricas por país
# MAGIC -- As 3 métricas pelos 9 cortes, no exemplo do corte por pais.
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
# MAGIC O briefing manda entregar os nove. Entregar sem dizer que alguns não informam nada
# MAGIC repete o erro do CRM que decepcionou a Silvana: tela cheia de cortes, nenhum
# MAGIC acionavel.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,3.2 Cartão discrimina?
# MAGIC -- Tipo de cartão discrimina? Esperado: não — quatro fatias de ~24% e 3,6% sem cartão.
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
# DBTITLE 1,3.3 Cartão e proxy?
# MAGIC -- Cartão serve de proxy de canal? Testei essa hipotese e ela e FALSA.
# MAGIC -- Esperado: dos 1.131 sem cartão, 1.124 são online e só 7 de revenda.
# MAGIC select
# MAGIC     case when salesorderheader.onlineorderflag then 'online' else 'revenda' end as canal
# MAGIC     , count(*) as pedidos_sem_cartao
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC where salesorderheader.creditcardid is null
# MAGIC group by case when salesorderheader.onlineorderflag then 'online' else 'revenda' end
# MAGIC order by pedidos_sem_cartao desc

# COMMAND ----------

# MAGIC %md
# MAGIC **Dois dos nove cortes não discriminam.** `status` e constante (5 em 100% dos
# MAGIC 31.465 pedidos) e `tipo de cartão` e praticamente uniforme (~24% em cada uma das
# MAGIC quatro bandeiras). Ambos entram no dashboard como **filtro documentado**, não como
# MAGIC visual de destaque — dizer qual corte não informa e barato e evita telas inuteis.
# MAGIC
# MAGIC E a hipotese que eu tinha de que "pedido sem cartão = revenda" **e falsa**: dos
# MAGIC 1.131 sem cartão, 1.124 são online. Canal se le em `onlineorderflag`, e ponto.

# COMMAND ----------

# MAGIC %md
# MAGIC ## a.2 — Quanto do catálogo nunca vendeu?
# MAGIC
# MAGIC O complemento do corte por produto: não o que vendeu, mas o que **nunca** vendeu.
# MAGIC Nenhuma das seis pergunta isso, porque todas perguntam sobre o que vendeu.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,3.4 Catálogo sem venda
# MAGIC -- Quanto do catálogo nunca vendeu? Esperado: 238 de 504 produtos (47%).
# MAGIC select
# MAGIC     count(*) as produtos_no_catalogo
# MAGIC     , count(distinct salesorderdetail.productid) as produtos_que_vendem
# MAGIC     , count(*) - count(distinct salesorderdetail.productid) as nunca_venderam
# MAGIC from workspace.adventure_works.product
# MAGIC left join workspace.adventure_works.salesorderdetail
# MAGIC     on product.productid = salesorderdetail.productid

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,3.5 Receita no topo
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
# MAGIC **238 dos 504 produtos (47%) nunca venderam.** Quase metade do catálogo custa
# MAGIC cadastro, estoque e atencao comercial sem devolver receita.
# MAGIC
# MAGIC Isso e a única economia desta análise que **não depende de vender mais nada** — e
# MAGIC por isso e o achado mais acionavel para a Silvana, que precisa de resultado
# MAGIC comercial imediato.

# COMMAND ----------

# MAGIC %md
# MAGIC ## a.3 — O corte por motivo da venda cobre a empresa inteira?
# MAGIC
# MAGIC Que fracao do negocio o corte por motivo realmente descreve.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,3.6 Motivo por canal
# MAGIC -- Motivo de venda existe nos dois canais? Esperado: NÃO — revenda tem zero motivo.
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
# DBTITLE 1,3.7 Motivos por pedido
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
# MAGIC **O corte por motivo descreve só o varejo online.** A revenda tem **zero** pedidos
# MAGIC com motivo — e a revenda e a maior parte da receita. Somando os dois canais,
# MAGIC **8.453 pedidos (26,9%) não tem motivo nenhum** e **4.482 tem mais de um**.
# MAGIC
# MAGIC Duas decisões saem daqui, e as duas são para não mentir no dashboard:
# MAGIC
# MAGIC 1. O visual de motivo leva **rotulo explícito de escopo** ("apenas vendas online").
# MAGIC    Sem isso, o gráfico parece descrever a Adventure Works e descreve um quarto dela.
# MAGIC 2. Existe o balde **"sem motivo informado"**, em vez de um `inner join` que apagaria
# MAGIC    26,9% da base em silêncio.
# MAGIC
# MAGIC E o 4.482 e a evidência de que `SalesReason` e **muitos-para-muitos**: receita por
# MAGIC motivo **não soma** ao total. E a decisão de modelagem aberta da Etapa 3
# MAGIC (bridge table ou não), documentada na Etapa 1 — ver o link na abertura.

# COMMAND ----------

# MAGIC %md
# MAGIC # 4. Pergunta (b) — produtos com maior ticket médio, por tempo e geografia
# MAGIC
# MAGIC > *Quais produtos tem o maior valor médio por pedido, por mês, ano, cidade, estado e
# MAGIC > pais? (valor médio por pedido = receita bruta − descontos de produto / número de
# MAGIC > pedidos no periodo analisado)*
# MAGIC
# MAGIC A formula do briefing subtrai desconto, entao o numerador e `linetotal` — receita
# MAGIC **liquida**. Não e `unitprice * orderqty`.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,4.1 Ticket por produto
# MAGIC -- Ticket médio por produto, na definição exata do briefing.
# MAGIC -- Denominador = pedidos DISTINTOS, não linhas de item.
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
# MAGIC O `having pedidos >= 30` não esta no briefing e e uma escolha minha: sem corte de
# MAGIC volume, o topo do ranking vira produto que vendeu duas vezes com ticket altissimo.
# MAGIC Isso responde a letra da pergunta e engana quem le. O corte fica **declarado no
# MAGIC dashboard**, como filtro visível, não escondido na consulta.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.1 — O desconto que a formula subtrai existe de fato, e onde?
# MAGIC
# MAGIC A formula do briefing subtrai desconto. Vale conferir se ha desconto para subtrair.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,4.2 Desconto e material?
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
# DBTITLE 1,4.3 Onde ha desconto
# MAGIC -- Onde o desconto acontece? Esperado: só na revenda — toda oferta e do tipo Reseller.
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
# MAGIC **O desconto e 0,478% da receita bruta** — e existe **só na revenda**. No online,
# MAGIC nenhum item tem desconto.
# MAGIC
# MAGIC Por que isso importa apesar de ser pequeno: a formula do briefing manda subtrair, e
# MAGIC nos subtraimos. Mas a diferença entre "receita bruta" e "receita liquida" e menor
# MAGIC que o arredondamento de qualquer decisão comercial — **exceto** no número do CEO,
# MAGIC onde a definição errada da 12.641.672,21 em vez de 12.646.112,16.
# MAGIC
# MAGIC Ou seja: desconto e irrelevante para o negocio e decisivo para a auditoria.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.2 — O ticket médio varia por praca?
# MAGIC
# MAGIC A pergunta (b) pede o corte geografico. Ele informa algo, ou os paises se parecem?

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,4.4 Ticket por país
# MAGIC -- Ticket médio por pais. Esperado: varia 3,4x — AU ~1.557 ate US ~5.232.
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
# MAGIC **O ticket médio varia 3,4x entre paises**, de ~1.557 na Australia a ~5.232 nos
# MAGIC Estados Unidos. O corte geografico **informa**, diferente de `status` e tipo de
# MAGIC cartão.
# MAGIC
# MAGIC ⚠️ **Mas cuidado com a leitura.** Boa parte dessa variacao e **mistura de canal**,
# MAGIC não diferença de mercado: paises com mais revenda tem ticket maior por construcao.
# MAGIC O gráfico honesto desse corte e **facetado por canal** — a versão simples sugere
# MAGIC que americano compra 3x mais que australiano, o que não e o que o dado diz.

# COMMAND ----------

# MAGIC %md
# MAGIC ## b.3 — Que natureza de desconto a empresa usa?
# MAGIC
# MAGIC Volume, liquidacao ou promocao de produto? A resposta muda a alavanca comercial.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,4.5 Tipo de oferta
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
# MAGIC com revendedor, tipicamente por volume. Não existe liquidacao nem promocao de
# MAGIC produto ao consumidor final.
# MAGIC
# MAGIC Isso responde de forma inesperada a expectativa da Silvana: a empresa **não** usa
# MAGIC promocao ao consumidor como alavanca. O que ela chama de "verba em promocao" não
# MAGIC existe no dado — a alavanca de desconto e comercial B2B.

# COMMAND ----------

# MAGIC %md
# MAGIC # 5. Pergunta (c) — os 10 principais clientes por valor
# MAGIC
# MAGIC > *Quais os 10 principais clientes por valor total de transação?*

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,5.1 Top 10 clientes
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
# DBTITLE 1,5.2 Concentração no topo
# MAGIC -- Concentração no topo. Esperado: top 10 = 7,2% da receita. Baixa dependencia.
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
# MAGIC **Os 10 maiores respondem por 7,2% da receita.** Não ha dependencia perigosa de
# MAGIC cliente — perder o maior deles não ameaca a empresa.
# MAGIC
# MAGIC Isso e uma **não-noticia valiosa**: o briefing pede o ranking, e o ranking sozinho
# MAGIC sugere que aqueles dez nomes são a empresa. Não são. Dizer o peso junto do ranking e
# MAGIC o que impede uma decisão errada de atendimento prioritario.

# COMMAND ----------

# MAGIC %md
# MAGIC ## c.2 — Os clientes voltam a comprar?
# MAGIC
# MAGIC O corte por cliente da pergunta (a) e o ranking da (c) tratam o cliente como
# MAGIC estatico. Ele volta?

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,5.3 Recompra por canal
# MAGIC -- Recompra por canal. Esperado: 39,1% no geral, mas o número e MUITO diferente
# MAGIC -- entre online e revenda — e a média dos dois não descreve nenhum.
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
# MAGIC **39,1% dos clientes compraram mais de uma vez** — e o número muda radicalmente por
# MAGIC canal. Revendedor recompra quase sempre (e uma relação continua); consumidor online,
# MAGIC muito menos.
# MAGIC
# MAGIC A métrica de retencao, portanto, **só faz sentido separada por canal**. Um número
# MAGIC único de "39% de recompra" descreve um cliente médio que não existe.

# COMMAND ----------

# MAGIC %md
# MAGIC # 6. Pergunta (d) — as 5 principais cidades por valor
# MAGIC
# MAGIC > *Quais as 5 principais cidades por valor total de transação?*

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,6.1 Top 5 cidades
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
# DBTITLE 1,6.2 Concentração geog.
# MAGIC -- Concentração geografica. Esperado: top 5 cidades = 11,0% da receita,
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
# MAGIC **As 5 maiores cidades são 11,0% da receita**, distribuida entre 558 cidades que
# MAGIC vendem (de 613 cadastradas). A receita e **pulverizada**, não concentrada.
# MAGIC
# MAGIC Registro de um erro meu na Etapa 1, porque ele ilustra o risco desta pergunta: eu
# MAGIC calculei 39,7% ao ler a coluna errada do endereco (`addressline2` em vez de `city`).
# MAGIC Com 39,7% a conclusão seria "concentre esforco em cinco pracas". Com 11,0% e o
# MAGIC oposto: **não existe praca que mova o ponteiro** — estratégia por cidade e
# MAGIC desperdicio, e o corte relevante e pais ou território.
# MAGIC
# MAGIC Uma coluna errada inverteu a recomendacao, e ninguém teria notado pelo formato do
# MAGIC resultado. E por isso que as conferências da ingestão existem, e por isso que
# MAGIC este notebook abre com perfil e reconciliação antes de qualquer conclusão.

# COMMAND ----------

# MAGIC %md
# MAGIC ### O corte que sobra quando cidade não serve
# MAGIC
# MAGIC Se as cinco maiores cidades são 11% e a receita esta espalhada por 558 delas, o
# MAGIC corte geografico útil não e cidade. O `salesterritory` e a alternativa que a base
# MAGIC oferece, e ele agrupa por regiao comercial em vez de por municipio.
# MAGIC
# MAGIC Isto não esta nas seis perguntas — entra porque a conclusão de `d.1` recomenda o
# MAGIC corte por território, e recomendar sem mostrar seria pedir confiança no lugar de
# MAGIC evidência.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,6.3 Por território
# MAGIC -- Receita por território comercial, o corte que a conclusão de d.1 recomenda.
# MAGIC -- São 10 territorios contra 558 cidades: cada linha aqui move o ponteiro.
# MAGIC select
# MAGIC     salesterritory.name as territorio
# MAGIC     , salesterritory.countryregioncode as pais
# MAGIC     , count(distinct salesorderheader.salesorderid) as pedidos
# MAGIC     , round(sum(salesorderdetail.linetotal), 2) as receita_liquida
# MAGIC     , round(
# MAGIC         100.0 * sum(salesorderdetail.linetotal)
# MAGIC         / sum(sum(salesorderdetail.linetotal)) over ()
# MAGIC         , 1
# MAGIC     ) as pct_da_receita
# MAGIC from workspace.adventure_works.salesorderheader
# MAGIC inner join workspace.adventure_works.salesorderdetail
# MAGIC     on salesorderheader.salesorderid = salesorderdetail.salesorderid
# MAGIC inner join workspace.adventure_works.salesterritory
# MAGIC     on salesorderheader.territoryid = salesterritory.territoryid
# MAGIC group by
# MAGIC     salesterritory.name
# MAGIC     , salesterritory.countryregioncode
# MAGIC order by receita_liquida desc

# COMMAND ----------

# MAGIC %md
# MAGIC ## d.2 — A top 5 de valor e a mesma de volume?
# MAGIC
# MAGIC Se as duas listas divergem, ha cidade de ticket alto e cidade de giro alto — e
# MAGIC isso muda o tipo de ação.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,6.4 Valor x volume
# MAGIC -- Valor x volume por cidade. Divergencia entre as duas posições revela
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
# MAGIC # 7. Pergunta (e) — pedidos, quantidade e valor por mês e ano
# MAGIC
# MAGIC > *Qual o número de pedidos, a quantidade comprada e o valor total da transação por
# MAGIC > mês e ano?*

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,7.1 Série mensal
# MAGIC -- A série mensal completa, com o canal separado — porque o comportamento
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
# MAGIC ## e.1 — A série tem quebra estrutural?
# MAGIC
# MAGIC Uma série com quebra não pode ser lida como tendência. Se houver, todo gráfico de
# MAGIC crescimento precisa de anotacao.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,7.2 Quebra de jul/2013
# MAGIC -- Quebra estrutural no online. Esperado: salto de 533 para 1.564 pedidos
# MAGIC -- entre jun e jul/2013 — quase 3x em um mês.
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
# MAGIC — quase 3x em um mês, e o patamar não volta.
# MAGIC
# MAGIC Isso não e crescimento orgânico; e mudança de regime — entrada em novos mercados,
# MAGIC campanha ou mudança de canal. O dado não diz qual, e **essa e uma pergunta para o
# MAGIC negocio**, não para a análise.
# MAGIC
# MAGIC Consequência para o dashboard: qualquer visual de tendência precisa de **anotacao em
# MAGIC jul/2013**. Sem ela, uma média de "crescimento mensal" mistura dois regimes e não
# MAGIC descreve nenhum dos dois.

# COMMAND ----------

# MAGIC %md
# MAGIC ## e.2 — A oscilacao mensal e de volume ou de valor?
# MAGIC
# MAGIC E a revenda tem ritmo mensal próprio?

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,7.3 Ritmo da revenda
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
# MAGIC > *Qual produto teve o maior número de unidades vendidas quando o motivo da venda
# MAGIC > foi "Promocao"?*

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,8.1 Motivos existentes
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
# DBTITLE 1,8.2 Unidades em promo
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
# MAGIC A pergunta (f) e a mais estreita das seis, e a resposta vem com um porém: como o
# MAGIC motivo existe **só no online** (`a.3`), ela descreve o varejo, não a empresa.
# MAGIC
# MAGIC O rotulo "Promotion" e **categoria** (`reasontype`), não nome de motivo — por isso o
# MAGIC filtro e `reasontype = 'Promotion'`. Usar `name` daria resposta diferente e errada.

# COMMAND ----------

# MAGIC %md
# MAGIC ## f.2 — Promocao aumenta o pedido? — controlando por canal
# MAGIC
# MAGIC A pergunta natural depois da (f). E onde eu errei primeiro, entao a consulta abaixo
# MAGIC já nasce com o controle.

# COMMAND ----------

# MAGIC %sql
# DBTITLE 1,8.3 Promo x pedido
# MAGIC -- Promocao aumenta o tamanho do pedido? Comparacao SÓ DENTRO DO ONLINE.
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
# MAGIC motivos.** Promocao esta associada a pedido **menor**, não maior.
# MAGIC
# MAGIC ⚠️ E aqui esta o erro que eu cometi antes e que este bloco existe para não repetir:
# MAGIC na primeira tentativa eu comparei "com promocao" contra "todo o resto" e achei 2,10
# MAGIC contra 9,57. Parecia que promocao destruia o pedido. **Era confusao de canal**: o
# MAGIC "resto" incluia a revenda, que compra por atacado e não tem motivo nenhum. Eu estava
# MAGIC comparando varejo com atacado e chamando de efeito de promocao.
# MAGIC
# MAGIC A comparacao honesta e dentro do mesmo canal, e ai o efeito e pequeno.
# MAGIC
# MAGIC **E associacao, não causa.** O dado não diz se a promocao encolheu o pedido ou se
# MAGIC pedido pequeno atrai promocao. Para a Silvana, a leitura útil e negativa: **não ha
# MAGIC evidência de que promocao aumente o pedido nesta base** — e não existe promocao ao
# MAGIC consumidor no dado de desconto (`b.3`).

# COMMAND ----------

# MAGIC %md
# MAGIC # 9. Gráficos
# MAGIC
# MAGIC Dois grupos, com propositos diferentes.
# MAGIC
# MAGIC **Os cinco primeiros existem porque a tabela não mostra o que o gráfico mostra:** a
# MAGIC quebra estrutural da série, a uniformidade que desqualifica um corte, a cauda longa
# MAGIC do catálogo, a confusao entre canal e mercado, e a comparacao que só vale dentro do
# MAGIC mesmo canal. Servem aos aprofundamentos `e.1`, `a.1`, `a.2`, `b.2` e `f.2`.
# MAGIC
# MAGIC **Os quatro últimos respondem visualmente as perguntas (b), (c), (d) e (f)**, que são
# MAGIC rankings — e ranking se le melhor em barra que em tabela.
# MAGIC
# MAGIC Com os nove, cada uma das seis perguntas do briefing tem ao menos um visual: a (a)
# MAGIC pelo tipo de cartão e pelo Pareto, a (e) pela série mensal, e as outras quatro no
# MAGIC segundo grupo.
# MAGIC
# MAGIC Os quatro últimos são também o rascunho do dashboard da Etapa 7 — mesmo corte, mesmo
# MAGIC aviso de escopo.

# COMMAND ----------

# DBTITLE 1,9.1 Série e quebra
import matplotlib.pyplot as plt
import pandas as pd

# A série mensal por canal, com a quebra de jul/2013 anotada. Sem a anotacao,
# o gráfico sugere crescimento continuo — e são dois regimes diferentes.
#
# Duas armadilhas de eixo, e as duas dao o MESMO erro (ConversionError):
#
#   1. a quebra tem de ser um Timestamp, não o texto "2013-07-01": o eixo x vem
#      de date_trunc, que o toPandas converte para datetime64, e o matplotlib
#      recusa texto num eixo de data
#   2. divisao no Spark devolve `decimal`, e o toPandas traz isso como objeto
#      Decimal do Python, que o matplotlib também recusa. Por isso os gráficos
#      com média e percentual convertem para `double` no próprio SQL. Precisão
#      de centavo não importa para desenhar — importa para o teste de aceite,
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
    ax.plot(grupo["mês"], grupo["pedidos"], marker="o", markersize=3, label=canal)

ax.axvline(QUEBRA, color="crimson", linestyle="--", linewidth=1)
ax.annotate(
    "jul/2013: 533 → 1.564 pedidos online\nquebra estrutural, não tendência",
    xy=(QUEBRA, 1564), xytext=(-260, -30), textcoords="offset points",
    color="crimson", fontsize=9,
    arrowprops=dict(arrowstyle="->", color="crimson", linewidth=1),
)
ax.set_title("Pedidos por mês e canal — a quebra de jul/2013")
ax.set_ylabel("pedidos")
ax.legend()
ax.grid(alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.2 Tipo de cartão
# Tipo de cartão: quatro fatias iguais. O gráfico existe para JUSTIFICAR uma
# ausência no dashboard — e a prova visual de que o corte não discrimina.
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
ax.set_title("Pedidos por tipo de cartão — quatro fatias iguais, corte que não informa")
ax.set_xlabel("pedidos")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.3 Pareto de produtos
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
ax.plot(pareto["posição"], pareto["pct_acumulado"], color="darkorange", linewidth=2)
ax.axhline(80, color="gray", linestyle=":", linewidth=1)
ax.set_title("Pareto: 266 produtos vendem, 238 do catálogo nunca venderam")
ax.set_xlabel("produtos, do maior para o menor")
ax.set_ylabel("% acumulado da receita")
ax.grid(alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.4 Ticket por país
# Ticket médio por pais, FACETADO POR CANAL. A versão sem faceta sugere que
# americano compra 3x mais que australiano; a diferença e mistura de canal.
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
ax.set_title("Ticket médio por pais e canal — a variacao e de canal, não de mercado")
ax.set_ylabel("ticket médio")
ax.set_xlabel("")
plt.xticks(rotation=30, ha="right")
ax.grid(axis="y", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.5 Promo no online
# Promocao vs outro motivo, SÓ DENTRO DO ONLINE. E o gráfico que impede a
# leitura errada: sem o recorte de canal, a diferença aparece como 2,10 x 9,57.
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
ax.set_title("Itens por pedido, apenas ONLINE — promocao não aumenta o pedido")
ax.set_ylabel("itens por pedido")
ax.grid(axis="y", alpha=0.3)
for i, v in enumerate(promo["itens_por_pedido"]):
    ax.text(i, v, f"{v:.2f}", ha="center", va="bottom")
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.6 (b) Ticket produto
# Pergunta (b): produtos com maior ticket médio. O corte de 30 pedidos esta no
# TITULO do gráfico, e não escondido na consulta — sem ele o topo do ranking vira
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
ax.set_title("(b) Maior ticket médio por produto — só produtos com 30+ pedidos")
ax.set_xlabel("ticket médio (receita liquida / pedidos)")
ax.grid(axis="x", alpha=0.3)
plt.tight_layout()
plt.show()

# COMMAND ----------

# DBTITLE 1,9.7 (c) Top 10 clientes
# Pergunta (c): os 10 maiores clientes. O titulo carrega o peso deles no total,
# porque o ranking sozinho sugere que aqueles dez nomes são a empresa — e não são.
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

# DBTITLE 1,9.8 (d) Cidades x resto
# Pergunta (d): as 5 maiores cidades, com o resto ao lado. A barra do "outras" e
# o ponto do gráfico: sem ela, cinco barras grandes sugerem concentração onde não
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

# DBTITLE 1,9.9 (f) Promo unidades
# Pergunta (f): unidades vendidas quando o motivo e Promotion. O rotulo de escopo
# no titulo não e enfeite — motivo de venda existe SÓ no online, entao este
# gráfico descreve o varejo e não a empresa.
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

# MAGIC %md
# MAGIC # 10. Síntese — o que a exploração mudou no entendimento
# MAGIC
# MAGIC O briefing pede explicitamente esta seção: como os insights ajudaram a entender o
# MAGIC dataset.
# MAGIC
# MAGIC **1. Não e um negocio, são dois.** Revenda e 12,1% dos pedidos e a maior parte da
# MAGIC receita; online e 87,9% dos pedidos e a menor parte. Isso não estava no briefing e
# MAGIC reorganizou tudo: toda métrica agregada que mistura os dois descreve um negocio
# MAGIC inexistente. Foi o achado com mais consequência.
# MAGIC
# MAGIC **2. Dois dos nove cortes da pergunta (a) não informam nada.** `status` e constante,
# MAGIC tipo de cartão e uniforme. Entregar os nove sem dizer isso repetiria o erro do CRM
# MAGIC que decepcionou a Silvana.
# MAGIC
# MAGIC **3. A receita e pulverizada, não concentrada.** Top 10 clientes = 7,2%; top 5
# MAGIC cidades = 11,0%. Duas perguntas do briefing pedem ranking, e o ranking sozinho
# MAGIC sugere o contrario. Aqui um erro meu de leitura de coluna chegou a inverter a
# MAGIC recomendacao — 39,7% viraria "concentre em cinco pracas".
# MAGIC
# MAGIC **4. A série tem quebra estrutural em jul/2013**, com o online triplicando em um mês.
# MAGIC Nenhuma leitura de tendência funciona sem essa anotacao.
# MAGIC
# MAGIC **5. Promocao não aumenta o pedido, e desconto ao consumidor não existe.** Toda
# MAGIC oferta e `Reseller`. A expectativa da Silvana sobre verba de promocao não encontra
# MAGIC apoio no dado.
# MAGIC
# MAGIC **6. Metade do catálogo não vende.** 238 de 504 produtos. E a única economia que
# MAGIC não depende de vender mais nada.
# MAGIC
# MAGIC ## O que fica para a Etapa 3
# MAGIC
# MAGIC A exploração **não** decide modelagem, mas evidenciou duas decisões:
# MAGIC
# MAGIC - **`SalesReason` e muitos-para-muitos** — 4.482 pedidos com mais de um motivo.
# MAGIC   Bridge table ou um motivo por pedido? A escolha muda a definição de um indicador
# MAGIC   já entregue ("receita por motivo de venda — não soma ao total").
# MAGIC - **O grao da tabela fato** — item de pedido, dado que a pergunta (f) precisa de
# MAGIC   unidade por produto.
# MAGIC
# MAGIC As duas estão registradas no documento da Etapa 1, marcadas como decisão conjunta,
# MAGIC e o link esta na abertura deste notebook.
