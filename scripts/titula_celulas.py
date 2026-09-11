# -*- coding: utf-8 -*-
"""Da titulo as celulas de codigo do notebook de analise exploratoria.

    python scripts/titula_celulas.py

Rodar de novo e seguro: os titulos existentes sao removidos antes de reaplicar.

## Por que uma lista explicita, e nao titulo derivado do comentario

A primeira versao disto DERIVAVA o titulo da primeira linha de comentario de cada
celula. O resultado foi ruim de um jeito que so aparece no painel do Databricks:

  - titulo com 58 caracteres na mediana, contra ~22 visiveis — 40 de 42 cortados
  - `grafico` abrindo nove titulos e `perfil` abrindo sete, gastando o espaco
    visivel ANTES de chegar ao que distingue a celula
  - nenhuma numeracao, num notebook cujas secoes ja sao numeradas no markdown

Derivacao nao tem como saber disso. Lista explicita tem duas vantagens: e revisavel
antes de aplicar, e e estavel — o titulo nao muda porque alguem reescreveu um
comentario.

O preco e ter de manter a lista em sincronia com as celulas, e por isso o script
falha alto se a contagem nao casar, em vez de titular na ordem errada.

## O formato

`<secao>.<sequencia> <rotulo curto>`, com o numero da secao igual ao do cabecalho de
markdown. O numero vem primeiro porque sobrevive ao corte: `3.4 Catalogo sem venda`
truncado ainda e localizavel.

O codigo do aprofundamento (`a.1`, `b.2`) NAO entra no titulo. Ele nao distingue
celulas — havia dois `a.1`, dois `a.2`, dois `b.1` — e ja esta no cabecalho de
markdown imediatamente acima. Os quatro ultimos graficos sao a excecao: neles a letra
da pergunta e a informacao util, porque e o que o dashboard da Etapa 7 reaproveita.
"""
import re
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
NB = AQUI.parent / "databricks" / "02-analise-exploratoria.py"
SEP = "\n\n# COMMAND ----------\n\n"

# Os titulos, na ordem das celulas de codigo. Agrupados por secao so para leitura.
TITULOS = [
    # 1. Perfil do dado
    "1.1 Tamanho e janela",
    "1.2 Canais e receita",
    "1.3 Status constante",
    "1.4 Nulos por coluna",
    "1.5 Unicidade das PKs",
    "1.6 Produto sem subcat",
    "1.7 Subcat sem categoria",
    # 2. Reconciliacao
    "2.1 Aceite do CEO",
    # 3. Pergunta (a)
    "3.1 Metricas por pais",
    "3.2 Cartao discrimina?",
    "3.3 Cartao e proxy?",
    "3.4 Catalogo sem venda",
    "3.5 Receita no topo",
    "3.6 Motivo por canal",
    "3.7 Motivos por pedido",
    # 4. Pergunta (b)
    "4.1 Ticket por produto",
    "4.2 Desconto e material?",
    "4.3 Onde ha desconto",
    "4.4 Ticket por pais",
    "4.5 Tipo de oferta",
    # 5. Pergunta (c)
    "5.1 Top 10 clientes",
    "5.2 Concentracao no topo",
    "5.3 Recompra por canal",
    # 6. Pergunta (d)
    "6.1 Top 5 cidades",
    "6.2 Concentracao geog.",
    "6.3 Por territorio",
    "6.4 Valor x volume",
    # 7. Pergunta (e)
    "7.1 Serie mensal",
    "7.2 Quebra de jul/2013",
    "7.3 Ritmo da revenda",
    # 8. Pergunta (f)
    "8.1 Motivos existentes",
    "8.2 Unidades em promo",
    "8.3 Promo x pedido",
    # 9. Graficos
    "9.1 Serie e quebra",
    "9.2 Tipo de cartao",
    "9.3 Pareto de produtos",
    "9.4 Ticket por pais",
    "9.5 Promo no online",
    "9.6 (b) Ticket produto",
    "9.7 (c) Top 10 clientes",
    "9.8 (d) Cidades x resto",
    "9.9 (f) Promo unidades",
]

# A secao de graficos nao tinha numero no markdown, e fica entre a 8 e a 9. Sem
# numerar ela, os nove graficos ficariam sem prefixo — o que e justamente o que se
# quer corrigir. Entao ela vira a 9 e a sintese vira a 10.
RENUMERA = [
    ("# MAGIC # Graficos", "# MAGIC # 9. Graficos"),
    ("# MAGIC # 9. Sintese — o que a exploracao mudou no entendimento",
     "# MAGIC # 10. Sintese — o que a exploracao mudou no entendimento"),
    ("| **Graficos** | Nove, em dois grupos — ver abaixo | 9 celulas Python |",
     "| **9. Graficos** | Nove, em dois grupos — ver abaixo | 9 celulas Python |"),
    ("| **9. Sintese** | O que a exploracao mudou no entendimento do dataset, "
     "que e a frase que o briefing pede | — |",
     "| **10. Sintese** | O que a exploracao mudou no entendimento do dataset, "
     "que e a frase que o briefing pede | — |"),
]


def e_codigo(celula):
    """A celula executa algo? Markdown nao conta, e o DBTITLE nao define o tipo."""
    uteis = [l for l in celula.split("\n") if l.strip()]
    uteis = [l for l in uteis if not l.startswith("# DBTITLE")]
    uteis = [l for l in uteis if l != "# Databricks notebook source"]
    if not uteis:
        return False
    return not uteis[0].strip().startswith("# MAGIC %md")


t = NB.read_text(encoding="utf-8")

for velho, novo in RENUMERA:
    if novo in t:
        continue                      # ja renumerado numa rodada anterior
    assert t.count(velho) == 1, f"nao achei para renumerar: {velho[:50]}"
    t = t.replace(velho, novo)

# limpa titulos anteriores antes de reaplicar
t = "\n".join(l for l in t.split("\n") if not l.startswith("# DBTITLE"))
celulas = t.split(SEP)

indices = [i for i, c in enumerate(celulas) if e_codigo(c)]
assert len(indices) == len(TITULOS), (
    f"o notebook tem {len(indices)} celulas de codigo e a lista tem {len(TITULOS)} "
    f"titulos. Alguem adicionou ou removeu celula: atualize TITULOS.")

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

# ---------------------------------------------------------------- conferencia
final = NB.read_text(encoding="utf-8")
titulos = [l[len("# DBTITLE 1,"):] for l in final.split("\n")
           if l.startswith("# DBTITLE 1,")]

assert len(titulos) == len(TITULOS), f"{len(titulos)} aplicados, {len(TITULOS)} na lista"
assert len(set(titulos)) == len(titulos), "titulo repetido"
assert titulos == TITULOS, "a ordem aplicada nao e a da lista"

# numeracao contigua por secao, e crescente na ordem das celulas
por_secao = {}
for x in titulos:
    s, n = re.match(r"(\d+)\.(\d+)", x).groups()
    por_secao.setdefault(int(s), []).append(int(n))
for s, seq in por_secao.items():
    assert seq == list(range(1, len(seq) + 1)), f"secao {s} com furo na sequencia: {seq}"
assert sorted(por_secao) == list(por_secao), "as secoes nao estao em ordem crescente"

longos = [x for x in titulos if len(x) > 24]
print(f"titulos aplicados: {len(titulos)}  |  todos unicos  |  numeracao contigua")
print(f"secoes: {sorted(por_secao)}")
print(f"acima de 24 caracteres: {longos if longos else 'nenhum'}")
