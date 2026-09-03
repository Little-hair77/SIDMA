import argparse
import json
import random
import shutil
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"
SPLIT_DIR = BASE_DIR / "dataset_split"
MODELS_DIR = BASE_DIR / "models"
IMG_SIZE = (224, 224)
SEED = 42


def dividir_dataset(origem: Path, destino: Path, proporcoes=(0.70, 0.15, 0.15)):
    """Copia as imagens de `origem/<classe>/*` para
    `destino/{train,val,test}/<classe>/*`, de forma estratificada."""
    random.seed(SEED)
    classes = [d.name for d in origem.iterdir() if d.is_dir()]
    if not classes:
        raise SystemExit(f"Nenhuma pasta de classe encontrada em {origem}")

    if destino.exists():
        shutil.rmtree(destino)

    resumo = {}
    for classe in classes:
        arquivos = [
            f for f in (origem / classe).iterdir()
            if f.suffix.lower() in (".jpg", ".jpeg", ".png", ".bmp")
        ]
        random.shuffle(arquivos)

        n = len(arquivos)
        n_train = int(n * proporcoes[0])
        n_val = int(n * proporcoes[1])

        splits = {
            "train": arquivos[:n_train],
            "val": arquivos[n_train:n_train + n_val],
            "test": arquivos[n_train + n_val:],
        }

        for split_nome, lista in splits.items():
            pasta_saida = destino / split_nome / classe
            pasta_saida.mkdir(parents=True, exist_ok=True)
            for arquivo in lista:
                shutil.copy2(arquivo, pasta_saida / arquivo.name)

        resumo[classe] = {k: len(v) for k, v in splits.items()}

    print("Divisão do dataset (imagens por classe):")
    for classe, contagem in resumo.items():
        print(f"  {classe}: {contagem}")

    total = sum(sum(c.values()) for c in resumo.values())
    if total < 100:
        print(
            f"\nAVISO: apenas {total} imagens no total. Datasets pequenos tendem a "
            "overfitting — considere aumentar o volume de imagens ou usar "
            "data augmentation mais agressivo (já incluído neste script)."
        )

    return sorted(classes)


def construir_modelo(num_classes, learning_rate=1e-3):
    import tensorflow as tf
    from tensorflow.keras import layers, models
    from tensorflow.keras.applications import MobileNetV2

    base_model = MobileNetV2(
        input_shape=IMG_SIZE + (3,),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False  # fase 1: backbone congelado

    entrada = layers.Input(shape=IMG_SIZE + (3,))
    x = tf.keras.applications.mobilenet_v2.preprocess_input(entrada)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.2)(x)
    saida = layers.Dense(
        1 if num_classes == 2 else num_classes,
        activation="sigmoid" if num_classes == 2 else "softmax",
    )(x)

    modelo = models.Model(entrada, saida)
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss="binary_crossentropy" if num_classes == 2 else "sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return modelo, base_model


def main():
    parser = argparse.ArgumentParser(description="Treina o modelo de classificação de mastite clínica.")
    parser.add_argument("--epochs", type=int, default=15, help="Épocas da fase 1 (backbone congelado)")
    parser.add_argument("--fine-tune-epochs", type=int, default=10, help="Épocas da fase 2 (fine-tuning)")
    parser.add_argument("--batch-size", type=int, default=16)
    args = parser.parse_args()

    import tensorflow as tf
    from sklearn.metrics import classification_report, confusion_matrix

    print("1/5 - Dividindo o dataset em treino/validação/teste...")
    classes = dividir_dataset(DATASET_DIR, SPLIT_DIR)
    print(f"Classes encontradas: {classes}\n")

    print("2/5 - Carregando os conjuntos de imagens...")
    train_ds = tf.keras.utils.image_dataset_from_directory(
        SPLIT_DIR / "train", image_size=IMG_SIZE, batch_size=args.batch_size,
        label_mode="binary" if len(classes) == 2 else "int", seed=SEED,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        SPLIT_DIR / "val", image_size=IMG_SIZE, batch_size=args.batch_size,
        label_mode="binary" if len(classes) == 2 else "int", seed=SEED,
    )
    test_ds = tf.keras.utils.image_dataset_from_directory(
        SPLIT_DIR / "test", image_size=IMG_SIZE, batch_size=args.batch_size,
        label_mode="binary" if len(classes) == 2 else "int", shuffle=False,
    )
    nomes_classes = train_ds.class_names  # ordem alfabética real usada pelo Keras

    aumento = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.08),
        tf.keras.layers.RandomZoom(0.1),
        tf.keras.layers.RandomContrast(0.1),
    ])
    train_ds = train_ds.map(lambda x, y: (aumento(x, training=True), y))

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(autotune)
    val_ds = val_ds.prefetch(autotune)
    test_ds = test_ds.prefetch(autotune)

    print("3/5 - Construindo e treinando o modelo (fase 1: backbone congelado)...")
    modelo, base_model = construir_modelo(len(nomes_classes))

    # Pesos por classe, calculados a partir da distribuição real do treino —
    # mitiga o viés para a classe majoritária quando o dataset é desbalanceado
    # (ver aviso do preparar_dataset.py).
    from sklearn.utils.class_weight import compute_class_weight
    import numpy as np

    rotulos_treino = np.concatenate([y.numpy() for _, y in train_ds.unbatch().batch(1024)])
    classes_presentes = np.unique(rotulos_treino)
    pesos = compute_class_weight(class_weight="balanced", classes=classes_presentes, y=rotulos_treino.flatten())
    class_weight = {int(c): float(p) for c, p in zip(classes_presentes, pesos)}
    print(f"Pesos por classe (compensando desbalanceamento): {class_weight}\n")

    historico_fase1 = modelo.fit(train_ds, validation_data=val_ds, epochs=args.epochs, class_weight=class_weight)

    print("\n4/5 - Fine-tuning (fase 2: descongelando as últimas camadas)...")
    base_model.trainable = True
    for camada in base_model.layers[:-30]:
        camada.trainable = False
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss=modelo.loss,
        metrics=["accuracy"],
    )
    historico_fase2 = modelo.fit(train_ds, validation_data=val_ds, epochs=args.fine_tune_epochs, class_weight=class_weight)

    print("\n5/5 - Avaliando no conjunto de teste (holdout)...")
    y_true, y_pred = [], []
    for imagens, rotulos in test_ds:
        preds = modelo.predict(imagens, verbose=0)
        if len(nomes_classes) == 2:
            y_pred.extend((preds.flatten() > 0.5).astype(int).tolist())
        else:
            y_pred.extend(preds.argmax(axis=1).tolist())
        y_true.extend(rotulos.numpy().flatten().astype(int).tolist())

    print("\nRelatório de classificação:")
    print(classification_report(y_true, y_pred, target_names=nomes_classes))
    print("Matriz de confusão (linhas = real, colunas = previsto):")
    print(nomes_classes)
    matriz = confusion_matrix(y_true, y_pred)
    print(matriz)

    MODELS_DIR.mkdir(exist_ok=True)
    caminho_modelo = MODELS_DIR / "mastite_model.keras"
    caminho_labels = MODELS_DIR / "labels.json"
    modelo.save(caminho_modelo)
    with open(caminho_labels, "w", encoding="utf-8") as f:
        json.dump(nomes_classes, f, ensure_ascii=False, indent=2)

    # Relatório de classificação em JSON (para citar números exatos no TCC
    # sem precisar copiar do terminal manualmente).
    relatorio_dict = classification_report(y_true, y_pred, target_names=nomes_classes, output_dict=True)
    with open(MODELS_DIR / "relatorio_classificacao.json", "w", encoding="utf-8") as f:
        json.dump(relatorio_dict, f, ensure_ascii=False, indent=2)

    _salvar_graficos(historico_fase1, historico_fase2, matriz, nomes_classes, MODELS_DIR)

    print(f"\nModelo salvo em: {caminho_modelo}")
    print(f"Mapa de classes salvo em: {caminho_labels}")
    print(f"Gráficos (curvas de treino + matriz de confusão) salvos em: {MODELS_DIR}")
    print(
        "\nPróximo passo: copie (ou aponte, via AI_MODEL_PATH em settings.py) esses "
        "dois arquivos para que o backend Django passe a usar o modelo real em "
        "vez do resultado simulado."
    )


def _salvar_graficos(historico_fase1, historico_fase2, matriz, nomes_classes, pasta_saida):
    """Gera e salva, como PNG, as curvas de acurácia/perda e a matriz de
    confusão — figuras prontas para o capítulo de resultados do TCC."""
    import matplotlib
    matplotlib.use("Agg")  # não depende de display gráfico (roda em qualquer terminal)
    import matplotlib.pyplot as plt
    import numpy as np

    # Curvas de treino: concatena fase 1 (backbone congelado) + fase 2 (fine-tuning)
    acc = historico_fase1.history["accuracy"] + historico_fase2.history["accuracy"]
    val_acc = historico_fase1.history["val_accuracy"] + historico_fase2.history["val_accuracy"]
    loss = historico_fase1.history["loss"] + historico_fase2.history["loss"]
    val_loss = historico_fase1.history["val_loss"] + historico_fase2.history["val_loss"]
    epoca_fine_tune = len(historico_fase1.history["accuracy"])

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4.5))

    ax1.plot(acc, label="Treino")
    ax1.plot(val_acc, label="Validação")
    ax1.axvline(x=epoca_fine_tune - 0.5, color="gray", linestyle="--", linewidth=1, label="Início do fine-tuning")
    ax1.set_title("Acurácia por época")
    ax1.set_xlabel("Época")
    ax1.set_ylabel("Acurácia")
    ax1.legend()

    ax2.plot(loss, label="Treino")
    ax2.plot(val_loss, label="Validação")
    ax2.axvline(x=epoca_fine_tune - 0.5, color="gray", linestyle="--", linewidth=1, label="Início do fine-tuning")
    ax2.set_title("Perda (loss) por época")
    ax2.set_xlabel("Época")
    ax2.set_ylabel("Loss")
    ax2.legend()

    fig.tight_layout()
    fig.savefig(pasta_saida / "historico_treinamento.png", dpi=150)
    plt.close(fig)

    # Matriz de confusão como heatmap anotado
    fig2, ax = plt.subplots(figsize=(5, 4.5))
    im = ax.imshow(matriz, cmap="Blues")
    ax.set_xticks(range(len(nomes_classes)))
    ax.set_yticks(range(len(nomes_classes)))
    ax.set_xticklabels(nomes_classes, rotation=30, ha="right")
    ax.set_yticklabels(nomes_classes)
    ax.set_xlabel("Classe prevista")
    ax.set_ylabel("Classe real")
    ax.set_title("Matriz de confusão (conjunto de teste)")

    valor_maximo = matriz.max()
    for i in range(matriz.shape[0]):
        for j in range(matriz.shape[1]):
            cor_texto = "white" if matriz[i, j] > valor_maximo / 2 else "black"
            ax.text(j, i, str(matriz[i, j]), ha="center", va="center", color=cor_texto, fontweight="bold")

    fig2.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig2.tight_layout()
    fig2.savefig(pasta_saida / "matriz_confusao.png", dpi=150)
    plt.close(fig2)


if __name__ == "__main__":
    main()
