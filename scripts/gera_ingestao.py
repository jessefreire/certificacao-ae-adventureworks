# -*- coding: utf-8 -*-
"""Gera o notebook de ingestao do AdventureWorks no Databricks.

    python scripts/gera_ingestao.py [caminho-da-pasta-AdventureWorks]

A pasta padrao e a do clone local do repositorio oficial; passe outro caminho, ou
defina AW_HOME, se o seu clone estiver em outro lugar. O que importa e que a pasta
tenha `install.sql` e `data/`.

## Por que um gerador, e nao SQL escrito a mao

Sao 65 tabelas e 437 colunas. A fonte da verdade e o `install.sql` do repositorio
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
    Desabilitar a aspa fazia o TAB dentro do XML partir o campo, e o FAILFAST
    derrubava a carga do `jobcandidate` (1 linha ruim) e do `productmodel` (6, uma
    delas com 22 campos onde ha 6 colunas). Com a aspa habilitada, as 65 tabelas
    ficam consistentes, nenhuma contagem muda, e o XML entra limpo em vez de
    escapado — conferido campo a campo nas 17 da analise.
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

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent

PADRAO_ORIGEM = Path(
    r"D:\Documentos\Indicium AI\Formação AE\Desafio\adventureworks-oficial\AdventureWorks")
ORIGEM = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(os.environ.get("AW_HOME", PADRAO_ORIGEM))
SAIDA = REPO / "databricks" / "ingestao-adventure-works.sql"

CATALOGO = "workspace"
SCHEMA = "adventure_works"
ALVO = f"{CATALOGO}.{SCHEMA}"
VOLUME = f"/Volumes/{CATALOGO}/{SCHEMA}/raw_adventure_works/AdventureWorks/data"

# Nao carregam, e o motivo e do arquivo de origem, nao escolha nossa:
EXCLUIDAS = {
    "Document": "coluna binaria (varbinary) nao atravessa TSV",
    "ProductPhoto": "duas colunas binarias: ThumbNailPhoto e LargePhoto",
    "ProductReview": "arquivo quebrado na origem: 7 campos onde o DDL declara 8, "
                     "e quebra de linha dentro de campo (34 linhas para 31 registros)",
}

# As 17 que as seis perguntas do briefing e os catorze aprofundamentos usam. Vem
# primeiro no notebook: se a cota da Free Edition interromper a carga, para-se aqui
# com a Etapa 2 desbloqueada. Sao tambem as unicas que serao declaradas como source
# no dbt, porque declarar source e assumir teste e documentacao.
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
# colunas distintas das 65 tabelas, so `group` e `primary` colidem — mas a lista
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
    "Person": "Person — pessoas, endereco e geografia",
    "HumanResources": "HumanResources — funcionarios e departamentos",
    "Production": "Production — produto, categoria e producao",
    "Purchasing": "Purchasing — fornecedor e compras",
    "Sales": "Sales — pedido, item, cliente e territorio",
}


def ident(col):
    """Backtick so quando o nome e reservado. A camada bruta espelha a origem,
    inclusive nomes que sao palavra reservada; o rename acontece no modelo de
    source do dbt, como o code style da casa manda."""
    c = col.lower()
    return f"`{c}`" if c in RESERVADAS else c


def e_numerico(tipo_pg):
    t = tipo_pg.strip().lower()
    return t.startswith(("decimal", "numeric", "money", "int", "smallint", "bigint",
                         "serial", "real", "double", "float"))


def tipo_databricks(nome_col, tipo_pg):
    """Traduz o tipo do install.sql (Postgres) para o do Databricks.

    Duas regras que a primeira versao errou, e as duas custaram carga interrompida:

    1. `decimal(p, s)` caia no fallback de texto, porque o mapeamento so reconhecia
       `numeric` sem precisao. Cinco colunas numericas viravam string em silencio —
       `perassemblyqty`, `availability`, `actualresourcehrs`, `receivedqty` e
       `rejectedqty`.
    2. a lista DINHEIRO era aplicada pelo NOME da coluna, sem olhar o tipo de
       origem. `unitmeasurecode` e `char(3)` — codigo de unidade, tipo 'EA' — e
       virava `decimal(19, 4)`. O cast estourava com CAST_INVALID_INPUT.

    Por isso a lista de dinheiro agora so vale quando a origem JA e numerica, e a
    precisao declarada na origem e preservada quando nao e coluna de valor.
    """
    t = tipo_pg.strip().lower()
    c = nome_col.lower()

    m = re.match(r"(?:numeric|decimal)\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)", t)
    if m:
        return "decimal(19, 4)" if c in DINHEIRO else f"decimal({m.group(1)}, {m.group(2)})"
    if t.startswith(("numeric", "decimal", "money")):
        return "decimal(19, 4)"
    # DINHEIRO so pode promover coluna que ja e numerica na origem
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
    return "string"   # fallback consciente: nunca inventa tipo numerico


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

    A primeira versao disto olhava so a primeira linha, e essa falha custou uma
    carga interrompida: o `jobcandidate` tem 12 linhas com 4 campos e UMA com 5,
    e o `productmodel` tem seis linhas fora do padrao, uma delas com 22 campos
    onde ha 6 colunas. Com `mode = FAILFAST` — que e o certo — isso derruba a
    carga na linha ruim, e nao no comeco.

    Le com a aspa CSV habilitada, que e como o Databricks vai ler. Assim a
    conferencia aqui e a carga la enxergam o mesmo arquivo.
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


def celula_da_tabela(schema, original, tabela, cols):
    casts = [f"cast(_c{i} as {tipo_databricks(c, t)}) as {ident(c)}"
             for i, (c, t) in enumerate(cols)]
    return (
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
    f"nao achei install.sql em {ORIGEM}. Passe o caminho da pasta AdventureWorks "
    f"como argumento, ou defina AW_HOME.")

texto = (ORIGEM / "install.sql").read_text(encoding="utf-8", errors="replace")

tabelas, problemas = {}, []
for schema, original in tabelas_do_install(texto):
    if original in EXCLUIDAS:
        continue
    cols = colunas(original, texto)
    if not cols:
        problemas.append(f"{original}: nao achei CREATE TABLE")
        continue
    n_tsv = campos_no_tsv(original)
    if n_tsv != len(cols):
        problemas.append(f"{original}: DDL {len(cols)} colunas, TSV {n_tsv} campos")

    # Um tipo numerico na origem nunca deve virar string, e um tipo textual nunca
    # deve virar decimal. As duas coisas aconteceram e derrubaram a carga, entao
    # ficam barradas aqui em vez de aparecerem como erro no Databricks.
    for col, tp in cols:
        destino = tipo_databricks(col, tp)
        if e_numerico(tp) and destino == "string":
            problemas.append(f"{original}.{col}: origem {tp} numerica virou string")
        if not e_numerico(tp) and destino.startswith("decimal"):
            problemas.append(f"{original}.{col}: origem {tp} textual virou {destino}")

    tabelas[original.lower()] = (schema, original, cols)

assert not problemas, "divergencia entre DDL e arquivo:\n  " + "\n  ".join(problemas)

faltando = [t for t in ESCOPO_ANALISE if t not in tabelas]
assert not faltando, f"tabela do escopo da analise que nao existe no DDL: {faltando}"

# ---------------------------------------------------------------- abertura
celulas = [md(f"""# Ingestao do AdventureWorks

Cria e carrega a camada bruta no Unity Catalog. **Nao e entregavel do desafio** — o
briefing nao pede artefato de ingestao —, e sim o pre-requisito para a Etapa 2. Roda
uma vez.

## Antes de rodar

A pasta `AdventureWorks` inteira precisa estar num Volume, subida com `Select folder`
(que preserva a estrutura de pastas):

    {VOLUME}/

Os nomes de tabela sao absolutos (`{ALVO}.<tabela>`), entao nao depende de qual
catalogo esta selecionado no editor. O nome do schema nao e escolha nossa: o briefing
determina `USE SOMENTE O SCHEMA adventure_works`.

## Repetir e seguro, e isso e por construcao

Cada tabela e criada e carregada em **uma** instrucao,
`create or replace table ... as select`. Repetir uma celula **substitui** os dados em
vez de somar, entao nao existe como duplicar.

O desenho anterior separava DDL e `COPY INTO`, e ai repetir a carga somava linhas —
`COPY INTO` sempre acrescenta, e `force = true` desliga a idempotencia dele. Isso
chegou a deixar `address` com 3x e `employeepayhistory` com 5x as linhas. A protecao
agora e propriedade do codigo, nao disciplina de quem roda.

## Onde rodar

**SQL Editor ou notebook**, mas a Free Edition esgota cota de compute e devolve
`RESOURCE_EXHAUSTED` — que chega disfarcado de `ValueError` do cliente gRPC. O
warehouse do SQL Editor e um pool separado do compute de notebook, com cota propria,
e foi por ele que a carga passou. Se estourar, espere e continue de onde parou: as
celulas sao independentes.

## Ordem das secoes

| Secao | Conteudo |
|---|---|
| 1 | As **17 tabelas** que a analise usa. Parar aqui e um estado valido |
| 2 | As outras 48 da camada bruta, por schema de origem |
| 3 | As conferencias. **Rodar antes de qualquer analise** |

## ⚠️ O que este notebook substitui, e o que NAO rodar

Este arquivo consolida seis artefatos anteriores. Eles foram **mantidos de proposito**
no workspace, como registro do caminho — e por isso vale dizer alto o que fazer com
eles: **nada.** Nenhum deles deve ser executado.

| Artefato antigo | Por que nao rodar |
|---|---|
| notebook `Ingestao Adventure Works` (celulas `01`, `01.01`, `02.01`) | superado pelas secoes 1 e 3 daqui |
| query `02.00-carga-escopo-minimo.sql` | **DUPLICA** — usa `COPY INTO` com `force = true` |
| query `02.99-recarga-limpa.sql` | resolvia a duplicacao que hoje nao acontece mais |
| query `03-verificacao-da-carga.sql` | virou a secao 3 deste notebook |

O risco concreto: o `COPY INTO` daqueles arquivos **acrescenta** linhas, e o
`force = true` desliga a protecao que ignoraria arquivo ja carregado. Rodar um deles
por engano soma a carga de novo — foi assim que `address` chegou a 3x e
`employeepayhistory` a 5x. Aqui isso nao existe: `create or replace` substitui.

Se um dia a duvida voltar, o sinal e este: contagem sendo **multiplo exato** do
esperado (2x, 3x…) e duplicacao, nao dado corrompido.

## Este arquivo e gerado

Fonte: `scripts/gera_ingestao.py`, que le o `install.sql` do repositorio oficial —
de onde saem nome, ordem e tipo de cada coluna. Editar celula a mao cria duas versoes
do mesmo SQL; para mudar algo, mude o gerador e regere.""")]

# ---------------------------------------------------------------- secao 1: escopo
celulas.append(md("""# 1. As 17 tabelas da analise

Vem primeiro de proposito. Sao as que as seis perguntas do briefing e os catorze
aprofundamentos da Etapa 1 exigem, e as unicas que serao declaradas como `source` no
dbt — declarar source e assumir o teste e a documentacao dela.

Se a cota interromper a carga aqui, a Etapa 2 esta desbloqueada mesmo assim."""))

n_cast = 0
for tabela in ESCOPO_ANALISE:
    schema, original, cols = tabelas[tabela]
    celulas.append(celula_da_tabela(schema, original, tabela, cols))
    n_cast += len(cols)

# ---------------------------------------------------------------- secao 2: o resto
resto = [t for t in tabelas if t not in ESCOPO_ANALISE]
por_schema = {}
for tabela in resto:
    por_schema.setdefault(tabelas[tabela][0], []).append(tabela)

celulas.append(md(f"""# 2. O resto da camada bruta

As outras {len(resto)} tabelas. Nenhuma pergunta do briefing usa, e a Etapa 2 nao
depende delas — mas subir tudo que carrega custa quase nada (79 MB, 759 mil linhas) e
remove o atrito de ingestao se o trabalho crescer para compras ou producao.

Tres tabelas ficam de fora das 68 do `install.sql`, por defeito de origem e nao por
escolha:

""" + "\n".join(f"- **`{t}`** — {motivo}" for t, motivo in EXCLUIDAS.items())))

for schema in ["Person", "HumanResources", "Production", "Purchasing", "Sales"]:
    if schema not in por_schema:
        continue
    celulas.append(md(f"## 2.{list(NOME_SCHEMA).index(schema) + 1} {NOME_SCHEMA[schema]}"))
    for tabela in por_schema[schema]:
        s, original, cols = tabelas[tabela]
        celulas.append(celula_da_tabela(s, original, tabela, cols))
        n_cast += len(cols)

# ---------------------------------------------------------------- secao 3: conferencias
celulas.append(md("""# 3. Posso confiar no que chegou?

Cinco conferencias. **Se alguma falhar, nao siga para a analise** — todo numero da
exploracao ficaria suspeito.

Os valores esperados estao embutidos no SQL, medidos nos proprios arquivos de origem.
Quem roda nao precisa saber de cor que sao 65 tabelas ou que a receita de 2011 e
12.646.112,16."""))

celulas.append("""-- 3.1 Dinheiro ficou exato? Tem de vir DECIMAL com 19 e 4 nas tres.
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
    f"        , '{'analise' if t in escopo else 'camada bruta'}' as escopo\n"
    f"        , {n} as esperado\n"
    "        , count(*) as carregado\n"
    f"    from {ALVO}.{t}"
    for t, n in linhas_esperadas)

celulas.append(f"""-- 3.2 A contagem bate com o arquivo de origem? As 17 da analise tem de dar `ok`.
--     `nao carregada` em camada bruta e esperado se voce parou na secao 1.
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
    ("pedido -> creditcard (so quem tem cartao)", "salesorderheader", "creditcard",
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
    "-- 3.3 As sete juncoes que a analise usa: alguma tem orfao? Tem de dar ZERO em todas.\n"
    "--     Todas deram zero nos arquivos antes da carga; diferente aqui significa carga errada.\n"
    + "\n\nunion all\n\n".join(blocos) + ";")

celulas.append(f"""-- 3.4 O NULL sobreviveu? Tem de dar 27.659 sem vendedor e ZERO com vendedor 0.
--     Sem o nullValue, campo vazio em coluna int recebe 0 e inventa um vendedor.
select
    count(*) as pedidos
    , count(salespersonid) as com_vendedor
    , sum(case when salespersonid = 0 then 1 else 0 end) as vendedor_zero_suspeito
    , count(*) - count(salespersonid) as sem_vendedor_esperado_27659
from {ALVO}.salesorderheader;""")

celulas.append(f"""-- 3.5 O teste de aceite do briefing. Tem de dar FECHA.
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

celulas.append(f"""-- 3.6 A integridade do linetotal. Tem de dar 121317 linhas e ZERO fora de um centavo.
--     Nesta base o campo vem do arquivo, nao e calculado pelo banco.
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

celulas.append(md("""# Fim da ingestao

Com as conferencias passando, a base esta confiavel e a analise exploratoria pode
comecar em `databricks/02-analise-exploratoria.py`."""))

# ---------------------------------------------------------------- escrita e asseguracao
fonte = "-- Databricks notebook source\n" + "\n\n-- COMMAND ----------\n\n".join(celulas) + "\n"
SAIDA.parent.mkdir(parents=True, exist_ok=True)
SAIDA.write_text(fonte, encoding="utf-8")

# So instrucao de verdade: linha que COMECA com o comando. Contar no texto inteiro
# pegaria tambem a mencao em prosa dentro das celulas de markdown.
codigo = [l for l in fonte.split("\n") if not l.startswith("-- MAGIC")]
n_tabelas = sum(1 for l in codigo if l.startswith("create or replace table "))
n_casts_no_arquivo = sum(l.count("cast(_c") for l in codigo)
assert n_tabelas == len(tabelas) == 65, f"{n_tabelas} create, {len(tabelas)} tabelas"
assert n_casts_no_arquivo == n_cast == 437, f"{n_casts_no_arquivo} casts, esperava 437"

# `copy into` e `force` sao os dois sinais do desenho antigo, que duplicava linhas.
sql = "\n".join(codigo).lower()
assert "copy into" not in sql, "sobrou COPY INTO — o desenho antigo voltou"
assert "force" not in sql, "sobrou `force` — o desenho antigo voltou"

# uma instrucao por celula: e o que o `%sql` executa com seguranca
for i, celula in enumerate(fonte.split("\n\n-- COMMAND ----------\n\n")):
    if celula.lstrip().startswith(("-- MAGIC", "-- Databricks notebook source\n-- MAGIC")):
        continue
    sem_comentario = "\n".join(
        l.split("--")[0] for l in celula.split("\n") if not l.strip().startswith("--"))
    n = sem_comentario.count(";")
    assert n == 1, f"celula {i} tem {n} instrucoes, esperava 1:\n{celula[:200]}"

print(f"OK -> {SAIDA.relative_to(REPO)}")
print(f"tabelas: {n_tabelas}  |  casts: {n_casts_no_arquivo}  |  celulas: {len(celulas)}")
print(f"  secao 1 (analise): {len(ESCOPO_ANALISE)}  |  secao 2 (resto): {len(resto)}")
