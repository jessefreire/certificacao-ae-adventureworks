# Desafio Final — Adventure Works

Projeto de certificação da Formação Analytics Engineer (Indicium). Constrói uma plataforma
de dados para a área comercial da Adventure Works: modelagem dimensional, transformação em
dbt com testes e documentação, e dashboard.

## Etapas

| # | Etapa | Entregável | Status |
|---|---|---|---|
| 1 | KPIs e perguntas de negócio | [`docs/01-kpis-e-perguntas.md`](docs/01-kpis-e-perguntas.md) · [mapa](docs/01.01-mapa-completo.md) · slides (fora do git, ver abaixo) | **completa** |
| 2 | Análise exploratória | [`databricks/`](databricks/) (ingestão, pronta: notebook + 3 scripts) + notebook de EDA | **em andamento** |
| 3 | Modelo conceitual | PDF | — |
| 4 | DW na nuvem + dbt | Databricks Free Edition + dbt Cloud | — |
| 5 | Transformação dbt | modelos, docs, testes de source/PK/qualidade | — |
| 6 | Mockup do dashboard | JPEG | — |
| 7 | Dashboard | Power BI ou Databricks AI/BI | — |
| 8 | Regras de negócio | documento | — |
| 9 | Apresentação | slides | — |
| 10 | Vídeo | 3-5 min | — |
| 11 | Planejamento do projeto | PDF — opcional | — |

## Base de dados

[`dpavancini/analytics-engineering/AdventureWorks`](https://github.com/dpavancini/analytics-engineering/tree/main/AdventureWorks)
— `install.sql` (68 tabelas em 5 schemas: Person, HumanResources, Production, Purchasing,
Sales) e `data/` com 72 TSV. Clone local fora do git, em
`Desafio/adventureworks-oficial/`.

## Slides

A Etapa 1 tem dois decks, em `Desafio/entregaveis/` **fora do controle de versão**:

| Arquivo | O que é |
|---|---|
| `Etapa1 - Secao do deck final.pptx` | 16 slides, sem capa e sem encerramento. É a seção 01 do deck final; as etapas seguintes se concatenam nele. |
| `Etapa1 - Video.pptx` | 5 slides, para o trecho de ~60 s que a Etapa 1 ocupa no vídeo. |

Ficam fora do git porque saem com a identidade visual da Indicium e logos de
clientes reais, e este repositório é público. Gerados com a skill
`indicium-slide-creator` (caminho `scripts/components.js`), fontes embutidas.
Para revisar e exportar PDF, abrir no **Google Slides** — é lá que as fontes da
Indicium são nativas.

## Ingestão no Databricks

Os scripts de `databricks/` são a etapa de EL. Os nomes de tabela são absolutos
(`workspace.adventure_works.<tabela>`), então não depende do catálogo selecionado.

**A forma recomendada de rodar** é importar
[`00-ingestao-adventure-works.sql`](databricks/00-ingestao-adventure-works.sql) como
notebook no Databricks (`Workspace → Import → File`). São 149 células: 11 de markdown
explicando cada bloco e 138 de SQL, **uma instrução por célula**. Isso não é enfeite — o
`COPY INTO` roda com `mode = FAILFAST`, e com as 65 cargas numa célula só a falha diria
"deu erro" sem dizer em qual tabela.

Esse notebook é **gerado** a partir dos arquivos abaixo, que continuam sendo a fonte
versionada e linteada. Editar célula à mão cria duas versões do mesmo SQL; para mudar algo,
muda-se o gerador e regera. Rodar tudo de novo é seguro: `create or replace` e
`force = true` recriam e recarregam do Volume, chegando ao mesmo resultado — o custo é
tempo, não perda, porque o dado bruto mora no Volume.

Alternativa: colar cada arquivo num editor SQL, na ordem.

| # | Arquivo | O que faz |
|---|---|---|
| 1 | [`01-ddl-adventure-works.sql`](databricks/01-ddl-adventure-works.sql) | 65 tabelas vazias. Traduz o `install.sql` (Postgres) para Databricks. Dinheiro em `decimal(19, 4)`, nunca `double` |
| 1.1 | [`01.01-conferencia-da-estrutura.sql`](databricks/01.01-conferencia-da-estrutura.sql) | 3 conferências antes de carregar 79 MB: as 65 tabelas nasceram, dinheiro veio `DECIMAL` e a precisão é 19 e 4 |
| 2.0 | [`02.00-carga-escopo-minimo.sql`](databricks/02.00-carga-escopo-minimo.sql) | **Atalho.** Só as 17 tabelas que a análise usa, para a Etapa 2 andar quando a cota não permite a carga completa. Não substitui 2.1–2.5 |
| 2.1 | [`02.01-carga-person.sql`](databricks/02.01-carga-person.sql) | 13 tabelas. `Person` guarda `address`, `stateprovince` e `countryregion` — sem ele não existe corte por cidade, estado ou país |
| 2.2 | [`02.02-carga-human-resources.sql`](databricks/02.02-carga-human-resources.sql) | 6 tabelas |
| 2.3 | [`02.03-carga-production.sql`](databricks/02.03-carga-production.sql) | 22 tabelas. É onde vive a hierarquia produto → subcategoria → categoria |
| 2.4 | [`02.04-carga-purchasing.sql`](databricks/02.04-carga-purchasing.sql) | 5 tabelas |
| 2.5 | [`02.05-carga-sales.sql`](databricks/02.05-carga-sales.sql) | 19 tabelas. O núcleo do desafio: pedido, item, motivo de venda, oferta, território |
| 3 | [`03-verificacao-da-carga.sql`](databricks/03-verificacao-da-carga.sql) | 5 conferências. Roda **antes** de qualquer análise: se falhar, todo número da exploração fica suspeito |

### O `RESOURCE_EXHAUSTED` da Free Edition

O erro que mais atrapalha esta etapa. Chega **disfarçado** de
`ValueError: Code in Status proto (StatusCode.INTERNAL) doesn't match status code
(StatusCode.RESOURCE_EXHAUSTED)` — o `ValueError` é o cliente gRPC se confundindo ao
traduzir o status; a informação real é o `RESOURCE_EXHAUSTED` no fim da linha.

**Não é erro de dado.** O SQL está correto; o compute recusou por cota.

E não é questão de tamanho do lote — foi a nossa primeira hipótese e ela é **falsa**.
Medido aqui: 13 instruções passaram, 6 falharam em seguida, e uma instrução sozinha
carregando 13 linhas (`jobcandidate`) também falhou. O consumo é **acumulado na sessão**,
não por comando.

O que de fato ajuda, em ordem:

1. **Rodar no SQL Editor, não no notebook.** O SQL warehouse é um pool de recursos
   separado do compute de notebook, com cota própria. `COPY INTO` é SQL puro e não
   precisa de Spark Connect. Se o traceback do erro mencionar
   `pyspark/sql/connect`, você está no compute de notebook.
2. **`Detach & re-attach`** no compute, se ficar no notebook. Zera a sessão, que é
   diferente de apenas esperar.
3. **Carregar só o escopo da análise** (`02.00`), 17 tabelas em vez de 65, e completar
   a camada bruta quando a cota renovar.

Repetir um arquivo depois de falha é sempre seguro: `force = true` reescreve a tabela em
vez de duplicar.

### Por que a carga vem em cinco arquivos

O corte segue os cinco schemas da origem — os mesmos que o briefing descreve —, então
cada arquivo é uma área do negócio e nomeia o que carrega. Isso vale por documentação e
por permitir retomar de onde parou, mas **não** foi o que resolveu o
`RESOURCE_EXHAUSTED`.

### Antes de rodar

Os arquivos brutos vão para um Volume do Unity Catalog, subindo a pasta `AdventureWorks`
**inteira** (`Select folder`), que preserva a estrutura. Caminho gravado nos 65 comandos:

```
/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/<Tabela>.csv
```

Se os arquivos estiverem em outro caminho, os scripts são regerados a partir de uma única
variável — não se ajustam 65 caminhos à mão.

O nome do schema não é escolha: o briefing determina `USE SOMENTE O SCHEMA adventure_works`.
O nome do volume segue o padrão `raw_<fonte>` do `2.5) Como definir os schemas padrão` do
referencial de processos, aplicado ao volume porque o schema já estava fixado pelo briefing.

### Três tabelas ficam de fora, por defeito de origem

`Document` e `ProductPhoto` têm coluna binária, que não atravessa um arquivo de texto.
`ProductReview` está quebrado na origem: sete campos onde o DDL declara oito, e quebra de
linha dentro de campo (34 linhas físicas para 31 registros).

A camada bruta sobe completa de propósito — 79 MB e 759 mil linhas custam quase nada, e
remove o atrito de ingestão se o trabalho crescer para compras ou produção. O escopo
**modelado** é outra decisão, e segue restrito a 17 tabelas: declarar uma tabela como
source no dbt é assumir o teste e a documentação dela.

### Linter

`sqlfluff 1.4.5`, configurado na raiz. O `02` está no `.sqlfluffignore` porque essa versão
não parseia `COPY INTO`.

```bash
uvx --from "sqlfluff==1.4.5" --with "click<8.1" sqlfluff lint databricks/
```

Duas armadilhas já pagas: o limite padrão de 20.000 bytes faz o linter **pular** arquivo
grande em silêncio, terminando com `All Finished!` sem ter checado nada — está desligado no
`.sqlfluff`. E a saída crua dos geradores **não** passa no linter: o arquivo entregue é o
resultado de `sqlfluff fix --force` sobre ela.

## Convenções de código

Segue o [`indicium-code-style`](https://bitbucket.org/indiciumtech/indicium-code-style):
prefixos `stg_`/`dim_`/`fact_`/`agg_`/`bridge_`, sqlfluff 1.4.5, 4 espaços, ≤100 colunas,
vírgula à frente, `inner join` explícito.

Toda consulta deste repositório vem comentada, em uma ou duas linhas, dizendo **o que se
confere** e **qual o valor esperado**. Comentário curto: o objetivo é entender a consulta
de relance, não ler um parágrafo antes de rodá-la.

Detalhes de cada decisão, e o que ainda está aberto, ficam nos anexos do documento da
Etapa 1.
