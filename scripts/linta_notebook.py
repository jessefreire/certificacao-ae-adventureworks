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


def confere_celulas(caminho, texto):
    """Nenhuma celula pode ser markdown sem o `%md`.

    Existe por um bug que chegou a rodar: ao inserir consultas novas, eu emendei no
    MEIO de celulas de markdown existentes, e o pedaco de baixo ficou sem o cabecalho
    `%md`. O Databricks entao executou texto como codigo, e a celula falhou com
    `SyntaxError: invalid character '—'` — o travessao do comentario.

    Foram tres celulas, e uma delas era a SINTESE, a secao que o briefing pede
    explicitamente. O linter de SQL nao pegava, porque essas celulas nao tem SQL.
    """
    prefixo = "# MAGIC" if caminho.suffix == ".py" else "-- MAGIC"
    titulo = "# DBTITLE" if caminho.suffix == ".py" else "-- DBTITLE"
    sep = SEPARADOR_PY if caminho.suffix == ".py" else SEPARADOR
    erros = []

    for i, celula in enumerate(texto.split(sep), 1):   # o Databricks numera de 1
        corpo = celula.replace("# Databricks notebook source\n", "", 1)
        corpo = corpo.replace("-- Databricks notebook source\n", "", 1)
        uteis = [l for l in corpo.split("\n") if l.strip()]
        if not uteis:
            erros.append(f"celula {i} esta vazia")
            continue

        tem_titulo = any(l.startswith(titulo) for l in uteis)
        # a linha de DBTITLE nao conta para descobrir o TIPO da celula: foi esse
        # detalhe que fez a primeira versao desta checagem passar por um bug real
        conteudo = [l for l in uteis if not l.startswith(titulo)]
        if not conteudo:
            erros.append(f"celula {i} tem titulo e nada mais")
            continue

        primeira = conteudo[0].strip()
        todas_magic = all(l.strip().startswith(prefixo) for l in conteudo)

        if primeira.startswith(f"{prefixo} %md"):
            if not todas_magic:
                fora = next(l for l in conteudo if not l.strip().startswith(prefixo))
                erros.append(f"celula {i} e marcada %md mas tem CODIGO — nada nela "
                             f"executa: {fora.strip()[:50]}")
            elif len(conteudo) > 1 and conteudo[1].strip() == f"{prefixo} %md":
                erros.append(f"celula {i} tem %md duplicado")
        elif primeira.startswith(f"{prefixo} %sql"):
            if not todas_magic:
                fora = next(l for l in conteudo if not l.strip().startswith(prefixo))
                erros.append(f"celula {i} e marcada %sql mas tem linha fora do magic: "
                             f"{fora.strip()[:50]}")
            if not tem_titulo:
                erros.append(f"celula {i} de SQL sem DBTITLE — aparece sem nome na "
                             f"navegacao")
        elif todas_magic:
            erros.append(f"celula {i} e markdown SEM %md — o Databricks vai executar "
                         f"como codigo: {primeira[:60]}")
        else:
            # celula de codigo na linguagem padrao do notebook
            if any(l.strip().startswith(f"{prefixo} %md") for l in conteudo):
                erros.append(f"celula {i} tem um %md no meio do codigo")
            if not tem_titulo:
                erros.append(f"celula {i} de codigo sem DBTITLE — aparece sem nome na "
                             f"navegacao")
    return erros


def confere_abertura(caminho, texto):
    """A celula de abertura promete uma estrutura. Ela tem de ser verdade.

    Existe porque a abertura ja mentiu tres vezes: citava arquivos de ingestao que
    foram apagados na consolidacao, dizia "cinco conferencias" quando eram seis, e
    afirmava 17 tabelas quando o notebook lia 13. Documentacao que desvia do
    artefato e pior do que documentacao nenhuma — entao o desvio passa a falhar
    aqui, e nao a ser descoberto por leitura.
    """
    if caminho.name != "02-analise-exploratoria.py":
        return []

    celulas = texto.split(SEPARADOR_PY)
    erros = []

    # 1. nada de referencia a arquivo que nao existe mais
    for morto in ("00-ingestao", "01-ddl", "02-carga", "02.99", "03-verificacao",
                  "notebooks/"):
        if morto in texto:
            erros.append(f"a abertura cita `{morto}`, que nao existe mais")

    # 2. as secoes prometidas existem
    for prometido in ("# 1. Perfil do dado", "# 2. Reconciliacao", "# Graficos",
                      "# 9. Sintese"):
        if f"# MAGIC {prometido}" not in texto:
            erros.append(f"a abertura promete `{prometido}`, que nao existe")

    # 3. a contagem por secao na tabela da abertura bate com a realidade
    marcos = []
    for i, c in enumerate(celulas):
        for nome in ("# 1. Perfil", "# 2. Reconciliacao", "# 3. Pergunta",
                     "# Graficos", "# 9. Sintese"):
            if f"# MAGIC {nome}" in c:
                marcos.append((nome, i))
    marcos.sort(key=lambda x: x[1])
    real = {}
    for (nome, ini), (_, fim) in zip(marcos, marcos[1:] + [("fim", len(celulas))]):
        real[nome] = sum(1 for c in celulas[ini:fim]
                         if c.lstrip().startswith("# MAGIC %sql"))
    for nome, rotulo in (("# 1. Perfil", "perfil"), ("# 2. Reconciliacao", "reconciliacao"),
                         ("# 3. Pergunta", "as seis perguntas")):
        n = real.get(nome, 0)
        # singular e plural: a tabela escreve "1 consulta", nao "1 consultas"
        if f"| {n} consulta |" not in texto and f"| {n} consultas |" not in texto:
            erros.append(
                f"{rotulo} tem {n} consulta(s), e a tabela da abertura diz outro numero")

    # 4. quantos graficos
    n_graficos = texto.count("plt.show()")
    if f"| {n_graficos} celulas Python |" not in texto:
        erros.append(f"sao {n_graficos} graficos, e a tabela da abertura diz outro numero")

    # 5. quantas tabelas o notebook LE, contra o que a abertura afirma
    lidas = len(set(re.findall(r"workspace\.adventure_works\.(\w+)", texto)))
    if f"le **{lidas}** tabelas" not in texto:
        erros.append(f"o notebook le {lidas} tabelas, e a abertura afirma outro numero")

    return erros


falhou = False
for alvo in alvos:
    texto, celulas = celulas_de(alvo)
    ingestao = [(i, s) for i, s in celulas if NAO_PARSEAVEL.search(s)]
    linta_veis = [(i, s) for i, s in celulas if not NAO_PARSEAVEL.search(s)]

    print(f"\n=== {alvo.name}")
    print(f"celulas de SQL: {len(celulas)}"
          f"  |  linteadas: {len(linta_veis)}"
          f"  |  ingestao, sintaxe nao suportada pela 1.4.5: {len(ingestao)}")

    erros_celula = confere_celulas(alvo, texto)
    if erros_celula:
        falhou = True
        for erro in erros_celula:
            print(f"  CELULA QUEBRADA: {erro}")
    else:
        print("celulas: todas com o magic correto")

    erros_abertura = confere_abertura(alvo, texto)
    if erros_abertura:
        falhou = True
        for erro in erros_abertura:
            print(f"  ABERTURA MENTINDO: {erro}")
    elif alvo.name == "02-analise-exploratoria.py":
        print("abertura: confere com o notebook")

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
