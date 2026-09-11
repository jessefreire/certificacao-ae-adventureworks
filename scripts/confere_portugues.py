# -*- coding: utf-8 -*-
"""Confere o português dos materiais: acento faltando e mojibake.

    python scripts/confere_portugues.py [arquivo ...]

Sem argumento, varre a prosa versionada do repositório.

## Por que existe

Eu escrevi ASCII de propósito em quase todo o código deste repositório, por um
receio de encoding que a medição desmentiu: não havia uma única ocorrência de
mojibake em arquivo nenhum, e o `docs/01-kpis-e-perguntas.md` sempre teve 976
caracteres acentuados e 117 cedilhas intactos. Acento sempre funcionou no caminho
de escrita, no SQL e no Databricks — o hábito era meu, não uma restrição técnica.

## O que é prosa, e o que é código

Esta é a parte que importa, e a que duas tentativas erradas ensinaram:

  - acentuar um identificador quebra o código (`ESCOPO_ANALISE`)
  - acentuar um nome de arquivo quebra o caminho: a primeira tentativa
    transformou `01-ingestao-adventure-works.sql` em `ingestão-...` dentro de um
    `Path(...)`, e o script passaria a abrir arquivo inexistente
  - acentuar SQL quebra a consulta: a segunda tentativa trocou o alias `juncao`
    por `junção` dentro de uma célula `%sql`, e o linter reprovou

Por isso a prosa é extraída por contexto, e não por arquivo inteiro. A mesma
função serve ao verificador e ao corretor, para os dois nunca discordarem sobre
o que pode ser tocado.

| Arquivo | Prosa é |
|---|---|
| `.md` | tudo, menos bloco de código cercado e trecho em crase |
| `.sql` | só o que vem depois de `--`, o que inclui markdown de notebook e `DBTITLE` |
| `.py` | comentários e textos; dentro de célula `%sql`, só as linhas `--` |
| `.txt` | tudo |

E, em qualquer arquivo, ficam protegidos: URL, caminho com barra, nome de arquivo
com extensão e os nomes dos artefatos do projeto.

## Acento faltando

A lista abaixo só tem palavras que NÃO existem em português sem o acento, de modo
que um acusado é sempre um erro real. Ficam deliberadamente de fora as ambíguas —
`e`/`é`, `esta`/`está`, `ate`/`até`, `para`/`pára` — porque a forma sem acento
também é palavra válida.
"""
import io
import re
import sys
import tokenize
import unicodedata
from collections import Counter
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent

FALTA = {
    "nao": "não", "sao": "são", "voce": "você", "codigo": "código",
    "analise": "análise", "analises": "análises", "conferencia": "conferência",
    "conferencias": "conferências", "referencia": "referência",
    "referencias": "referências", "numero": "número", "numeros": "números",
    "ja": "já", "so": "só", "tambem": "também", "proprio": "próprio",
    "propria": "própria", "proprios": "próprios", "proprias": "próprias",
    "estao": "estão", "sera": "será", "serao": "serão", "apos": "após",
    "atraves": "através", "tres": "três", "ultima": "última", "ultimo": "último",
    "ultimos": "últimos", "ultimas": "últimas", "unico": "único", "unica": "única",
    "unicos": "únicos", "unicas": "únicas", "possivel": "possível",
    "impossivel": "impossível", "disponivel": "disponível", "legivel": "legível",
    "ilegivel": "ilegível", "variavel": "variável", "variaveis": "variáveis",
    "confiavel": "confiável", "memoria": "memória", "historico": "histórico",
    "automatico": "automático", "automatica": "automática", "basico": "básico",
    "logico": "lógico", "tecnico": "técnico", "tecnica": "técnica",
    "pratico": "prático", "pratica": "prática", "publico": "público",
    "publica": "pública", "minimo": "mínimo", "minima": "mínima",
    "maximo": "máximo", "maxima": "máxima", "precisao": "precisão",
    "decisao": "decisão", "decisoes": "decisões", "versao": "versão",
    "versoes": "versões", "razao": "razão", "razoes": "razões",
    "validacao": "validação", "documentacao": "documentação",
    "execucao": "execução", "execucoes": "execuções", "ingestao": "ingestão",
    "exploracao": "exploração", "apuracao": "apuração", "informacao": "informação",
    "informacoes": "informações", "configuracao": "configuração",
    "duplicacao": "duplicação", "observacao": "observação",
    "observacoes": "observações", "conclusao": "conclusão",
    "conclusoes": "conclusões", "excecao": "exceção", "excecoes": "exceções",
    "instrucao": "instrução", "instrucoes": "instruções", "secao": "seção",
    "secoes": "seções", "opcao": "opção", "opcoes": "opções",
    "posicao": "posição", "posicoes": "posições", "relacao": "relação",
    "definicao": "definição", "definicoes": "definições", "cabecalho": "cabeçalho",
    "cabecalhos": "cabeçalhos", "servico": "serviço", "comeca": "começa",
    "comecar": "começar", "comecou": "começou", "preco": "preço",
    "precos": "preços", "licao": "lição", "licoes": "lições",
    "asseguracao": "asseguração", "asseguracoes": "assegurações",
    "acao": "ação", "acoes": "ações", "padrao": "padrão", "padroes": "padrões",
    "pagina": "página", "paginas": "páginas", "area": "área", "areas": "áreas",
    "criterio": "critério", "criterios": "critérios", "obvio": "óbvio",
    "obvia": "óbvia", "serie": "série", "mes": "mês", "ingles": "inglês",
    "portugues": "português", "ninguem": "ninguém", "alguem": "alguém",
    "porem": "porém", "alem": "além", "consequencia": "consequência",
    "consequencias": "consequências", "evidencia": "evidência",
    "evidencias": "evidências", "experiencia": "experiência",
    "frequencia": "frequência", "tendencia": "tendência", "sequencia": "sequência",
    "transacao": "transação", "transacoes": "transações", "dimensao": "dimensão",
    "dimensoes": "dimensões", "inversao": "inversão", "pulverizacao": "pulverização",
    "renumeracao": "renumeração", "navegacao": "navegação", "orfao": "órfão",
    "numeracao": "numeração", "contigua": "contígua", "contiguas": "contíguas",
    "contiguo": "contíguo", "violacao": "violação", "violacoes": "violações",
    "derivacao": "derivação", "rejeicao": "rejeição", "explicita": "explícita",
    "explicito": "explícito", "monetarias": "monetárias", "monetaria": "monetária",
    "reconciliacao": "reconciliação", "territorio": "território",
    "metricas": "métricas", "metrica": "métrica", "catalogo": "catálogo",
    "concentracao": "concentração",
    "orfaos": "órfãos", "medio": "médio", "media": "média", "medias": "médias",
    "medios": "médios", "cartao": "cartão", "cartoes": "cartões",
    "gerencia": "gerência", "ordenacao": "ordenação", "sintese": "síntese",
    "grafico": "gráfico", "graficos": "gráficos", "duvida": "dúvida",
    "duvidas": "dúvidas", "diario": "diário", "necessario": "necessário",
    "necessaria": "necessária", "usuario": "usuário", "usuarios": "usuários",
    "relatorio": "relatório", "relatorios": "relatórios",
    "obrigatorio": "obrigatório", "obrigatoria": "obrigatória",
    "proposito": "propósito", "silencio": "silêncio", "prejuizo": "prejuízo",
    "residuo": "resíduo", "arbitraria": "arbitrária", "arbitrario": "arbitrário",
    "multiplo": "múltiplo", "multiplos": "múltiplos", "identico": "idêntico",
    "identica": "idêntica", "identicos": "idênticos", "identicas": "idênticas",
    "importancia": "importância", "ausencia": "ausência", "presenca": "presença",
    "diferenca": "diferença", "diferencas": "diferenças", "confianca": "confiança",
    "mudanca": "mudança", "mudancas": "mudanças", "seguranca": "segurança",
    "provavel": "provável", "util": "útil", "uteis": "úteis", "inutil": "inútil",
    "nivel": "nível", "niveis": "níveis", "responsavel": "responsável",
    "estavel": "estável", "compativel": "compatível",
    "incompativel": "incompatível", "visivel": "visível", "invisivel": "invisível",
    "credito": "crédito", "estrategia": "estratégia", "sucesso": "sucesso",
    "familia": "família", "familias": "famílias", "intuitiva": "intuitiva",
}
FALTA = {k: v for k, v in FALTA.items() if k != v}

# Palavras em que a forma SEM acento também é palavra válida do português. Nunca entram
# no dicionário, nem escritas à mão nem derivadas do corpus — acusá-las produziria falso
# positivo, e um verificador com falso positivo deixa de ser lido.
AMBIGUAS = {
    # artigo, contração e pronome contra a forma acentuada
    "a", "as", "no", "nos", "e", "esta", "estas", "este", "ate", "para", "da", "de",
    "do", "por", "pode", "la", "lo", "pais",
    # singular contra plural do verbo
    "tem", "vem",
    # verbo contra substantivo ou contra infinitivo com pronome (`ligá-la`)
    "liga", "acompanha", "caia", "continuo", "valido", "conta", "torna", "sabia",
    "critica", "medida", "secretaria", "duvida", "publica", "pratica",
}

# O dicionário escrito à mão erra por omissão: ele cobre o que alguém lembrou de listar.
# Foi assim que `promocao`, `associacao` e `submissao` passaram por três revisões. A
# correção não é escrever mais palavras — é parar de depender de memória.
#
# Toda palavra acentuada que JÁ existe na prosa do repositório é prova de como ela se
# escreve. Basta tirar o acento dela para obter a forma errada correspondente, e então
# procurar por essa forma. O dicionário passa a crescer sozinho com o texto.
def _sem_acento(palavra):
    return unicodedata.normalize("NFKD", palavra).encode("ascii", "ignore").decode()


# A derivação tem um ponto cego: ela só aprende palavra que o corpus escreve certo em
# algum lugar. `submissao` aparecia duas vezes, errado nas duas, e por isso era invisível
# — ninguém tinha escrito `submissão` para servir de exemplo.
#
# Estes sufixos cobrem esse vão. São terminações em que o acento é obrigatório em
# português, sem exceção que valha a pena tratar. Não entram `-vel` solto (quebraria
# `level`) nem `-ao` solto (quebraria `grao` já coberto e nomes próprios).
SUFIXOS = [
    ("coes", "ções"), ("soes", "sões"), ("cao", "ção"), ("sao", "são"),
    ("encia", "ência"), ("ancia", "ância"), ("avel", "ável"), ("ivel", "ível"),
    ("orio", "ório"), ("ario", "ário"),
]
# `-aria` ficou de fora deliberadamente: colide com o futuro do pretérito — `gastaria`,
# `ignoraria`, `derrubaria` — e com `varia`. Foi o teste que mostrou, não o raciocínio.

# Palavras que casam um sufixo mas não são português.
ESTRANGEIRAS = {"scenario", "primario", "ratio", "level", "novel", "travel", "ario"}


def suspeita_por_sufixo(palavra):
    """Forma acentuada provável, ou None. Usada só quando a derivação não conhece a palavra."""
    p = palavra.lower()
    if p in ESTRANGEIRAS or p in AMBIGUAS or len(p) < 5:
        return None
    for errado, certo in SUFIXOS:
        if p.endswith(errado):
            return p[: -len(errado)] + certo
    return None


def deriva_do_corpus(textos):
    """Mapa `forma errada -> forma certa` extraído das palavras acentuadas do próprio texto."""
    derivado = {}
    for texto in textos:
        for palavra in re.findall(r"\b\w+\b", texto, re.UNICODE):
            if not any(ord(c) > 127 for c in palavra):
                continue
            correta = palavra.lower()
            errada = _sem_acento(correta)
            if errada == correta or not errada.isalpha() or errada in AMBIGUAS:
                continue
            derivado[errada] = correta
    return derivado

MOJIBAKE = re.compile(r"Ã[\x80-\xbf]|Â[\x80-\xbf]|â€|�")

# Nunca tocar: acentuar qualquer um destes quebra caminho, link ou identificador.
PROTEGIDO = [
    re.compile(r"https?://\S+"),
    re.compile(r"\b[\w.-]+(?:/[\w.-]+)+\b"),
    re.compile(r"\b[\w][\w.-]*\.(?:py|sql|md|txt|csv|json|pptx|docx|ipynb|yml|yaml)\b"),
    re.compile(r"\b(?:01-ingestao-adventure-works|02-analise-exploratoria|gera_ingestao|"
               r"linta_notebook|titula_celulas|audita_tipos|confere_portugues|"
               r"01-kpis-e-perguntas|01\.01-mapa-completo|desafio-adventureworks|"
               r"adventureworks-oficial|raw_adventure_works|adventure_works|"
               r"formacao-analytics-engineering)\b"),
    # Subscrito de string é nome de coluna vindo do alias do SQL, que fica em ASCII.
    # Sem esta linha o corretor lê `grupo["mes"]` como prosa, escreve `mês`, e o
    # gráfico morre com KeyError na execução — foi o que aconteceu.
    re.compile(r"""\[\s*["'][^"'\]]+["']\s*\]"""),
]

BLOCO_CODIGO = re.compile(r"```.*?```", re.S)
CRASE = re.compile(r"`[^`\n]+`")
TEM_SQL = re.compile(r"\b(select|create or replace|read_files|union all|from workspace)\b", re.I)

# A partir do Python 3.12 a f-string deixou de ser um token STRING e passou a ser
# FSTRING_START / FSTRING_MIDDLE / FSTRING_END. Sem incluir o MIDDLE, todo texto
# dentro de f-string escapava da verificacao E da correcao — foi assim que 42
# ocorrencias sobreviveram a primeira passagem, todas em `md(f"""...""")`.
FSTRING_START = getattr(tokenize, "FSTRING_START", -1)
FSTRING_MIDDLE = getattr(tokenize, "FSTRING_MIDDLE", -2)
FSTRING_END = getattr(tokenize, "FSTRING_END", -3)

IGNORA = {"confere_portugues.py"}
PADROES = ["README.md", "docs/*.md", "databricks/*.sql", "databricks/*.py",
           "scripts/*.py", "entrega/*.txt"]


def _linhas_de_comentario_sql(texto, base=0):
    """Spans das linhas `--` de um trecho de SQL. O resto é consulta."""
    pos, spans = base, []
    for linha in texto.splitlines(keepends=True):
        s = linha.lstrip()
        if s.startswith("--"):
            ini = pos + (len(linha) - len(s)) + 2
            spans.append((ini, pos + len(linha.rstrip("\n"))))
        pos += len(linha)
    return spans


def regioes_prosa(caminho, texto):
    """[(inicio, fim)] do que é prosa neste arquivo. O resto é código."""
    if caminho.suffix == ".md":
        spans, fim = [], 0
        proibido = [(m.start(), m.end()) for m in BLOCO_CODIGO.finditer(texto)]
        proibido += [(m.start(), m.end()) for m in CRASE.finditer(texto)]
        for a, b in sorted(proibido):
            if a > fim:
                spans.append((fim, a))
            fim = max(fim, b)
        spans.append((fim, len(texto)))
        return spans

    if caminho.suffix == ".txt":
        return [(0, len(texto))]

    if caminho.suffix == ".sql":
        return _linhas_de_comentario_sql(texto)

    # .py — comentários e textos, com as células %sql tratadas como SQL
    linhas = texto.splitlines(keepends=True)
    inicio_da_linha = [0]
    for l in linhas:
        inicio_da_linha.append(inicio_da_linha[-1] + len(l))

    spans, modo, markdown, pendentes = [], None, False, None
    for tok in tokenize.generate_tokens(io.StringIO(texto).readline):
        base = inicio_da_linha[tok.start[0] - 1] + tok.start[1]

        # Texto passado para `md(...)` é markdown de célula por definição, mesmo
        # quando MENCIONA SQL. Sem esta marca, o bloco que explica
        # `create or replace table ... as select` seria lido como consulta e
        # ficaria sem acento — foi o que sobrou de uma passagem anterior.
        if tok.type == tokenize.NAME and tok.string == "md":
            markdown = True
        elif tok.type == tokenize.NEWLINE:
            markdown = False

        if tok.type == tokenize.COMMENT:
            s = tok.string
            if s.startswith("# MAGIC %sql"):
                modo = "sql"
                continue
            if s.startswith("# MAGIC %md"):
                modo = "md"
                continue
            if s.startswith("# COMMAND"):
                modo = None
                continue
            if s.startswith("# MAGIC"):
                interno = s[len("# MAGIC"):]
                desloc = len(s) - len(interno)
                if modo == "sql":
                    # dentro de célula SQL, só a linha `--` é prosa
                    spans += _linhas_de_comentario_sql(interno, base + desloc)
                else:
                    spans.append((base + desloc, base + len(s)))
                continue
            if s.startswith("# DBTITLE"):
                corte = s.find(",")
                if corte != -1:
                    spans.append((base + corte + 1, base + len(s)))
                continue
            spans.append((base + 1, base + len(s)))   # comentário comum

        elif tok.type == FSTRING_START:
            # A f-string chega em pedaços, e um pedaço isolado como
            # `' as juncao , count(*) as orfaos from '` não tem palavra-chave
            # bastante para ser reconhecido como SQL. Decidir por pedaço trocou o
            # alias `orfaos` por `órfãos` e quebrou o lexer. Então junta-se a
            # f-string inteira, decide-se uma vez, e só então emitem-se os spans.
            pendentes = []

        elif tok.type == FSTRING_MIDDLE and pendentes is not None:
            pendentes.append((base, tok.string))

        elif tok.type == FSTRING_END and pendentes is not None:
            inteiro = "".join(s for _, s in pendentes)
            e_sql = TEM_SQL.search(inteiro) and not markdown
            for b, s in pendentes:
                if e_sql:
                    spans += _linhas_de_comentario_sql(s, b)
                else:
                    spans.append((b, b + len(s)))
            pendentes = None

        elif tok.type == tokenize.STRING:
            # `grupo["mes"]` não é prosa: é nome de coluna, e o alias que o produz
            # (`as mes`) fica em ASCII porque alias de SQL fica em ASCII. Tratar o
            # literal como prosa escreveu `mês` e o gráfico morreu com KeyError —
            # e o diff parecia certo, porque `mês` É a grafia correta da palavra.
            fim = base + len(tok.string)
            antes = texto[:base].rstrip()
            depois = texto[fim:].lstrip()
            if antes.endswith("[") and depois.startswith("]"):
                continue
            if TEM_SQL.search(tok.string) and not markdown:
                spans += _linhas_de_comentario_sql(tok.string, base)
            else:
                spans.append((base, base + len(tok.string)))
    return spans


LITERAL_SQL = re.compile(r"'[^'\n]*'")
ACENTUADA = re.compile(r"\b\w*[À-ÿ]\w*\b")


def acento_em_nome_de_coluna(caminho, texto):
    """Subscrito de string acentuado no Python do notebook — KeyError garantido.

    Irmão do caso do alias: `grupo["mes"]` virou `grupo["mês"]` numa passagem de
    acentuação, mas o alias que produz a coluna é `as mes` e continua em ASCII, como
    tem de ser. O gráfico quebraria na execução, não aqui — e a acentuação em si
    parecia certa lendo o diff, porque `mês` É a grafia correta da palavra.

    A regra que separa os dois: rótulo de gráfico é prosa e leva acento; subscrito de
    string é nome de coluna vindo do SQL e fica em ASCII.
    """
    if caminho.suffix != ".py":
        return []
    erros = []
    for n, linha in enumerate(texto.split("\n"), 1):
        if linha.startswith("# MAGIC") or linha.lstrip().startswith("#"):
            continue
        for m in re.finditer(r"""\[\s*["']([^"']+)["']\s*\]""", linha):
            nome = m.group(1)
            if any(ord(c) > 127 for c in nome):
                erros.append(f"linha {n}: `{nome}` é nome de coluna do SQL "
                             f"e não pode ter acento")
    return erros


def acento_no_codigo_sql(caminho, texto):
    """Identificador de SQL acentuado — o erro inverso, e mais perigoso.

    Uma passagem de acentuação trocou o alias `orfaos` por `órfãos` dentro da
    consulta, e o sqlfluff parou com `LXR | Unable to lex characters`. Palavra
    acentuada é bem-vinda em comentário e em literal de texto — que vira rótulo na
    tela —, mas nunca em nome de coluna, alias ou tabela.
    """
    if caminho.suffix != ".sql":
        return []
    achados = []
    for n, linha in enumerate(texto.split("\n"), 1):
        if linha.lstrip().startswith("--"):
            continue                      # comentário: acento é o esperado
        sem_literal = LITERAL_SQL.sub(lambda m: " " * len(m.group(0)), linha)
        for m in ACENTUADA.finditer(sem_literal):
            achados.append(f"linha {n}: `{m.group(0)}` é identificador de SQL e "
                           f"não pode ter acento")
    return achados


def palavras_sem_acento(caminho, texto):
    """Ocorrências de palavra sem acento, só na prosa e fora do protegido."""
    achados = Counter()
    for ini, fim in regioes_prosa(caminho, texto):
        trecho = texto[ini:fim]
        for padrao in PROTEGIDO:
            trecho = padrao.sub(lambda m: " " * len(m.group(0)), trecho)
        for bruto in re.findall(r"\b[A-Za-z]+\b", trecho):
            p = bruto.lower()
            if p in FALTA:
                achados[p] += 1
                continue
            provavel = suspeita_por_sufixo(p)
            if provavel and provavel != p:
                FALTA[p] = provavel      # passa a valer para o corretor também
                achados[p] += 1
    return achados


def main():
    alvos = [Path(a) for a in sys.argv[1:]]
    if not alvos:
        for padrao in PADROES:
            alvos += sorted(REPO.glob(padrao))
    alvos = [a for a in alvos if a.name not in IGNORA]

    # O dicionario cresce com o proprio texto: cada palavra acentuada que ja esta la
    # ensina como a sua forma sem acento deveria ser escrita.
    corpus = []
    for a in alvos:
        try:
            corpus.append(a.read_bytes().decode("utf-8"))
        except (OSError, UnicodeDecodeError):
            pass
    FALTA.update({k: v for k, v in deriva_do_corpus(corpus).items() if k not in FALTA})

    total, falhou = Counter(), False
    print(f"{'arquivo':<44} {'sem acento':>11}   as mais frequentes")
    print("-" * 92)
    for alvo in alvos:
        bruto = alvo.read_bytes()
        try:
            texto = bruto.decode("utf-8")
        except UnicodeDecodeError as e:
            print(f"  {alvo.name}: não é UTF-8 válido — {e}")
            falhou = True
            continue

        # O README e este próprio script CITAM os padrões de mojibake, entre crases,
        # ao documentar o que se procura. Citação não é defeito: código inline sai
        # antes da busca, senão a documentação da verificação reprova a si mesma.
        sem_citacao = re.sub(r"`[^`\n]*`", "", texto)
        if MOJIBAKE.search(sem_citacao):
            print(f"  {alvo.name}: mojibake — {MOJIBAKE.findall(sem_citacao)[:3]}")
            falhou = True

        for erro in acento_em_nome_de_coluna(alvo, texto):
            print(f"  {alvo.name}: {erro}")
            falhou = True

        for erro in acento_no_codigo_sql(alvo, texto):
            print(f"  {alvo.name}: {erro}")
            falhou = True

        achados = palavras_sem_acento(alvo, texto)
        total += achados
        if achados:
            falhou = True
            top = ", ".join(f"{FALTA[w]}({n})" for w, n in achados.most_common(4))
            try:
                rel = alvo.relative_to(REPO)
            except ValueError:
                rel = alvo.name
            print(f"{str(rel):<44} {sum(achados.values()):>11}   {top}")

    print("-" * 92)
    if falhou:
        print(f"TOTAL: {sum(total.values())} ocorrência(s), {len(total)} palavra(s)")
        sys.exit("há português a corrigir — prosa leva acento; código fica em ASCII")
    print(f"{len(alvos)} arquivos: acentuação correta e nenhum mojibake")


if __name__ == "__main__":
    main()
