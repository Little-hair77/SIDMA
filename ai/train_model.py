import argparse
import json
import random
import shutil
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import preprocessamento as pp

BASE_DIR = Path(__file__).resolve().parent
DATASET_BRUTO_DIR = BASE_DIR / "dataset"
DATASET_PADRONIZADO_DIR = BASE_DIR / "dataset_padronizado"  # gerado por padronizar_dataset.py
MARCADOR_PADRONIZADO = "PADRONIZADO_V2.txt"
EXTENSOES = (".jpg", ".jpeg", ".png", ".bmp")
SPLIT_DIR = BASE_DIR / "dataset_split"
MODELS_DIR = BASE_DIR / "models"
IMG_SIZE = (224, 224)
SEED = 42


def dividir_dataset(origem: Path, destino: Path, proporcoes=(0.70, 0.15, 0.15), por_fonte=True):
    """Copia as imagens de `origem/<classe>/**` para `destino/{train,val,test}/<classe>/*`.

    DIVISÃO POR FONTE: cada subpasta dentro de uma classe (ex.: Clots/fazenda_a/)
    é tratada como UMA fonte (mesma câmera, local, dia) e vai INTEIRA para um único
    conjunto. Assim o teste avalia o modelo em fontes que ele nunca viu, que é a
    única forma honesta de medir se ele generaliza. Arquivos soltos na pasta da
    classe contam cada um como uma fonte própria (divisão aleatória, como antes).

    Se não houver subpastas, a acurácia no teste tende a ficar inflada: o teste
    vem da mesma fonte do treino (o aviso é impresso)."""
    random.seed(SEED)
    classes = [d.name for d in origem.iterdir() if d.is_dir()]
    if not classes:
        raise SystemExit(f"Nenhuma pasta de classe encontrada em {origem}")

    if destino.exists():
        shutil.rmtree(destino)

    resumo, tem_fontes = {}, False
    for classe in classes:
        pasta_classe = origem / classe
        grupos = defaultdict(list)
        for f in pasta_classe.rglob("*"):
            if not (f.is_file() and f.suffix.lower() in EXTENSOES):
                continue
            rel = f.relative_to(pasta_classe)
            if por_fonte and len(rel.parts) > 1:
                grupos[("fonte", rel.parts[0])].append(f)
                tem_fontes = True
            else:
                grupos[("arquivo", str(rel))].append(f)

        n = sum(len(v) for v in grupos.values())
        alvo = {"train": n * proporcoes[0], "val": n * proporcoes[1], "test": n * proporcoes[2]}
        atual = {k: 0 for k in alvo}
        splits = {k: [] for k in alvo}

        ordem = list(grupos.items())
        random.shuffle(ordem)
        ordem.sort(key=lambda kv: -len(kv[1]))  # fontes grandes primeiro; as soltas preenchem as sobras
        for _, arquivos in ordem:
            escolhido = max(alvo, key=lambda k: alvo[k] - atual[k])
            splits[escolhido] += arquivos
            atual[escolhido] += len(arquivos)

        vazios = [k for k, v in splits.items() if not v]
        if vazios:
            raise SystemExit(
                f"Classe '{classe}': não consegui formar os conjuntos {vazios} "
                f"({len(grupos)} grupos, {n} imagens). Use mais de uma fonte/subpasta ou mais imagens."
            )

        for split_nome, lista in splits.items():
            pasta_saida = destino / split_nome / classe
            pasta_saida.mkdir(parents=True, exist_ok=True)
            for arquivo in lista:
                nome_unico = "__".join(arquivo.relative_to(pasta_classe).parts)
                shutil.copy2(arquivo, pasta_saida / nome_unico)

        resumo[classe] = {k: len(v) for k, v in splits.items()}
        resumo[classe]["fontes"] = {
            k: sorted({g[1] for g, arqs in grupos.items() if g[0] == "fonte" and arqs and arqs[0] in set(v)})
            for k, v in splits.items()
        }

    print("Divisão do dataset (imagens por classe):")
    for classe, contagem in resumo.items():
        print(f"  {classe}: " + ", ".join(f"{k}={contagem[k]}" for k in ("train", "val", "test")))
        for k in ("val", "test"):
            if contagem["fontes"][k]:
                print(f"      fontes em {k}: {', '.join(contagem['fontes'][k])}")

    if not tem_fontes:
        print(
            "\nAVISO: o dataset não tem subpastas de fonte. Treino e teste saem da MESMA fonte, então a "
            "acurácia do teste tende a ficar inflada e NÃO mede se o modelo generaliza para fotos novas. "
            "Guarde cada sessão/câmera/local em uma subpasta (ver padronizar_dataset.py)."
        )

    total = sum(sum(c[k] for k in ("train", "val", "test")) for c in resumo.values())
    if total < 100:
        print(
            f"\nAVISO: apenas {total} imagens no total. Datasets pequenos tendem a "
            "overfitting — considere aumentar o volume de imagens ou usar "
            "data augmentation mais agressivo (já incluído neste script)."
        )

    return sorted(classes)


def construir_modelo(num_classes, learning_rate=1e-3, pesos="imagenet"):
    import tensorflow as tf
    from tensorflow.keras import layers, models
    from tensorflow.keras.applications import MobileNetV2

    base_model = MobileNetV2(
        input_shape=IMG_SIZE + (3,),
        include_top=False,
        weights=None if pesos == "none" else "imagenet",
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
    parser.add_argument("--dataset", default=None,
                        help="Pasta do dataset. Padrão: dataset_padronizado/ se existir (veja padronizar_dataset.py), senão dataset/.")
    parser.add_argument("--divisao", choices=["por-fonte", "aleatoria"], default="por-fonte",
                        help="por-fonte: cada subpasta de uma classe vai inteira para treino, validação OU teste.")
    parser.add_argument("--teste-externo", default=None,
                        help="Pasta com subpastas por classe de imagens de OUTRA fonte (nunca usadas no treino). "
                             "É a medida mais honesta de generalização.")
    parser.add_argument("--pesos", choices=["imagenet", "none"], default="imagenet",
                        help="'none' só para testes offline do script (sem baixar os pesos do ImageNet).")
    args = parser.parse_args()

    if args.dataset:
        dataset_dir = Path(args.dataset)
    elif (DATASET_PADRONIZADO_DIR / MARCADOR_PADRONIZADO).exists():
        dataset_dir = DATASET_PADRONIZADO_DIR
    else:
        dataset_dir = DATASET_BRUTO_DIR
    modo_preprocessamento = pp.MODO_PADRONIZADO if (dataset_dir / MARCADOR_PADRONIZADO).exists() else pp.MODO_LEGADO
    print(f"Dataset: {dataset_dir}  |  pré-processamento: {modo_preprocessamento}")

    import tensorflow as tf
    from sklearn.metrics import classification_report, confusion_matrix

    print("1/5 - Dividindo o dataset em treino/validação/teste...")
    classes = dividir_dataset(dataset_dir, SPLIT_DIR, por_fonte=(args.divisao == "por-fonte"))
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

    # Augmentation pensada para o problema real: a mesma amostra chega ao app com
    # ângulo, luz, foco, compressão e RESOLUÇÃO diferentes. Ensinar o modelo a
    # ignorar isso evita que ele decore a "assinatura" da câmera do dataset.
    # (Sem alterar matiz: a cor do leite e dos coágulos é informação real.)
    geometria = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal_and_vertical"),
        tf.keras.layers.RandomRotation(0.25),
        tf.keras.layers.RandomZoom((-0.3, 0.15)),
        tf.keras.layers.RandomTranslation(0.1, 0.1),
        tf.keras.layers.RandomContrast(0.25),
        tf.keras.layers.RandomBrightness(0.25, value_range=(0, 255)),
    ])

    def aumentar(imagem, rotulo):
        x = geometria(imagem, training=True)
        # resolução baixa: reduz e volta (simula foto pequena / de galeria)
        if tf.random.uniform(()) < 0.4:
            lado = tf.random.uniform((), 80, 200, dtype=tf.int32)
            x = tf.image.resize(tf.image.resize(x, (lado, lado), antialias=True), IMG_SIZE, method="bilinear")
        # desfoque leve (foto fora de foco)
        if tf.random.uniform(()) < 0.3:
            x = tf.nn.avg_pool2d(x[None], ksize=3, strides=1, padding="SAME")[0]
        # compressão JPEG forte (WhatsApp, galeria)
        if tf.random.uniform(()) < 0.4:
            x = tf.image.random_jpeg_quality(tf.clip_by_value(x, 0.0, 255.0) / 255.0, 30, 95) * 255.0
        return tf.clip_by_value(x, 0.0, 255.0), rotulo

    train_ds = train_ds.unbatch().map(aumentar, num_parallel_calls=tf.data.AUTOTUNE).batch(args.batch_size)

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(autotune)
    val_ds = val_ds.prefetch(autotune)
    test_ds = test_ds.prefetch(autotune)

    print("3/5 - Construindo e treinando o modelo (fase 1: backbone congelado)...")
    modelo, base_model = construir_modelo(len(nomes_classes), pesos=args.pesos)

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

    # BACKUP: se já existe um modelo treinado, guarda uma cópia (com labels, meta e
    # detector OOD) em models/anteriores/<data-hora>/ antes de sobrescrever.
    # Para voltar ao modelo antigo, é só copiar esses arquivos de volta para models/.
    anteriores = [p for p in ("mastite_model.keras", "labels.json", "meta.json", "ood_stats.npz", "ood_stats.json")
                  if (MODELS_DIR / p).exists()]
    if anteriores:
        pasta_backup = MODELS_DIR / "anteriores" / datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        pasta_backup.mkdir(parents=True)
        for nome in anteriores:
            shutil.copy2(MODELS_DIR / nome, pasta_backup / nome)
        print(f"\nModelo anterior preservado em: {pasta_backup}")

    modelo.save(caminho_modelo)
    with open(caminho_labels, "w", encoding="utf-8") as f:
        json.dump(nomes_classes, f, ensure_ascii=False, indent=2)

    # meta.json: diz ao backend, ao gradcam e ao testar_modelo COMO alimentar este modelo.
    # É o que impede treino e uso de reduzirem a imagem de formas diferentes.
    meta = {
        "preprocessamento": modo_preprocessamento,
        "img_size": list(IMG_SIZE),
        "classes": nomes_classes,
        "dataset": str(dataset_dir),
        "divisao": args.divisao,
        "treinado_em": datetime.now().isoformat(timespec="seconds"),
    }
    with open(MODELS_DIR / "meta.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    # O detector OOD do modelo anterior não vale para este (o espaço interno muda).
    # Já está no backup; aqui é removido para o backend não usar um detector desatualizado.
    for velho in ("ood_stats.npz", "ood_stats.json"):
        if (MODELS_DIR / velho).exists():
            (MODELS_DIR / velho).unlink()
            print(f"Removido {velho} (era do modelo anterior). Rode 'python construir_detector_ood.py' de novo.")

    if args.teste_externo:
        _avaliar_externo(modelo, Path(args.teste_externo), nomes_classes, modo_preprocessamento, MODELS_DIR)

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
        "\nPróximo passo: (1) rode 'python construir_detector_ood.py' para gerar o portão que "
        "recusa imagens que não são amostras de leite; (2) o backend usa models/mastite_model.keras, "
        "labels.json, meta.json e ood_stats.npz automaticamente (settings.AI_MODELS_DIR)."
    )


def _avaliar_externo(modelo, pasta, nomes_classes, modo, pasta_saida):
    """Avalia em imagens de OUTRA fonte (nunca usadas no treino). Usa o pré-processamento
    do modelo (preprocessamento.py), então é o mesmo caminho que o app percorre."""
    import numpy as np
    from sklearn.metrics import classification_report, confusion_matrix

    print("\n" + "=" * 60)
    print(f"TESTE EXTERNO ({pasta}): imagens de outra fonte, nunca vistas no treino")
    print("=" * 60)
    y_true, y_pred = [], []
    for sub in sorted(d for d in pasta.iterdir() if d.is_dir()):
        if sub.name not in nomes_classes:
            print(f"  (ignorando '{sub.name}': não é uma das classes {nomes_classes})")
            continue
        arquivos = sorted(p for p in sub.rglob("*") if p.suffix.lower() in pp_extensoes())
        if not arquivos:
            continue
        lote = np.stack([pp.imagem_para_modelo(a, modo) for a in arquivos])
        saida = np.asarray(modelo.predict(lote, batch_size=32, verbose=0)).reshape(len(arquivos), -1)
        pred = (saida[:, 0] > 0.5).astype(int) if len(nomes_classes) == 2 else saida.argmax(axis=1)
        y_true += [nomes_classes.index(sub.name)] * len(arquivos)
        y_pred += pred.tolist()
    if not y_true:
        print("  Nenhuma imagem encontrada.")
        return
    print(classification_report(y_true, y_pred, labels=list(range(len(nomes_classes))), target_names=nomes_classes, zero_division=0))
    print("Matriz de confusão (linhas = real, colunas = previsto):")
    print(confusion_matrix(y_true, y_pred, labels=list(range(len(nomes_classes)))))
    relatorio = classification_report(y_true, y_pred, labels=list(range(len(nomes_classes))), target_names=nomes_classes, output_dict=True, zero_division=0)
    with open(pasta_saida / "relatorio_teste_externo.json", "w", encoding="utf-8") as f:
        json.dump(relatorio, f, ensure_ascii=False, indent=2)
    print("\nSe este número for MUITO menor que o do teste interno, o modelo não generaliza: ")
    print("colete mais variedade (ângulo, luz, câmera, local) e retreine.")


def pp_extensoes():
    return {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


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