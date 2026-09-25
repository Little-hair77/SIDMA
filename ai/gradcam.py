"""
Gera visualizações Grad-CAM para o modelo treinado em train_model.py.

O Grad-CAM produz um "mapa de calor" sobre a imagem original mostrando quais
regiões mais pesaram na decisão do modelo. Isso serve para verificar se ele
está realmente reagindo à região da amostra de leite/possível coágulo, ou se
está se apoiando em pistas espúrias (fundo, bordas, características de
câmera/resolução que não têm relação com mastite).

Observação: como a saída do modelo é uma única unidade sigmoid (2 classes),
o mapa de calor sempre mostra o que empurrou a predição em direção à classe
labels[1] (a segunda em ordem alfabética). Para uma imagem prevista como
labels[0], o mapa ainda é informativo — mostra as regiões que mais reduziram
a confiança na classe labels[1] — mas a leitura é um pouco menos direta.

Uso:
    python gradcam.py caminho/para/imagem.jpg
    python gradcam.py caminho/para/pasta_com_imagens/
    python gradcam.py dataset_split/test/Clots/           # ex: uma classe do teste
"""
import argparse
from pathlib import Path

import numpy as np

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
IMG_SIZE = (224, 224)
NOME_ULTIMA_CAMADA_CONV = "out_relu"  # última ativação conv do MobileNetV2, padrão para Grad-CAM


def carregar_modelo_e_labels():
    import json
    import tensorflow as tf

    caminho_modelo = MODELS_DIR / "mastite_model.keras"
    caminho_labels = MODELS_DIR / "labels.json"
    if not caminho_modelo.exists() or not caminho_labels.exists():
        raise SystemExit(f"Modelo não encontrado em {MODELS_DIR}. Rode train_model.py primeiro.")

    modelo = tf.keras.models.load_model(caminho_modelo)
    with open(caminho_labels, encoding="utf-8") as f:
        labels = json.load(f)
    return modelo, labels


def _localizar_base_model(modelo):
    """Encontra a sub-rede MobileNetV2 dentro do modelo funcional treinado."""
    for camada in modelo.layers:
        try:
            camada.get_layer(NOME_ULTIMA_CAMADA_CONV)
            return camada
        except (ValueError, AttributeError):
            continue
    raise SystemExit(
        "Não encontrei a sub-rede MobileNetV2 dentro do modelo carregado. "
        "Verifique se o modelo foi construído com construir_modelo() em train_model.py."
    )


def gerar_mapa_calor(modelo, base_model, imagem_array):
    import tensorflow as tf

    ultima_camada_conv = base_model.get_layer(NOME_ULTIMA_CAMADA_CONV)
    modelo_grad = tf.keras.models.Model(
        inputs=modelo.inputs,
        outputs=[ultima_camada_conv.output, modelo.output],
    )

    entrada = np.expand_dims(imagem_array, axis=0)

    with tf.GradientTape() as tape:
        saida_conv, predicao = modelo_grad(entrada)
        alvo = predicao[:, 0]  # única unidade de saída (sigmoid)

    gradientes = tape.gradient(alvo, saida_conv)
    pesos = tf.reduce_mean(gradientes, axis=(0, 1, 2))

    saida_conv = saida_conv[0]
    mapa_calor = tf.reduce_sum(saida_conv * pesos, axis=-1)
    mapa_calor = tf.maximum(mapa_calor, 0) / (tf.reduce_max(mapa_calor) + 1e-8)
    return mapa_calor.numpy(), float(predicao.numpy()[0][0])


def salvar_sobreposicao(caminho_imagem_original, mapa_calor, predicao, labels, caminho_saida):
    from PIL import Image

    try:
        import matplotlib
        colormap = matplotlib.colormaps["jet"]
    except (ImportError, AttributeError, KeyError):
        import matplotlib.cm as cm
        colormap = cm.get_cmap("jet")

    imagem_original = Image.open(caminho_imagem_original).convert("RGB").resize(IMG_SIZE)
    mapa_calor_img = Image.fromarray(np.uint8(255 * mapa_calor)).resize(IMG_SIZE)

    mapa_colorido = colormap(np.array(mapa_calor_img))[:, :, :3]
    mapa_colorido = Image.fromarray(np.uint8(mapa_colorido * 255))

    sobreposicao = Image.blend(imagem_original, mapa_colorido, alpha=0.4)

    indice_previsto = 1 if predicao > 0.5 else 0
    confianca = predicao if indice_previsto == 1 else 1 - predicao
    classe_prevista = labels[indice_previsto]

    caminho_saida.parent.mkdir(parents=True, exist_ok=True)
    sobreposicao.save(caminho_saida)
    print(f"  {caminho_imagem_original.name} -> previsto: {classe_prevista} ({confianca * 100:.1f}%) | salvo em {caminho_saida}")


def processar_imagem(modelo, base_model, labels, caminho_imagem, pasta_saida):
    import tensorflow as tf

    imagem = tf.keras.utils.load_img(caminho_imagem, target_size=IMG_SIZE)
    imagem_array = tf.keras.utils.img_to_array(imagem)

    mapa_calor, predicao = gerar_mapa_calor(modelo, base_model, imagem_array)
    caminho_saida = pasta_saida / f"gradcam_{caminho_imagem.stem}.png"
    salvar_sobreposicao(caminho_imagem, mapa_calor, predicao, labels, caminho_saida)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("caminho", help="Caminho de uma imagem ou de uma pasta com imagens.")
    parser.add_argument(
        "--saida", default=str(BASE_DIR / "gradcam_resultados"),
        help="Pasta onde salvar as imagens com o mapa de calor sobreposto (padrão: ai/gradcam_resultados/).",
    )
    args = parser.parse_args()

    modelo, labels = carregar_modelo_e_labels()
    base_model = _localizar_base_model(modelo)

    caminho = Path(args.caminho)
    pasta_saida = Path(args.saida)
    extensoes = {".jpg", ".jpeg", ".png", ".bmp"}

    if caminho.is_dir():
        imagens = sorted(f for f in caminho.iterdir() if f.suffix.lower() in extensoes)
        if not imagens:
            raise SystemExit(f"Nenhuma imagem encontrada em {caminho}")
        print(f"Gerando Grad-CAM para {len(imagens)} imagem(ns)...\n")
        for img in imagens:
            processar_imagem(modelo, base_model, labels, img, pasta_saida)
    elif caminho.is_file():
        processar_imagem(modelo, base_model, labels, caminho, pasta_saida)
    else:
        raise SystemExit(f"Caminho não encontrado: {caminho}")

    print(f"\nPronto. Resultados em: {pasta_saida}")


if __name__ == "__main__":
    main()