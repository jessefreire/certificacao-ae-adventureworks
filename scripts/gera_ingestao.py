# -*- coding: utf-8 -*-
"""Gera o notebook de ingestao do AdventureWorks no Databricks.

    python scripts/gera_ingestao.py [caminho-da-pasta-AdventureWorks]

A pasta padrao e a do clone local do repositorio oficial; passe outro caminho, ou
defina AW_HOME, se o seu clone estiver em outro lugar. O que importa e que a pasta
tenha `install.sql` e `data/`.

## Por que um gerador, e nao SQL escrito a mao

Sao 64 tabelas e 431 colunas. A fonte da verdade e o `install.sql` do repositorio
oficial: dele saem nome, ORDEM e tipo de cada coluna. Escrever isso a mao seria
convidar o desalinhamento silencioso — a carga e por POSICAO, porque os arquivos
nao tem linha de cabecalho.

## A decisao central: uma instrucao por tabela

Cada tabela e criada e carregada em UMA instrucao:

    create or replace table <tabela> as select <casts> from read_files(<arquivo>)

O desenho anterior separava `create or replace table` (DDL) de `copy into` (carga),
e essa separacao foi a origem do pior bug desta etapa: `COPY INTO` sempre
ACRESCENTA, e `force = true` desliga a idempotencia nativa dele. Rodar a carga sem
esvaziar a tabela antes duplicava as linhas — `address` chegou a 3x e
`employeepayhistory` a 5x, seguindo a orientacao errada de "repetir o arquivo depois
da falha".

Com `create or replace table ... as select`, duplicar passa a ser IMPOSSIVEL: a
instrucao substitui os dados em vez de somar. A protecao deixa de depender de
disciplina e passa a ser propriedade do codigo.

## Armadilhas do arquivo de origem, medidas nos proprios CSVs

  - separador TAB, apesar da extensao `.csv`, e SEM cabecalho
  - campo vazio precisa virar NULL. So no salesorderheader sao 27.659 salespersonid
    vazios. Sem `nullValue`, coluna int recebe 0 e "sem vendedor" viraria
    "vendedor 0" — um vendedor que nao existe, e a analise de canal iria por agua
  - `quote => '"'`, ou seja aspa CSV HABILITADA. Eu havia desabilitado, com o
    raciocinio de que o XML do `person` tem aspas dentro do campo. Estava errado: o
    arquivo escapa aquelas aspas duplicando-as, que e exatamente a convencao CSV.
    Habilitar corrigiu o `jobcandidate` e deixou o XML do `person` e do `store`
    entrar limpo em vez de escapado. Medido antes de mudar: nenhuma contagem de
    linha muda, e nas 17 da analise a unica diferenca de conteudo esta em coluna
    XML — conferido campo a campo. Nao resolveu o `productmodel`, que acabou em
    EXCLUIDAS.
  - `escape => '"'`, e nao a barra invertida que o Spark usa por padrao. O arquivo
    escapa aspa DUPLICANDO-a, convencao CSV, e nao com barra. Sem declarar isso, o
    leitor trata cada barra invertida do conteudo como escape e o registro se desfaz: o
    `jobcandidate` tem 86 barras invertidas e o `productmodel` 236, sempre dentro do
    XML. O `person` e o `store`, que carregaram bem, tem ZERO — foi essa assimetria
    que apontou a causa.
  - `mode => 'FAILFAST'`: linha ruim falha alto, em vez de virar NULL em silencio.
    Foi ele que pegou os dois problemas acima, e por isso fica
  - dinheiro em `decimal(19, 4)`, nunca `double`: o teste de aceite do briefing tem
    de fechar ao centavo, e a soma exata tem 4 casas decimais

## Sobre o linter

O arquivo gerado NAO passa pelo sqlfluff, e nao e por descuido: a versao 1.4.5, que
o guia da casa fixa, e de 2022 e nao parseia nem `COPY INTO` nem a sintaxe de
parametro nomeado do `read_files` (`format => 'csv'`). O `scripts/linta_notebook.py`
classifica celula por celula e exige que todas as demais passem.
"""
import csv
import os
import re
import sys
from pathlib import Path

# O console do Windows usa cp1252 e QUEBRA ao imprimir acento. Sem esta linha o
# script morre no meio do relatório com UnicodeEncodeError — e o erro parece ser
# do que ele estava conferindo, não da impressão.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent

PADRAO_ORIGEM = Path(
    r"D:\Documentos\Indicium AI\Formação AE\Desafio\adventureworks-oficial\AdventureWorks")
ORIGEM = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(os.environ.get("AW_HOME", PADRAO_ORIGEM))
SAIDA = REPO / "databricks" / "01-ingestao-adventure-works.sql"

CATALOGO = "workspace"
SCHEMA = "adventure_works"
ALVO = f"{CATALOGO}.{SCHEMA}"
VOLUME = f"/Volumes/{CATALOGO}/{SCHEMA}/raw_adventure_works/AdventureWorks/data"

# Não carregam, e o motivo e do arquivo de origem, não escolha nossa:
EXCLUIDAS = {
    "Document": "coluna binária (varbinary) não atravessa TSV",
    "ProductPhoto": "duas colunas binárias: ThumbNailPhoto e LargePhoto",
    "ProductReview": "arquivo quebrado na origem: 7 campos onde o DDL declara 8, "
                     "e quebra de linha dentro de campo (34 linhas para 31 registros)",
    "ProductModel": "o XML de CatalogDescription tem 48 TABs dentro de campo aspado, "
                    "e o leitor de CSV do Spark não honra a aspa nesse caso: 6 das 128 "
                    "linhas se partem, uma delas em 22 campos onde há 6 colunas. "
                    "Tentado com quote, com escape e sem: nenhuma combinação resolve. "
                    "O JobCandidate, que tem o mesmo tipo de XML mas UM tab, carrega "
                    "normalmente — então o limite e a quantidade, não a estrutura",
}

# As 17 que as seis perguntas do briefing e os catorze aprofundamentos usam. Vem
# primeiro no notebook: se a cota da Free Edition interromper a carga, para-se aqui
# com a Etapa 2 desbloqueada. São também as únicas que serão declaradas como source
# no dbt, porque declarar source e assumir teste e documentação.
ESCOPO_ANALISE = [
    "countryregion", "stateprovince", "address", "person", "store", "customer",
    "creditcard", "productcategory", "productsubcategory", "product", "specialoffer",
    "salesterritory", "salesperson", "salesreason", "salesorderheader",
    "salesorderdetail", "salesorderheadersalesreason",
]

DINHEIRO = {
    "unitprice", "unitpricediscount", "linetotal", "subtotal", "taxamt", "freight",
    "totaldue", "standardcost", "listprice", "salesquota", "bonus", "commissionpct",
    "salesytd", "saleslastyear", "costytd", "costlastyear", "discountpct", "weight",
    "rate", "taxrate", "averageleadtime", "lastreceiptcost", "minorderqty",
    "maxorderqty", "onorderqty", "actualcost", "unitmeasurecode",
}

# Palavras reservadas do Spark SQL / ANSI. Lista real, em vez de chute: das 203
# colunas distintas das 65 tabelas, só `group` e `primary` colidem — mas a lista
# inteira deixa o gerador seguro se o escopo crescer.
RESERVADAS = set("""all and any as asc at authorization between by case cast check
collate column commit constraint create cross cube current current_date current_time
current_timestamp current_user delete describe distinct drop else end escape except
exists external false fetch filter for foreign from full function global grant group
grouping having in inner insert intersect interval into is join lateral leading left
like limit local natural no not null of on only or order out outer overlaps partition
position primary references revoke right rollback rollup row rows select session_user
set some start table tablesample then time to trailing true truncate union unique
unknown update user using values when where window with""".split())

NOME_SCHEMA = {
    "Person": "Person — pessoas, endereço e geografia",
    "HumanResources": "HumanResources — funcionarios e departamentos",
    "Production": "Production — produto, categoria e produção",
    "Purchasing": "Purchasing — fornecedor e compras",
    "Sales": "Sales — pedido, item, cliente e território",
}


def ident(col):
    """Backtick só quando o nome e reservado. A camada bruta espelha a origem,
    inclusive nomes que são palavra reservada; o rename acontece no modelo de
    source do dbt, como o code style da casa manda."""
    c = col.lower()
    return f"`{c}`" if c in RESERVADAS else c


def e_numerico(tipo_pg):
    t = tipo_pg.strip().lower()
    return t.startswith(("decimal", "numeric", "money", "int", "smallint", "bigint",
                         "serial", "real", "double", "float"))


def tipo_databricks(nome_col, tipo_pg):
    """Traduz o tipo do install.sql (Postgres) para o do Databricks.

    Duas regras que a primeira versão errou, e as duas custaram carga interrompida:

    1. `decimal(p, s)` caia no fallback de texto, porque o mapeamento só reconhecia
       `numeric` sem precisão. Cinco colunas numéricas viravam string em silêncio —
       `perassemblyqty`, `availability`, `actualresourcehrs`, `receivedqty` e
       `rejectedqty`.
    2. a lista DINHEIRO era aplicada pelo NOME da coluna, sem olhar o tipo de
       origem. `unitmeasurecode` e `char(3)` — código de unidade, tipo 'EA' — e
       virava `decimal(19, 4)`. O cast estourava com CAST_INVALID_INPUT.

    Por isso a lista de dinheiro agora só vale quando a origem JÁ e numérica, e a
    precisão declarada na origem e preservada quando não e coluna de valor.
    """
    t = tipo_pg.strip().lower()
    c = nome_col.lower()

    m = re.match(r"(?:numeric|decimal)\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)", t)
    if m:
        return "decimal(19, 4)" if c in DINHEIRO else f"decimal({m.group(1)}, {m.group(2)})"
    if t.startswith(("numeric", "decimal", "money")):
        return "decimal(19, 4)"
    # DINHEIRO só pode promover coluna que já e numérica na origem
    if c in DINHEIRO and e_numerico(t):
        return "decimal(19, 4)"
    if t in ("serial", "int", "integer"):
        return "int"
    if t == "smallint":
        return "smallint"
    if t == "bigint":
        return "bigint"
    if t.startswith("timestamp") or t == "date":
        return "timestamp"
    if t in ("uuid", "xml"):
        return "string"
    if t == "boolean":
        return "boolean"
    if t.startswith(("varchar", "char", "text", "nvarchar", "name")):
        return "string"
    return "string"   # fallback consciente: nunca inventa tipo numérico


def tabelas_do_install(texto):
    """[(schema, tabela)] na ordem do arquivo."""
    schema, out = None, []
    for linha in texto.splitlines():
        m = re.match(r"\s*CREATE SCHEMA\s+(\w+)", linha, re.I)
        if m:
            schema = m.group(1)
            continue
        m = re.match(r"\s*CREATE TABLE\s+(\w+)\s*\(", linha, re.I)
        if m and schema:
            out.append((schema, m.group(1)))
    return out


def colunas(tabela, texto):
    m = re.search(rf"CREATE TABLE {tabela}\(\n(.*?)\n\s*\)", texto, re.S | re.I)
    if not m:
        return None
    cols = []
    for linha in m.group(1).split("\n"):
        s = linha.strip()
        if not s or s.upper().startswith("CONSTRAINT"):
            continue
        s = s.split("--")[0].rstrip().rstrip(",")
        if not s:
            continue
        mm = re.match(r'^"?(\w+)"?\s+([A-Za-z]+(?:\(\s*[\w,\s]+\))?)', s)
        if mm:
            cols.append((mm.group(1), mm.group(2)))
    return cols


def conta_linhas(arquivo):
    with open(ORIGEM / "data" / f"{arquivo}.csv", encoding="utf-8",
              errors="replace", newline="") as f:
        return sum(1 for r in csv.reader(f, delimiter="\t", quoting=csv.QUOTE_NONE) if r)


def campos_no_tsv(arquivo):
    """Quantos campos por linha o arquivo tem — conferindo TODAS as linhas.

    A primeira versão disto olhava só a primeira linha, e essa falha custou uma
    carga interrompida: o `jobcandidate` tem 12 linhas com 4 campos e UMA com 5,
    e o `productmodel` tem seis linhas fora do padrão, uma delas com 22 campos
    onde há 6 colunas. Com `mode = FAILFAST` — que e o certo — isso derruba a
    carga na linha ruim, e não no comeco.

    Lê com a aspa CSV habilitada, que e como o Databricks vai ler. Assim a
    conferência aqui e a carga la enxergam o mesmo arquivo.
    """
    with open(ORIGEM / "data" / f"{arquivo}.csv", encoding="utf-8",
              errors="replace", newline="") as f:
        contagens = {len(r) for r in csv.reader(f, delimiter="\t", quotechar='"') if r}
    assert len(contagens) == 1, (
        f"{arquivo}.csv tem linhas com contagens diferentes de campos: "
        f"{sorted(contagens)}. Com FAILFAST a carga vai quebrar. Ou a tabela entra "
        f"em EXCLUIDAS, ou o arquivo precisa de tratamento.")
    return contagens.pop()


def md(texto):
    return "\n".join(["-- MAGIC %md"] + [f"-- MAGIC {l}".rstrip() for l in texto.split("\n")])


def celula_da_tabela(schema, original, tabela, cols, titulo):
    """`título` e o DBTITLE, o nome da célula na navegação do Databricks.

    Formato `<seção>.<NN> NomeDaTabela`, sem o schema. O painel corta o título em
    torno de 22 caracteres, então o prefixo de schema (`Production.`) gastaria 11
    deles antes de chegar ao que distingue a célula. O schema continua visível no
    cabeçalho de markdown do bloco e no comentário da própria célula.
    """
    casts = [f"cast(_c{i} as {tipo_databricks(c, t)}) as {ident(c)}"
             for i, (c, t) in enumerate(cols)]
    return (
        f"-- DBTITLE 1,{titulo}\n"
        f"-- {schema}.{original}: {len(cols)} colunas\n"
        f"create or replace table {ALVO}.{tabela} as\n"
        f"select\n"
        f"    " + "\n    , ".join(casts) + "\n"
        f"from read_files(\n"
        f"    '{VOLUME}/{original}.csv'\n"
        f"    , format => 'csv'\n"
        f"    , sep => '\\t'\n"
        f"    , header => false\n"
        f"    , nullValue => ''\n"
        f"    , quote => '\"'\n"
        f"    , escape => '\"'\n"
        f"    , mode => 'FAILFAST'\n"
        f");"
    )


# ---------------------------------------------------------------- leitura da origem
assert (ORIGEM / "install.sql").exists(), (
    f"não achei install.sql em {ORIGEM}. Passe o caminho da pasta AdventureWorks "
    f"como argumento, ou defina AW_HOME.")

texto = (ORIGEM / "install.sql").read_text(encoding="utf-8", errors="replace")

tabelas, problemas = {}, []
for schema, original in tabelas_do_install(texto):
    if original in EXCLUIDAS:
        continue
    cols = colunas(original, texto)
    if not cols:
        problemas.append(f"{original}: não achei CREATE TABLE")
        continue
    n_tsv = campos_no_tsv(original)
    if n_tsv != len(cols):
        problemas.append(f"{original}: DDL {len(cols)} colunas, TSV {n_tsv} campos")

    # Um tipo numérico na origem nunca deve virar string, e um tipo textual nunca
    # deve virar decimal. As duas coisas aconteceram e derrubaram a carga, então
    # ficam barradas aqui em vez de aparecerem como erro no Databricks.
    for col, tp in cols:
        destino = tipo_databricks(col, tp)
        if e_numerico(tp) and destino == "string":
            problemas.append(f"{original}.{col}: origem {tp} numérica virou string")
        if not e_numerico(tp) and destino.startswith("decimal"):
            problemas.append(f"{original}.{col}: origem {tp} textual virou {destino}")

    tabelas[original.lower()] = (schema, original, cols)

assert not problemas, "divergência entre DDL e arquivo:\n  " + "\n  ".join(problemas)

faltando = [t for t in ESCOPO_ANALISE if t not in tabelas]
assert not faltando, f"tabela do escopo da análise que não existe no DDL: {faltando}"

# ---------------------------------------------------------------- abertura
celulas = [md(f"""# Ingestão do AdventureWorks

Cria e carrega a camada bruta no Unity Catalog. **Não e entregável do desafio** — o
briefing não pede artefato de ingestão —, e sim o pré-requisito para a Etapa 2. Roda
uma vez.

## Antes de rodar

A pasta `AdventureWorks` inteira precisa estar num Volume, subida com `Select folder`
(que preserva a estrutura de pastas):

    {VOLUME}/

Os nomes de tabela são absolutos (`{ALVO}.<tabela>`), então não depende de qual
catálogo esta selecionado no editor. O nome do schema não e escolha nossa: o briefing
determina `USE SOMENTE O SCHEMA adventure_works`.

## Repetir e seguro, e isso e por construção

Cada tabela e criada e carregada em **uma** instrução,
`create or replace table ... as select`. Repetir uma célula **substitui** os dados em
vez de somar, então não existe como duplicar.

O desenho anterior separava DDL e `COPY INTO`, e ai repetir a carga somava linhas —
`COPY INTO` sempre acrescenta, e `force = true` desliga a idempotência dele. Isso
chegou a deixar `address` com 3x e `employeepayhistory` com 5x as linhas. A proteção
agora e propriedade do código, não disciplina de quem roda.

## Onde rodar

**SQL Editor ou notebook**, mas a Free Edition esgota cota de compute e devolve
`RESOURCE_EXHAUSTED` — que chega disfarçado de `ValueError` do cliente gRPC. O
warehouse do SQL Editor e um pool separado do compute de notebook, com cota própria,
e foi por ele que a carga passou. Se estourar, espere e continue de onde parou: as
células são independentes.

## Ordem das seções

| Seção | Conteúdo |
|---|---|
| 1 | As **17 tabelas** que a análise usa. Parar aqui e um estado valido |
| 2 | As outras 48 da camada bruta, por schema de origem |
| 3 | As conferências. **Rodar antes de qualquer análise** |

## ⚠️ O que este notebook substitui, e o que NÃO rodar

Este arquivo consolida seis artefatos anteriores. Eles foram **mantidos de propósito**
no workspace, como registro do caminho — e por isso vale dizer alto o que fazer com
eles: **nada.** Nenhum deles deve ser executado.

| Artefato antigo | Por que não rodar |
|---|---|
| notebook `Ingestão Adventure Works` (células `01`, `01.01`, `02.01`) | superado pelas seções 1 e 3 daqui |
| query `02.00-carga-escopo-minimo.sql` | **DUPLICA** — usa `COPY INTO` com `force = true` |
| query `02.99-recarga-limpa.sql` | resolvia a duplicação que hoje não acontece mais |
| query `03-verificacao-da-carga.sql` | virou a seção 3 deste notebook |

O risco concreto: o `COPY INTO` daqueles arquivos **acrescenta** linhas, e o
`force = true` desliga a proteção que ignoraria arquivo já carregado. Rodar um deles
por engano soma a carga de novo — foi assim que `address` chegou a 3x e
`employeepayhistory` a 5x. Aqui isso não existe: `create or replace` substitui.

Se um dia a dúvida voltar, o sinal e este: contagem sendo **múltiplo exato** do
esperado (2x, 3x…) e duplicação, não dado corrompido.

## Este arquivo e gerado

Fonte: `scripts/gera_ingestao.py`, que lê o `install.sql` do repositório oficial —
de onde saem nome, ordem e tipo de cada coluna. Editar célula a mão cria duas versões
do mesmo SQL; para mudar algo, mude o gerador e regere.""")]

# ---------------------------------------------------------------- seção 1: escopo
celulas.append(md("""# 1. As 17 tabelas da análise

Vem primeiro de propósito. São as que as seis perguntas do briefing e os catorze
aprofundamentos da Etapa 1 exigem, e as únicas que serão declaradas como `source` no
dbt — declarar source e assumir o teste e a documentação dela.

Se a cota interromper a carga aqui, a Etapa 2 esta desbloqueada mesmo assim."""))

n_cast = 0
for n, tabela in enumerate(ESCOPO_ANALISE, 1):
    schema, original, cols = tabelas[tabela]
    celulas.append(celula_da_tabela(schema, original, tabela, cols,
                                    f"1.{n:02d} {original}"))
    n_cast += len(cols)

# ---------------------------------------------------------------- seção 2: o resto
resto = [t for t in tabelas if t not in ESCOPO_ANALISE]
por_schema = {}
for tabela in resto:
    por_schema.setdefault(tabelas[tabela][0], []).append(tabela)

celulas.append(md(f"""# 2. O resto da camada bruta

As outras {len(resto)} tabelas. Nenhuma pergunta do briefing usa, e a Etapa 2 não
depende delas — mas subir tudo que carrega custa quase nada (79 MB, 759 mil linhas) e
remove o atrito de ingestão se o trabalho crescer para compras ou produção.

Três tabelas ficam de fora das 68 do `install.sql`, por defeito de origem e não por
escolha:

""" + "\n".join(f"- **`{t}`** — {motivo}" for t, motivo in EXCLUIDAS.items())))

# a sequência da seção 2 corre pelas cinco subseções de schema sem reiniciar:
# o número tem de crescer junto com a ordem das células no notebook
n_resto = 0
for schema in ["Person", "HumanResources", "Production", "Purchasing", "Sales"]:
    if schema not in por_schema:
        continue
    celulas.append(md(f"## 2.{list(NOME_SCHEMA).index(schema) + 1} {NOME_SCHEMA[schema]}"))
    for tabela in por_schema[schema]:
        s, original, cols = tabelas[tabela]
        n_resto += 1
        celulas.append(celula_da_tabela(s, original, tabela, cols,
                                        f"2.{n_resto:02d} {original}"))
        n_cast += len(cols)

# ---------------------------------------------------------------- seção 3: conferências
celulas.append(md("""# 3. Posso confiar no que chegou?

Cinco conferências. **Se alguma falhar, não siga para a análise** — todo número da
exploração ficaria suspeito.

Os valores esperados estão embutidos no SQL, medidos nos próprios arquivos de origem.
Quem roda não precisa saber de cor que são 65 tabelas ou que a receita de 2011 e
12.646.112,16."""))

celulas.append("""-- DBTITLE 1,3.1 Tipo do dinheiro
-- 3.1 Dinheiro ficou exato? Tem de vir DECIMAL com 19 e 4 nas três.
--     Com double, o teste de aceite sai arredondado e a causa fica escondida no tipo.
select
    column_name
    , data_type
    , numeric_precision
    , numeric_scale
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal')
order by column_name asc;""")

linhas_esperadas = [(t, conta_linhas(tabelas[t][1])) for t in tabelas]
escopo = set(ESCOPO_ANALISE)
sel = "\n    union all\n".join(
    "    select\n"
    f"        '{t}' as tabela\n"
    f"        , '{'análise' if t in escopo else 'camada bruta'}' as escopo\n"
    f"        , {n} as esperado\n"
    "        , count(*) as carregado\n"
    f"    from {ALVO}.{t}"
    for t, n in linhas_esperadas)

celulas.append(f"""-- DBTITLE 1,3.2 Contagem por tabela
-- 3.2 A contagem bate com o arquivo de origem? As 17 da análise tem de dar `ok`.
--     `não carregada` em camada bruta e esperado se você parou na seção 1.
with contagem as (
{sel}
)

select
    tabela
    , escopo
    , esperado
    , carregado
    , case
        when esperado = carregado then 'ok'
        when carregado = 0 then 'nao carregada'
        else 'DIVERGE'
    end as resultado
from contagem
order by
    escopo asc
    , resultado desc
    , tabela asc;""")

JUNCOES = [
    ("pedido -> address", "salesorderheader", "address",
     "salesorderheader.billtoaddressid = address.addressid", "address.addressid is null"),
    ("pedido -> customer", "salesorderheader", "customer",
     "salesorderheader.customerid = customer.customerid", "customer.customerid is null"),
    ("pedido -> salesterritory", "salesorderheader", "salesterritory",
     "salesorderheader.territoryid = salesterritory.territoryid",
     "salesterritory.territoryid is null"),
    ("pedido -> creditcard (só quem tem cartão)", "salesorderheader", "creditcard",
     "salesorderheader.creditcardid = creditcard.creditcardid",
     "salesorderheader.creditcardid is not null\n    and creditcard.creditcardid is null"),
    ("item -> product", "salesorderdetail", "product",
     "salesorderdetail.productid = product.productid", "product.productid is null"),
    ("item -> specialoffer", "salesorderdetail", "specialoffer",
     "salesorderdetail.specialofferid = specialoffer.specialofferid",
     "specialoffer.specialofferid is null"),
]
blocos = [
    f"select\n    '{nome}' as juncao\n    , count(*) as orfaos\n"
    f"from {ALVO}.{esq}\nleft join {ALVO}.{dir}\n    on {cond}\nwhere {filtro}"
    for nome, esq, dir, cond, filtro in JUNCOES
]
blocos.append(
    "select\n    'cliente -> nome (person ou store)' as juncao\n    , count(*) as orfaos\n"
    f"from {ALVO}.customer\nleft join {ALVO}.person\n"
    "    on customer.personid = person.businessentityid\n"
    f"left join {ALVO}.store\n"
    "    on customer.storeid = store.businessentityid\n"
    "where person.businessentityid is null\n    and store.businessentityid is null")

celulas.append(
    "-- DBTITLE 1,3.3 As sete junções\n"
    "-- 3.3 As sete junções que a análise usa: alguma tem órfão? Tem de dar ZERO em todas.\n"
    "--     Todas deram zero nos arquivos antes da carga; diferente aqui significa carga errada.\n"
    + "\n\nunion all\n\n".join(blocos) + ";")

celulas.append(f"""-- DBTITLE 1,3.4 NULL sobreviveu
-- 3.4 O NULL sobreviveu? Tem de dar 27.659 sem vendedor e ZERO com vendedor 0.
--     Sem o nullValue, campo vazio em coluna int recebe 0 e inventa um vendedor.
select
    count(*) as pedidos
    , count(salespersonid) as com_vendedor
    , sum(case when salespersonid = 0 then 1 else 0 end) as vendedor_zero_suspeito
    , count(*) - count(salespersonid) as sem_vendedor_esperado_27659
from {ALVO}.salesorderheader;""")

celulas.append(f"""-- DBTITLE 1,3.5 Aceite do briefing
-- 3.5 O teste de aceite do briefing. Tem de dar FECHA.
--     Soma exata = 12646112.1607; o briefing informa arredondado a centavos, porque
--     unitprice tem 4 casas e 2.832 dos 5.642 itens de 2011 usam as quatro.
select
    12646112.16 as esperado_em_centavos
    , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
    , case
        when round(sum(salesorderdetail.unitprice * salesorderdetail.orderqty), 2)
            = 12646112.16
            then 'FECHA'
        else 'DIVERGE'
    end as resultado
from {ALVO}.salesorderdetail
inner join {ALVO}.salesorderheader
    on salesorderdetail.salesorderid = salesorderheader.salesorderid
where year(salesorderheader.orderdate) = 2011;""")

celulas.append(f"""-- DBTITLE 1,3.6 Integridade linetotal
-- 3.6 A integridade do linetotal. Tem de dar 121317 linhas e ZERO fora de um centavo.
--     Nesta base o campo vem do arquivo, não e calculado pelo banco.
select
    count(*) as linhas
    , sum(
        case
            when abs(
                salesorderdetail.unitprice
                * (1 - salesorderdetail.unitpricediscount)
                * salesorderdetail.orderqty
                - salesorderdetail.linetotal
            ) > 0.01 then 1
            else 0
        end
    ) as fora_de_um_centavo
from {ALVO}.salesorderdetail;""")

celulas.append(md("""# Fim da ingestão

Com as conferências passando, a base esta confiável e a análise exploratória pode
começar em `databricks/02-analise-exploratoria.py`."""))

# ---------------------------------------------------------------- escrita e asseguração
fonte = "-- Databricks notebook source\n" + "\n\n-- COMMAND ----------\n\n".join(celulas) + "\n"
SAIDA.parent.mkdir(parents=True, exist_ok=True)
SAIDA.write_text(fonte, encoding="utf-8")

# Só instrução de verdade: linha que COMEÇA com o comando. Contar no texto inteiro
# pegaria também a menção em prosa dentro das células de markdown.
codigo = [l for l in fonte.split("\n") if not l.startswith("-- MAGIC")]
n_tabelas = sum(1 for l in codigo if l.startswith("create or replace table "))
n_casts_no_arquivo = sum(l.count("cast(_c") for l in codigo)
# Coerência entre o que a memória contou e o que foi escrito no arquivo. Sem número
# fixo: o escopo muda quando uma tabela entra em EXCLUIDAS, e um número cravado aqui
# viraria mentira silenciosa. O piso de 400 casts pega perda grosseira.
assert n_tabelas == len(tabelas), f"{n_tabelas} create no arquivo, {len(tabelas)} em memória"
assert n_casts_no_arquivo == n_cast, f"{n_casts_no_arquivo} casts no arquivo, {n_cast} contados"
assert n_tabelas >= 60 and n_cast >= 400, f"perda de escopo: {n_tabelas} tabelas, {n_cast} casts"

# `copy into` e `force` são os dois sinais do desenho antigo, que duplicava linhas.
sql = "\n".join(codigo).lower()
assert "copy into" not in sql, "sobrou COPY INTO — o desenho antigo voltou"
assert "force" not in sql, "sobrou `force` — o desenho antigo voltou"

# uma instrução por célula: e o que o `%sql` executa com segurança
for i, celula in enumerate(fonte.split("\n\n-- COMMAND ----------\n\n")):
    if celula.lstrip().startswith(("-- MAGIC", "-- Databricks notebook source\n-- MAGIC")):
        continue
    sem_comentario = "\n".join(
        l.split("--")[0] for l in celula.split("\n") if not l.strip().startswith("--"))
    n = sem_comentario.count(";")
    assert n == 1, f"célula {i} tem {n} instruções, esperava 1:\n{celula[:200]}"

print(f"OK -> {SAIDA.relative_to(REPO)}")
print(f"tabelas: {n_tabelas}  |  casts: {n_casts_no_arquivo}  |  células: {len(celulas)}")
print(f"  seção 1 (análise): {len(ESCOPO_ANALISE)}  |  seção 2 (resto): {len(resto)}")
