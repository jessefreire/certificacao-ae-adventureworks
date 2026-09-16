# Etapa 1 — KPIs e perguntas de negócio

**Projeto:** Plataforma de dados Adventure Works — área comercial
**Etapa:** 1 de 10 — *"Research and definition of KPIs and business questions relevant to
Adventure Works' business context. You must propose which indicators should be tracked on
the dashboard and provide a justification."*
**Status:** Etapa 1 completa — perguntas de negócio (§2), indicadores definidos e
propostos (§3) e justificativa em cada um
**Fonte dos dados:** [`dpavancini/analytics-engineering`](https://github.com/dpavancini/analytics-engineering/tree/main/AdventureWorks)
(via fork `jessefreireufc`, commit `1f77a1c` — fork e upstream no mesmo commit, nada defasado)

> Os blocos marcados **DECISÃO CONJUNTA**, no **Anexo B**, **não são escopo desta etapa** — são
> modelagem, ou seja Etapa 3. Estão aqui porque a apuração da Etapa 1 obrigou a enxergá-los,
> e registrar cedo custa barato. Não travam a entrega da Etapa 1.

> ✅ **Os números deste documento foram apurados nos CSVs do repositório oficial**, não
> estimados. O `install.sql` e os 72 TSV da pasta `data/` são a mesma fonte que vai virar o
> DW, então qualquer número aqui é o número que o dbt tem de reproduzir. Isso resolveu duas
> das quatro questões abertas e derrubou uma hipótese minha — ver Anexo B.4.

---

## 1. Quem decide, quem paga e quem atrapalha

O briefing não descreve só uma empresa — descreve um **conflito**. Ele pede explicitamente
*"articular a importância de uma cultura data-driven, tendo em mente que a Diretora
Comercial desconhece o potencial do dado para melhorar a performance"* — ignorar isso é
perder a narrativa que o próprio briefing pede.

| Pessoa | Papel | O que quer | O que nos exige |
|---|---|---|---|
| **João Muller** | Diretor de Inovação | concebeu e patrocina o projeto | resultado rápido e visível, senão perde o patrocínio |
| **Carlos Silveira** | CEO | dado **auditável** — citou vendas brutas de 2011 = **US$ 12.646.112,16** | reconciliar com a auditoria contábil e provar com teste |
| **Silvana Teixeira** | Diretora Comercial | verba em promoção, não em dado. Já ouviu promessa de "data-driven" do CRM e do Web Analytics, e não veio nada | é a **dona da área** do projeto e é contra ele |
| **Nilson Ramos** | Diretor de TI | garantir acesso aos dados | — |
| **Gabriel Santos** | Analista de dados | agenda apertada; hoje responde perguntas ad-hoc em SQL | pedidos agrupados e poucos, não um gotejar de dúvidas |

Duas leituras que valem para todo o resto do projeto:

**A Silvana não é um obstáculo, é o público.** Ela é a única pessoa do briefing que já foi
decepcionada por uma promessa de dados. Um dashboard que a convença convence qualquer
avaliador.

**O pedido do Carlos é a resposta ao ceticismo da Silvana.** Ele pede que o número feche
com a auditoria. Ela desconfia porque *as promessas anteriores nunca provaram o número*.
São dois parágrafos separados do briefing, e ligá-los é a espinha dorsal da apresentação
final: o que muda agora não é a ferramenta, é que o número passa a ser **verificável**.

**O Gabriel é o gargalo declarado.** Consequência prática: fazer **uma** lista consolidada
de tudo que precisamos do banco (Anexo C), em vez de voltar nele cinco vezes.

---

## 2. As seis perguntas do briefing e seus aprofundamentos

O briefing lista seis perguntas que o dashboard **tem** de responder. Elas são o piso, e a
Etapa 1 pede indicadores propostos por nós além delas. A escolha de método aqui é
deliberada: em vez de inventar temas novos, **cada pergunta nossa nasce de uma das seis**. O
código diz de onde ela vem — `a.1` aprofunda a pergunta (a), `f.2` aprofunda a (f).

São **14 aprofundamentos**, distribuídos por onde a veia é mais rica: 3 em (a), 3 em (b), 2
em cada uma das outras. Cada um passou por dois filtros:

1. **Nasce de uma das seis.** Se não nasce, não entra — por rigoroso que fosse o tema.
2. **O dado responde, e o quebra discrimina.** Se as duas respostas possíveis levam à mesma
   ação, ou se o quebra devolve um único valor, a pergunta não presta.

> **As evidências abaixo foram apuradas nos CSVs da base oficial.** Elas estão aqui para
> provar que o dado sustenta a pergunta e que o quebra informa algo — não como análise. A
> análise completa, com gráficos e comentário por insight, é a **Etapa 2**.

> ⚠️ **Um eixo que atravessa tudo: o canal.** A Adventure Works é duas empresas na mesma
> base — **27.659 pedidos online** (varejo, 1 a 2 itens por pedido) e **3.806 de revenda**
> (56 itens por pedido, ticket 21.148). O canal não está entre as dimensões que o briefing
> pede, e por isso **não virou pergunta**: virou **variável de controle**. Sem separar canal,
> três dos aprofundamentos abaixo dariam a resposta errada — ver b.1, e.2 e f.2.

---

### 2.1 Pergunta (a) — pedidos, quantidade e valor por nove dimensões

> *Qual o número de pedidos, a quantidade comprada e o valor total da transação por produto,
> tipo de cartão, motivo da venda, data da venda, cliente, status, cidade, estado e país?*

É a pergunta mais larga do briefing: 3 métricas × 9 quebras. O que ela literalmente pede é a
tabela fato inteira com todas as dimensões plugadas.

#### a.1 — Quais dos nove quebras de fato discriminam?

| | |
|---|---|
| **O que responde** | Se cada um dos nove quebras separa a receita em grupos diferentes, ou se devolve grupos iguais. |
| **Evidência** | **Dois dos nove não discriminam.** `status` é constante: 100% dos 31.465 pedidos estão em `5` (Shipped), zero exceções. `tipo de cartão` é praticamente uniforme: ColonialVoice 24,4%, SuperiorCard 24,3%, Distinguish 24,1%, Vista 23,6%, sem cartão 3,6%. |
| **Por que existe** | O briefing manda entregar os nove. Entregar sem dizer que dois não informam nada é o mesmo erro do CRM que decepcionou a Silvana: uma tela cheia de quebras, nenhum acionável. Dizer qual quebra não discrimina é o oposto — e é barato. |
| **Decide** | Onde gastar espaço de tela e atenção. `status` e `tipo de cartão` entram como filtro documentado, não como visual de destaque. |

> Tentei ancorar o canal em `tipo de cartão`, apostando que pedido sem cartão fosse revenda.
> **Não é:** dos 1.131 pedidos sem cartão, 1.124 são online e apenas 7 de revenda. O tipo de
> cartão não é proxy de canal nesta base.

#### a.2 — Quanto do catálogo nunca vendeu?

| | |
|---|---|
| **O que responde** | O complemento do quebra por produto: não o que vendeu, mas o que nunca vendeu. |
| **Evidência** | **238 dos 504 produtos (47%) nunca venderam.** Dos 266 que vendem, o top 10 concentra 28,2% da receita. |
| **Por que existe** | Quase metade do catálogo custa cadastro, estoque e atenção comercial sem devolver receita. Isso não aparece em nenhuma das seis, porque todas perguntam sobre o que vendeu. |
| **Decide** | Poda de portfólio — a única economia desta lista que não depende de vender mais nada. |

#### a.3 — O quebra por motivo da venda cobre a empresa inteira?

| | |
|---|---|
| **O que responde** | Que fração do negócio o quebra por motivo realmente descreve. |
| **Evidência** | **Não cobre.** Motivo de venda existe **só no online** — a revenda tem **zero** pedidos com motivo. Somando, 8.453 pedidos (26,9%) não têm motivo nenhum, e 4.482 têm mais de um. |
| **Por que existe** | Sem esse aviso, um gráfico de "receita por motivo" parece descrever a Adventure Works e descreve só o varejo online — de onde vem a menor parte da receita. É erro por omissão, do tipo que ninguém percebe. |
| **Decide** | Que o visual de motivo leve rótulo explícito de escopo, e que exista o balde "sem motivo informado" em vez de um `inner join` que apaga um quarto da base. |

---

### 2.2 Pergunta (b) — produtos com maior ticket médio, por tempo e geografia

> *Quais produtos têm o maior valor médio por pedido, por mês, ano, cidade, estado e país?
> (valor médio por pedido = receita bruta − descontos de produto / número de pedidos no
> período analisado)*

Esta é a mais rica das seis, e por um motivo específico: **a fórmula introduz dois conceitos
que nenhuma das outras cinco menciona** — receita bruta e desconto. É de lá que saem três
aprofundamentos.

#### b.1 — O desconto que a fórmula subtrai existe de fato, e onde?

| | |
|---|---|
| **O que responde** | Se o desconto é uma alavanca real na Adventure Works, e em que parte do negócio ele vive. |
| **Evidência** | Desconto aparece em **3.282 de 121.317 linhas (2,7%)** e soma **0,478% da receita bruta**. E o achado que importa: **todas as ofertas especiais são de categoria `Reseller`** — não existe oferta configurada para o varejo online. |
| **Por que existe** | A Silvana defende verba em promoção. O dado dela diz que o desconto hoje é instrumento de **revenda**, e que no varejo online — que é 88% dos pedidos — praticamente não existe. Ou há alavanca ociosa, ou o instrumento não é esse. Nos dois casos a conversa muda, e muda com o número dela. |
| **Decide** | Se a política de desconto se estende ao varejo, e com que expectativa. |

#### b.2 — O ticket médio varia por praça?

| | |
|---|---|
| **O que responde** | Se o "por cidade, estado e país" da pergunta (b) revela diferença real de comportamento. |
| **Evidência** | Varia **3,4x** entre países: Austrália 1.557 · Alemanha 1.874 · Reino Unido 2.383 · França 2.714 · Canadá 4.022 · **EUA 5.232**. No extremo por cidade, Toronto tem ticket de **25.344**. |
| **Por que existe** | Preço e mix únicos, com essa dispersão, são dinheiro deixado na mesa em algumas praças e venda perdida em outras. |
| **Decide** | Política de preço e de mix por região. |

#### b.3 — Que natureza de desconto a empresa usa: volume, liquidação ou promoção de produto?

| | |
|---|---|
| **O que responde** | A composição do desconto — não quanto, mas de que tipo. |
| **Evidência** | `Volume Discount 11 to 14` (3.428 linhas) · `Volume Discount 15 to 24` (606) · `Touring-3000 Promotion` (524) · `Touring-1000 Promotion` (244) · `Mountain-500 Silver Clearance Sale` (169) · `Mountain-100 Clearance Sale` (137). |
| **Por que existe** | Desconto por volume **compra escala**; liquidação **limpa estoque**; promoção de produto **testa demanda**. São três decisões comerciais opostas escondidas atrás de um só número de "desconto". |
| **Decide** | Qual tipo de desconto ampliar e qual cortar. |

---

### 2.3 Pergunta (c) — os 10 principais clientes por valor

> *Quem são os 10 principais clientes por valor total de transação, filtrando por produto,
> tipo de cartão, motivo da venda, data da venda, status, cidade, estado e país?*

O enunciado pede um **ranking**. Um ranking responde "quem", e para decidir falta "quanto
disso importa".

#### c.1 — Quanto da receita depende dos 10 maiores?

| | |
|---|---|
| **O que responde** | Transforma a lista de nomes em medida de risco: a fatia que o topo representa. |
| **Evidência** | **Apenas 7,2%** da receita. São 19.119 clientes com compra, dos quais 635 são lojas e o restante pessoas físicas. |
| **Por que existe** | O top 10 sozinho sugere que existem clientes decisivos. A fatia diz que **não existem** — e essa resposta negativa é tão acionável quanto a positiva. |
| **Decide** | Que a prioridade comercial não é blindar grandes contas (não há dependência), e sim ganhar escala. Uma conclusão que o ranking pedido pelo briefing, sozinho, sugeriria ao contrário. |

#### c.2 — Os clientes voltam a comprar?

| | |
|---|---|
| **O que responde** | Se o valor de um cliente vem de uma compra grande ou de compras repetidas. |
| **Evidência** | **39,1% dos clientes têm mais de um pedido** (7.470 de 19.119). |
| **Por que existe** | Sem isso, "cliente de alto valor" e "cliente frequente" viram a mesma coisa na tela, e são alavancas diferentes: uma se puxa com atendimento, a outra com aquisição. |
| **Decide** | Priorizar retenção ou conquista. **Precisa de definição prévia:** `customer` mistura pessoa física e loja, e "recorrente" não significa o mesmo nos dois. |

---

### 2.4 Pergunta (d) — as 5 principais cidades por valor

> *Quais são as 5 principais cidades por valor total de transação, filtrando por produto,
> tipo de cartão, motivo da venda, data da venda, cliente, status, cidade, estado e país?*

#### d.1 — Quanto as cinco primeiras concentram?

| | |
|---|---|
| **O que responde** | Se faz sentido decidir por cidade. |
| **Evidência** | O top 5 concentra **apenas 11,0%** da receita, e há **558 cidades com venda** de 613 cadastradas. |
| **Por que existe** | A receita é **pulverizada**. Um plano construído sobre as cinco primeiras cidades endereça um nono do negócio. |
| **Decide** | Que a unidade útil de decisão geográfica é **país ou território**, não cidade — e que o top 5 do briefing é curiosidade, não estratégia. |

#### d.2 — A top 5 de valor é a mesma de volume?

| | |
|---|---|
| **O que responde** | Se "melhor cidade" quer dizer a mesma coisa medida em receita e em número de pedidos. |
| **Evidência** | **Só 2 de 5 coincidem.** Por valor: Toronto (176 pedidos, ticket 25.344), Londres, Paris, Seattle (134 pedidos, ticket 11.717), Burnaby. Por volume: Londres (756), Paris (575), Cliffside (414, ticket 511), Bellingham, Burien. |
| **Por que existe** | A divergência não é ruído — é o mapa de onde há **revenda** (poucos pedidos enormes, como Toronto e Seattle) contra onde há **varejo** (muitos pedidos pequenos, como Cliffside). O canal reaparece aqui sem ter sido convidado. |
| **Decide** | Se a expansão busca praça nova de varejo ou parceiro novo de revenda — decisões com times e custos diferentes. |

---

### 2.5 Pergunta (e) — pedidos, quantidade e valor por mês e ano

> *Qual o número de pedidos, a quantidade comprada e o valor total da transação por mês e
> ano? (dica: gráfico de série temporal)*

#### e.1 — A série tem quebra estrutural?

| | |
|---|---|
| **O que responde** | Se a série pode ser lida como uma coisa só ao longo do tempo. |
| **Evidência** | **Não.** O canal online salta de **533 pedidos em jun/2013 para 1.564 em jul/2013** e permanece nesse patamar. A janela vai de mai/2011 a jun/2014, com o primeiro e o último ano incompletos (jun/2014 tem 939 pedidos e receita quase nula). |
| **Por que existe** | Sem essa leitura, "crescemos 3x" é o gráfico dizendo que a empresa mudou de tamanho, não que a operação melhorou. E média mensal calculada sobre a janela inteira mistura duas empresas. |
| **Decide** | A janela de análise, e que o gráfico de série temporal **anote a quebra** em vez de suavizá-la. |

#### e.2 — A oscilação mensal é de volume ou de valor — e a revenda tem ritmo mensal?

| | |
|---|---|
| **O que responde** | Decompõe a variação da série: mais pedidos, ou pedidos maiores. |
| **Evidência** | Em **2012** a receita oscila **2,78x** entre o melhor e o pior mês, contra **1,78x** dos pedidos — a oscilação é de **ticket**. Em **2013** inverte: receita 2,43x contra pedidos 6,47x. E a revenda **não tem ritmo mensal**: zero pedidos em jun/2011, set/2011, nov/2011 e jun/2014; 2 pedidos em abr/2014; 271 em mar/2014. |
| **Por que existe** | A mesma variação percentual pede ações opostas. E meta mensal de revenda é ficção: o canal vende em lotes, não por mês. |
| **Decide** | Onde agir quando o mês vem ruim, e que a série temporal separe canal em vez de somar os dois. |

---

### 2.6 Pergunta (f) — produto com mais unidades no motivo "Promotion"

> *Qual produto tem o maior número de unidades compradas pelo motivo de venda "Promotion"?*

A mais estreita das seis — pede um nome. É também a que abre a pergunta mais política do
projeto.

#### f.1 — Qual é a resposta, e o que ela revela?

| | |
|---|---|
| **O que responde** | O nome pedido, e o padrão por trás dele. |
| **Evidência** | **Water Bottle - 30 oz.** com 546 unidades, seguida de Road Bottle Cage (416), AWC Logo Cap (301) e Mountain-200 Black 42 (299). Os três primeiros são **acessórios de baixo valor**, não bicicletas. |
| **Por que existe** | A resposta crua é um nome de produto. A leitura é que **promoção move acessório**, não o item de ticket alto — o que muda tanto o que se promove quanto o que se espera da promoção. |
| **Decide** | Se a promoção existe para girar acessório (e então é ferramenta de volume) ou para vender bicicleta (e então não está funcionando). |

#### f.2 — Promoção aumenta o pedido? — controlando por canal

| | |
|---|---|
| **O que responde** | Se pedido com motivo promocional é maior que pedido sem, comparando o comparável. |
| **Evidência (dentro do online)** | com promoção: **2,10 itens** e ticket **1.810** · outro motivo: 2,39 itens e ticket **824** · sem motivo: 1,38 itens e ticket 1.491. **O pedido promocional tem ticket 2,2x o de outro motivo, no mesmo canal.** |
| **Por que existe** | É a pergunta que testa a tese da Silvana com o dado dela. E é a que mais fácil se responde errado: a comparação ingênua — 2,10 itens com promoção contra 9,57 sem motivo — **compara online com revenda**, porque motivo de venda só existe no online e o pedido de revenda tem 56 itens. Eu mesmo cheguei a essa leitura errada antes de controlar o canal. |
| **Decide** | Manter, ampliar ou redirecionar a verba de promoção — com evidência, não com opinião. |

---

### 2.7 Transversal — a reconciliação com a contabilidade

Não aprofunda nenhuma das seis, e por isso não entra na contagem dos 14. É a **condição para
que qualquer uma delas valha**: o CEO pede que os números fechem com a auditoria, e a receita
bruta de 2011 tem de dar **US$ 12.646.112,16** — apurado como `sum(unitprice * orderqty)`
sobre `orderdate`, ver Anexo B.4.

É também a peça que responde ao ceticismo da Silvana. O CRM e o Web Analytics prometeram
visão; nenhum dos dois provou o número. O que muda agora não é a ferramenta — é que a
resposta passa a ser verificável, e o teste roda a cada carga.

---

## 3. Catálogo de indicadores

O briefing pede quatro coisas nesta etapa: **pesquisar e definir os KPIs**, definir as
**perguntas de negócio** (§2), **propor quais vão para o dashboard** (§3.1, com a regra de quebra em §3.2) e
**justificar**.
Esta seção cobre a primeira e a terceira.

Cada indicador é registrado com o conjunto de atributos que o referencial da Indicium AI exige
— *"nome, definição, fórmula de cálculo, fonte dos dados, periodicidade e responsável"*
(`2.7) Como definir indicadores da plataforma e acompanhá-los`, linha 226) — mais três que
faltam ali e que são o que liga o indicador ao modelo dimensional e à pergunta que o
originou: **grão**, **dimensões de quebra** e **responde**.

Sobre o campo **responsável**: são papéis do briefing, não pessoas reais. Quem responde por
um indicador é quem toma a decisão que ele destrava — não quem o calcula.

---

### 3.1 Os nove que vão para o dashboard

#### 1. Receita bruta

| | |
|---|---|
| **Definição** | Valor de venda dos itens antes de qualquer desconto. É a métrica **auditada**: é ela que tem de fechar com a contabilidade. |
| **Fórmula** | `sum(unitprice * orderqty)` |
| **Grão** | item de pedido |
| **Fonte** | `salesorderdetail` |
| **Dimensões** | todas |
| **Periodicidade** | mensal, com fechamento anual para a reconciliação |
| **Responsável** | CEO (Carlos Silveira) — é o pedido dele |
| **Responde** | §2.7 (reconciliação) |
| **Decisão que destrava** | Se o dashboard pode ser usado para decidir. 2011 tem de dar US$ 12.646.112,16. |

#### 2. Receita líquida

| | |
|---|---|
| **Definição** | Receita depois do desconto concedido. É a métrica de trabalho do dia a dia comercial. |
| **Fórmula** | `sum(linetotal)` |
| **Grão** | item de pedido |
| **Fonte** | `salesorderdetail` |
| **Dimensões** | todas |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial (Silvana Teixeira) |
| **Responde** | a.2, c.1, d.1, e.2 |
| **Decisão que destrava** | Onde a receita está e onde não está. |

> As duas convivem na tela de propósito: a **bruta** é a que fecha com a auditoria, a
> **líquida** é a que reflete o que a empresa recebeu. A diferença entre elas **é** o
> indicador nº 6.

#### 3. Número de pedidos

| | |
|---|---|
| **Definição** | Quantidade de pedidos distintos no período. Contagem, não soma de linhas. |
| **Fórmula** | `count(distinct salesorderid)` |
| **Grão** | pedido (contado a partir do grão de item) |
| **Fonte** | `salesorderheader` |
| **Dimensões** | todas |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial |
| **Responde** | e.1, e.2 |
| **Decisão que destrava** | Se o crescimento é mais gente comprando ou o mesmo comprando mais. |

> ⚠️ Como a fato vive no grão de item, `count(*)` conta **itens**, não pedidos, e infla o
> número. A contagem distinta não é preferência de estilo: é a definição.

#### 4. Itens vendidos

| | |
|---|---|
| **Definição** | Unidades físicas vendidas. |
| **Fórmula** | `sum(orderqty)` |
| **Grão** | item de pedido |
| **Fonte** | `salesorderdetail` |
| **Dimensões** | produto, motivo, tempo, geografia |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial |
| **Responde** | f.1 |
| **Decisão que destrava** | Giro por produto — e é a métrica que a pergunta (f) pede. |

#### 5. Ticket médio

| | |
|---|---|
| **Definição** | Valor médio por pedido no período. Traduz meta de receita em número de pedidos. |
| **Fórmula** | `sum(linetotal) / count(distinct salesorderid)` |
| **Grão** | pedido |
| **Fonte** | `salesorderdetail` + `salesorderheader` |
| **Dimensões** | produto, mês, ano, cidade, estado, país |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial |
| **Responde** | b.2, e.2 |
| **Decisão que destrava** | Onde subir preço e onde subir volume. Varia 3,4x entre países. |

> A fórmula do briefing — *"gross revenue − product discounts / number of orders"* — já tem
> o desconto embutido no `linetotal`. Subtrair de novo desconta duas vezes; ver Anexo A.2.

#### 6. Taxa de desconto

| | |
|---|---|
| **Definição** | Fração da receita bruta devolvida ao cliente como desconto. |
| **Fórmula** | `sum(unitprice * unitpricediscount * orderqty) / sum(unitprice * orderqty)` |
| **Grão** | item de pedido |
| **Fonte** | `salesorderdetail`, com quebra por `specialoffer` |
| **Dimensões** | canal, produto, tempo, tipo de oferta |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial |
| **Responde** | b.1, b.3 |
| **Decisão que destrava** | Teto de desconto, e se a política se estende ao varejo. Hoje é 0,478% da receita bruta, e **100% das ofertas são de revenda**. |

#### 7. Receita por motivo de venda

| | |
|---|---|
| **Definição** | Receita atribuída a cada motivo declarado de compra. **Não soma ao total** — um pedido pode ter vários motivos. |
| **Fórmula** | `sum(linetotal)` agregado pela associação pedido↔motivo |
| **Grão** | item de pedido × motivo |
| **Fonte** | `salesorderdetail` + `salesorderheadersalesreason` + `salesreason` |
| **Dimensões** | motivo, tipo de motivo, produto, tempo |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria Comercial |
| **Responde** | a.3, f.2 |
| **Decisão que destrava** | Alocação de verba entre preço, promoção e propaganda. |

> Dois avisos que **têm de estar na tela**, não só aqui: este indicador descreve **só o
> canal online** (a revenda não tem motivo registrado), e **26,9% dos pedidos não têm motivo
> nenhum** — precisa do balde "sem motivo informado". O tratamento técnico do N:N é decisão
> da Etapa 3, ver Anexo B.1.

#### 8. Mix de canal

| | |
|---|---|
| **Definição** | Participação de venda online e de revenda em receita, pedidos e ticket, lado a lado. |
| **Fórmula** | os indicadores 2, 3 e 5 quebrados por `onlineorderflag` |
| **Grão** | pedido |
| **Fonte** | `salesorderheader` |
| **Dimensões** | canal × tempo × geografia |
| **Periodicidade** | mensal |
| **Responsável** | Diretoria de Inovação (João Muller) — decide alocação de esforço |
| **Responde** | é o **eixo de controle** da §2, não um aprofundamento |
| **Decisão que destrava** | Onde alocar equipe comercial. E, mais importante, impede que os outros indicadores sejam lidos errado. |

> Entra no dashboard mesmo não sendo uma das dimensões que o briefing pede, e a justificativa
> é forte: **27.659 pedidos online contra 3.806 de revenda**, com ticket de ordem de grandeza
> diferente. Em contagem o online domina 8 para 1; em receita a história se inverte. Sem esse
> visual, três dos outros indicadores enganam quem lê.

#### 9. Concentração de clientes

| | |
|---|---|
| **Definição** | Fatia da receita que vem dos dez maiores clientes. Medida de dependência. |
| **Fórmula** | receita dos 10 maiores ÷ receita total |
| **Grão** | cliente |
| **Fonte** | `salesorderheader` + `customer` |
| **Dimensões** | tempo, canal, geografia |
| **Periodicidade** | trimestral — muda devagar |
| **Responsável** | Diretoria Comercial |
| **Responde** | c.1 |
| **Decisão que destrava** | Se vale atendimento dedicado. Hoje são **7,2%**: não há dependência, e a prioridade é escala, não blindagem. |

---

### 3.2 Regra de quebra — por que estes nove

Declarada, para a escolha ser auditável em vez de gosto pessoal. **Entra no dashboard o
indicador que satisfaz ao menos uma condição:**

1. **é exigido pelo briefing** — as métricas das seis perguntas (indicadores 2, 3, 4, 5);
2. **é a condição de confiança** — a métrica auditada pelo CEO (indicador 1);
3. **responde um aprofundamento da §2 que muda uma decisão da Silvana e cabe numa frase**
   (indicadores 6, 7, 9);
4. **impede que os outros sejam lidos errado** (indicador 8).

E **sai** o indicador que: precisa de definição de negócio que ainda não existe; é lista e
não número; ou responde uma pergunta que o dado já respondeu de forma constante.

---

## 4. O mapa completo

A mesma estrutura deste documento em uma imagem — as seis âncoras, os catorze
aprofundamentos e a decisão que cada um destrava: **[`01.01-mapa-completo.md`](01.01-mapa-completo.md)**.

Ficou em arquivo separado porque são 73 nós, e o diagrama ocupava mais espaço aqui do
que a leitura tolera. Lá o GitHub renderiza direto, e o código Mermaid serve para o
FigJam e para o PDF do fluxo.


---

# Anexos — insumos para as etapas seguintes

Nada aqui é escopo da Etapa 1. São achados que a apuração desta etapa produziu e que as
próximas consomem — registrados agora porque reapurar depois custa mais caro. Cada anexo
diz a que etapa pertence.


## Anexo A. As métricas e a pegadinha do desconto

> **Pertence à Etapas 3 e 5.**

As perguntas e os quebras estão na §2. Aqui ficam as **métricas** que elas exigem e a
armadilha de cálculo que precede qualquer SQL.

### A.1 As métricas, com a fórmula

Tabelas do schema `adventure_works` (nomes a confirmar — Anexo C):

| Métrica | Cálculo | Grão nativo |
|---|---|---|
| `qtd_pedidos` | `count(distinct salesorderid)` | cabeçalho |
| `qtd_itens` | `sum(orderqty)` | item |
| **`receita_bruta`** | **`sum(unitprice * orderqty)`** | **item** — é a métrica auditada pelo CEO, ver Anexo B.4 |
| `desconto` | `sum(unitprice * unitpricediscount * orderqty)` | item |
| `receita_liquida` | `sum(linetotal)` | item |

### A.2 Pegadinha do desconto — ler antes de escrever qualquer SQL

`salesorderdetail.linetotal` **já tem o desconto aplicado**:

```
linetotal = unitprice * (1 - unitpricediscount) * orderqty
```

Ou seja: `receita_liquida = receita_bruta − desconto`.

> ⚠️ **Nesta porta para Postgres, `linetotal` NÃO é coluna calculada.** No SQL Server
> original ela é computada; aqui o `install.sql` a declara como `numeric` simples e o valor
> vem pronto do CSV — o comentário `-- AS ISNULL(UnitPrice * (1.0 - UnitPriceDiscount) *
> OrderQty, 0.0)` ficou no arquivo como documentação, sem virar `GENERATED`. O mesmo vale
> para `totaldue` e `salesordernumber`.
>
> Conferi as 121.317 linhas: **zero divergências** acima de um centavo, então o dado está
> íntegro hoje. Mas nada no banco garante isso, o que faz dessa identidade um **teste de
> qualidade de verdade** para a Etapa 5 — o briefing pede "data quality tests", e este é um
> que testa uma invariante real em vez de um `not_null` decorativo.

A fórmula que o briefing dá para a pergunta (b) é *"average order value = Gross revenue −
product discounts / number of orders"*. Se alguém ler "gross revenue" como `sum(linetotal)`
e **ainda** subtrair o desconto, o desconto é descontado duas vezes e o ticket médio sai
baixo demais. A leitura correta:

```sql
ticket_medio = sum(salesorderdetail.linetotal)
               / count(distinct salesorderdetail.salesorderid)
```

> Sem alias de iniciais de propósito: o code style da Indicium AI proíbe apelidar tabela de até
> três palavras, e manda prefixar a coluna com o nome inteiro. Ver
> `resumo_code_style_indicium.md` no Módulo IV.

Vale documentar isso nas regras de negócio (Etapa 8) — é o tipo de erro que ninguém percebe
porque o número continua *parecendo* plausível.

---


## Anexo B. Antecipações de modelagem

> **Pertence à Etapa 3.**

> **Esta seção não é escopo da Etapa 1.** A Etapa 1 pede KPIs, perguntas de negócio e
> justificativa; modelagem é a **Etapa 3**. O que está aqui são decisões de modelagem que a
> apuração da Etapa 1 já obrigou a enxergar, registradas para não se perderem. As duas que
> continuam abertas travam a Etapa 3, não esta.

### B.1 `SalesReason` é muitos-para-muitos — e isso quebra a soma

No diagrama existe **`salesorderheadersalesreason`**, uma tabela associativa: um pedido pode
ter **vários** motivos de venda ao mesmo tempo (ex.: "On Promotion" *e* "Price").

Consequência: um `inner join` ingênuo entre a fato e os motivos **duplica a receita** de todo
pedido com mais de um motivo. A soma total do dashboard passa a não fechar com os
US$ 12.646.112,16 do CEO — e o problema não aparece no número global, só quando alguém filtra
por motivo. É o pior tipo de erro: silencioso e seletivo.

Isso afeta diretamente as perguntas (a) — "valor total por motivo da venda" — e (f).

> **DECISÃO CONJUNTA A** — como tratar o motivo da venda:
>
> 1. **Bridge** (`bridge_orders_sales_reasons`, prefixo do code style). É o que o **Módulo 3
>    do curso** ensina para exatamente este caso — o slide *Bridge Tables* diz "useful when:
>    many-to-many relationship", e o resumo do módulo define a bridge como "tabela auxiliar
>    para resolver relacionamentos muitos-para-muitos entre fato e dimensão, contendo apenas
>    chaves primárias, sem valor de negócio próprio". O `dbt_coding_conventions.md` do
>    `indicium-code-style` reconhece o padrão: lista `bridge_` entre os prefixos oficiais e
>    diz que "aggregate and bridge models are exceptions, as they often don't need normal
>    primary keys". Custo: o dashboard precisa dizer que "receita por motivo" **não soma** ao
>    total.
>
>    **A bridge já existe na origem.** A `salesorderheadersalesreason` tem três colunas —
>    `salesorderid`, `salesreasonid`, `modifieddate`. É literalmente a definição do Módulo 3.
>    Então a decisão não é criar uma bridge, é **preservar ou destruir** a que existe.
> 2. **Um motivo por pedido**, com regra de desempate explícita (ex.: menor `salesreasonid`).
>    Simples, soma fecha, mas joga informação fora e a regra é arbitrária.
> 3. **Aceitar a duplicação** e documentá-la. Mais barato, e o mais fácil de ser cobrado
>    numa banca.
>
> Recomendação: **(1)**. É a resposta que sustenta pergunta na apresentação.

**Tamanho do problema, medido:** dos 31.465 pedidos, **4.482 têm mais de um motivo** (4.329
com dois e 153 com três). São 14,2% dos pedidos que têm motivo — receita suficiente para o
total do dashboard não fechar de forma visível.

**Segunda armadilha no mesmo lugar:** **8.453 pedidos (26,9%) não têm motivo nenhum.**
Qualquer quebra por motivo perde mais de um quarto da base em silêncio — precisa de um bucket
**"sem motivo informado"** explícito, não um `inner join` que some as linhas.

### B.2 O que é "Promotion" na pergunta (f)? — ✅ resolvido, não é decisão

A pergunta (f) diz *"the 'Promotion' sales reason"*, e a tabela `salesreason` tem duas
colunas nomeadas: `name` e `reasontype`. Parecia ambíguo entre um motivo e um grupo de
motivos. Fui aos dados: são só 10 motivos, e **'On Promotion' é o único com
`reasontype = 'Promotion'`**.

| id | name | reasontype |
|---|---|---|
| 1 | Price | Other |
| **2** | **On Promotion** | **Promotion** |
| 3 | Magazine Advertisement | Marketing |
| 4 | Television Advertisement | Marketing |
| 5 | Manufacturer | Other |
| 6 | Review | Other |
| 7 | Demo Event | Marketing |
| 8 | Sponsorship | Marketing |
| 9 | Quality | Other |
| 10 | Other | Other |

As duas leituras selecionam **exatamente os mesmos 3.515 pedidos**. Não há decisão a tomar
— só uma escolha de qual coluna escrever no filtro. Fica registrado nas regras de negócio
porque a equivalência é uma propriedade *deste* dado, não uma garantia do modelo: bastaria
a Adventure Works criar um segundo motivo promocional para as duas leituras divergirem.

### B.3 O grão da tabela fato

Tensão real entre as perguntas:

- (a), (b) e (f) precisam de **produto e quantidade** → só existem em `salesorderdetail`, no
  grão de **item de pedido**.
- (a), (c) e (d) contam **pedidos**, e o denominador de (b) é "number of orders".
- Tipo de cartão, motivo, status e cliente vivem no **cabeçalho** (`salesorderheader`).

> **DECISÃO CONJUNTA C** — uma fato ou duas?
>
> Recomendação: **uma fato no grão de item de pedido**, com `salesorderid` como **dimensão
> degenerada**, e `qtd_pedidos` definida como `count(distinct salesorderid)` em vez de
> `count(*)`. Motivos: o item é o grão mais fino que as perguntas exigem, atributos de
> cabeçalho se repetem sem prejuízo, e o code style da Indicium AI pede PK única por modelo —
> aqui é `salesorderdetailid`, que já é única e natural.
>
> O preço a pagar, que precisa estar documentado: **toda** medida de contagem de pedidos
> tem de ser distinta. Um `count(*)` distraído conta itens e infla o número.

### B.4 O teste de aceite do CEO — ✅ resolvido nos dados

US$ 12.646.112,16 em vendas brutas de 2011 é o número que precisa fechar, e vira teste dbt
na Etapa 5. Apurei nos CSVs, e o resultado **contraria a hipótese óbvia**:

| Definição de 2011 (por `orderdate`) | Valor | |
|---|---:|---|
| `sum(unitprice * orderqty)` — **antes** do desconto | **12.646.112,16** | ✅ **bate exato** |
| `sum(salesorderheader.subtotal)` | 12.641.672,21 | erra por 4.439,95 |
| `sum(salesorderdetail.linetotal)` | 12.641.672,21 | idem |
| `sum(totaldue)` (com imposto e frete) | 14.155.699,53 | alto demais |
| `sum(subtotal)` por `shipdate` | 12.527.981,99 | data errada |

**"Gross sales" é literalmente bruto: receita antes do desconto.** A diferença de
4.439,95 é exatamente o desconto concedido em 2011. Minha hipótese de trabalho era
`sum(subtotal)`, e estava errada por esse valor.

Três consequências que importam:

1. **A métrica de aceite só existe no grão de item.** `unitprice` e `orderqty` vivem em
   `salesorderdetail`; o cabeçalho só guarda o `subtotal`, que já é líquido. Isso reforça a
   decisão C — uma fato no grão de item não é preferência de estilo, é o que torna o teste
   do CEO possível de escrever.
2. **`receita_bruta` deixa de ser métrica de apoio e passa a ser a métrica auditada.** Ela
   tem de estar no modelo com esse nome e essa definição.
3. **A data é `orderdate`, e não há filtro de status** — 2011 tem 1.607 pedidos e todos
   entram.

O teste dbt, então, é sobre `sum(unitprice * orderqty)` com `extract(year from orderdate)
= 2011`, esperando `12646112.16`.

⚠️ **O teste tem de comparar em centavos, não em igualdade exata.** A soma exata é
`12646112.1607`: `unitprice` tem 4 casas decimais e **2.832 dos 5.642 itens de 2011** usam
as quatro. O briefing informa o número já arredondado, então a asserção é
`round(soma, 2) = 12646112.16`. Confirmado no Databricks e na aritmética decimal dos
arquivos de origem, dígito por dígito — e é essa quarta casa que justifica
`decimal(19, 4)` em vez de `double`.

> Nota de leitura para a apresentação: 2011 tem só 1.607 pedidos dos 31.465 do dataset, e é
> um ano dominado por revenda. Não use 2011 como retrato do negócio — ele é o ano do
> **teste**, não da análise.

---


## Anexo C. A base, conferida contra o repositório oficial

> **Pertence à Etapa 4.**

Fonte: `install.sql` + os 72 TSV de `AdventureWorks/data/`.

**O que o briefing promete e a base entrega:**

| Briefing | Base | |
|---|---|---|
| 68 tabelas | 68 `CREATE TABLE` | ✅ |
| 5 schemas | Person 13 · HumanResources 6 · Production 25 · Purchasing 5 · Sales 19 | ✅ |
| 500+ produtos, 20 mil clientes, 31 mil pedidos | 31.465 pedidos, 121.317 itens | ✅ |

**A contagem de schemas do briefing está certa; o que falta é o nome.** Ele diz "5 schemas"
e lista quatro (HR, sales, production, purchasing) — o quinto é **`Person`**, e é ele que
guarda `Address`, `StateProvince` e `CountryRegion`. Sem esse schema não existe quebra por
cidade, estado ou país, que quatro das seis perguntas exigem. Vale dizer que `CountryRegion`
mora em `Person`, não em `Sales`, o que não é intuitivo.

**O diagrama do briefing tem um schema que a base não tem.** A imagem é o `AdventureWorks
2008 OLTP Schema` do SQL Server e mostra **seis** grupos, incluindo `dbo`
(`AWBuildVersion`, `DatabaseLog`, `ErrorLog`). O `install.sql` não cria nenhuma dessas: o
diagrama é mapa de **relacionamento**, não inventário desta base.

### O único item realmente aberto

**De onde vem o schema `adventure_works`?** O briefing manda *"USE ONLY THE adventure_works
SCHEMA"*, e a string **`adventure_works` não aparece uma única vez no repositório** — nem no
`install.sql`, nem em nenhum `.md`, `.yml`, `.sql`, `.py` ou `.json`. No Postgres a base
nasce com os cinco schemas acima.

A leitura mais provável é que `adventure_works` seja o nome do schema **de destino**, criado
no passo de ingestão (EL) para dentro do Databricks, achatando as 68 tabelas num só lugar.
Isso muda o SQL de toda a Etapa 5 — `sales.salesorderheader` viraria
`adventure_works.salesorderheader` — então precisa ser confirmado no tutorial de ingestão da
trilha antes de escrever o primeiro `source()`. Duas notas:

- O briefing manda seguir *"the initial setup tutorial on the repository's main page"*, mas
  o README raiz deste repo é do **livro** Analytics Engineering e não tem link de trilha nem
  menção ao AdventureWorks no sumário. Ou o briefing aponta para outra página, ou o material
  divergiu.
- O repo é fork de `dpavancini/analytics-engineering` e está **no mesmo commit do upstream**
  (`1f77a1c`, de julho de 2021). Não há nada defasado nem faltando aqui.

### Uma dúvida que continua de negócio, não de dado

Proporção de `customer` com `personid` versus `storeid` — decide se "cliente recorrente"
tem um sentido só ou dois (c.2, na §2.3). Dá para medir no CSV, mas a definição é escolha de
negócio, não de dado.

---


## Anexo D. O argumento para a Silvana

> **Pertence à Etapa 9.**

Não é a lista de KPIs. É esta sequência:

1. **O que ela não consegue responder hoje.** Toda pergunta dela sobre venda passa pela
   agenda do Gabriel. "Quanto a promoção do mês passado custou em margem?" hoje é um
   pedido, uma fila e uma planilha — e a resposta chega depois que a decisão já foi tomada.
2. **Uma decisão por KPI.** Os nove indicadores da §3.1 foram escritos para isso: cada um
   termina no campo *decisão que destrava*, não numa definição.
3. **Por que agora é diferente.** Não porque a ferramenta é melhor. Porque o número vai ser
   **reconciliado com a auditoria contábil** — o pedido do próprio CEO — e o teste que prova
   isso roda a cada carga. O CRM e o Web Analytics prometeram visão; nenhum dos dois
   provou o número. É essa a diferença, e é honesta.
4. **O que pedimos dela.** Validar os KPIs desta lista. É o passo 10 do método de modelo
   conceitual da Indicium AI (*"valide a modelagem com as áreas de negócio"*) e, na prática,
   é o que transforma a cética em coautora.

---


## Anexo E. Convenções de código

> **Pertence à Etapa 5.**

Do `indicium-code-style` (Bitbucket, `indiciumtech/indicium-code-style`), para o nome dos
modelos da Etapa 5 nascer certo:

- modelos no **plural**; source como `<source>__<tabela>`
- prefixos: `stg_`, `dim_`, `fact_`, `agg_`, **`bridge_`**
- PK única por modelo (surrogate se preciso); **bridge e agregado são exceção**
- só source/staging leem de `source()`; o resto lê de `ref()`
- SQL: sqlfluff 1.4.5, 4 espaços, ≤100 colunas, palavras-chave minúsculas, `as` sempre,
  vírgula à frente, CTE em vez de subquery, `inner join` explícito, `count(*)`

---


## Referências

- **Base oficial:** [`dpavancini/analytics-engineering/AdventureWorks`](https://github.com/dpavancini/analytics-engineering/tree/main/AdventureWorks)
  — porta para Postgres feita por **Lorin Thwaits** a partir do *Adventure Works **2014**
  OLTP Script* da Microsoft (cabeçalho do `install.sql`, linhas 1-6). Dado fictício de uma
  indústria de bicicletas, com vendas de **mai/2011 a jun/2014** (`install.sql`, linha 3019).
  `install.sql` (68 tabelas, 5 schemas) e `data/` (72 TSV). Clonado localmente em
  `Desafio/adventureworks-oficial/`, fora do git. Fork usado:
  [`jessefreireufc`](https://github.com/jessefreireufc/analytics-engineering/tree/main/AdventureWorks),
  no mesmo commit `1f77a1c` do upstream.
- `Desafio/Briefing Desafio.txt` — briefing oficial
- `Desafio/imagemDesafio.png` — `AdventureWorks 2008 OLTP Schema` (SQL Server; a base
  Postgres não tem o schema `dbo` que aparece nele). ⚠️ O **2008** é do título do diagrama,
  **não** da base: o dado carregado é a porta da versão **2014**. É um engano fácil de
  cometer, porque as duas fontes vivem no mesmo briefing
- Referencial Indicium AI (local, não versionado): `3.1) Por onde começar o Modelo Conceitual`
  (passo a passo, linhas 247-257), `2.7) Como definir indicadores` (atributos por
  indicador, adotado na §3)
- **Módulo 3 do curso** (`resumo_modulo3.md` Anexo C e o slide *Bridge Tables*) — é a base da
  recomendação de bridge em Anexo B.1
- `Desafio/indicium-code-style/dbt_coding_conventions.md` — prefixos `stg_`/`dim_`/`fact_`/
  `agg_`/`bridge_`, e a isenção de PK única para bridge e agregado
- ⚠️ `5.4) Boas práticas envolvendo tabelas bridges` do referencial **não** fundamenta a
  Anexo B.1: ele trata de relacionamento circular entre **múltiplas tabelas fato** no Power BI,
  construído com `full outer join`, e nomeia o modelo `bdg_`. Passa a valer se o projeto
  crescer para mais de uma fato. Note a divergência de prefixo com o code style (`bridge_`)
- `Desafio/indicium-code-style/sql_style_guide.md` — sqlfluff 1.4.5 e o estilo de SQL
