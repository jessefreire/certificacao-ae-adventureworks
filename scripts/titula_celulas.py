# -*- coding: utf-8 -*-
"""Da título as células de código do notebook de análise exploratória.

    python scripts/titula_celulas.py

Rodar de novo e seguro: os títulos existentes são removidos antes de reaplicar.

## Por que uma lista explícita, e não título derivado do comentário

A primeira versão disto DERIVAVA o título da primeira linha de comentário de cada
célula. O resultado foi ruim de um jeito que só aparece no painel do Databricks:

  - título com 58 caracteres na mediana, contra ~22 visíveis — 40 de 42 cortados
  - `gráfico` abrindo nove títulos e `perfil` abrindo sete, gastando o espaço
    visível ANTES de chegar ao que distingue a célula
  - nenhuma numeração, num notebook cujas seções já são numeradas no markdown

Derivação não tem como saber disso. Lista explícita tem duas vantagens: e revisável
antes de aplicar, e e estável — o título não muda porque alguém reescreveu um
comentário.

O preço e ter de manter a lista em sincronia com as células, e por isso o script
falha alto se a contagem não casar, em vez de titular na ordem errada.

## O formato

`<seção>.<sequência> <rótulo curto>`, com o número da seção igual ao do cabeçalho de
markdown. O número vem primeiro porque sobrevive ao corte: `3.4 Catálogo sem venda`
truncado ainda e localizável.

O código do aprofundamento (`a.1`, `b.2`) NÃO entra no título. Ele não distingue
células — havia dois `a.1`, dois `a.2`, dois `b.1` — e já esta no cabeçalho de
markdown imediatamente acima. Os quatro últimos gráficos são a exceção: neles a letra
da pergunta e a informação útil, porque e o que o dashboard da Etapa 7 reaproveita.
"""
import re
import sys
from pathlib import Path

# O console do Windows usa cp1252 e QUEBRA ao imprimir acento. Sem esta linha o
# script morre no meio do relatório com UnicodeEncodeError — e o erro parece ser
# do que ele estava conferindo, não da impressão.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
NB = AQUI.parent / "databricks" / "02-analise-exploratoria.py"
SEP = "\n\n# COMMAND ----------\n\n"

# Os títulos, na ordem das células de código. Agrupados por seção só para leitura.
TITULOS = [
    # 1. Perfil do dado
    "1.1 Tamanho e janela",
    "1.2 Canais e receita",
    "1.3 Status constante",
    "1.4 Nulos por coluna",
    "1.5 Unicidade das PKs",
    "1.6 Produto sem subcat",
    "1.7 Subcat sem categoria",
    # 2. Reconciliação
    "2.1 Aceite do CEO",
    # 3. Pergunta (a)
    "3.1 Métricas por país",
    "3.2 Cartão discrimina?",
    "3.3 Cartão e proxy?",
    "3.4 Catálogo sem venda",
    "3.5 Receita no topo",
    "3.6 Motivo por canal",
    "3.7 Motivos por pedido",
    # 4. Pergunta (b)
    "4.1 Ticket por produto",
    "4.2 Desconto e material?",
    "4.3 Onde há desconto",
    "4.4 Ticket por país",
    "4.5 Tipo de oferta",
    # 5. Pergunta (c)
    "5.1 Top 10 clientes",
    "5.2 Concentração no topo",
    "5.3 Recompra por canal",
    # 6. Pergunta (d)
    "6.1 Top 5 cidades",
    "6.2 Concentração geog.",
    "6.3 Por território",
    "6.4 Valor x volume",
    # 7. Pergunta (e)
    "7.1 Série mensal",
    "7.2 Quebra de jul/2013",
    "7.3 Ritmo da revenda",
    # 8. Pergunta (f)
    "8.1 Motivos existentes",
    "8.2 Unidades em promo",
    "8.3 Promo x pedido",
    # 9. Gráficos
    "9.1 Série e quebra",
    "9.2 Tipo de cartão",
    "9.3 Pareto de produtos",
    "9.4 Ticket por país",
    "9.5 Promo no online",
    "9.6 (b) Ticket produto",
    "9.7 (c) Top 10 clientes",
    "9.8 (d) Cidades x resto",
    "9.9 (f) Promo unidades",
]

# A seção de gráficos não tinha número no markdown, e fica entre a 8 e a 9. Sem
# numerar ela, os nove gráficos ficariam sem prefixo — o que e justamente o que se
# quer corrigir. Então ela vira a 9 e a síntese vira a 10.
RENUMERA = [
    ("# MAGIC # Gráficos", "# MAGIC # 9. Gráficos"),
    ("# MAGIC # 9. Síntese — o que a exploração mudou no entendimento",
     "# MAGIC # 10. Síntese — o que a exploração mudou no entendimento"),
    ("| **Gráficos** | Nove, em dois grupos — ver abaixo | 9 células Python |",
     "| **9. Gráficos** | Nove, em dois grupos — ver abaixo | 9 células Python |"),
    ("| **9. Síntese** | O que a exploração mudou no entendimento do dataset, "
     "que e a frase que o briefing pede | — |",
     "| **10. Síntese** | O que a exploração mudou no entendimento do dataset, "
     "que e a frase que o briefing pede | — |"),
]


def e_codigo(celula):
    """A célula executa algo? Markdown não conta, e o DBTITLE não define o tipo."""
    uteis = [l for l in celula.split("\n") if l.strip()]
    uteis = [l for l in uteis if not l.startswith("# DBTITLE")]
    uteis = [l for l in uteis if l != "# Databricks notebook source"]
    if not uteis:
        return False
    return not uteis[0].strip().startswith("# MAGIC %md")


t = NB.read_text(encoding="utf-8")

for velho, novo in RENUMERA:
    if novo in t:
        continue                      # já renumerado numa rodada anterior
    assert t.count(velho) == 1, f"não achei para renumerar: {velho[:50]}"
    t = t.replace(velho, novo)

# limpa títulos anteriores antes de reaplicar
t = "\n".join(l for l in t.split("\n") if not l.startswith("# DBTITLE"))
celulas = t.split(SEP)

indices = [i for i, c in enumerate(celulas) if e_codigo(c)]
assert len(indices) == len(TITULOS), (
    f"o notebook tem {len(indices)} células de código e a lista tem {len(TITULOS)} "
    f"títulos. Alguém adicionou ou removeu célula: atualize TÍTULOS.")

for i, titulo in zip(indices, TITULOS):
    c = celulas[i]
    if "# MAGIC %sql\n" in c:
        celulas[i] = c.replace("# MAGIC %sql\n",
                               f"# MAGIC %sql\n# DBTITLE 1,{titulo}\n", 1)
    else:
        cabeca = ""
        if c.startswith("# Databricks notebook source\n"):
            cabeca = "# Databricks notebook source\n"
            c = c[len(cabeca):]
        celulas[i] = f"{cabeca}# DBTITLE 1,{titulo}\n{c}"

NB.write_text(SEP.join(celulas), encoding="utf-8")

# ---------------------------------------------------------------- conferência
final = NB.read_text(encoding="utf-8")
titulos = [l[len("# DBTITLE 1,"):] for l in final.split("\n")
           if l.startswith("# DBTITLE 1,")]

assert len(titulos) == len(TITULOS), f"{len(titulos)} aplicados, {len(TITULOS)} na lista"
assert len(set(titulos)) == len(titulos), "título repetido"
assert titulos == TITULOS, "a ordem aplicada não e a da lista"

# numeração contígua por seção, e crescente na ordem das células
por_secao = {}
for x in titulos:
    s, n = re.match(r"(\d+)\.(\d+)", x).groups()
    por_secao.setdefault(int(s), []).append(int(n))
for s, seq in por_secao.items():
    assert seq == list(range(1, len(seq) + 1)), f"seção {s} com furo na sequência: {seq}"
assert sorted(por_secao) == list(por_secao), "as seções não estão em ordem crescente"

longos = [x for x in titulos if len(x) > 24]
print(f"títulos aplicados: {len(titulos)}  |  todos únicos  |  numeração contígua")
print(f"seções: {sorted(por_secao)}")
print(f"acima de 24 caracteres: {longos if longos else 'nenhum'}")
