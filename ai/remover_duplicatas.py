"""
Remove duplicatas exatas (mesmo conteúdo de arquivo) do dataset de treino,
MOVENDO-AS para uma pasta separada (não apaga nada permanentemente) e
mantendo sempre a primeira ocorrência de cada imagem (por ordem alfabética).

Esse aequivo não tem relação com "imagens corrompidas" nem com a qualidade/origem
do dataset — é sobre garantir que a mesma foto não apareça duas vezes, o
que poderia fazer a mesma imagem cair em treino E em teste ao mesmo tempo,
inflando artificialmente a acurácia medida depois do treino.

Uso:
    python remover_duplicatas.py            # modo simulação: só mostra o que seria movido
    python remover_duplicatas.py --aplicar   # move de verdade para dataset_duplicatas_removidas/
"""
import argparse
import hashlib
import shutil
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"
BACKUP_DIR = BASE_DIR / "dataset_duplicatas_removidas"
EXTENSOES_VALIDAS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def _hash_arquivo(caminho: Path) -> str:
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(8192), b""):
            h.update(bloco)
    return h.hexdigest()


def remover_duplicatas(aplicar: bool):
    if not DATASET_DIR.exists():
        raise SystemExit(f"Pasta não encontrada: {DATASET_DIR}")

    classes = sorted([d.name for d in DATASET_DIR.iterdir() if d.is_dir()])
    if not classes:
        raise SystemExit(f"Nenhuma subpasta de classe encontrada em {DATASET_DIR}.")

    hashes_vistos = {}
    duplicatas = []

    for classe in classes:
        pasta = DATASET_DIR / classe
        arquivos = sorted(
            f for f in pasta.iterdir()
            if f.is_file() and f.suffix.lower() in EXTENSOES_VALIDAS
        )

        for arquivo in arquivos:
            h = _hash_arquivo(arquivo)
            if h in hashes_vistos:
                duplicatas.append((classe, arquivo))
            else:
                hashes_vistos[h] = arquivo

    if not duplicatas:
        print("Nenhuma duplicata encontrada. Dataset já está limpo nesse quesito.")
        return

    print(f"{len(duplicatas)} imagem(ns) duplicada(s) encontrada(s):\n")
    for classe, arquivo in duplicatas:
        if aplicar:
            destino_pasta = BACKUP_DIR / classe
            destino_pasta.mkdir(parents=True, exist_ok=True)
            destino = destino_pasta / arquivo.name
            print(f"  MOVENDO: {arquivo.relative_to(DATASET_DIR)}  ->  {destino.relative_to(BASE_DIR)}")
            shutil.move(str(arquivo), str(destino))
        else:
            print(f"  (seria movida): {arquivo.relative_to(DATASET_DIR)}")

    print()
    if not aplicar:
        print("Modo de simulação (dry-run) — nada foi movido ainda.")
        print("Revise a lista acima e, se estiver tudo certo, rode:")
        print("    python remover_duplicatas.py --aplicar")
    else:
        print(f"{len(duplicatas)} arquivo(s) movido(s) para: {BACKUP_DIR}")
        print("Elas continuam no seu disco (não foram apagadas), só saíram do dataset de treino.")
        print("Rode 'python preparar_dataset.py' de novo para confirmar que sumiram os avisos de duplicata.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--aplicar",
        action="store_true",
        help="Move de fato os arquivos duplicados para dataset_duplicatas_removidas/. Sem essa flag, só mostra o que seria movido.",
    )
    args = parser.parse_args()
    remover_duplicatas(args.aplicar)