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
