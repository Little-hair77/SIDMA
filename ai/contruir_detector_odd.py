"""
Constrói o detector de imagens fora do escopo e salva em models/ood_stats.npz.

para Rodar DEPOIS de treinar o modelo (train_model.py) e SEMPRE que retreinar:

    python construir_detector_ood.py
    python construir_detector_ood.py --negativos caminho/pasta_de_imagens_que_NAO_sao_leite

Como o limiar é escolhido:
  - ajusta a distribuição com as imagens de TREINO (dataset_split/train);
  - mede as distâncias nas imagens de VALIDAÇÃO (dataset_split/val), que o
    ajuste não viu;
  - o limiar é o percentil --percentil (padrão 99) dessas distâncias, vezes
    --margem. Ou seja: com os padrões, ~1% das imagens boas da validação seriam
    recusadas e o resto passa.

Passando --negativos (prints, paredes, mãos, outras fotos quaisquer), o
script mostra quantas dessas imagens o detector recusaria. É a forma de medir se
o portão funciona de verdade, e de ajustar --percentil / --margem.
"""
import argparse
import json
from pathlib import Path

import numpy as np

import ood
import preprocessamento

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
SPLIT_DIR = BASE_DIR / "dataset_split"


def _embeddings_por_classe(extrator, pasta, modo):
    """Lê pasta/<classe>/* e devolve embeddings e rótulos (índice da classe)."""
    embs, rotulos, nomes = [], [], []
    for i, sub in enumerate(sorted(d for d in Path(pasta).iterdir() if d.is_dir())):
        e, _, caminhos = ood.embeddings_da_pasta(extrator, sub, modo)
        if len(caminhos):
            embs.append(e)
            rotulos += [i] * len(caminhos)
        nomes.append(sub.name)
    return np.concatenate(embs), np.array(rotulos), nomes


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--treino", default=str(SPLIT_DIR / "train"))
    ap.add_argument("--validacao", default=str(SPLIT_DIR / "val"))
    ap.add_argument("--negativos", default=None, help="Pasta com imagens que NÃO são amostras de leite (opcional, para medir o portão).")
    ap.add_argument("--percentil", type=float, default=99.0)
    ap.add_argument("--margem", type=float, default=1.0)
    ap.add_argument("--modelo", default=str(MODELS_DIR / "mastite_model.keras"))
    ap.add_argument("--saida", default=str(MODELS_DIR / "ood_stats.npz"))
    args = ap.parse_args()

    import tensorflow as tf

    modelo = tf.keras.models.load_model(args.modelo)
    extrator = ood.carregar_extrator(modelo)
    modo = preprocessamento.modo_do_modelo(Path(args.modelo).parent)
    print(f"Pré-processamento do modelo: {modo}")

    print("1/3 - Calculando embeddings do treino...")
    emb_tr, rot_tr, nomes = _embeddings_por_classe(extrator, args.treino, modo)
    print(f"      {len(emb_tr)} imagens, {emb_tr.shape[1]} dimensões, classes: {nomes}")

    print("2/3 - Ajustando a distribuição (Mahalanobis, covariância compartilhada)...")
    medias, precisao = ood.ajustar_gaussiana(emb_tr, rot_tr)

    print("3/3 - Escolhendo o limiar com a validação...")
    emb_va, _, _ = _embeddings_por_classe(extrator, args.validacao, modo)
    d_tr = ood.distancia_mahalanobis(emb_tr, medias, precisao)
    d_va = ood.distancia_mahalanobis(emb_va, medias, precisao)
    limiar = float(np.percentile(d_va, args.percentil) * args.margem)

    print(f"\n  distância no treino     : mediana {np.median(d_tr):.1f} | p99 {np.percentile(d_tr, 99):.1f}")
    print(f"  distância na validação  : mediana {np.median(d_va):.1f} | p99 {np.percentile(d_va, 99):.1f}")
    print(f"  LIMIAR escolhido        : {limiar:.1f}  (p{args.percentil:g} da validação x {args.margem:g})")
    print(f"  imagens boas recusadas  : {(d_va > limiar).mean() * 100:.1f}% da validação")

    relatorio = {"limiar": limiar, "percentil": args.percentil, "margem": args.margem,
                 "n_treino": int(len(emb_tr)), "n_validacao": int(len(emb_va)),
                 "recusadas_validacao_pct": float((d_va > limiar).mean() * 100)}

    if args.negativos:
        e_neg, _, caminhos = ood.embeddings_da_pasta(extrator, args.negativos, modo)
        if len(caminhos):
            d_neg = ood.distancia_mahalanobis(e_neg, medias, precisao)
            recusadas = float((d_neg > limiar).mean() * 100)
            relatorio.update({"n_negativos": int(len(caminhos)), "negativos_recusados_pct": recusadas})
            print(f"\n  NEGATIVOS ({len(caminhos)} imagens sem relação): {recusadas:.1f}% recusados")
            print(f"  distância dos negativos : mediana {np.median(d_neg):.1f} | mínima {d_neg.min():.1f}")
            # AUROC: probabilidade de uma imagem sem relação ter distância maior que uma boa
            from sklearn.metrics import roc_auc_score
            y = np.r_[np.zeros(len(d_va)), np.ones(len(d_neg))]
            auroc = float(roc_auc_score(y, np.r_[d_va, d_neg]))
            relatorio["auroc"] = auroc
            print(f"  AUROC (bom x sem relação): {auroc:.3f}   (1.0 = separação perfeita, 0.5 = acaso)")
            for c, d in sorted(zip(caminhos, d_neg), key=lambda t: t[1])[:5]:
                print(f"     mais difíceis de recusar: {c.name}  (distância {d:.1f})")

    np.savez(args.saida, medias=medias, precisao=precisao, limiar=np.float32(limiar))
    with open(Path(args.saida).with_suffix(".json"), "w", encoding="utf-8") as f:
        json.dump(relatorio, f, ensure_ascii=False, indent=2)
    print(f"\nSalvo em: {args.saida}")
    print("O backend passa a usar o portão automaticamente (ele procura models/ood_stats.npz).")


if __name__ == "__main__":
    main()