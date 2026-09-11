# -*- coding: utf-8 -*-
"""Simula, no dado real, cada cast que o notebook de ingestão vai executar.

    python scripts/audita_tipos.py [caminho-da-pasta-AdventureWorks]

## Por que existe

A carga quebrou três vezes em execução, e as três poderiam ter sido previstas aqui:

  - `CAST_INVALID_INPUT` no `'EA '` indo para decimal, porque a lista de colunas
    monetárias era aplicada pelo nome sem olhar o tipo de origem
  - cinco colunas `decimal(p, s)` viravam string em silêncio
  - `FAILED_READ_FILE` em arquivo cujo campo aspado tem TAB

Descobrir isso na célula 39 de 80, depois de esperar cota da Free Edition, custa uma
tarde. Descobrir aqui custa trinta segundos.

Lê a fonte da verdade certa: o **notebook gerado**, não o `install.sql`. O que
importa e o cast que vai rodar de fato, com o tipo que o gerador decidiu.

## O que confere, valor por valor

| Tipo destino | Rejeita |
|---|---|
| `int` / `smallint` / `bigint` | não numérico, ou fora da faixa do tipo |
| `decimal(p, s)` | digitos inteiros acima de `p - s` (estouro de precisão) |
| `timestamp` | texto que não casa com os formatos do arquivo |
| `boolean` | valor fora do conjunto que o Spark aceita |
| `string` | nada |

Campo vazio nunca e rejeitado: o `nullValue => ''` da carga o transforma em NULL
antes do cast.
"""
import csv
import os
import re
import sys
from decimal import Decimal, InvalidOperation
from pathlib import Path

# O console do Windows usa cp1252 e QUEBRA ao imprimir acento. Sem esta linha o
# script morre no meio do relatório com UnicodeEncodeError — e o erro parece ser
# do que ele estava conferindo, não da impressão.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
NOTEBOOK = REPO / "databricks" / "01-ingestao-adventure-works.sql"

PADRAO_ORIGEM = Path(
    r"D:\Documentos\Indicium AI\Formação AE\Desafio\adventureworks-oficial\AdventureWorks")
ORIGEM = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(os.environ.get("AW_HOME", PADRAO_ORIGEM))

FAIXA = {"int": (-2**31, 2**31 - 1),
         "smallint": (-2**15, 2**15 - 1),
         "bigint": (-2**63, 2**63 - 1)}

# o Spark aceita estes, em qualquer caixa, ao converter texto para boolean
BOOLEANOS = {"t", "true", "y", "yes", "1", "f", "false", "n", "no", "0"}

FORMATOS_TS = [
    re.compile(r"^\d{4}-\d{2}-\d{2}$"),
    re.compile(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d+)?$"),
    re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$"),
]


def invalido(valor, tipo):
    """Devolve o motivo da rejeição, ou None se o cast passa."""
    if valor == "":
        return None          # nullValue => '' transforma em NULL antes do cast

    if tipo in FAIXA:
        try:
            n = int(valor)
        except ValueError:
            return "não e inteiro"
        lo, hi = FAIXA[tipo]
        return None if lo <= n <= hi else f"fora da faixa de {tipo}"

    m = re.match(r"decimal\((\d+),\s*(\d+)\)", tipo)
    if m:
        p, s = int(m.group(1)), int(m.group(2))
        try:
            d = Decimal(valor)
        except InvalidOperation:
            return "não e número"
        inteiros = len(d.quantize(Decimal(1)).as_tuple().digits)
        if d.quantize(Decimal(1)) == 0:
            inteiros = 0
        return None if inteiros <= p - s else f"estoura decimal({p}, {s})"

    if tipo == "timestamp":
        return None if any(f.match(valor) for f in FORMATOS_TS) else "não parece data"

    if tipo == "boolean":
        return None if valor.strip().lower() in BOOLEANOS else "não e booleano"

    return None              # string aceita qualquer coisa


# ---------------------------------------------------------------- lê o notebook
assert NOTEBOOK.exists(), f"não achei {NOTEBOOK}. Rode scripts/gera_ingestao.py antes."
texto = NOTEBOOK.read_text(encoding="utf-8")

celulas = []
for c in texto.split("\n\n-- COMMAND ----------\n\n"):
    if "read_files(" not in c:
        continue
    tabela = re.search(r"create or replace table \S+\.(\w+) as", c).group(1)
    arquivo = re.search(r"data/([\w.]+)\.csv", c).group(1)
    casts = re.findall(r"cast\(_c(\d+) as ([\w()\s,]+?)\) as (`?\w+`?)", c)
    celulas.append((tabela, arquivo, [(int(i), t.strip(), n.strip("`")) for i, t, n in casts]))

print(f"células de carga no notebook: {len(celulas)}")
print(f"colunas com cast: {sum(len(c[2]) for c in celulas)}\n")

# ---------------------------------------------------------------- simula
problemas = []
for tabela, arquivo, casts in celulas:
    p = ORIGEM / "data" / f"{arquivo}.csv"
    assert p.exists(), f"{tabela}: não achei {p.name}"
    with open(p, encoding="utf-8", errors="replace", newline="") as f:
        linhas = [r for r in csv.reader(f, delimiter="\t", quotechar='"') if r]

    # o mesmo defeito que derrubou o productmodel: linha com contagem diferente
    contagens = {len(r) for r in linhas}
    if len(contagens) != 1:
        problemas.append((tabela, "-", "-", f"linhas com {sorted(contagens)} campos",
                          len(linhas)))
        continue
    if next(iter(contagens)) != len(casts):
        problemas.append((tabela, "-", "-",
                          f"{next(iter(contagens))} campos no arquivo, "
                          f"{len(casts)} casts", len(linhas)))
        continue

    for pos, tipo, nome in casts:
        ruins, exemplo = 0, None
        for r in linhas:
            motivo = invalido(r[pos], tipo)
            if motivo:
                ruins += 1
                if exemplo is None:
                    exemplo = (r[pos][:40], motivo)
        if ruins:
            problemas.append((tabela, nome, tipo,
                              f"{exemplo[1]} — ex.: {exemplo[0]!r}", ruins))

# ---------------------------------------------------------------- relatório
if not problemas:
    print("Nenhum cast vai falhar. As células de carga rodam limpas.")
else:
    print(f"{'tabela':<26} {'coluna':<22} {'destino':<16} {'linhas':>7}  problema")
    print("-" * 110)
    for tabela, nome, tipo, motivo, n in problemas:
        print(f"{tabela:<26} {nome:<22} {tipo:<16} {n:>7}  {motivo}")
    print("-" * 110)
    print(f"{len(problemas)} problema(s) — cada um derrubaria a célula da tabela")
    sys.exit(1)
