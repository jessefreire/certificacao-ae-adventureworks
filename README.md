# Desafio Final — Adventure Works

Projeto de certificação da Formação Analytics Engineer (Indicium). Constrói uma plataforma de
dados para a área comercial da Adventure Works: modelagem dimensional, transformação em dbt com
testes e documentação, e dashboard.

## O que rodar, em ordem

São **dois** arquivos, e os dois são notebooks do Databricks (`Workspace → Import → File`):

| # | Arquivo | O que é |
|---|---|---|
| 1 | [`databricks/ingestao-adventure-works.sql`](databricks/ingestao-adventure-works.sql) | Cria e carrega a camada bruta. **Pré-requisito**, roda uma vez |
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
| 2 | Análise exploratória | [`databricks/02-analise-exploratoria.py`](databricks/02-analise-exploratoria.py) | escrita, falta executar |
| 3 | Modelo conceitual | PDF | — |
| 4 | DW na nuvem + dbt | Databricks Free Edition + dbt Cloud | ingestão feita |
| 5 | Transformação dbt | modelos, docs, testes de source/PK/qualidade | — |
| 6 | Mockup do dashboard | JPEG, no Figma | — |
| 7 | Dashboard | Power BI ou Databricks AI/BI | — |
| 8 | Regras de negócio | documento | — |
| 9 | Apresentação | slides | seção da Etapa 1 pronta |
| 10 | Vídeo | 3-5 min | — |
| 11 | Planejamento do projeto | PDF — opcional | — |

## Os oito entregáveis, e onde cada um está

A seção 5 do briefing é a lista fechada do que se submete, e `"adesão aos requisitos de
entrega"` é critério de nota. O mapa 1:1:

| O briefing pede | Onde está |
|---|---|
| Notebook da análise exploratória, em Python ou SQL, com código, gráficos e comentário por insight | `databricks/02-analise-exploratoria.py` |
| Link do repositório com os modelos dbt | `entrega/links.txt` — projeto dbt pendente |
| PDF do modelo conceitual | pendente, Etapa 3 |
| JPEG do mockup, feito no Figma | pendente, Etapa 6 |
| PBIX com as medidas DAX documentadas dentro do arquivo, **ou** link + JSON do AI/BI | pendente, Etapa 7 |
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

Um notebook, [`databricks/ingestao-adventure-works.sql`](databricks/ingestao-adventure-works.sql),
com 81 células em três seções: as **17 tabelas que a análise usa**, as **48 restantes** da camada
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

Repetir uma célula **substitui** os dados em vez de somar. Não existe como duplicar. É a
correção do pior erro desta etapa, e ela vive no código em vez de depender de quem roda — ver
[Armadilhas pagas](#armadilhas-pagas).

O cast explícito por posição existe porque os arquivos **não têm linha de cabeçalho**: o
Databricks lê as colunas como `_c0`, `_c1`, e a única fonte da verdade sobre qual é qual é a
ordem do `install.sql`. São 437 colunas nomeadas uma a uma — dinheiro em `decimal(19, 4)`, nunca
`double`.

### Parar na seção 1 é um estado válido

As 17 tabelas da análise vêm primeiro **de propósito**. A Free Edition esgota cota de compute, e
parar ali deixa a Etapa 2 desbloqueada. As outras 48 não são usadas por nenhuma pergunta do
briefing — sobem porque custam quase nada (79 MB, 759 mil linhas) e removem o atrito de ingestão
se o trabalho crescer para compras ou produção.

O escopo **modelado** é outra decisão: só as 17 serão declaradas como `source` no dbt, porque
declarar source é assumir o teste e a documentação dela.

### Três tabelas ficam de fora, por defeito de origem

`Document` e `ProductPhoto` têm coluna binária, que não atravessa arquivo de texto.
`ProductReview` está quebrado na origem: sete campos onde o DDL declara oito, e quebra de linha
dentro de campo — 34 linhas físicas para 31 registros.

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

Resultado da última execução: **todas passaram.**

## Análise exploratória (Etapa 2)

[`databricks/02-analise-exploratoria.py`](databricks/02-analise-exploratoria.py) — 76 células:
40 de markdown, 31 de SQL e 5 de gráfico. Linguagem padrão **Python**, porque os gráficos
exigem, com o SQL em células `%sql`.

**A pergunta não se descobre nele.** A estrutura segue a Etapa 1: perfil do dado, reconciliação
com o número do CEO, e então uma seção por pergunta do briefing com seus aprofundamentos
(`a.1`…`f.2`), cada um com consulta, evidência e comentário.

O que cada seção entrega além da resposta é o aviso que impede a leitura errada: motivo de venda
existe só no online, o ticket por país varia por mistura de canal, as cinco maiores cidades são
11% da receita, e a série tem quebra estrutural em jul/2013.

## Convenções de código

Segue o [`indicium-code-style`](https://github.com/indiciumtech/indicium-code-style): prefixos
`stg_`/`dim_`/`fact_`/`agg_`/`bridge_`, sqlfluff 1.4.5, 4 espaços, ≤100 colunas, vírgula à
frente, `inner join` explícito, `group by` com a coluna escrita — nem ordinal, nem `all`.

Toda consulta vem comentada, em uma ou duas linhas, dizendo **o que se confere** e **qual o
valor esperado**. Comentário curto: o objetivo é entender a consulta de relance.

### O linter alcança o SQL de dentro dos notebooks

```bash
python scripts/linta_notebook.py          # confere
python scripts/linta_notebook.py --fix    # corrige e devolve às células
```

O sqlfluff não lê notebook. A ferramenta extrai cada célula para um arquivo, roda o linter, e
com `--fix` devolve o SQL corrigido. Cobertura atual: **31 de 31** células do notebook de
análise e **6 de 6** células de conferência da ingestão, zero violação.

As 65 células de ingestão **não** são linteadas, e isso é declarado em vez de escondido: a
versão 1.4.5 não parseia `read_files(format => 'csv')` nem `COPY INTO`. A ferramenta separa as
duas famílias e conta cada uma, em vez de excluir o arquivo inteiro do lint.

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

**`group by all` não é parseável pela 1.4.5**, e eu havia usado em 37 lugares. O guia da casa
também marca `group by 1, 2` como prática ruim — então a coluna vai escrita, uma por linha e com
vírgula à frente.

## Slides

A Etapa 1 tem dois decks, em `Desafio/entregaveis/`, **fora do controle de versão**: a seção do
deck final (16 slides) e a versão para o vídeo (5 slides). Ficam fora do git porque saem com a
identidade visual da Indicium e logos de clientes reais, e este repositório é público. Para
revisar e exportar PDF, abrir no **Google Slides** — é lá que as fontes da Indicium são nativas.
