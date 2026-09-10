# -*- coding: utf-8 -*-
"""Aplica o code style da casa ao SQL que vive dentro dos notebooks.

    python scripts/linta_notebook.py [arquivo ...]

Sem argumento, confere os dois notebooks de `databricks/`.

## Por que existe

O sqlfluff nao le notebook. Sem esta ferramenta, o padrao da casa nao alcanca
justamente o SQL que o avaliador vai ler. O ciclo e: extrair cada celula para um
arquivo proprio, rodar o linter, e — com `--fix` — devolver o SQL corrigido para
dentro da celula.

Um arquivo por celula, e nao um arquivo com tudo, porque assim o erro aponta a
celula.

## As celulas de ingestao nao sao linteadas, e isso e declarado

A versao 1.4.5, que o guia da casa fixa, e de 2022 e nao parseia a sintaxe de
ingestao do Databricks — nem `COPY INTO`, nem o parametro nomeado do `read_files`
(`format => 'csv'`). Em vez de excluir o arquivo inteiro do lint, o que jogaria fora
tambem as celulas de conferencia, esta ferramenta SEPARA as duas famílias: as celulas
de ingestao sao contadas e declaradas, e todas as outras tem de passar com zero
violacao.

## Duas falhas que devolvem falso sucesso, e por isso as asseguracoes

  - arquivo acima de 20.000 bytes e PULADO em silencio, com aviso e "All Finished!"
    no fim — indistinguivel de sucesso. Desligado no `.sqlfluff` da raiz.
  - o sqlfluff 1.4.5 QUEBRA quando o alvo esta em outro drive que o diretorio de
    trabalho (`ValueError: Paths don't have the same drive`, no `os.path.commonpath`).
    O crash saía silencioso e o relatorio dizia zero violacao quando eram 78.

Por isso o script falha alto se o linter nao concluir, e vale rodar teste negativo —
introduzir violacao de proposito — antes de confiar num "zero".
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
CONFIG = REPO / ".sqlfluff"

PADRAO = [
    REPO / "databricks" / "ingestao-adventure-works.sql",
    REPO / "databricks" / "02-analise-exploratoria.py",
]

SEPARADOR = "\n\n-- COMMAND ----------\n\n"
SEPARADOR_PY = "\n\n# COMMAND ----------\n\n"

# Sintaxe de ingestao do Databricks que a versao 1.4.5 nao parseia.
NAO_PARSEAVEL = re.compile(r"\bread_files\s*\(|\bcopy into\b", re.I)

CORRIGIR = "--fix" in sys.argv
alvos = [Path(a) for a in sys.argv[1:] if not a.startswith("--")] or PADRAO


def celulas_de(caminho):
    """[(indice, sql)] das celulas de SQL, nos dois formatos de notebook."""
    texto = caminho.read_text(encoding="utf-8")
    if caminho.suffix == ".py":
        # notebook Python: SQL vive em celula marcada com `# MAGIC %sql`
        saida = []
        for i, celula in enumerate(texto.split(SEPARADOR_PY)):
            linhas = celula.split("\n")
            if not linhas[0].strip().startswith("# MAGIC %sql"):
                continue
            corpo = [l[len("# MAGIC "):] if l.startswith("# MAGIC ") else ""
                     for l in linhas[1:] if l.strip().startswith("# MAGIC")]
            sql = "\n".join(corpo).rstrip()
            if sql:
                saida.append((i, sql))
        return texto, saida

    # notebook SQL: a celula JA e SQL; markdown vem prefixado por `-- MAGIC`
    saida = []
    for i, celula in enumerate(texto.split(SEPARADOR)):
        c = celula.replace("-- Databricks notebook source\n", "", 1)
        if c.lstrip().startswith("-- MAGIC"):
            continue
        if c.strip():
            saida.append((i, c.strip()))
    return texto, saida


def linta(pasta):
    """Devolve a saida do linter, com asseguracao de que ele realmente rodou."""
    r = subprocess.run(
        ["uvx", "--from", "sqlfluff==1.4.5", "--with", "click<8.1", "sqlfluff",
         "fix" if CORRIGIR else "lint", ".", "--config", str(CONFIG)]
        + (["--force"] if CORRIGIR else []),
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        # cwd na propria pasta: o sqlfluff 1.4.5 quebra se o alvo estiver em
        # outro drive que o diretorio de trabalho
        cwd=str(pasta),
    )
    saida = (r.stdout or "") + (r.stderr or "")
    assert "Traceback" not in saida, f"o sqlfluff quebrou:\n{saida[-900:]}"
    assert "Skipping" not in saida, f"arquivo PULADO em silencio:\n{saida[-900:]}"
    assert "All Finished" in saida, f"o sqlfluff nao concluiu:\n{saida[-900:]}"
    return saida


falhou = False
for alvo in alvos:
    texto, celulas = celulas_de(alvo)
    ingestao = [(i, s) for i, s in celulas if NAO_PARSEAVEL.search(s)]
    linta_veis = [(i, s) for i, s in celulas if not NAO_PARSEAVEL.search(s)]

    print(f"\n=== {alvo.name}")
    print(f"celulas de SQL: {len(celulas)}"
          f"  |  linteadas: {len(linta_veis)}"
          f"  |  ingestao, sintaxe nao suportada pela 1.4.5: {len(ingestao)}")

    if not linta_veis:
        continue

    with tempfile.TemporaryDirectory(dir=REPO) as tmp:
        pasta = Path(tmp)
        for i, sql in linta_veis:
            # `;` colado no fim: em linha propria o L052 reclama
            (pasta / f"celula-{i:03d}.sql").write_text(sql.rstrip().rstrip(";") + ";\n",
                                                       encoding="utf-8")
        saida = linta(pasta)
        violacoes = [l for l in saida.split("\n") if l.startswith("L:")]
        print(f"violacoes: {len(violacoes)}")
        for l in violacoes[:25]:
            print("  " + l)
        for l in sorted({l.split("[")[-1].split("]")[0]
                         for l in saida.split("\n") if "FAIL" in l}):
            print("  celula com problema: " + l)

        if CORRIGIR and not violacoes:
            corrigidas = 0
            partes = texto.split(SEPARADOR_PY if alvo.suffix == ".py" else SEPARADOR)
            for i, _ in linta_veis:
                novo = (pasta / f"celula-{i:03d}.sql").read_text(
                    encoding="utf-8").rstrip().removesuffix(";").rstrip()
                if alvo.suffix == ".py":
                    partes[i] = "\n".join(
                        ["# MAGIC %sql"] + [f"# MAGIC {l}".rstrip()
                                            for l in novo.split("\n")])
                else:
                    partes[i] = novo + ";"
                corrigidas += 1
            alvo.write_text(
                (SEPARADOR_PY if alvo.suffix == ".py" else SEPARADOR).join(partes),
                encoding="utf-8")
            print(f"devolvidas ao notebook: {corrigidas} celulas")
        elif violacoes:
            falhou = True

if falhou:
    sys.exit("ha violacao de code style — rode com --fix, ou corrija a mao")
print("\nok")
