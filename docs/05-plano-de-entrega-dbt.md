# Etapa 5 — plano de entrega em branches

A Etapa 5 vale **metade da nota** do desafio: doze dos vinte e oito itens do formulário de
avaliação, com peso 5,00 de 10. Um deles, o **2.12**, é sobre boas práticas de Git — então a
forma de construir também conta, não só o resultado.

Este documento é o plano: o que cada branch entrega, o que prova que ela está pronta, e o
ritual de PR que o projeto segue.

> O modelo a construir está em [`03.01-modelo-conceitual.md`](03.01-modelo-conceitual.md)
> (o desenho) e [`03-decisoes-de-modelagem.md`](03-decisoes-de-modelagem.md) (as colunas, os
> papéis e as decisões com a medição de cada uma). **Nada aqui inventa modelagem** — este
> documento é só a ordem de execução.

## Princípio: fatia vertical, não camada horizontal

Cada branch entrega algo que **roda e passa nos testes**. Não se faz "todos os staging",
depois "todos os testes", depois "toda a documentação" — porque nesse arranjo nada está
pronto até o fim, e a dívida de documentação sempre sobra.

É o mesmo padrão do projeto BanVic das aulas, que teve sete branches, cada uma fechando uma
fatia: `chore/habilita-seeds`, depois uma dimensão, depois a documentação, depois o
`date_spine`, depois duas pipelines completas.

E o code style é explícito: *"um model não está completo sem testes e documentação"*. Então
o `.yml` com descrições e testes entra **junto** com o modelo, na mesma branch.

## `.yml` ao lado do `.sql`, não em pasta `schema/`

O `dbt_coding_conventions.md` é literal: *"documentation and tests for each model
should be placed in a `schema.yml` file **alongside** the model file"* — "alongside"
é mesma pasta, não subpasta. O motivo que o documento dá: achar mais fácil, ver de
relance quem tem teste e quem não tem, e evitar conflito de merge.

O projeto BanVic usou uma subpasta `models/staging/erp_banvic/schema/` para os `.yml`,
separada dos `.sql` — o que **diverge** do code style, não o segue. Neste projeto, cada
`.yml` fica ao lado do `.sql` correspondente, seguindo a convenção normativa ao pé da
letra.

### Duas alternativas não oficiais, registradas para decisão futura

Nenhuma das duas está no `dbt_coding_conventions.md`. Ficam aqui para o caso de alguém
da Indicium AI, na prática, confirmar um padrão diferente do que o documento escrito diz
— aí a mudança já vem registrada, com a fonte e o custo de cada opção.

**1. Pasta `schema/` separada dos `.sql`** — o que o BanVic fez nas aulas. Separa
visualmente "o que faz" de "o que documenta e testa", mas contraria o `alongside`
explícito da linha 339, e o próprio code style lista como benefício do padrão dele
"evitar conflito de merge" — que a subpasta não compromete, mas também não ajuda.

**2. Pasta por domínio, um modelo por pasta** — o guia oficial do **dbt Labs**
("How we structure our dbt projects"), não da Indicium AI:

```
models/
└── staging/
    ├── customers/
    │   ├── stg_customers.sql
    │   └── _customers__models.yml
    └── orders/
        ├── stg_orders.sql
        └── _orders__models.yml
```

Aqui o `.yml` é **por domínio**, cobrindo vários modelos — o que contraria a outra regra
do code style, "um arquivo por model, nomeado `<nome do model>.yml`". E o padrão existe
para projetos com **múltiplas fontes de dados** isoladas; este projeto tem uma fonte só
(`adventure_works`, 17 tabelas), então 17 subpastas de uma tabela cada não organizaria
nada — só acrescentaria nível de diretório. Faria sentido se o projeto um dia ganhasse
uma segunda fonte, e aí a pasta seria por **fonte**, não por tabela individual.

**Decisão atual:** seguir o code style ao pé da letra — `.sql` e `.yml` juntos, direto em
`models/staging/`, sem subpasta. Revisitar se a conferência com alguém da Indicium AI
apontar outra coisa.

## Progresso da branch 1 — staging

> Atualizado a cada modelo commitado. Conferido direto no branch remoto, não de memória.

| # | Modelo | Estado |
|---|---|---|
| 1 | `countryregion` | ✅ |
| 2 | `stateprovince` | ✅ |
| 3 | `address` | ✅ |
| 4 | `person` | ✅ |
| 5 | `store` | pendente |
| 6 | `customer` | pendente |
| 7 | `creditcard` | pendente |
| 8 | `productcategory` | pendente |
| 9 | `productsubcategory` | pendente |
| 10 | `product` | pendente |
| 11 | `specialoffer` | pendente |
| 12 | `salesterritory` | pendente |
| 13 | `salesperson` | pendente |
| 14 | `salesreason` | pendente |
| 15 | `salesorderheader` | pendente |
| 16 | `salesorderdetail` | ✅ — nasceu antes da branch, via commit direto no repositório |
| 17 | `salesorderheadersalesreason` | pendente |

**5 de 17 prontos.**

## As nove branches

| # | Branch | Entrega | Pronto quando |
|---|---|---|---|
| 1 | `feature/staging-adventure-works` | os 17 `stg_*` e seus `.yml` | `dbt build --select staging` verde |
| 2 | `feature/dim-dates` | `dim_dates` por `dbt_utils.date_spine` | calendário sem buraco em mês sem venda |
| 3 | `feature/dim-product` | produto + subcategoria + categoria | 504 produtos, com os 238 que nunca venderam |
| 4 | `feature/dim-customer` | cliente + pessoa + loja | `coalesce` com loja em prioridade, e `customer_type` |
| 5 | `feature/dim-geography` | endereço + estado + país | chave composta cidade + estado |
| 6 | `feature/dim-simples` | cartão, território, oferta, vendedor, motivo | membros "não informado" nos três que precisam |
| 7 | `feature/bridge-order-sales-reason` | a ponte | cobre os 31.465 pedidos, com `allocation_factor` |
| 8 | `feature/fact-sales` | a fato e o teste de PK | `dbt test --select fact_sales` verde |
| 9 | `feature/teste-aceite-ceo` | o teste de regra de negócio | fecha em **12.646.112,16** |

### Por que a nona é separada

Ela é o item **2.10** do formulário — o mais objetivo dos vinte e oito — e o briefing cita o
pedido do CEO nominalmente. Num PR próprio, ela vira um commit que se abre no vídeo e se diz
"este é o teste que o CEO pediu". Dentro de outro PR, some no meio.

### Por que as dimensões não viram uma só

Daria para fundir as branches 3 a 6 numa `feature/dimensoes` e ficar com seis, mais perto do
BanVic. Não vale: dimensão é onde moram as decisões difíceis — o membro desconhecido do
vendedor, que cobre 87,9% dos pedidos; a chave de cidade, que existe porque 38 cidades se
repetem entre estados; os produtos sem venda, que um `inner join` eliminaria. PR pequeno é
onde essas decisões ficam visíveis para quem revisa.

## O ritual, por branch

```
1. Studio:   Create branch  ->  feature/<nome>
2. Studio:   escreve o .sql e o .yml juntos
3. Studio:   Ctrl+S  (o dbt Cloud roda o que esta SALVO)
4. Studio:   dbt build --select <modelo>   ->  tem de passar
5. Studio:   Commit and sync
6. GitHub:   abre o PR  ->  base: main  <-  compare: feature/<nome>
7. GitHub:   merge
8. Studio:   volta para main  ->  Pull from main
```

Três coisas que já custaram tempo neste projeto e no BanVic:

- **`Ctrl+S` antes de rodar.** O dbt Cloud executa o arquivo salvo, não o que está na tela.
  Sem salvar, você depura um problema que já corrigiu.
- **A `main` aparece travada com cadeado.** É proteção, não erro.
- **Se o PR acusar conflito**, confira primeiro se `base` e `compare` não estão invertidos.
  É o engano mais comum e não parece o que é.

## Mensagem de commit

Formato **Conventional Commits**: `tipo: descrição curta no imperativo`.

| Tipo | Quando | Exemplo real para este projeto |
|---|---|---|
| `feat:` | modelo novo, coluna nova | `feat: cria dim_product com a hierarquia de categoria` |
| `fix:` | conserta algo quebrado | `fix: corrige fan-out da bridge na contagem de pedidos` |
| `test:` | teste adicionado ou corrigido | `test: adiciona unique_combination_of_columns na bridge` |
| `docs:` | documentação | `docs: descreve o papel de cada coluna da fato` |
| `refactor:` | reorganiza sem mudar resultado | `refactor: extrai CTE de renomeacao repetida` |
| `chore:` | configuração, manutenção | `chore: fixa dbt_utils na faixa 1.3` |
| `perf:` | desempenho | `perf: materializa fact_sales como table` |

A regra de escolha, em uma linha: **muda o que o consumidor vê? `feat`. Conserta algo
quebrado? `fix`. Só arruma a casa? `chore`.**

### O corpo do commit importa mais que o título

O título diz **o quê**. O corpo diz **por quê** — e é o porquê que se perde em três semanas.
Nos modelos com decisão embutida, escreva o número que sustenta a escolha:

```
feat: cria dim_salesperson com membro "sem vendedor"

O salespersonid do pedido e nulo em 27.659 de 31.465 pedidos (87,9%), e o
conjunto coincide EXATAMENTE com os pedidos online: nao e dado faltante, e o
significado do canal.

Sem o membro -1, filtrar por vendedor apagaria o varejo inteiro.
```

Commit sem corpo é aceitável quando o título já basta — `chore: fixa dbt_utils na faixa 1.3`
não precisa de explicação.

## Descrição do PR

Quatro blocos curtos. O objetivo é que quem revisa saiba o que olhar sem abrir o diff
inteiro:

```markdown
## O que entrega
dim_geography, com endereco, estado e pais denormalizados.

## Decisões que valem revisão
- Chave composta `city_key` = cidade + stateprovinceid. Medido: 575 nomes de cidade
  para 613 pares (cidade, estado) — 38 cidades existem em mais de um estado, e
  agrupar pelo nome as funde.
- Geografia e de COBRANCA (billtoaddressid). Bill-to e ship-to diferem em 99 de
  31.465 pedidos (0,31%), entao nao ha dimensao de papel duplo.

## Como conferir
dbt build --select dim_geography

## Itens do formulário que isto atende
2.8 (documentacao das marts) · 2.9 (chaves e testes) · 2.11 (logica SQL)
```

O último bloco não é burocracia: ele obriga a pensar se o PR realmente atende ao que vai ser
avaliado, e vira roteiro do vídeo depois.

## O que fica pronto ao fim das nove

| Item do formulário | Onde nasce |
|---|---|
| 2.1 Organização do projeto | estrutura de pastas, desde a branch 1 |
| 2.2 `dbt_project.yml` | já em `main` |
| 2.3 Code style | sqlfluff em cada modelo |
| 2.4 Fontes e mapeamento | já em `main`, `_adventure_works.yml` |
| 2.5 Documentação e testes de source | já em `main`, 39 testes |
| 2.6 Modelagem de stagings | branch 1 |
| 2.7 Conformidade com o modelo conceitual | branches 2 a 8, contra o `03.01` |
| 2.8 Documentação das marts | `.yml` de cada modelo |
| 2.9 Chaves e testes de schema | `unique` + `not_null` em cada PK |
| 2.10 Teste de regra de negócio | branch 9 |
| 2.11 Lógica SQL | todas |
| 2.12 Boas práticas de Git | as nove, pelo próprio ritual |

## Uma coisa a não esquecer no fim

O briefing exige, na lista de demonstrações do vídeo, um **`dbt test --select source:*`**
passando. Ele já passa hoje, com os 39 testes das fontes — mas vale rodar de novo depois da
última branch, porque source quebra quando alguém mexe no schema de origem e ninguém percebe.

## Como comunicar isto no vídeo e nos slides

### A linha do tempo real, e como narrar sem imprecisão

`dbt_project.yml`, `packages.yml`, `_adventure_works.yml` (as 17 fontes) e o primeiro
modelo de staging (`stg_adventure_works__salesorderdetail`) **não nasceram no Studio** — 
foram versionados direto por `git`, antes mesmo de o dbt Cloud ser conectado, a partir do
que já estava decidido em [`03.01-modelo-conceitual.md`](03.01-modelo-conceitual.md) e
[`03-decisoes-de-modelagem.md`](03-decisoes-de-modelagem.md). A branch só os **puxou**
depois, com "Pull from main".

O briefing não exige que cada linha seja digitada ao vivo — só que `dbt run`,
`dbt test --select source:*` e `dbt test` **rodem de verdade na tela** (item 4.2). Mas
dizer "fiz tudo isso aqui, do zero" seria impreciso. A narrativa correta é mais forte que a
imprecisa: **o modelo foi desenhado primeiro** (Etapa 3, com evidência medida em cada
decisão), **as fontes e o primeiro modelo nasceram desse desenho**, e o resto da staging é
construído **ao vivo**, em branch, com PR de verdade. É o processo que o item **2.7**
avalia, e é o que um AE sênior faz — modelar antes de codificar.

### Roteiro do trecho de vídeo sobre a camada de staging

1. Mostre o diagrama (`03.01-modelo-conceitual.md` ou o PDF): *"A partir das decisões
   registradas aqui, defini a primeira camada — staging, que só renomeia e tipa, sem
   lógica de negócio."*
2. Abra `_adventure_works.yml`: *"São as 17 fontes do escopo, cada uma com teste de
   chave."* Rode `dbt test --select source:*` na tela.
3. Abra `stg_adventure_works__salesorderdetail.sql`: *"É aqui que a métrica bruta nasce,
   porque a origem só traz a líquida. É o número que o CEO acompanha."*
4. Rode `dbt build --select stg_adventure_works__salesorderdetail` mostrando sucesso.
5. Mostre o `.yml` do modelo, destaque a marca "ATRIBUTO, não métrica" em `unit_price`.
6. Feche com a branch: *"A partir daqui, cada modelo segue este mesmo fluxo — branch,
   build, PR, merge."* Mostre o PR aberto ou mesclado no GitHub — é a prova do item 2.12.

### Nos slides (Etapa 9)

- A estrela, direto do PDF da Etapa 3.
- Um slide só para "por que duas receitas": a bruta nasce no staging porque o CEO a pede
  nominalmente; a líquida é o que a origem já trazia pronta.
- O link do PR mesclado, como evidência do processo — não só do resultado.
