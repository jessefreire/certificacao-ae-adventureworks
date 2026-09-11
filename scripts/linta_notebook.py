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

# O console do Windows usa cp1252 e QUEBRA ao imprimir acento. Sem esta linha o
# script morre no meio do relatório com UnicodeEncodeError — e o erro parece ser
# do que ele estava conferindo, não da impressão.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
CONFIG = REPO / ".sqlfluff"

PADRAO = [
    REPO / "databricks" / "01-ingestao-adventure-works.sql",
    REPO / "databricks" / "02-analise-exploratoria.py",
]

SEPARADOR = "\n\n-- COMMAND ----------\n\n"
SEPARADOR_PY = "\n\n# COMMAND ----------\n\n"

# Sintaxe de ingestão do Databricks que a versão 1.4.5 não parseia.
NAO_PARSEAVEL = re.compile(r"\bread_files\s*\(|\bcopy into\b", re.I)

CORRIGIR = "--fix" in sys.argv
alvos = [Path(a) for a in sys.argv[1:] if not a.startswith("--")] or PADRAO


def celulas_de(caminho):
    """[(indice, sql)] das células de SQL, nos dois formatos de notebook."""
    texto = caminho.read_text(encoding="utf-8")
    if caminho.suffix == ".py":
        # notebook Python: SQL vive em célula marcada com `# MAGIC %sql`
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

    # notebook SQL: a célula JÁ e SQL; markdown vem prefixado por `-- MAGIC`
    saida = []
    for i, celula in enumerate(texto.split(SEPARADOR)):
        c = celula.replace("-- Databricks notebook source\n", "", 1)
        if c.lstrip().startswith("-- MAGIC"):
            continue
        if c.strip():
            saida.append((i, c.strip()))
    return texto, saida


def linta(pasta):
    """Devolve a saida do linter, com asseguração de que ele realmente rodou."""
    r = subprocess.run(
        ["uvx", "--from", "sqlfluff==1.4.5", "--with", "click<8.1", "sqlfluff",
         "fix" if CORRIGIR else "lint", ".", "--config", str(CONFIG)]
        + (["--force"] if CORRIGIR else []),
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        # cwd na própria pasta: o sqlfluff 1.4.5 quebra se o alvo estiver em
        # outro drive que o diretório de trabalho
        cwd=str(pasta),
    )
    saida = (r.stdout or "") + (r.stderr or "")
    assert "Traceback" not in saida, f"o sqlfluff quebrou:\n{saida[-900:]}"
    assert "Skipping" not in saida, f"arquivo PULADO em silêncio:\n{saida[-900:]}"
    assert "All Finished" in saida, f"o sqlfluff não concluiu:\n{saida[-900:]}"
    return saida


def confere_celulas(caminho, texto):
    """Nenhuma célula pode ser markdown sem o `%md`.

    Existe por um bug que chegou a rodar: ao inserir consultas novas, eu emendei no
    MEIO de células de markdown existentes, e o pedaco de baixo ficou sem o cabeçalho
    `%md`. O Databricks então executou texto como código, e a célula falhou com
    `SyntaxError: invalid character '—'` — o travessão do comentário.

    Foram três células, e uma delas era a SÍNTESE, a seção que o briefing pede
    explicitamente. O linter de SQL não pegava, porque essas células não tem SQL.
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
            erros.append(f"célula {i} esta vazia")
            continue

        tem_titulo = any(l.startswith(titulo) for l in uteis)
        # a linha de DBTITLE não conta para descobrir o TIPO da célula: foi esse
        # detalhe que fez a primeira versão desta checagem passar por um bug real
        conteudo = [l for l in uteis if not l.startswith(titulo)]
        if not conteudo:
            erros.append(f"célula {i} tem título e nada mais")
            continue

        primeira = conteudo[0].strip()
        todas_magic = all(l.strip().startswith(prefixo) for l in conteudo)

        if primeira.startswith(f"{prefixo} %md"):
            if not todas_magic:
                fora = next(l for l in conteudo if not l.strip().startswith(prefixo))
                erros.append(f"célula {i} e marcada %md mas tem CÓDIGO — nada nela "
                             f"executa: {fora.strip()[:50]}")
            elif len(conteudo) > 1 and conteudo[1].strip() == f"{prefixo} %md":
                erros.append(f"célula {i} tem %md duplicado")
        elif primeira.startswith(f"{prefixo} %sql"):
            if not todas_magic:
                fora = next(l for l in conteudo if not l.strip().startswith(prefixo))
                erros.append(f"célula {i} e marcada %sql mas tem linha fora do magic: "
                             f"{fora.strip()[:50]}")
            if not tem_titulo:
                erros.append(f"célula {i} de SQL sem DBTITLE — aparece sem nome na "
                             f"navegação")
        elif todas_magic:
            erros.append(f"célula {i} e markdown SEM %md — o Databricks vai executar "
                         f"como código: {primeira[:60]}")
        else:
            # célula de código na linguagem padrão do notebook
            if any(l.strip().startswith(f"{prefixo} %md") for l in conteudo):
                erros.append(f"célula {i} tem um %md no meio do código")
            if not tem_titulo:
                erros.append(f"célula {i} de código sem DBTITLE — aparece sem nome na "
                             f"navegação")
    return erros


def confere_titulos(caminho, texto):
    """Os títulos das células: únicos, numerados, contiguos e na ordem.

    O painel do Databricks corta o título em torno de 22 caracteres, então título
    longo e título com prefixo repetido são a mesma falha: quem lê não consegue
    distinguir uma célula da outra. A primeira versão dos títulos tinha 58
    caracteres de mediana e `gráfico` abrindo nove deles.

    O número tem de crescer junto com a ordem das células, senão a navegação ordena
    diferente do notebook — e ai o título atrapalha em vez de ajudar.
    """
    marca = "# DBTITLE 1," if caminho.suffix == ".py" else "-- DBTITLE 1,"
    titulos = [l[len(marca):] for l in texto.split("\n") if l.startswith(marca)]
    if not titulos:
        return ["nenhuma celula tem titulo"]

    erros = []

    repetidos = {x for x in titulos if titulos.count(x) > 1}
    if repetidos:
        erros.append(f"título repetido: {sorted(repetidos)[:3]}")

    sem_numero = [x for x in titulos if not re.match(r"\d+\.\d+ ", x)]
    if sem_numero:
        erros.append(f"título sem prefixo numérico: {sem_numero[:3]}")

    # Rótulo em prosa tem de caber; nome de tabela não tem o que encurtar sem
    # inventar abreviação, e o número mantem a célula localizável mesmo cortada.
    # Duas tabelas do AdventureWorks passam de 32 caracteres só no nome:
    # SalesOrderHeaderSalesReason e ProductModelProductDescriptionCulture.
    def rotulo(x):
        return re.sub(r"^\d+\.\d+ ", "", x)

    longos = [x for x in titulos
              if len(x) > 32 and " " in rotulo(x)]
    if longos:
        erros.append(f"título em prosa longo demais para o painel: {longos[:2]}")
    gigantes = [x for x in titulos if len(x) > 48]
    if gigantes:
        erros.append(f"título passa de 48 caracteres: {gigantes[:2]}")

    # numeração contígua por seção, e seções em ordem crescente
    ordem_secoes, por_secao = [], {}
    for x in titulos:
        m = re.match(r"(\d+)\.(\d+) ", x)
        if not m:
            continue
        s, n = int(m.group(1)), int(m.group(2))
        if s not in por_secao:
            por_secao[s] = []
            ordem_secoes.append(s)
        por_secao[s].append(n)
    for s, seq in por_secao.items():
        if seq != list(range(1, len(seq) + 1)):
            erros.append(f"seção {s} com furo ou fora de ordem na sequência: {seq}")
    if ordem_secoes != sorted(ordem_secoes):
        erros.append(f"as seções não aparecem em ordem crescente: {ordem_secoes}")

    return erros


def confere_abertura(caminho, texto):
    """A célula de abertura promete uma estrutura. Ela tem de ser verdade.

    Existe porque a abertura já mentiu três vezes: citava arquivos de ingestão que
    foram apagados na consolidação, dizia "cinco conferências" quando eram seis, e
    afirmava 17 tabelas quando o notebook lia 13. Documentação que desvia do
    artefato e pior do que documentação nenhuma — então o desvio passa a falhar
    aqui, e não a ser descoberto por leitura.
    """
    if caminho.name != "02-analise-exploratoria.py":
        return []

    celulas = texto.split(SEPARADOR_PY)
    erros = []

    # 1. nada de referência a arquivo que não existe mais
    for morto in ("00-ingestão", "01-ddl", "02-carga", "02.99", "03-verificação",
                  "notebooks/"):
        if morto in texto:
            erros.append(f"a abertura cita `{morto}`, que não existe mais")

    # 2. as seções prometidas existem
    for prometido in ("# 1. Perfil do dado", "# 2. Reconciliação", "# 9. Gráficos",
                      "# 10. Síntese"):
        if f"# MAGIC {prometido}" not in texto:
            erros.append(f"a abertura promete `{prometido}`, que não existe")

    # 3. a contagem por seção na tabela da abertura bate com a realidade
    marcos = []
    for i, c in enumerate(celulas):
        for nome in ("# 1. Perfil", "# 2. Reconciliação", "# 3. Pergunta",
                     "# 9. Gráficos", "# 10. Síntese"):
            if f"# MAGIC {nome}" in c:
                marcos.append((nome, i))
    marcos.sort(key=lambda x: x[1])
    real = {}
    for (nome, ini), (_, fim) in zip(marcos, marcos[1:] + [("fim", len(celulas))]):
        real[nome] = sum(1 for c in celulas[ini:fim]
                         if c.lstrip().startswith("# MAGIC %sql"))
    for nome, rotulo in (("# 1. Perfil", "perfil"), ("# 2. Reconciliação", "reconciliação"),
                         ("# 3. Pergunta", "as seis perguntas")):
        n = real.get(nome, 0)
        # singular e plural: a tabela escreve "1 consulta", não "1 consultas"
        if f"| {n} consulta |" not in texto and f"| {n} consultas |" not in texto:
            erros.append(
                f"{rotulo} tem {n} consulta(s), e a tabela da abertura diz outro número")

    # 4. quantos gráficos
    n_graficos = texto.count("plt.show()")
    if f"| {n_graficos} células Python |" not in texto:
        erros.append(f"são {n_graficos} gráficos, e a tabela da abertura diz outro número")

    # 5. quantas tabelas o notebook LÊ, contra o que a abertura afirma
    lidas = len(set(re.findall(r"workspace\.adventure_works\.(\w+)", texto)))
    if f"lê **{lidas}** tabelas" not in texto:
        erros.append(f"o notebook lê {lidas} tabelas, e a abertura afirma outro número")

    return erros


falhou = False
for alvo in alvos:
    texto, celulas = celulas_de(alvo)
    ingestao = [(i, s) for i, s in celulas if NAO_PARSEAVEL.search(s)]
    linta_veis = [(i, s) for i, s in celulas if not NAO_PARSEAVEL.search(s)]

    print(f"\n=== {alvo.name}")
    print(f"células de SQL: {len(celulas)}"
          f"  |  linteadas: {len(linta_veis)}"
          f"  |  ingestão, sintaxe não suportada pela 1.4.5: {len(ingestao)}")

    erros_celula = confere_celulas(alvo, texto)
    if erros_celula:
        falhou = True
        for erro in erros_celula:
            print(f"  CÉLULA QUEBRADA: {erro}")
    else:
        print("células: todas com o magic correto")

    erros_titulo = confere_titulos(alvo, texto)
    if erros_titulo:
        falhou = True
        for erro in erros_titulo:
            print(f"  TÍTULO: {erro}")
    else:
        marca = "# DBTITLE 1," if alvo.suffix == ".py" else "-- DBTITLE 1,"
        n = sum(1 for l in texto.split("\n") if l.startswith(marca))
        print(f"títulos: {n}, únicos, numerados e em ordem")

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
            # `;` colado no fim: em linha própria o L052 reclama
            (pasta / f"célula-{i:03d}.sql").write_text(sql.rstrip().rstrip(";") + ";\n",
                                                       encoding="utf-8")
        saida = linta(pasta)
        violacoes = [l for l in saida.split("\n") if l.startswith("L:")]
        print(f"violações: {len(violacoes)}")
        for l in violacoes[:25]:
            print("  " + l)
        for l in sorted({l.split("[")[-1].split("]")[0]
                         for l in saida.split("\n") if "FAIL" in l}):
            print("  célula com problema: " + l)

        if CORRIGIR and not violacoes:
            corrigidas = 0
            partes = texto.split(SEPARADOR_PY if alvo.suffix == ".py" else SEPARADOR)
            for i, _ in linta_veis:
                novo = (pasta / f"célula-{i:03d}.sql").read_text(
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
            print(f"devolvidas ao notebook: {corrigidas} células")
        elif violacoes:
            falhou = True

if falhou:
    sys.exit("há violação de code style — rode com --fix, ou corrija a mão")
print("\nok")
