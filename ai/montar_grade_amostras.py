"""
Comparação visual e numérica entre as classes do dataset (SOMENTE LEITURA).

Responde a pergunta: "o FUNDO da foto (recipiente, mesa, luz) já entrega a classe,
sem precisar olhar o leite?". Se entregar, o modelo pode estar usando o ambiente de
captura como atalho, em vez de reconhecer coágulos.

Uso (rode na pasta ai/):
    python montar_grade_amostras.py
    python montar_grade_amostras.py --dataset dataset            # fotos originais, sem padronizar
    python montar_grade_amostras.py --n 30 --colunas 5           # grade maior
    python montar_grade_amostras.py --semente 7                  # outra amostra aleatória de fotos

Gera, em ai/relatorio_visual/ (nada do dataset é alterado):
    grade_amostras.png    uma coluna de fotos por classe, lado a lado, com saturação (S)
                          e brilho (B) de cada foto. Serve para comparar a olho nu o
                          fundo, o ângulo, o enquadramento e a luz entre as classes.
    fundo_vs_centro.png   histogramas de saturação e brilho da BORDA (fundo) e do CENTRO
                          (onde fica o leite), uma cor por classe.

E imprime a acurácia de adivinhar a classe usando só a borda, só o centro, ou os dois.
"""
import argparse
import random
from pathlib import Path

import numpy as np

BASE_DIR = Path(__file__).resolve().parent
EXTENSOES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
SEMENTE_PADRAO = 42
CORES_CLASSE = [(192, 57, 43), (39, 120, 190), (39, 174, 96), (142, 68, 173)]
NOMES_FEATURES = ["R", "G", "B", "saturação", "brilho", "contraste"]
IDX_SAT, IDX_BRILHO = 3, 4


def _imagens_por_classe(raiz: Path):
    classes = {}
    for sub in sorted(d for d in raiz.iterdir() if d.is_dir()):
        arquivos = sorted(p for p in sub.rglob("*") if p.suffix.lower() in EXTENSOES)
        if arquivos:
            classes[sub.name] = arquivos
    return classes


def _mascaras(h, w):
    """BORDA = moldura externa (15% de cada lado) ~ fundo/ambiente.
    CENTRO = quadrado central (30%-70%) ~ onde normalmente está o leite."""
    yy, xx = np.mgrid[0:h, 0:w]
    y = yy / max(h - 1, 1)
    x = xx / max(w - 1, 1)
    centro = (x >= 0.30) & (x <= 0.70) & (y >= 0.30) & (y <= 0.70)
    borda = (x < 0.15) | (x > 0.85) | (y < 0.15) | (y > 0.85)
    return borda, centro


def _extrair(caminho: Path):
    from PIL import Image

    with Image.open(caminho) as im:
        if im.format == "JPEG":
            im.draft("RGB", (512, 512))  # decodifica já reduzido: bem mais rápido
        im = im.convert("RGB")
        im.thumbnail((256, 256))
        rgb = np.asarray(im, dtype=np.float32)
        hsv = np.asarray(im.convert("HSV"), dtype=np.float32)
    h, w = rgb.shape[:2]
    if min(h, w) < 20:
        raise ValueError("imagem pequena demais")
    cinza = rgb.mean(axis=2)
    borda, centro = _mascaras(h, w)

    def regiao(m):
        return [float(rgb[..., 0][m].mean()), float(rgb[..., 1][m].mean()), float(rgb[..., 2][m].mean()),
                float(hsv[..., 1][m].mean()), float(cinza[m].mean()), float(cinza[m].std())]

    return {"borda": regiao(borda), "centro": regiao(centro),
            "sat": float(hsv[..., 1].mean()), "brilho": float(cinza.mean())}


def _acuracia_cv(X, y):
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import StratifiedKFold, cross_val_score

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=SEMENTE_PADRAO)
    rf = RandomForestClassifier(n_estimators=200, min_samples_leaf=2, class_weight="balanced",
                                random_state=SEMENTE_PADRAO, n_jobs=-1)
    return float(cross_val_score(rf, X, y, cv=cv, scoring="balanced_accuracy").mean())


def _fonte(tamanho):
    from PIL import ImageFont

    for nome in ("arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(nome, tamanho)
        except Exception:
            continue
    try:
        return ImageFont.load_default(size=tamanho)
    except TypeError:
        return ImageFont.load_default()


def _montar_grade(nomes, por_classe, dados, n, colunas, caminho_saida):
    from PIL import Image, ImageDraw

    T, LEG, GAP, CAB, MARGEM = 220, 20, 6, 46, 10
    linhas = -(-n // colunas)
    larg_bloco = colunas * (T + GAP) + GAP
    alt_bloco = linhas * (T + LEG + GAP) + GAP
    largura = MARGEM * 2 + len(nomes) * larg_bloco + (len(nomes) - 1) * MARGEM * 2
    altura = MARGEM * 2 + CAB + alt_bloco
    canvas = Image.new("RGB", (largura, altura), (24, 24, 27))
    d = ImageDraw.Draw(canvas)
    f_cab, f_leg = _fonte(17), _fonte(12)

    for ci, nome in enumerate(nomes):
        x0 = MARGEM + ci * (larg_bloco + MARGEM * 2)
        itens = dados[nome]
        cor = CORES_CLASSE[ci % len(CORES_CLASSE)]
        sat_media = np.mean([i["sat"] for i in itens])
        bri_media = np.mean([i["brilho"] for i in itens])
        d.rectangle([x0, MARGEM, x0 + larg_bloco, MARGEM + CAB - 6], fill=cor)
        d.text((x0 + 10, MARGEM + 4), f"{nome}  ({len(por_classe[nome])} fotos no dataset)", fill="white", font=f_cab)
        d.text((x0 + 10, MARGEM + 25), f"média da amostra: saturação {sat_media:.0f} | brilho {bri_media:.0f}",
               fill=(255, 255, 255), font=f_leg)
        for k, item in enumerate(itens[:n]):
            r, c = divmod(k, colunas)
            tx = x0 + GAP + c * (T + GAP)
            ty = MARGEM + CAB + GAP + r * (T + LEG + GAP)
            try:
                with Image.open(item["caminho"]) as im:
                    if im.format == "JPEG":
                        im.draft("RGB", (T * 2, T * 2))
                    im = im.convert("RGB")
                    im.thumbnail((T, T))
                    fundo = Image.new("RGB", (T, T), (58, 58, 62))
                    fundo.paste(im, ((T - im.width) // 2, (T - im.height) // 2))
                canvas.paste(fundo, (tx, ty))
            except Exception:
                d.rectangle([tx, ty, tx + T, ty + T], fill=(90, 30, 30))
            sessao = item["caminho"].parent.name
            sessao = "" if sessao == nome else sessao[:10] + " "
            d.text((tx + 2, ty + T + 3), f"{sessao}S{item['sat']:.0f} B{item['brilho']:.0f}",
                   fill=(210, 210, 215), font=f_leg)
    canvas.save(caminho_saida)


def _montar_histogramas(nomes, dados, acc, caminho_saida):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, eixos = plt.subplots(2, 2, figsize=(11, 7))
    painel = [(0, 0, "borda", IDX_SAT, "Saturação da BORDA (fundo)"),
              (0, 1, "centro", IDX_SAT, "Saturação do CENTRO (leite)"),
              (1, 0, "borda", IDX_BRILHO, "Brilho da BORDA (fundo)"),
              (1, 1, "centro", IDX_BRILHO, "Brilho do CENTRO (leite)")]
    for r, c, regiao, idx, titulo in painel:
        ax = eixos[r][c]
        todos = np.concatenate([[i[regiao][idx] for i in dados[n]] for n in nomes])
        faixa = (float(todos.min()), float(todos.max()))
        for ci, nome in enumerate(nomes):
            vals = [i[regiao][idx] for i in dados[nome]]
            cor = tuple(v / 255 for v in CORES_CLASSE[ci % len(CORES_CLASSE)])
            ax.hist(vals, bins=30, range=faixa, alpha=0.55, color=cor, label=nome, density=True)
            ax.axvline(np.mean(vals), color=cor, linestyle="--", linewidth=1.5)
        ax.set_title(titulo, fontsize=11)
        ax.set_yticks([])
        ax.legend(fontsize=9)
    fig.suptitle(f"Só a BORDA prevê a classe com {acc['borda']:.0%}  |  só o CENTRO: {acc['centro']:.0%}  "
                 f"|  acaso: {1 / len(nomes):.0%}\n(linha tracejada = média da classe; quanto menos as curvas se "
                 f"sobrepõem, mais a região diferencia as classes)", fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.92))
    fig.savefig(caminho_saida, dpi=110)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dataset", default=str(BASE_DIR / "dataset_padronizado"),
                    help="Pasta com uma subpasta por classe (padrão: dataset_padronizado).")
    ap.add_argument("--n", type=int, default=20, help="Fotos por classe na grade.")
    ap.add_argument("--colunas", type=int, default=4, help="Colunas de fotos por classe na grade.")
    ap.add_argument("--max-por-classe", type=int, default=400, help="Máximo de fotos analisadas por classe.")
    ap.add_argument("--semente", type=int, default=SEMENTE_PADRAO, help="Muda quais fotos são sorteadas.")
    ap.add_argument("--saida", default=str(BASE_DIR / "relatorio_visual"))
    args = ap.parse_args()

    raiz = Path(args.dataset)
    if not raiz.is_dir():
        raise SystemExit(f"Pasta não encontrada: {raiz}")
    por_classe = _imagens_por_classe(raiz)
    if len(por_classe) < 2:
        raise SystemExit(f"Preciso de pelo menos 2 classes (subpastas com imagens) em {raiz}")
    nomes = list(por_classe)

    random.seed(args.semente)
    dados = {}
    for nome in nomes:
        arquivos = random.sample(por_classe[nome], min(args.max_por_classe, len(por_classe[nome])))
        print(f"  lendo {nome}: {len(arquivos)} imagens...")
        itens = []
        for a in arquivos:
            try:
                itens.append({**_extrair(a), "caminho": a})
            except Exception:
                pass
        dados[nome] = itens

    saida = Path(args.saida)
    saida.mkdir(parents=True, exist_ok=True)
    _montar_grade(nomes, por_classe, dados, args.n, args.colunas, saida / "grade_amostras.png")

    menor = min(len(v) for v in dados.values())
    if menor < 10:
        print(f"\n  (poucas imagens legíveis por classe: {menor}. Pulei a análise numérica.)")
        print(f"  Grade salva em: {saida / 'grade_amostras.png'}")
        return

    y = np.array([ci for ci, n in enumerate(nomes) for _ in dados[n]])
    def matriz(regiao):
        return np.array([i[regiao] for n in nomes for i in dados[n]], dtype=np.float64)
    Xb, Xc = matriz("borda"), matriz("centro")
    acc = {"borda": _acuracia_cv(Xb, y), "centro": _acuracia_cv(Xc, y), "ambos": _acuracia_cv(np.hstack([Xb, Xc]), y)}
    _montar_histogramas(nomes, dados, acc, saida / "fundo_vs_centro.png")

    acaso = 1.0 / len(nomes)
    print("\n" + "=" * 74)
    print(f"Acurácia balanceada (validação cruzada 5x). Acaso = {acaso:.2f}")
    print("-" * 74)
    print(f"  só a BORDA / fundo da foto (sem leite)     {acc['borda']:5.2f}")
    print(f"  só o CENTRO (onde fica o leite)            {acc['centro']:5.2f}")
    print(f"  borda + centro                             {acc['ambos']:5.2f}")
    print("-" * 74)
    if acc["borda"] >= 0.80:
        print("  LEITURA: ALERTA. O fundo SOZINHO já adivinha a classe. O modelo pode estar usando o")
        print("  ambiente de captura (luz, mesa, recipiente, ângulo) em vez do leite.")
    elif acc["borda"] >= 0.65:
        print("  LEITURA: ATENÇÃO. O fundo tem sinal de classe acima do acaso. Confira a grade.")
    else:
        print("  LEITURA: o fundo sozinho NÃO prevê bem a classe. Boa notícia: a diferença está mais no")
        print("  centro (leite), que é onde ela deveria estar.")
    print("  Cuidados: (1) borda/centro são janelas fixas e podem pegar parte do recipiente;")
    print("  (2) fotos em sequência da mesma amostra são quase iguais e podem inflar esse número na")
    print("  validação cruzada. Por isso o teste definitivo é uma sessão nova, com as duas classes.")
    print(f"\n  Imagens salvas em: {saida}")


if __name__ == "__main__":
    main()