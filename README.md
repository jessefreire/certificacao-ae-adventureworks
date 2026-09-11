# Desafio Final — Adventure Works

Projeto de certificação da Formação Analytics Engineer (Indicium AI). Constrói uma plataforma de
dados para a área comercial da Adventure Works: modelagem dimensional, transformação em dbt com
testes e documentação, e dashboard.

## O que rodar, em ordem

São **dois** arquivos, e os dois são notebooks do Databricks (`Workspace → Import → File`):

| # | Arquivo | O que é |
|---|---|---|
| 1 | [`databricks/01-ingestao-adventure-works.sql`](databricks/01-ingestao-adventure-works.sql) | Cria e carrega a camada bruta. **Pré-requisito**, roda uma vez |
| 2 | [`databricks/02-analise-exploratoria.py`](databricks/02-analise-exploratoria.py) | A análise da Etapa 2. **Entregável** |

Nada mais precisa ser executado. Os antigos `01-ddl`, `02.x-carga`, `02.99-recarga-limpa` e
`03-verificacao` foram consolidados no arquivo 1.

⚠️ **No workspace do Databricks eles continuam existindo, e isso é deliberado** — ficam como
registro do caminho. Mas **não devem ser executados**: o `COPY INTO` deles acrescenta linhas, e
o `force = true` desliga a proteção contra recarga. Rodar um por engano soma a carga de novo.
O notebook de ingestão traz essa lista com o motivo de cada um, na abertura.

## Estrutura

Regra de nomenclatura: **número = etapa do briefing; sem número = infraestrutura.**

```
docs/          documentos de etapa
databricks/    o que roda no Databricks (os dois notebooks)
scripts/       geradores e linter — o notebook de ingestão é gerado, não escrito à mão
dbt/           Etapa 5
entrega/       links.txt, que o briefing exige em arquivo de texto
```

## Etapas

| # | Etapa | Entregável | Status |
|---|---|---|---|
| 1 | KPIs e perguntas de negócio | [`docs/01-kpis-e-perguntas.md`](docs/01-kpis-e-perguntas.md) · [mapa](docs/01.01-mapa-completo.md) | **completa** |
| 2 | Análise exploratória | [`databricks/02-analise-exploratoria.py`](databricks/02-analise-exploratoria.py) | **completa** — executada e conferida |
| 3 | Modelo conceitual | [`docs/03-decisoes-de-modelagem.md`](docs/03-decisoes-de-modelagem.md) · PDF | **decisões fechadas** — diagrama pendente |
| 4 | DW na nuvem + dbt | Databricks Free Edition + dbt Cloud | **ingestão completa e conferida** |
| 5 | Transformação dbt | modelos, docs, testes de source/PK/qualidade | — |
| 6 | Mockup do dashboard | JPEG, no Figma | — |
| 7 | Dashboard | **Power BI** — `.pbix` com as medidas DAX documentadas dentro do arquivo | — |
| 8 | Regras de negócio | documento | — |
| 9 | Apresentação | slides | seções das Etapas 1 e 2 prontas |
| 10 | Vídeo | 3-5 min | — |
| 11 | Planejamento do projeto | PDF — opcional | — |

## Os oito entregáveis, e onde cada um está

A seção 5 do briefing é a lista fechada do que se submete, e `"adesão aos requisitos de
entrega"` é critério de nota. O mapa 1:1:

| O briefing pede | Onde está |
|---|---|
| Notebook da análise exploratória, em Python ou SQL, com código, gráficos e comentário por insight | `databricks/02-analise-exploratoria.py` |
| Link do repositório com os modelos dbt | `entrega/links.txt` — projeto dbt pendente |
| PDF do modelo conceitual | pendente, Etapa 3 — decisões em [`docs/03-decisoes-de-modelagem.md`](docs/03-decisoes-de-modelagem.md) |
| JPEG do mockup, feito no Figma | pendente, Etapa 6 |
| PBIX com as medidas DAX documentadas dentro do arquivo | pendente, Etapa 7 — **Power BI decidido**, AI/BI descartado |
| Arquivo com a documentação das regras de negócio | pendente, Etapa 8 |
| Apresentação em slides | `Desafio/entregaveis/` (fora do git) |
| Vídeo de 3 a 5 minutos | pendente, Etapa 10 |

**A ingestão não está nessa lista** — o briefing não pede artefato de ingestão, nem script nem
notebook, e a lista de demonstrações obrigatórias do vídeo também não tem item de ingestão. Ela
é infraestrutura, e é por isso que cabe num arquivo só.

Todo link entregue precisa estar com **acesso público**, o que o briefing repete
explicitamente. Ver `entrega/links.txt`.

## Base de dados

[`dpavancini/analytics-engineering/AdventureWorks`](https://github.com/dpavancini/analytics-engineering/tree/main/AdventureWorks)
— porta para Postgres feita por **Lorin Thwaits** a partir do *Adventure Works **2014** OLTP
Script* da Microsoft (cabeçalho do `install.sql`). Dado fictício de uma indústria de bicicletas,
com vendas de **mai/2011 a jun/2014**. São 68 tabelas em 5 schemas (Person, HumanResources,
Production, Purchasing, Sales); cerca de 500 produtos, 20 mil clientes, 31 mil pedidos.

⚠️ O diagrama que o briefing distribui diz *2008* porque é a imagem do **SQL Server**, não desta
base. É um engano fácil de cometer: as duas fontes vivem no mesmo briefing.

O clone fica em `Desafio/adventureworks-oficial/`, **fora do git**.

## Ingestão

Um notebook, [`databricks/01-ingestao-adventure-works.sql`](databricks/01-ingestao-adventure-works.sql),
com 80 células em três seções: as **17 tabelas que a análise usa**, as **47 restantes** da camada
bruta, e as **conferências**.

### Antes de rodar

A pasta `AdventureWorks` inteira precisa estar num Volume do Unity Catalog, subida com
`Select folder` — que preserva a estrutura:

```
/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/
```

O nome do schema não é escolha nossa: o briefing determina `USE SOMENTE O SCHEMA
adventure_works`. O nome do volume segue o padrão `raw_<fonte>` do documento
`2.5) Como definir os schemas padrão` do referencial de processos, aplicado ao volume porque o
schema já estava fixado pelo briefing.

Os nomes de tabela são absolutos (`workspace.adventure_works.<tabela>`), então não depende de
qual catálogo está selecionado no editor.

### Repetir é seguro, e isso é por construção

Cada tabela é criada e carregada em **uma** instrução:

```sql
create or replace table workspace.adventure_works.address as
select cast(_c0 as int) as addressid, ...
from read_files('.../Address.csv', format => 'csv', sep => '\t', header => false, ...)
```

As opções de leitura, e o que cada uma evita: `sep => '\t'` porque os arquivos têm extensão
`.csv` mas são separados por tab; `nullValue => ''` porque sem ele campo vazio em coluna `int`
recebe **0**, e "sem vendedor" viraria "vendedor 0"; `quote => '"'` porque o XML de algumas
tabelas está entre aspas com as internas duplicadas, que é a convenção CSV; e
`mode => 'FAILFAST'` para linha ruim derrubar a carga em vez de virar `NULL` em silêncio.

Repetir uma célula **substitui** os dados em vez de somar. Não existe como duplicar. É a
correção do pior erro desta etapa, e ela vive no código em vez de depender de quem roda — ver
[Armadilhas pagas](#armadilhas-pagas).

O cast explícito por posição existe porque os arquivos **não têm linha de cabeçalho**: o
Databricks lê as colunas como `_c0`, `_c1`, e a única fonte da verdade sobre qual é qual é a
ordem do `install.sql`. São 431 colunas nomeadas uma a uma — dinheiro em `decimal(19, 4)`, nunca
`double`.

### Parar na seção 1 é um estado válido

As 17 tabelas da análise vêm primeiro **de propósito**. A Free Edition esgota cota de compute, e
parar ali deixa a Etapa 2 desbloqueada. As outras 47 não são usadas por nenhuma pergunta do
briefing — sobem porque custam quase nada (79 MB, 759 mil linhas) e removem o atrito de ingestão
se o trabalho crescer para compras ou produção.

O escopo **modelado** é outra decisão: só as 17 serão declaradas como `source` no dbt, porque
declarar source é assumir o teste e a documentação dela.

### Quatro tabelas ficam de fora, por defeito de origem

Das 68 do `install.sql`, **64 carregam**. As quatro que ficam fora não são escolha nossa:

| Tabela | Defeito |
|---|---|
| `Document` | coluna binária (`varbinary`), que não atravessa arquivo de texto |
| `ProductPhoto` | duas colunas binárias: `ThumbNailPhoto` e `LargePhoto` |
| `ProductReview` | sete campos onde o DDL declara oito, e quebra de linha dentro de campo — 34 linhas físicas para 31 registros |
| `ProductModel` | 48 TABs dentro de campo aspado no XML de `CatalogDescription`; o leitor do Spark não honra a aspa nesse caso e 6 das 128 linhas se partem, uma em **22** campos onde há 6 |

O `ProductModel` foi o único que custou tentativa: `quote`, `escape` e as duas em conjunto, sem
sucesso. O `JobCandidate` tem o mesmo tipo de XML mas **um** tab, e carrega normalmente — então
o limite é a quantidade de tabs, não a estrutura. Nenhuma das quatro é usada por pergunta alguma
do briefing, então o custo analítico é zero.

### As conferências

Rodam **antes de qualquer análise**. Se alguma falhar, todo número da exploração fica suspeito.
Os valores esperados estão embutidos no SQL, medidos nos próprios arquivos de origem.

| # | Confere | Esperado |
|---|---|---|
| 3.1 | tipo do dinheiro | `DECIMAL`, precisão 19, escala 4 |
| 3.2 | contagem por tabela | as 17 da análise em `ok` |
| 3.3 | as sete junções da análise | zero órfão em todas |
| 3.4 | o `NULL` sobreviveu | 27.659 sem vendedor, zero "vendedor 0" |
| 3.5 | o aceite do briefing | `FECHA`, com soma exata `12.646.112,1607` |
| 3.6 | integridade do `linetotal` | 121.317 linhas, zero fora de um centavo |

Resultado da última execução: **todas passaram** — as 64 tabelas em `ok`, com a contagem
idêntica à dos arquivos de origem, e o aceite fechando em `12.646.112,1607`.

Essa execução também é a prova prática de que a duplicação morreu: as 13 tabelas que estavam
em 2x, 3x e 5x voltaram ao número exato sem nenhuma intervenção. `businessentity` de 41.554
para 20.777, `employeepayhistory` de 1.580 para 316. O `create or replace` substitui.

## Análise exploratória (Etapa 2)

[`databricks/02-analise-exploratoria.py`](databricks/02-analise-exploratoria.py) — 84 células:
43 de markdown, 33 de SQL e 9 de gráfico, em **10 seções**. Lê **16** das 17 tabelas do
escopo da análise. Linguagem padrão **Python**, porque os gráficos
exigem, com o SQL em células `%sql`.

**A pergunta não se descobre nele.** A estrutura segue a Etapa 1: perfil do dado, reconciliação
com o número do CEO, e então uma seção por pergunta do briefing com seus aprofundamentos
(`a.1`…`f.2`), cada um com consulta, evidência e comentário.

O que cada seção entrega além da resposta é o aviso que impede a leitura errada: motivo de venda
existe só no online, o ticket por país varia por mistura de canal, as cinco maiores cidades são
11% da receita, e a série tem quebra estrutural em jul/2013.

Os **nove gráficos** vêm em dois grupos, e a divisão é proposital. Os cinco primeiros existem
onde o gráfico mostra algo que a tabela não mostra — a quebra da série, a uniformidade que
desqualifica um corte, a cauda longa do catálogo, a confusão entre canal e mercado, e a
comparação que só vale dentro do mesmo canal. Os quatro últimos respondem visualmente as
perguntas **(b)**, **(c)**, **(d)** e **(f)**, que são rankings. Com os nove, cada uma das seis
perguntas do briefing tem ao menos um visual — e os quatro últimos já são o rascunho do
dashboard da Etapa 7, com o mesmo corte e o mesmo aviso de escopo.

## Convenções de código

Segue o [`indicium-code-style`](https://github.com/indiciumtech/indicium-code-style): prefixos
`stg_`/`dim_`/`fact_`/`agg_`/`bridge_`, sqlfluff 1.4.5, 4 espaços, ≤100 colunas, vírgula à
frente, `inner join` explícito, `group by` com a coluna escrita — nem ordinal, nem `all`.

Toda consulta vem comentada, em uma ou duas linhas, dizendo **o que se confere** e **qual o
valor esperado**. Comentário curto: o objetivo é entender a consulta de relance.

Prosa em português leva acento — comentário, docstring, markdown de célula e título de célula
inclusive. Identificador não: nome de variável, alias de SQL, nome de tabela, de coluna e de
arquivo ficam em ASCII. Alias acentuado quebra o lexer do sqlfluff (`LXR | Unable to lex
characters`), e nome de arquivo acentuado quebra os links deste README, do docx e dos decks.

### O verificador de português

```bash
python scripts/confere_portugues.py
```

Confere três coisas em 10 arquivos: **palavra sem acento** (um dicionário só de palavras que
não existem em português sem acento, de modo que não há falso positivo — `e`/`é`, `esta`/`está`
e `ate`/`até` ficam de fora porque a forma sem acento também é palavra), **mojibake** (`Ã§`,
`Â`, `â€`) e o **erro inverso**: acento dentro de identificador de SQL, que foi como um
`as orfaos` virou `as órfãos` e derrubou o linter.

Ele sabe o que é prosa em cada tipo de arquivo — markdown fora dos blocos de código, comentário
e docstring no Python, comentário no SQL — e protege URL, caminho, nome de arquivo e nome de
artefato. Roda na mesma rotina do `linta_notebook.py`, para o desvio falhar em vez de ser
descoberto lendo.

### O linter alcança o SQL de dentro dos notebooks

```bash
python scripts/linta_notebook.py          # confere
python scripts/linta_notebook.py --fix    # corrige e devolve às células
```

O sqlfluff não lê notebook. A ferramenta extrai cada célula para um arquivo, roda o linter, e
com `--fix` devolve o SQL corrigido. Cobertura atual: **33 de 33** células do notebook de
análise e **6 de 6** células de conferência da ingestão, zero violação.

Ela também confere os **títulos**: únicos, com prefixo numérico, sequência contígua por seção,
seções em ordem crescente, e rótulo em prosa que caiba no painel (nome de tabela é exceto — não
há o que encurtar em `ProductModelProductDescriptionCulture` sem inventar abreviação).

E confere a **integridade das células** nos dois notebooks: markdown sem `%md` (que o
Databricks executaria como código), `%md` em célula que tem código (que faria nada executar),
magic duplicado, célula vazia, e **célula de código sem `DBTITLE`**.

O `DBTITLE` é o título da célula. Sem ele cada uma aparece sem nome na navegação do Databricks,
e "Cell 37" não ajuda ninguém a voltar a uma consulta. São **70** títulos na ingestão e **42**
no de análise, todos no formato `<seção>.<sequência> <rótulo curto>`:

```
ingestão                      análise
1.01 CountryRegion            1.1 Tamanho e janela      6.1 Top 5 cidades
1.02 StateProvince            1.2 Canais e receita      6.3 Por território
2.01 BusinessEntity           2.1 Aceite do CEO         9.3 Pareto de produtos
3.5 Aceite do briefing        3.2 Cartão discrimina?    9.8 (d) Cidades x resto
```

Três decisões, e todas vêm de uma medição: **o painel corta o título em torno de 22
caracteres.**

O **número vem primeiro** porque sobrevive ao corte — `3.4 Catalogo sem venda` truncado ainda é
localizável — e é o mesmo número da seção no markdown, o que dá ordenação.

**Nada de prefixo repetido.** A primeira versão derivava o título do comentário da célula, e o
resultado tinha 58 caracteres de mediana com `grafico` abrindo nove títulos e `perfil` sete: a
palavra repetida consumia o espaço visível antes de chegar ao que distingue. Na ingestão, o
prefixo de schema (`Production.`) gastava 11 caracteres pelo mesmo motivo — ele saiu, e o schema
continua no cabeçalho de markdown do bloco.

**O código do aprofundamento (`a.1`, `b.2`) não entra no título**, porque não distingue células:
havia dois `a.1`, dois `a.2`, dois `b.1`. Ele fica onde pertence, no cabeçalho imediatamente
acima. A exceção são os quatro últimos gráficos, onde a letra da pergunta é a informação útil.

Os títulos do notebook de análise são uma **lista explícita** em
[`scripts/titula_celulas.py`](scripts/titula_celulas.py), não derivados de comentário —
derivação foi o que produziu a primeira versão, e ela não tem como saber que um prefixo
repetido desperdiça espaço. Lista explícita é revisável e estável, e o script falha se o número
de células não casar com o de títulos.

Ela também **confere se a abertura do notebook de EDA está dizendo a verdade**: se as seções
prometidas existem, se a contagem de consultas por seção bate, se o número de gráficos e de
tabelas lidas confere, e se não sobrou referência a arquivo apagado. Isso existe porque aquela
abertura já mentiu três vezes — citava os scripts de ingestão depois da consolidação, dizia
cinco conferências quando eram seis, e afirmava 17 tabelas quando o notebook lia 13.
Documentação que desvia do artefato é pior que documentação nenhuma, então o desvio passou a
falhar no linter em vez de ser descoberto por leitura.

As 65 células de ingestão **não** são linteadas, e isso é declarado em vez de escondido: a
versão 1.4.5 não parseia `read_files(format => 'csv')` nem `COPY INTO`. A ferramenta separa as
duas famílias e conta cada uma, em vez de excluir o arquivo inteiro do lint.

### A auditoria que prevê a falha antes de rodar

```bash
python scripts/audita_tipos.py
```

Simula, **no dado real**, cada um dos 431 casts que o notebook vai executar: inteiro fora de
faixa, `decimal(p, s)` estourando precisão, texto indo para coluna numérica, data que não casa
com os formatos do arquivo, booleano fora do conjunto aceito. Também confere se alguma linha tem
contagem de campos diferente das outras.

Existe porque a carga quebrou três vezes **em execução**, na célula 36, na 39 e na 41 — e duas
delas eram previsíveis aqui. Descobrir na célula 39 de 80, depois de esperar cota, custa uma
tarde; descobrir aqui custa trinta segundos.

Validado contra o histórico: rodando o auditor na versão do notebook de dois commits atrás, ele
acusa os três `unitmeasurecode` indo para `decimal`, com o valor `'EA '` que de fato derrubou a
célula 39.

**O que ele não prevê**, e vale saber: a falha do `ProductModel`. O Python parseia aquele arquivo
corretamente e o Spark não, então nenhuma simulação local o pegaria. O indicador indireto é a
quantidade de TABs dentro de campo aspado — `Person` tem 10 e carrega, `JobCandidate` tem 1 e
carrega, `ProductModel` tinha 48 e falha. Nenhuma outra das 64 tem esse padrão.

### O notebook de ingestão é gerado

```bash
python scripts/gera_ingestao.py           # lê o install.sql e regera o notebook
```

Editar célula à mão cria duas versões do mesmo SQL. Para mudar algo, muda-se o gerador. Ele
assegura o que produziu: 65 tabelas, 437 casts, uma instrução por célula, e zero ocorrência de
`copy into` ou `force` — os dois sinais do desenho antigo.

## Armadilhas pagas

Ficam registradas porque cada uma custou tempo, e três delas quase entraram na entrega como se
fossem verdade.

**`force = true` não protege contra duplicação — faz o oposto.** Eu afirmei isso em nove
arquivos. `COPY INTO` **sempre acrescenta**, e o `force` desliga a idempotência nativa dele.
Como a orientação era "repita o arquivo depois da falha", a base ficou com `address` em 3x,
`person` em 3x e `employeepayhistory` em 5x. Quem pegou foi a conferência de contagem, e a
assinatura é inconfundível: `DIVERGE` com o carregado sendo **múltiplo exato** do esperado — não
é dado corrompido, é a mesma carga somada. A correção definitiva é o desenho atual, uma
instrução por tabela: duplicar deixou de ser possível.

**`RESOURCE_EXHAUSTED` chega disfarçado.** A mensagem aparece como
`ValueError: Code in Status proto (StatusCode.INTERNAL) doesn't match status code
(StatusCode.RESOURCE_EXHAUSTED)` — o `ValueError` é o cliente gRPC se confundindo, e manda
investigar o lugar errado. Não é erro de dado. E **não é tamanho de lote**: 13 instruções
passaram, as 6 seguintes falharam, e uma sozinha carregando 13 linhas também falhou. O consumo é
acumulado na sessão. O que resolveu foi trocar de superfície: **SQL Editor**, cujo warehouse é
um pool separado do compute de notebook. Se o traceback mencionar `pyspark/sql/connect`, você
está no compute de notebook.

**O teste de aceite reprovava uma base correta.** A soma exata é `12.646.112,1607` e o briefing
informa `12.646.112,16` — arredondado a centavos, porque `unitprice` tem 4 casas decimais e
2.832 dos 5.642 itens de 2011 usam as quatro. Comparar com igualdade exata contra um literal de
duas casas nunca poderia fechar. E é justamente essa quarta casa que justifica `decimal(19, 4)`:
com `double`, as 2.832 multiplicações acumulariam resíduo binário e o arredondamento poderia
cair no centavo errado.

**Duas falhas do linter que devolvem falso sucesso.** Arquivo acima de 20.000 bytes é **pulado
em silêncio**, com um aviso e `All Finished!` no fim — indistinguível de sucesso; está desligado
no `.sqlfluff`. E o sqlfluff 1.4.5 **quebra** quando o alvo está em outro drive que o diretório
de trabalho (`ValueError: Paths don't have the same drive`); o crash saía silencioso e o
relatório dizia zero violação quando eram 78. As duas só apareceram por **teste negativo** —
introduzir violação de propósito e confirmar que a ferramenta reprova. Vale repetir isso antes
de confiar em qualquer "zero".

**Duas tabelas quebravam a carga por defeito de origem, e a aspa CSV era a causa.** Eu havia
desabilitado `quote` no leitor, com o raciocínio de que o XML de algumas tabelas tem aspas
dentro do campo. Errado: o arquivo escapa aquelas aspas **duplicando-as**, que é exatamente a
convenção CSV. Com a aspa desabilitada, um TAB dentro do XML partia o campo — e o `FAILFAST`
derrubava a carga do `jobcandidate` (1 linha com 5 campos onde há 4) e do `productmodel` (6
linhas fora do padrão, uma com **22** campos onde há 6). Habilitando `quote => '"'` as 65
tabelas ficam consistentes, nenhuma contagem muda, e o XML entra limpo em vez de escapado —
conferido campo a campo nas 17 da análise.

E a auditoria que deveria ter pego isso antes conferia apenas a **primeira linha** de cada
arquivo. Hoje o gerador confere **todas**, e falha alto se uma tabela tiver linhas com
contagens diferentes de campos.

**Dois erros no mapeamento de tipos, que só apareceram na execução.** O `decimal(p, s)` da
origem caía no fallback de texto, porque o mapeamento só reconhecia `numeric` sem precisão —
cinco colunas numéricas viravam `string` em silêncio (`perassemblyqty`, `availability`,
`actualresourcehrs`, `receivedqty`, `rejectedqty`). E a lista de colunas monetárias era aplicada
pelo **nome**, sem olhar o tipo de origem: `unitmeasurecode` é `char(3)` — código de unidade,
como `'EA '` — e virava `decimal(19, 4)`, estourando com `CAST_INVALID_INPUT`.

São 8 colunas afetadas, **nenhuma nas 17 da análise**. Hoje a lista de dinheiro só promove
coluna que já é numérica na origem, a precisão declarada é preservada, e o gerador **barra**
qualquer numérico que vire string ou textual que vire decimal — em vez de deixar isso aparecer
como erro no Databricks.

**`group by all` não é parseável pela 1.4.5**, e eu havia usado em 37 lugares. O guia da casa
também marca `group by 1, 2` como prática ruim — então a coluna vai escrita, uma por linha e com
vírgula à frente.

## Slides

As Etapas 1 e 2 têm dois decks cada, em `Desafio/entregaveis/`, **fora do controle de versão**:

| Arquivo | Slides |
|---|---|
| `Etapa1 - Secao do deck final.pptx` | 16 |
| `Etapa1 - Video.pptx` | 5 |
| `Etapa2 - Secao do deck final.pptx` | 16 |
| `Etapa2 - Video.pptx` | 5 |

As seções se concatenam no deck final; as versões de vídeo ocupam ~60 s cada, dentro dos 3 a 5
minutos que o briefing pede.

Ficam fora do git porque saem com a identidade visual da Indicium AI e logos de clientes reais, e
este repositório é público. Para revisar e exportar PDF, abrir no **Google Slides** — é lá que as
fontes da Indicium AI são nativas.

A seção da Etapa 2 **não repete** o que a da Etapa 1 já mostra (tipo de cartão, catálogo parado,
promoção por canal, a tabela dos nove indicadores). Ela mostra o que a exploração acrescentou: a
base conferida, a inversão de canal, a pulverização da receita, a quebra da série e as duas
decisões que vão para a modelagem.
