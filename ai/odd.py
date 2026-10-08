"""
Funções compartilhadas pelo detector de "imagem fora do escopo" (OOD).

O modelo foi treinado só com 2 classes (Clots / NoClots), então ele é
OBRIGADO a escolher uma das duas para QUALQUER imagem — inclusive um print de
tela ou uma foto de parede — e muitas vezes escolhe com confiança altíssima.

Para detectar isso, usamos o "embedding" que o próprio modelo calcula (saída do
GlobalAveragePooling, 1280 números por imagem). Imagens parecidas com as do
treino caem perto das imagens do treino nesse espaço; imagens sem relação caem
longe. A distância usada é a de Mahalanobis (a "distância estatística" ao
centro de cada classe), com covariância compartilhada e encolhimento de
Ledoit-Wolf, que é estável mesmo com poucas imagens por dimensão.

Este arquivo só precisa de numpy + tensorflow, então pode ser reaproveitado
tanto pelos scripts de ai/ quanto pelo backend Django.
"""
from pathlib import Path

import numpy as np

IMG_SIZE = (224, 224)
EXTENSOES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def carregar_extrator(modelo):
    """Modelo auxiliar com DUAS saídas na mesma passada: (embedding, predição)."""
    import tensorflow as tf

    camada_gap = None
    for camada in modelo.layers:
        if isinstance(camada, tf.keras.layers.GlobalAveragePooling2D):
            camada_gap = camada
    if camada_gap is None:
        raise RuntimeError("GlobalAveragePooling2D não encontrada no modelo carregado.")
    return tf.keras.Model(modelo.inputs, [camada_gap.output, modelo.output])


def carregar_imagem(caminho, modo):
    """Mesmo pré-processamento do treino e do backend (ver preprocessamento.py)."""
    import preprocessamento

    return preprocessamento.imagem_para_modelo(caminho, modo)


def listar_imagens(pasta):
    return sorted(p for p in Path(pasta).rglob("*") if p.suffix.lower() in EXTENSOES)


def embeddings_da_pasta(extrator, pasta, modo, lote=32):
    """Retorna (embeddings [N,D], predições [N], caminhos) de todas as imagens da pasta."""
    caminhos = listar_imagens(pasta)
    embs, preds = [], []
    for i in range(0, len(caminhos), lote):
        arrays = []
        for c in caminhos[i:i + lote]:
            try:
                arrays.append(carregar_imagem(c, modo))
            except Exception:
                arrays.append(np.zeros(IMG_SIZE + (3,), dtype=np.float32))
        e, p = extrator.predict(np.stack(arrays), verbose=0)
        embs.append(e)
        preds.append(np.asarray(p).reshape(len(arrays), -1)[:, 0])
    if not caminhos:
        return np.zeros((0, 1)), np.zeros(0), []
    return np.concatenate(embs), np.concatenate(preds), caminhos


def ajustar_gaussiana(embs, rotulos):
    """Média por classe + covariância compartilhada (encolhida) -> matriz de precisão."""
    from sklearn.covariance import LedoitWolf

    rotulos = np.asarray(rotulos)
    classes = np.unique(rotulos)
    medias = np.stack([embs[rotulos == c].mean(axis=0) for c in classes])
    centrados = embs - medias[np.searchsorted(classes, rotulos)]
    cov = LedoitWolf().fit(centrados.astype(np.float64)).covariance_
    precisao = np.linalg.pinv(cov)
    return medias.astype(np.float32), precisao.astype(np.float32)


def distancia_mahalanobis(embs, medias, precisao):
    """Menor distância (ao quadrado) entre o embedding e o centro de qualquer classe."""
    embs = np.atleast_2d(embs).astype(np.float64)
    melhores = np.full(len(embs), np.inf)
    for m in medias.astype(np.float64):
        d = embs - m
        melhores = np.minimum(melhores, np.einsum("ij,jk,ik->i", d, precisao.astype(np.float64), d))
    return melhores