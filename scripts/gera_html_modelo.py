# -*- coding: utf-8 -*-
"""Monta a página HTML do modelo conceitual, para virar o PDF da Etapa 3.

    python scripts/gera_html_modelo.py

Escreve em `Desafio/entregaveis/`, que fica fora do git. Depois é `Ctrl+P` no navegador e
`Salvar como PDF`.

## Por que gerar em vez de escrever o HTML à mão

O entregável do item 1.1 do formulário é o diagrama, e o do item 1.2 é o mapeamento de
fontes. Os dois vivem em `docs/03.01-modelo-conceitual.md`, que é versionado e renderiza no
GitHub. Um HTML escrito à mão seria uma **segunda** cópia do mesmo conteúdo, e as duas
divergiriam na primeira correção — exatamente o risco que o item 2.7 do formulário cobra
entre diagrama e projeto.

Então o markdown entra inteiro, embutido, e quem renderiza é o navegador: `marked` para o
texto e `mermaid` para o diagrama. O PDF passa a ser uma fotografia do arquivo versionado.

## Por que renderizar no cliente

Não há biblioteca de markdown instalada, e instalar uma para gerar um PDF por etapa é
desproporcional. As duas bibliotecas vêm de CDN e só precisam existir no momento em que a
página é aberta para imprimir.
"""
import json
import sys
from pathlib import Path

# O console do Windows usa cp1252 e QUEBRA ao imprimir acento.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
FONTE = REPO / "docs" / "03.01-modelo-conceitual.md"
SAIDA = REPO.parent / "entregaveis" / "Etapa3 - Modelo conceitual.html"

MARKED = "https://cdnjs.cloudflare.com/ajax/libs/marked/14.1.3/marked.min.js"
MERMAID = "https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.9.1/mermaid.min.js"

MOLDE = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>Modelo conceitual — Adventure Works</title>
<style>
  /* Paisagem, porque o erDiagram e largo e em retrato sai ilegível. */
  @page {{ size: A3 landscape; margin: 14mm; }}
  :root {{ --tinta: #14181f; --fraco: #5b6472; --borda: #d8dde5; --fundo: #fff; }}
  body {{ margin: 0 auto; max-width: 1180px; padding: 32px 28px 64px;
         font: 15px/1.62 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
         color: var(--tinta); background: var(--fundo); }}
  h1 {{ font-size: 30px; margin: 0 0 6px; letter-spacing: -.4px; }}
  h2 {{ font-size: 21px; margin: 34px 0 10px; padding-bottom: 6px;
       border-bottom: 1px solid var(--borda); }}
  h3 {{ font-size: 17px; margin: 24px 0 8px; }}
  p, li {{ max-width: 78ch; }}
  table {{ border-collapse: collapse; margin: 14px 0; font-size: 14px; width: 100%; }}
  th, td {{ border: 1px solid var(--borda); padding: 7px 10px; text-align: left;
           vertical-align: top; }}
  th {{ background: #f3f5f8; font-weight: 600; }}
  code {{ font: 13px/1.5 "Cascadia Code", Consolas, monospace;
         background: #f3f5f8; padding: 1px 5px; border-radius: 3px; }}
  blockquote {{ margin: 14px 0; padding: 2px 0 2px 16px; border-left: 3px solid var(--borda);
               color: var(--fraco); }}
  .mermaid {{ margin: 18px 0 26px; text-align: center; }}
  .rodape {{ margin-top: 40px; padding-top: 12px; border-top: 1px solid var(--borda);
            font-size: 12px; color: var(--fraco); }}
  /* Não partir tabela nem diagrama entre páginas impressas. */
  @media print {{
    body {{ max-width: none; padding: 0; }}
    table, .mermaid, h2 {{ break-inside: avoid; }}
    h2, h3 {{ break-after: avoid; }}
  }}
</style>
</head>
<body>
<div id="alvo">Renderizando…</div>
<div class="rodape">
  Adventure Works · Certificação em Analytics Engineering (Indicium AI) · Etapa 3 —
  modelo conceitual. Gerado de <code>docs/03.01-modelo-conceitual.md</code>.
</div>

<script src="{marked}"></script>
<script src="{mermaid}"></script>
<script>
  const fonte = {markdown};

  // O mermaid precisa achar os blocos DEPOIS que o marked os transformou, então a
  // renderização e em duas etapas: markdown primeiro, diagrama depois.
  marked.setOptions({{ gfm: true, breaks: false }});
  document.getElementById("alvo").innerHTML = marked.parse(fonte);

  document.querySelectorAll("pre > code.language-mermaid").forEach(function (bloco) {{
    const caixa = document.createElement("div");
    caixa.className = "mermaid";
    caixa.textContent = bloco.textContent;
    bloco.parentElement.replaceWith(caixa);
  }});

  mermaid.initialize({{ startOnLoad: true, theme: "neutral",
                       er: {{ useMaxWidth: true, entityPadding: 10 }} }});
</script>
</body>
</html>
"""

assert FONTE.exists(), f"não achei {FONTE}"
texto = FONTE.read_text(encoding="utf-8")

SAIDA.parent.mkdir(parents=True, exist_ok=True)
SAIDA.write_text(
    MOLDE.format(marked=MARKED, mermaid=MERMAID, markdown=json.dumps(texto)),
    encoding="utf-8")

blocos = texto.count("```mermaid")
print(f"OK -> {SAIDA}")
print(f"markdown embutido: {len(texto):,} caracteres  |  diagramas: {blocos}")
print("\nAbra no navegador e use Ctrl+P -> Salvar como PDF (A3 paisagem).")
