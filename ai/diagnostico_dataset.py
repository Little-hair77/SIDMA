"""
Diagnóstico de "atalhos" (shortcut learning) no dataset e no modelo.

Pergunta que este script responde com números:
    "O modelo está aprendendo o COÁGULO, ou está aprendendo a CÂMERA/RESOLUÇÃO
     de cada classe?"

Por que isso importa: no relatório do dataset, a classe Clots tem imagens de
~3258x3798 px (3,3 MB) e a NoClots de ~1399x1778 px (1,0 MB). Se as classes vêm
de fontes diferentes, o modelo pode acertar 99% no teste (que vem da MESMA
fonte) e falhar em qualquer foto nova — que é exatamente o que acontece.

Uso (rode na pasta ai/):
    python diagnostico_dataset.py                 # as duas partes
    python diagnostico_dataset.py --so-metadados  # só a parte A (não precisa do modelo)
    python diagnostico_dataset.py --so-robustez   # só a parte B

PARTE A - Teste dos metadados
    Tenta adivinhar a classe usando SÓ propriedades do arquivo que não têm nada
    a ver com leite (resolução, tamanho, formato, câmera, compressão). Se isso
    já acerta muito mais que o acaso, as classes são distinguíveis por "assinatura
    de fonte" e o modelo pode estar usando isso.

PARTE B - Teste de robustez do modelo
    Pega imagens do conjunto de teste, aplica o tipo de variação que acontece no
    mundo real (foto reduzida, comprimida, desfocada, mais escura/clara, girada,
    recortada) e mede quanto a acurácia cai e quantas previsões mudam.
"""
import argparse
import io
import json
import random
import sys
from pathlib import Path

import numpy as np

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
EXTENSOES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
SEED = 42


def _imagens_por_classe(raiz: Path):
    classes = {}
    for sub in sorted(d for d in raiz.iterdir() if d.is_dir()):
        arquivos = sorted(p for p in sub.rglob("*") if p.suffix.lower() in EXTENSOES)
        if arquivos:
            classes[sub.name] = arquivos
    return classes


# --------------------------------------------------------------------------- #
# PARTE A - metadados
# --------------------------------------------------------------------------- #
def _features(caminho: Path):
    from PIL import Image

    tamanho_kb = caminho.stat().st_size / 1024
    with Image.open(caminho) as im:
        formato = im.format or "?"
        largura, altura = im.size
        try:
            tem_exif_camera = int(bool(im.getexif().get(271)))  # 271 = fabricante da câmera
        except Exception:
            tem_exif_camera = 0
        tabelas = getattr(im, "quantization", None)
        q_med = float(np.mean(list(tabelas[0]))) if tabelas else -1.0  # menor = JPEG de maior qualidade
        if formato == "JPEG":
            im.draft("RGB", (512, 512))  # decodifica já reduzido: bem mais rápido
        im = im.convert("RGB")
        im.thumbnail((256, 256))
        rgb = np.asarray(im, dtype=np.float32)
        hsv = np.asarray(im.convert("HSV"), dtype=np.float32)

    cinza = rgb.mean(axis=2)
    lap = 4 * cinza[1:-1, 1:-1] - cinza[:-2, 1:-1] - cinza[2:, 1:-1] - cinza[1:-1, :-2] - cinza[1:-1, 2:]
    return {
        "largura": largura, "altura": altura, "lado_menor": min(largura, altura),
        "proporcao": largura / max(altura, 1), "tamanho_kb": tamanho_kb,
        "bytes_por_pixel": caminho.stat().st_size / max(largura * altura, 1),
        "formato": {"JPEG": 0, "PNG": 1, "WEBP": 2, "BMP": 3}.get(formato, 4),
        "tem_exif_camera": tem_exif_camera, "qualidade_jpeg": q_med,
        "brilho": float(cinza.mean()), "contraste": float(cinza.std()),
        "nitidez": float(lap.var()), "saturacao": float(hsv[:, :, 1].mean()),
    }


def parte_a(dataset: Path, max_por_classe: int):
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import StratifiedKFold, cross_val_score

    print("=" * 74)
    print("PARTE A - O arquivo sozinho (sem olhar o conteúdo) já entrega a classe?")
    print("=" * 74)
    classes = _imagens_por_classe(dataset)
    if len(classes) < 2:
        raise SystemExit(f"Preciso de pelo menos 2 classes em {dataset}")

    random.seed(SEED)
    linhas, rotulos = [], []
    for i, (nome, arquivos) in enumerate(classes.items()):
        amostra = random.sample(arquivos, min(max_por_classe, len(arquivos)))
        print(f"  lendo {nome}: {len(amostra)} imagens...")
        for a in amostra:
            try:
                linhas.append(_features(a))
                rotulos.append(i)
            except Exception:
                pass
    y = np.array(rotulos)
    nomes = list(classes)

    print("\n  Médias por classe (se forem muito diferentes, as fontes são diferentes):")
    chaves = ["largura", "altura", "tamanho_kb", "bytes_por_pixel", "brilho", "nitidez", "saturacao"]
    print("  %-18s" % "" + "".join("%-14s" % n for n in nomes))
    for k in chaves:
        medias = [np.mean([l[k] for l, r in zip(linhas, y) if r == i]) for i in range(len(nomes))]
        print("  %-18s" % k + "".join("%-14.1f" % m for m in medias))

    grupos = {
        "resolução / tamanho / formato": ["largura", "altura", "lado_menor", "proporcao", "tamanho_kb", "bytes_por_pixel", "formato"],
        "câmera / compressão": ["tem_exif_camera", "qualidade_jpeg"],
        "aparência (brilho, contraste, nitidez, cor)": ["brilho", "contraste", "nitidez", "saturacao"],
        "TODOS os metadados juntos": list(linhas[0].keys()),
    }
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=SEED)
    acaso = 1.0 / len(nomes)
    print(f"\n  Acurácia balanceada (validação cruzada 5x). Acaso = {acaso:.2f}")
    print("  " + "-" * 70)
    resultados = {}
    for rotulo, cols in grupos.items():
        X = np.array([[l[c] for c in cols] for l in linhas], dtype=np.float64)
        rf = RandomForestClassifier(n_estimators=200, min_samples_leaf=2, class_weight="balanced", random_state=SEED, n_jobs=-1)
        acc = float(cross_val_score(rf, X, y, cv=cv, scoring="balanced_accuracy").mean())
        resultados[rotulo] = acc
        alerta = "  <-- ALERTA" if acc >= 0.80 and "aparência" not in rotulo else ""
        print(f"  {rotulo:<46} {acc:5.2f}{alerta}")

    print()
    res = resultados["resolução / tamanho / formato"]
    if res >= 0.80:
        print(f"  VEREDITO: ALERTA. Só pela resolução/tamanho/formato dá para adivinhar a classe em {res:.0%} dos casos.")
        print("  As classes têm 'assinatura de fonte'. Um modelo pode atingir 99% no teste sem ter aprendido")
        print("  coágulo nenhum. Ações: (1) colete as DUAS classes com a mesma câmera/resolução/fonte;")
        print("  (2) rode padronizar_dataset.py; (3) separe treino/teste por fonte (ver train_model.py).")
    elif res >= 0.65:
        print(f"  VEREDITO: ATENÇÃO. Resolução/tamanho/formato prevê a classe em {res:.0%} (acaso = {acaso:.0%}). Há sinal de fonte.")
    else:
        print(f"  VEREDITO: sem sinal forte de fonte por resolução/tamanho ({res:.0%}). Mesmo assim rode a parte B.")
    print("  Obs.: 'aparência' pode refletir diferença real do leite (cor, textura); não é, sozinha, um problema.")
    return resultados


# --------------------------------------------------------------------------- #
# PARTE B - robustez
# --------------------------------------------------------------------------- #
def _perturbacoes():
    from PIL import Image, ImageEnhance, ImageFilter

    def reduzir(lado):
        def f(im):
            im = im.convert("RGB")
            im.thumbnail((lado, lado), Image.LANCZOS)
            buf = io.BytesIO()
            im.save(buf, "JPEG", quality=85)  # como uma foto de celular/WhatsApp
            buf.seek(0)
            return Image.open(buf).convert("RGB")
        return f

    def jpeg(q):
        def f(im):
            buf = io.BytesIO()
            im.convert("RGB").save(buf, "JPEG", quality=q)
            buf.seek(0)
            return Image.open(buf).convert("RGB")
        return f

    def recorte_central(frac):
        def f(im):
            w, h = im.size
            cw, ch = int(w * frac), int(h * frac)
            x, y = (w - cw) // 2, (h - ch) // 2
            return im.crop((x, y, x + cw, y + ch))
        return f

    return {
        "original": lambda im: im.convert("RGB"),
        "reduzida p/ 640 px (galeria/WhatsApp)": reduzir(640),
        "reduzida p/ 320 px": reduzir(320),
        "JPEG de baixa qualidade (q=30)": jpeg(30),
        "levemente desfocada": lambda im: im.convert("RGB").filter(ImageFilter.GaussianBlur(2)),
        "mais escura (x0.6)": lambda im: ImageEnhance.Brightness(im.convert("RGB")).enhance(0.6),
        "mais clara (x1.4)": lambda im: ImageEnhance.Brightness(im.convert("RGB")).enhance(1.4),
        "girada 90 graus": lambda im: im.convert("RGB").rotate(90, expand=True),
        "espelhada": lambda im: im.convert("RGB").transpose(Image.FLIP_LEFT_RIGHT),
        "recorte central de 60%": recorte_central(0.6),
    }


def parte_b(teste: Path, n_por_classe: int, modelo_path: Path):
    import os
    os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
    import tensorflow as tf
    from PIL import Image

    sys.path.insert(0, str(BASE_DIR))
    import preprocessamento as pp

    print("\n" + "=" * 74)
    print("PARTE B - O modelo aguenta as variações do mundo real?")
    print("=" * 74)

    modelo = tf.keras.models.load_model(modelo_path)
    labels = json.load(open(modelo_path.parent / "labels.json", encoding="utf-8"))
    modo = pp.modo_do_modelo(modelo_path.parent)
    print(f"  Pré-processamento do modelo: {modo}")

    classes = _imagens_por_classe(teste)
    random.seed(SEED)
    itens = []  # (caminho, indice_classe_real)
    for nome, arquivos in classes.items():
        if nome not in labels:
            print(f"  (ignorando pasta '{nome}': não está em labels.json {labels})")
            continue
        for a in random.sample(arquivos, min(n_por_classe, len(arquivos))):
            itens.append((a, labels.index(nome)))
    if not itens:
        raise SystemExit(f"Nenhuma imagem utilizável em {teste}")
    y_real = np.array([i for _, i in itens])
    print(f"  {len(itens)} imagens do teste ({n_por_classe} por classe, no máximo)\n")

    originais = [Image.open(c) for c, _ in itens]
    for im in originais:
        im.load()

    def prever(imagens):
        arr = np.stack([pp.pil_para_modelo(im, modo) for im in imagens])
        p = np.asarray(modelo.predict(arr, batch_size=32, verbose=0)).reshape(len(imagens), -1)
        return (p[:, 0] > 0.5).astype(int) if len(labels) == 2 else p.argmax(axis=1)

    base = None
    print(f"  {'variação':<42}{'acurácia':>10}{'queda':>9}{'mudam de classe':>18}")
    print("  " + "-" * 79)
    resumo = {}
    for nome, f in _perturbacoes().items():
        pred = prever([f(im) for im in originais])
        acc = float((pred == y_real).mean())
        if base is None:
            base = (acc, pred)
        queda = (base[0] - acc) * 100
        muda = float((pred != base[1]).mean()) * 100
        resumo[nome] = (acc, queda, muda)
        marca = "  <--" if queda >= 10 else ""
        print(f"  {nome:<42}{acc * 100:>9.1f}%{queda:>8.1f}p{muda:>16.1f}%{marca}")

    print()
    chave = "reduzida p/ 640 px (galeria/WhatsApp)"
    # Variações que NÃO deveriam mudar o diagnóstico (a amostra é a mesma; só a foto mudou).
    # Rotação e recorte ficam de fora: eles podem mudar o que aparece na imagem.
    neutras = ["reduzida p/ 640 px (galeria/WhatsApp)", "reduzida p/ 320 px", "JPEG de baixa qualidade (q=30)",
               "levemente desfocada", "mais escura (x0.6)", "mais clara (x1.4)", "espelhada"]
    pior_troca = max(resumo[k][2] for k in neutras)
    if base[0] < 0.70:
        print(f"  VEREDITO: a acurácia de partida já é baixa ({base[0]:.0%}); as variações abaixo não são interpretáveis.")
    elif resumo[chave][1] >= 10:
        print("  VEREDITO: ALERTA. A acurácia despenca quando a MESMA foto chega reduzida.")
        print("  O modelo depende da resolução/nitidez de origem, não só do conteúdo da amostra.")
    elif pior_troca >= 15:
        print(f"  VEREDITO: INSTÁVEL. Até {pior_troca:.0f}% das previsões mudam de classe com variações que não deveriam")
        print("  alterar o diagnóstico (a amostra é a mesma). A acurácia média pode esconder isso.")
    elif max(v[1] for k, v in resumo.items() if k != "original") >= 10:
        print("  VEREDITO: ATENÇÃO. Algumas variações derrubam a acurácia em 10+ pontos (marcadas com <--).")
    else:
        print("  VEREDITO: o modelo é estável nessas variações.")
    print("  Obs.: isto usa o conjunto de teste da MESMA fonte do treino. Para medir de verdade, avalie")
    print("  também numa pasta de imagens de OUTRA fonte (ver --teste-externo em train_model.py).")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dataset", default=str(BASE_DIR / "dataset"), help="Pasta com uma subpasta por classe (parte A).")
    ap.add_argument("--teste", default=str(BASE_DIR / "dataset_split" / "test"), help="Pasta de teste com uma subpasta por classe (parte B).")
    ap.add_argument("--modelo", default=str(MODELS_DIR / "mastite_model.keras"))
    ap.add_argument("--max-por-classe", type=int, default=400, help="Máximo de imagens lidas por classe na parte A.")
    ap.add_argument("--n-por-classe", type=int, default=60, help="Imagens por classe usadas na parte B.")
    ap.add_argument("--so-metadados", action="store_true")
    ap.add_argument("--so-robustez", action="store_true")
    args = ap.parse_args()

    if not args.so_robustez:
        parte_a(Path(args.dataset), args.max_por_classe)
    if not args.so_metadados:
        parte_b(Path(args.teste), args.n_por_classe, Path(args.modelo))


if __name__ == "__main__":
    main()