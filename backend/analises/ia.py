"""
Integração com o modelo de IA treinado em ai/train_model.py.

Enquanto os arquivos ai/models/mastite_model.keras e ai/models/labels.json
não existirem (modelo ainda não treinado), a classificação cai automaticamente
para o modo simulado (mock) — para não
quebrar o resto do app enquanto o treinamento não estiver pronto.
"""

import json
import random
from pathlib import Path

from django.conf import settings

from .models import Analise

IMG_SIZE = (224, 224)

# Abaixo desse limiar de confiança, o resultado é reportado como "Necessária
# avaliação adicional" em vez de forçar uma decisão binária pouco confiável.
LIMIAR_CONFIANCA_MINIMA = 0.65

_cache = {"modelo": None, "labels": None, "tentou_carregar": False}


def _caminhos_modelo():
    base = getattr(settings, "AI_MODELS_DIR", settings.BASE_DIR / "ai" / "models")
    return Path(base) / "mastite_model.keras", Path(base) / "labels.json"


def _carregar_modelo():
    """Carrega o modelo uma única vez (fica em cache em memória do processo)."""
    if _cache["tentou_carregar"]:
        return _cache["modelo"], _cache["labels"]

    _cache["tentou_carregar"] = True
    caminho_modelo, caminho_labels = _caminhos_modelo()

    if not caminho_modelo.exists() or not caminho_labels.exists():
        print(
            "[SIDMA-IA] Modelo treinado não encontrado em "
            f"{caminho_modelo}. Usando classificação SIMULADA (mock)."
        )
        return None, None

    import tensorflow as tf

    modelo = tf.keras.models.load_model(caminho_modelo)
    with open(caminho_labels, encoding="utf-8") as f:
        labels = json.load(f)

    print(f"[SIDMA-IA] Modelo real carregado com sucesso. Classes: {labels}")
    _cache["modelo"] = modelo
    _cache["labels"] = labels
    return modelo, labels


def _classificacao_simulada():
    resultado = random.choice([
        Analise.Resultado.SEM_INDICIOS,
        Analise.Resultado.POSSIVEL_MASTITE,
        Analise.Resultado.AVALIACAO_ADICIONAL,
    ])
    confianca = round(random.uniform(70.0, 99.0), 2)
    return resultado, confianca, True


def classificar_imagem_leite(caminho_imagem: str):
    """Classifica a imagem de uma amostra de leite.

    Retorna uma tupla (resultado, confianca_percentual, simulado):
    - resultado: um dos valores de Analise.Resultado
    - confianca_percentual: float de 0 a 100
    - simulado: True se ainda estamos no modo mock (modelo não treinado)
    """
    modelo, labels = _carregar_modelo()
    if modelo is None:
        return _classificacao_simulada()

    import numpy as np
    import tensorflow as tf

    imagem = tf.keras.utils.load_img(caminho_imagem, target_size=IMG_SIZE)
    entrada = tf.keras.utils.img_to_array(imagem)
    entrada = np.expand_dims(entrada, axis=0)
    # O pré-processamento do MobileNetV2 (normalização de pixels) já está
    # embutido como a primeira camada do próprio modelo salvo — não repetir aqui.

    predicao = modelo.predict(entrada, verbose=0)[0]

    if len(labels) == 2:
        prob_segunda_classe = float(predicao[0])  # saída da camada sigmoid
        indice_previsto = 1 if prob_segunda_classe > 0.5 else 0
        confianca_modelo = prob_segunda_classe if indice_previsto == 1 else 1 - prob_segunda_classe
    else:
        indice_previsto = int(np.argmax(predicao))
        confianca_modelo = float(predicao[indice_previsto])

    classe_prevista = labels[indice_previsto]  # nome literal da pasta usada no treino
    classe_normalizada = classe_prevista.strip().lower().replace("_", "").replace("-", "")

    # Aceita diferentes convenções de nome de pasta usadas no dataset
    # (ex.: 'saudavel', 'noclots', 'sem_mastite' = classe saudável).
    NOMES_CLASSE_SAUDAVEL = {"saudavel", "noclots", "semmastite", "healthy", "normal"}

    if confianca_modelo < LIMIAR_CONFIANCA_MINIMA:
        resultado = Analise.Resultado.AVALIACAO_ADICIONAL
    elif classe_normalizada in NOMES_CLASSE_SAUDAVEL:
        resultado = Analise.Resultado.SEM_INDICIOS
    else:
        resultado = Analise.Resultado.POSSIVEL_MASTITE

    confianca = round(confianca_modelo * 100, 2)
    return resultado, confianca, False