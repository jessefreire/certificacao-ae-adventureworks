# Etapa 4 — configurar o dbt Cloud sobre o Databricks

Fecha o item **1.3 Configuração de Ambiente** do formulário de avaliação, e é pré-requisito
da Etapa 5, que vale metade da nota.

> **O curso ensina dbt Core, não Cloud.** A apostila do Módulo IV é explícita: *"neste
> curso vamos utilizar a versão open-source (…) você pode utilizar a versão cloud de forma
> equivalente se desejar"*. O briefing, por outro lado, sugere **dbt Cloud**. Este documento
> é a ponte: o que o curso ensina continua valendo para o projeto em si — estrutura,
> convenções, comandos —, e muda só a camada de configuração.
>
> A diferença que mais confunde: **no dbt Cloud não existe `profiles.yml`**. As credenciais
> ficam na interface, em *Connection* e *Development Credentials*. Todo material do curso
> que fala em `~/.dbt/profiles.yml` é a rota local, que fica aqui como alternativa no fim.

## Antes de começar: o que ter em mãos

Três valores do Databricks, todos na mesma tela. No workspace, abra **SQL Warehouses**,
clique no seu warehouse e vá em **Connection details**:

| O que | Onde | Exemplo de formato |
|---|---|---|
| **Server hostname** | Connection details | `dbc-xxxxxxxx-xxxx.cloud.databricks.com` |
| **HTTP path** | Connection details | `/sql/1.0/warehouses/abc123def456` |
| **Token de acesso** | avatar → Settings → Developer → Access tokens → *Generate new token* | começa com `dapi…` |

⚠️ **O token é senha.** Ele aparece **uma única vez** na tela — copie na hora. Não cole em
conversa, não commite, não guarde em arquivo do repositório. Se vazar, revogue na mesma tela
e gere outro.

E os dois valores que o briefing já fixou para este desafio:

| Campo | Valor |
|---|---|
| **Catalog** | `workspace` |
| **Schema (alvo do dbt)** | `dbt_<seu nome>` para desenvolvimento — **não** `adventure_works` |

O `adventure_works` é a **origem**, e o briefing manda usar só ele como fonte. Os modelos
que o dbt cria precisam nascer em outro lugar, senão você mistura camada bruta com camada
transformada no mesmo schema — e perde a rastreabilidade que a ingestão construiu.

## Passo 1 — criar a conta

Em `getdbt.com`, crie a conta. O plano **Developer** é gratuito e suficiente: um projeto,
um usuário de desenvolvimento.

Na criação ele pede nome do projeto — use **`adventure_works`**.

## Passo 2 — a conexão com o Databricks

Em **Settings → Connections → New connection**, escolha **Databricks**.

| Campo | O que pôr |
|---|---|
| Server Hostname | o hostname, **sem** `https://` |
| HTTP Path | o caminho que começa com `/sql/1.0/…` |
| Catalog | `workspace` |

Salve. Depois, em **Development credentials** (que é por usuário, não por conexão):

| Campo | O que pôr |
|---|---|
| Token | o `dapi…` |
| Schema | `dbt_<seu nome>` |
| Threads | `4` |

Clique em **Test Connection**. Tem de dar verde antes de seguir — conexão que falha aqui
falha em tudo depois, e o erro fica mais difícil de ler.

**Se falhar:** hostname com `https://` na frente é a causa mais comum; depois, warehouse
parado (ligue no Databricks e espere subir); depois, token expirado.

## Passo 3 — conectar o repositório

Em **Settings → Projects → seu projeto → Repository → Add repository**.

Se você conectar pelo **GitHub** com a integração oficial, autorize e escolha
`certificacao-ae-adventureworks`. Se preferir não instalar o app do GitHub, use **Git
clone** com a URL SSH e cadastre a **deploy key** que o dbt Cloud gera, no GitHub em
*Settings → Deploy keys* do repositório, **com permissão de escrita**.

O projeto fica na **raiz** do repositório — foi exatamente para isso que a gente extraiu ele
do repositório de formação. Não há subdiretório a configurar.

## Passo 4 — inicializar o projeto

No **Studio** (o editor do dbt Cloud), ele oferece *Initialize dbt project*. Aceite: isso
cria a estrutura que a apostila descreve no `dbt init` — `models/`, `macros/`, `seeds/`,
`snapshots/`, `tests/`, `analyses/` e o `dbt_project.yml`.

Depois **crie uma branch** antes de escrever qualquer coisa. O curso é explícito nisso
(`git checkout -b novos_modelos_dbt`); no Studio é o botão *Create branch*. A `main` fica
protegida, e a Etapa 5 nasce em PR — o que atende o item **2.12 Boas Práticas de Git**.

## Passo 5 — o `dbt_project.yml`

Substitua o gerado por este. As escolhas estão comentadas porque cada uma vem de um
documento diferente, e algumas se contradizem entre si:

```yaml
name: "adventure_works"
version: "1.0.0"
config-version: 2

# O code style pede que o nome do profile inclua a empresa, para não colidir entre
# projetos. No dbt Cloud o profile é gerenciado pela interface, mas o campo continua
# existindo e vale manter coerente.
profile: "indicium_adventure_works"

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]
analysis-paths: ["analyses"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets: ["target", "dbt_packages"]

models:
  adventure_works:
    # Staging e intermediate como view: o referencial (documento 2.5) observa que essas
    # camadas geralmente não precisam ser materializadas, porque armazenamento é mais
    # barato que processamento — mas view ainda dá nome e lineage.
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    # Marts como table: é o que o BI consome, e leitura repetida compensa a materialização.
    marts:
      +materialized: table
      +schema: marts
```

**Uma divergência declarada:** o `dbt_coding_conventions.md` pede `ephemeral` como
materialização padrão global. Aqui a materialização é declarada **por camada**, que é a
prática do `banvic-dbt` e do fluxo `ae-fullflow`. O motivo é o item **4.3** do formulário:
o vídeo precisa demonstrar o `dbt run` criando objetos no Databricks, e modelo `ephemeral`
não cria objeto nenhum — ele vira CTE. Escolha consciente, não descuido.

## Passo 6 — `packages.yml` e `dbt deps`

Crie na **raiz**, ao lado do `dbt_project.yml` — em pasta errada o `dbt deps` não instala
nada e não reclama:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.3.0", "<1.4.0"]
```

**Por que essa faixa, e não `1.3.1` cravado.** Há um conflito real entre dois documentos da
casa: o `dbt_coding_conventions.md` lista pinar patch exato como **prática ruim** e pede
faixa de minor; a skill `dbt-packages-tests` e o `banvic-dbt` pinam `1.3.1` porque
**`1.4.1` pode não funcionar com Databricks**. A faixa acima satisfaz os dois: respeita a
convenção e não deixa subir para a minor problemática.

Rode **`dbt deps`**. E confira que `dbt_packages/` está no `.gitignore` — no nosso já está.

O `dbt_utils` não é enfeite: a `dim_dates` do modelo é gerada pela macro `date_spine`, que é
o padrão da casa (ADR013, documento `2.3)`).

## Passo 7 — a source

Só as **17 tabelas do escopo** são declaradas. Declarar source é assumir teste e
documentação dela, e o item **2.5** cobra justamente isso.

O arquivo vive em `models/staging/`, e o nome começa com `_` para o dbt não o confundir com
model. Em `models/staging/_adventure_works.yml`:

```yaml
version: 2

sources:
  - name: adventure_works
    description: "Camada bruta do AdventureWorks 2014, carregada do Volume do Unity Catalog."
    database: workspace
    schema: adventure_works
    tables:
      - name: salesorderheader
        description: "Cabecalho do pedido. Uma linha por pedido."
        columns:
          - name: salesorderid
            description: "Chave primaria do pedido."
            data_tests:
              - unique
              - not_null
      - name: salesorderdetail
        description: "Item de pedido. E o grao da fact_sales."
        columns:
          - name: salesorderdetailid
            data_tests:
              - unique
              - not_null
      # … as outras 15
```

Repare no `database: workspace` — em Databricks o `database` do dbt é o **catálogo**, e o
referencial (documento `2.5)`) registra essa equivalência.

**Os testes de source não são decorativos:** o briefing exige, na lista de demonstrações do
vídeo, um `dbt test --select source:*` passando. Source declarada sem teste reprova essa
demonstração.

## Passo 8 — validar

No Studio, o console aceita os comandos do curso. A ordem canônica, que o material do
Módulo IV registra e que evita o erro mais comum:

```
dbt debug
dbt deps
dbt run
dbt test
```

**`dbt debug`** tem de terminar em `All checks passed!`.

**Nunca rode `dbt test` antes de `dbt run`** — sem os objetos criados, o teste falha com
`TABLE_OR_VIEW_NOT_FOUND` e o erro parece de modelagem quando é de ordem.

Para o item 1.3 fechar, basta um `dbt run` que complete. Um modelo de staging já serve como
prova de que o ambiente está de pé — os outros vêm na Etapa 5.

## O que fecha o item 1.3

| Evidência | Como mostrar no vídeo |
|---|---|
| Conexão configurada | *Test Connection* verde |
| Projeto conectado ao Git | o repositório e a branch no Studio |
| dbt executando de fato | `dbt debug` e `dbt run` rodando na tela |

## Erros conhecidos, e o que cada um significa

| Erro | Causa |
|---|---|
| `Connection test failed` | hostname com `https://`, ou warehouse desligado |
| `dbt deps` não instala nada | `packages.yml` fora da raiz |
| `TABLE_OR_VIEW_NOT_FOUND` no teste | rodou `dbt test` antes do `dbt run` |
| `Table or view not found` no run | schema errado na source — confira no Catalog do Databricks |
| `UNRESOLVED_COLUMN` | nome de coluna que não existe; confira no Catalog |
| `'MacroNamespace object' has no attribute…` | teste do `dbt_utils` com sintaxe antiga: falta `arguments:`, ou o nome da macro está incompleto |
| O que você editou não surtiu efeito | **o dbt Cloud roda o que está salvo.** `Ctrl+S` antes de rodar |

## Alternativa: dbt Core local

Se o dbt Cloud der problema — cota, conexão, o que for —, o caminho local é o que o curso
ensina e o que o `INSTALACAO.md` deste repositório já documenta:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install dbt-databricks
dbt init
dbt debug
```

Com `~/.dbt/profiles.yml` assim — e este arquivo **nunca** entra no git:

```yaml
indicium_adventure_works:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: workspace
      schema: dbt_<seu nome>
      host: <hostname>.cloud.databricks.com
      http_path: /sql/1.0/warehouses/<id>
      token: <token>
      threads: 4
```

O `.gitignore` do repositório já cobre `profiles.yml`. O briefing aceita as duas rotas: ele
**sugere** dbt Cloud, não exige.
