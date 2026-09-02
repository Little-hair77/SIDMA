"""
Teste rápido do modelo treinado em UMA imagem, direto pelo terminal —
sem precisar subir o backend Django/Flutter só para conferir se o modelo
está classificando de forma razoável.

Uso:
    python testar_modelo.py caminho/para/imagem.jpg
    python testar_modelo.py caminho/para/imagem.jpg --limiar 70

Usa exatamente o mesmo pré-processamento (resize 224x224, RGB) e a mesma
lógica de limiar de confiança que o backend usa em `analises/ia.py`, para
que o resultado aqui seja um previsor confiável do que vai acontecer em
produção.
"""

import argparse
import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
IMG_SIZE = (224, 224)


def main():
    parser = argparse.ArgumentParser(description="Testa o modelo treinado em uma única imagem.")
    parser.add_argument("imagem", type=str, help="Caminho da imagem a classificar")
    parser.add_argument("--limiar", type=float, default=65.0, help="Confiança mínima (%%) para não cair em 'avaliação adicional'")
    args = parser.parse_args()

    caminho_modelo = MODELS_DIR / "mastite_model.keras"
    caminho_labels = MODELS_DIR / "labels.json"

    if not caminho_modelo.exists() or not caminho_labels.exists():
        raise SystemExit(
            f"Modelo não encontrado em {MODELS_DIR}. Rode 'python train_model.py' primeiro."
        )

    import numpy as np
    import tensorflow as tf
    from PIL import Image

    print("Carregando modelo...")
    modelo = tf.keras.models.load_model(caminho_modelo)
    with open(caminho_labels, "r", encoding="utf-8") as f:
        labels = json.load(f)

    indice_mastite = next((i for i, nome in enumerate(labels) if "mastite" in nome.lower()), None)
    if indice_mastite is None:
        raise SystemExit(f"Não identifiquei a classe de mastite em labels.json: {labels}")

    imagem = Image.open(args.imagem).convert("RGB").resize(IMG_SIZE)
    lote = np.expand_dims(np.array(imagem, dtype=np.float32), axis=0)

    predicao = modelo.predict(lote, verbose=0)

    if len(labels) == 2:
        prob_classe_1 = float(predicao[0][0])
        probs = [1.0 - prob_classe_1, prob_classe_1]
    else:
        probs = tf.nn.softmax(predicao[0]).numpy().tolist()

    idx_previsto = int(np.argmax(probs))
    confianca = round(probs[idx_previsto] * 100, 2)

    print("\n--- Probabilidades por classe ---")
    for nome, prob in zip(labels, probs):
        print(f"  {nome}: {prob * 100:.2f}%")

    print(f"\nClasse com maior probabilidade: {labels[idx_previsto]} ({confianca}%)")

    if confianca < args.limiar:
        resultado_final = "NECESSÁRIA AVALIAÇÃO ADICIONAL (confiança abaixo do limiar)"
    elif idx_previsto == indice_mastite:
        resultado_final = "POSSÍVEL MASTITE"
    else:
        resultado_final = "SEM INDÍCIOS"

    print(f"Resultado que o app exibiria: {resultado_final}")


if __name__ == "__main__":
    main()
