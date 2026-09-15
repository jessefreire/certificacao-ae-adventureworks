# Etapa 4 — configurar o dbt Cloud sobre o Databricks

Fecha a configuração do ambiente que o briefing pede na Etapa 4, e é pré-requisito
da Etapa 5.

Este documento segue o caminho que as **aulas práticas** usam — dbt Cloud com Databricks,
registrado em `SETUP_AMBIENTE_AULAS.md` no repositório de formação, com as pegadinhas que
apareceram na montagem do ambiente do BanVic. A diferença aqui é só o alvo: em vez do fork
do `banvic-dbt` e do catálogo `dev`, o projeto aponta para `certificacao-ae-adventureworks`
e para o catálogo `workspace`.

> A apostila escrita do Módulo IV diz que *"neste curso vamos utilizar a versão
> open-source"* e trata do dbt Core, com `~/.dbt/profiles.yml`. As aulas práticas usam o
> **Cloud**. Onde os dois divergirem, vale o Cloud — e a rota local fica no fim como
> alternativa.

## Antes de começar: o que ter em mãos

Três valores do Databricks. No workspace, **SQL Warehouses** → seu warehouse →
**Connection details**:

| O que | Onde | Formato |
|---|---|---|
| **Server hostname** | Connection details | `dbc-xxxxxxxx-xxxx.cloud.databricks.com` |
| **HTTP path** | Connection details | `/sql/1.0/warehouses/abc123def456` |
| **Token** | avatar → Settings → Developer → Access tokens → *Generate new token* | começa com `dapi…` |

⚠️ **O token precisa de escopo `All APIs`, não só `sql`.** Essa foi uma pegadinha real do
setup das aulas: com escopo restrito, o dbt conecta e depois falha com `PERMISSION_DENIED`
num ponto que não parece ter relação com permissão.

⚠️ **O token é senha** e aparece **uma única vez**. Copie na hora, cole direto no dbt Cloud.
Não cole em conversa, não commite. Se vazar, revogue na mesma tela e gere outro.

E os dois valores que o briefing fixa para este desafio:

| Campo | Valor | Por quê |
|---|---|---|
| **Catalog** | `workspace` | é onde a camada bruta foi carregada |
| **Schema** | `dbt_<nome>_<sobrenome>` | **não** `adventure_works` |

O `adventure_works` é a **origem**, e o briefing manda usar só ele como fonte. Se os modelos
nascerem lá, você mistura camada bruta com transformada no mesmo schema e perde a
rastreabilidade que a ingestão construiu.

## Passo 1 — criar o projeto

Em <https://cloud.getdbt.com>:

- **primeira vez:** o dbt abre o fluxo de criação automaticamente;
- **caso contrário:** engrenagem no canto superior direito → **Account Settings** →
  **+ New Project**.

Nome do projeto: **`adventure_works`**.

## Passo 2 — a plataforma e as credenciais

**Data platform:** selecione **Databricks**.

| Campo | Valor |
|---|---|
| Host | o Server Hostname, **sem** `https://` |
| HTTP Path | o caminho que começa com `/sql/1.0/…` |
| Token | o `dapi…` |
| Catalog | `workspace` |
| Schema | `dbt_<nome>_<sobrenome>` |

Três coisas que só se aprende apanhando, e que o registro das aulas já documenta:

**As credenciais pessoais vão no ambiente `Development`, não no `Deployment`.** O token
entra na *profile page* do usuário. Deployment é para execução agendada, e não é o que você
precisa agora.

**A versão do dbt tem de ser `Latest`, não `Fusion`.** O Fusion ainda não suporta a conexão
clássica com Databricks. Se o projeto vier com Fusion por padrão, troque antes de tentar
conectar — senão o erro não diz o que está errado.

**O warehouse precisa estar ligado.** Se estiver parado, ligue no Databricks e espere subir
antes de testar.

Teste a conexão. Tem de dar verde antes de seguir.

## Passo 3 — conectar o repositório

Selecione **GitHub**, autorize, e escolha **`certificacao-ae-adventureworks`**.

O projeto fica na **raiz** do repositório — foi para isso que a gente o extraiu do
repositório de formação. Não há subdiretório a configurar.

Se tudo estiver certo, aparece **"Your project is ready!"**.

## Passo 4 — o Studio, e a branch

O IDE do dbt Cloud chama-se **Studio** (era "Develop"; o nome mudou e a documentação antiga
ainda usa o antigo).

**A `main` aparece travada, com um cadeado.** Isso não é erro: é proteção. Crie uma branch
antes de editar qualquer coisa — a Etapa 5 passa a nascer em PR, boa prática de Git
independente de qualquer critério de correção.

Duas leituras do Studio que confundem no começo:

- **arquivo vermelho no explorador = modificado**, não com erro. É o `git diff`.
- **erro de verdade** é o contador `Error` no painel de execução.
- **o dbt Cloud roda o que está salvo.** `Ctrl+S` antes de rodar, sempre.

Aceite o *Initialize dbt project*: ele cria `models/`, `macros/`, `seeds/`, `snapshots/`,
`tests/`, `analyses/` e o `dbt_project.yml`.

## Passo 5 — o `dbt_project.yml`

```yaml
name: "adventure_works"
version: "1.0.0"
config-version: 2

# O code style pede que o nome do profile inclua a empresa, para nao colidir entre
# projetos. No dbt Cloud o profile e gerenciado pela interface, mas o campo continua
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
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
```

**Uma divergência declarada:** o `dbt_coding_conventions.md` pede `ephemeral` como
materialização padrão global. Aqui ela é declarada **por camada**, como no `banvic-dbt` e no
fluxo `ae-fullflow`. O motivo é que o briefing pede uma demonstração do `dbt run` criando
objetos no Databricks, e modelo `ephemeral` não cria objeto nenhum — vira CTE. Escolha
consciente, não descuido.

## Passo 6 — `packages.yml` e `dbt deps`

Na **raiz**, ao lado do `dbt_project.yml`. Em pasta errada o `dbt deps` não instala nada e
não reclama:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.3.0", "<1.4.0"]
```

**Por que a faixa, e não `1.3.1` cravado.** Dois documentos da casa se contradizem: o
`dbt_coding_conventions.md` lista pinar patch exato como prática **ruim** e pede faixa de
minor; a skill `dbt-packages-tests` e o `banvic-dbt` pinam `1.3.1` porque **`1.4.1` pode não
funcionar com Databricks**. A faixa satisfaz os dois.

Rode **`dbt deps`**. O `dbt_packages/` já está no `.gitignore` do repositório.

O `dbt_utils` não é enfeite: a `dim_dates` do modelo é gerada pela macro `date_spine`, que é
o padrão da casa (ADR013, documento `2.3)` do referencial).

## Passo 7 — a source

Só as **17 tabelas do escopo**. Declarar source é assumir teste e documentação dela, e o
briefing pede exatamente isso na Etapa 5: documentação de tabelas e testes de source.

O arquivo vive em `models/staging/` e começa com `_` para o dbt não o confundir com model —
convenção que o material do Módulo IV registra. Em `models/staging/_adventure_works.yml`:

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

Em Databricks, o `database` do dbt é o **catálogo** — equivalência que o documento `2.5)` do
referencial registra.

**Os testes de source não são decorativos:** o briefing exige, entre as demonstrações do
vídeo, um `dbt test --select source:*` passando.

## Os comandos, e o que cada um faz de fato

| Comando | Faz | Não faz |
|---|---|---|
| `dbt debug` | testa a conexão — autentica, acha catalog/schema | não toca em modelo nenhum |
| `dbt deps` | baixa os pacotes do `packages.yml`, trava a versão no `package-lock.yml` | não roda modelo |
| `dbt run` | **cria** os objetos no Databricks a partir dos `.sql` | não testa nada |
| `dbt test` | roda os `data_tests` dos `.yml` contra o que **já existe** | não cria nada |
| `dbt build` | `run` + `test` juntos, na ordem certa, modelo por modelo | — é o atalho recomendado |
| `dbt compile` | só traduz Jinja para SQL puro, sem executar | útil para depurar SQL gerado |
| `dbt docs generate` | monta a documentação navegável a partir dos `.yml` | rodar só no fim |

**A ordem importa por um motivo concreto:** `dbt test` antes de `dbt run` falha com
`TABLE_OR_VIEW_NOT_FOUND`, porque o objeto testado ainda não existe no Databricks. `dbt
build` nunca inverte essa ordem, e por isso é preferível a rodar os dois separados.

**Prefira `--select <modelo>` a rodar o projeto inteiro**, a partir do momento em que
houver mais de um modelo. Com um só, não faz diferença; com dezessete, rodar tudo a cada
`Ctrl+S` é lento e mistura erro do modelo novo com modelo que já estava ok. É o padrão que
`05-plano-de-entrega-dbt.md` usa em cada branch: `dbt build --select <modelo>`.

## Passo 8 — validar

No Studio, a ordem canônica que o Módulo IV registra:

```
dbt debug
dbt deps
dbt run
dbt test
```

**`dbt debug`** tem de terminar em `All checks passed!`.

**Nunca rode `dbt test` antes de `dbt run`** — sem os objetos criados, o teste falha com
`TABLE_OR_VIEW_NOT_FOUND`, e o erro parece de modelagem quando é de ordem.

Para a configuração do ambiente fechar, basta um `dbt run` que complete. Um modelo de
staging já prova que o ambiente está de pé; os outros vêm na Etapa 5.

## O que comprova a configuração do ambiente

| Evidência | Como mostrar no vídeo |
|---|---|
| Conexão configurada | o teste de conexão verde |
| Projeto conectado ao Git | o repositório e a branch no Studio |
| dbt executando de fato | `dbt debug` e `dbt run` rodando na tela |

## Erros conhecidos

| Erro | Causa |
|---|---|
| `PERMISSION_DENIED` depois de conectar | token com escopo `sql` em vez de **All APIs** |
| Conexão falha | hostname com `https://`, ou warehouse desligado |
| Conexão falha e a mensagem não ajuda | versão **Fusion** em vez de `Latest` |
| `dbt deps` não instala nada | `packages.yml` fora da raiz |
| `TABLE_OR_VIEW_NOT_FOUND` no teste | rodou `dbt test` antes do `dbt run` |
| `Table or view not found` no run | schema errado na source — confira no Catalog |
| `UNRESOLVED_COLUMN` | coluna que não existe; confira no Catalog |
| `'MacroNamespace object' has no attribute…` | teste do `dbt_utils` sem `arguments:`, ou nome da macro incompleto |
| A edição não surtiu efeito | **o dbt Cloud roda o que está salvo.** `Ctrl+S` |

## Alternativa: dbt Core local

É o que a apostila do Módulo IV ensina e o que o `INSTALACAO.md` documenta:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install dbt-databricks
dbt init
dbt debug
```

Com `~/.dbt/profiles.yml` assim — e este arquivo **nunca** entra no git, já coberto pelo
`.gitignore`:

```yaml
indicium_adventure_works:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: workspace
      schema: dbt_<nome>_<sobrenome>
      host: <hostname>.cloud.databricks.com
      http_path: /sql/1.0/warehouses/<id>
      token: <token>
      threads: 4
```

O briefing **sugere** dbt Cloud, não exige — as duas rotas atendem.
