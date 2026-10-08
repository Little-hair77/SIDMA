"""
Pré-processamento ÚNICO de imagens para o modelo do SIDMA.

Por que isto existe: antes, o treino (image_dataset_from_directory), o backend
(ia.py), o gradcam.py e o testar_modelo.py reduziam a imagem para 224x224 de
formas DIFERENTES (bilinear sem antialias, "nearest" e bicúbico). Medimos que a
mesma foto muda de P(NoClots) em até 0,47 só por causa disso. Agora todos usam
as funções deste arquivo.

Dois modos, declarados em models/meta.json ("preprocessamento"):

  legado_bilinear  -> reproduz EXATAMENTE o treino antigo (decodifica e reduz
                      com bilinear sem antialias). Use para o modelo que já
                      existe, até ele ser retreinado.
  padronizado_v2   -> corrige a orientação EXIF, converte para RGB, reduz com
                      antialias (LANCZOS) e sempre chega em 224x224. É o modo
                      do dataset gerado por padronizar_dataset.py.

Se meta.json não existir, assume "legado_bilinear" (é o que o modelo atual usa).
"""
import json
from pathlib import Path

import numpy as np

IMG_SIZE = (224, 224)
MODO_LEGADO = "legado_bilinear"
MODO_PADRONIZADO = "padronizado_v2"
LADO_MAX_INTERMEDIARIO = 1024  # fotos de 12 MP são reduzidas até aqui antes do passo final


def ler_meta(pasta_modelos) -> dict:
    caminho = Path(pasta_modelos) / "meta.json"
    if caminho.exists():
        with open(caminho, encoding="utf-8") as f:
            return json.load(f)
    return {}


def modo_do_modelo(pasta_modelos) -> str:
    return ler_meta(pasta_modelos).get("preprocessamento", MODO_LEGADO)


def pil_para_modelo(img, modo=MODO_PADRONIZADO) -> np.ndarray:
    """PIL.Image -> array float32 (224, 224, 3) com valores de 0 a 255.
    (O MobileNetV2 normaliza os pixels DENTRO do modelo; não normalizar aqui.)"""
    from PIL import Image, ImageOps

    if modo == MODO_LEGADO:
        import tensorflow as tf

        arr = np.asarray(img.convert("RGB"), dtype=np.float32)
        return tf.image.resize(arr, IMG_SIZE, method="bilinear").numpy().astype(np.float32)

    img = ImageOps.exif_transpose(img).convert("RGB")
    if max(img.size) > LADO_MAX_INTERMEDIARIO:
        img.thumbnail((LADO_MAX_INTERMEDIARIO, LADO_MAX_INTERMEDIARIO), Image.LANCZOS)
    img = img.resize(IMG_SIZE, Image.LANCZOS)
    return np.asarray(img, dtype=np.float32)


def imagem_para_modelo(caminho, modo=MODO_PADRONIZADO) -> np.ndarray:
    from PIL import Image

    with Image.open(caminho) as img:
        img.load()
        return pil_para_modelo(img, modo)