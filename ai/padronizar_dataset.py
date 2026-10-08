"""
Padroniza o dataset: toda imagem passa pelo MESMO caminho, então resolução,
formato de arquivo, compressão e orientação EXIF deixam de ser pistas que o
modelo possa usar para "adivinhar" a classe.

O que faz com cada imagem (ver preprocessamento.py, modo padronizado_v2):
  1. lê o arquivo (jpg, png, bmp, webp) e corrige a orientação pela EXIF;
  2. converte para RGB;
  3. se for muito grande (foto de 12 MP), reduz até 1024 px com antialias;
  4. reduz para 224x224 com antialias (LANCZOS);
  5. grava como PNG (sem perdas, então não adiciona artefatos de JPEG).

Organização esperada da pasta de origem (uma subpasta por classe):

    dataset/
      Clots/
        foto_001.jpg                 <- arquivos soltos: cada um conta como uma "fonte"
        fazenda_joao_2026-09/        <- subpasta = UMA fonte (mesma câmera/local/dia)
          img_01.jpg
          img_02.jpg
      NoClots/
        ...

Guardar cada FONTE em uma subpasta é o que permite ao train_model.py separar
treino e teste por fonte (um teste honesto: o modelo é avaliado em fontes que
nunca viu). Imagens duplicadas (mesmo conteúdo) são ignoradas.

Uso (na pasta ai/):
    python padronizar_dataset.py
    python padronizar_dataset.py --origem dataset --destino dataset_padronizado

Depois treine com:  python train_model.py   (ele usa dataset_padronizado se existir)
"""
import argparse
import csv
import hashlib
import shutil
from collections import defaultdict
from pathlib import Path

import numpy as np

import preprocessamento as pp

BASE_DIR = Path(__file__).resolve().parent
EXTENSOES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
MARCADOR = "PADRONIZADO_V2.txt"  # train_model.py procura este arquivo para saber o modo


def _hash(caminho: Path) -> str:
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(1 << 16), b""):
            h.update(bloco)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--origem", default=str(BASE_DIR / "dataset"))
    ap.add_argument("--destino", default=str(BASE_DIR / "dataset_padronizado"))
    args = ap.parse_args()

    from PIL import Image

    origem, destino = Path(args.origem), Path(args.destino)
    if not origem.exists():
        raise SystemExit(f"Pasta não encontrada: {origem}")
    classes = sorted(d for d in origem.iterdir() if d.is_dir())
    if not classes:
        raise SystemExit(f"Nenhuma subpasta de classe em {origem}")

    # Proteção: o destino é APAGADO antes de gravar. Nunca pode ser (nem conter) a origem.
    o, d = origem.resolve(), destino.resolve()
    if d == o or o in d.parents or d in o.parents:
        raise SystemExit(
            f"O destino ({destino}) não pode ser igual a, nem estar dentro de/conter, a origem ({origem}): "
            "ele é apagado antes de gravar e você perderia o dataset original."
        )

    if destino.exists():
        shutil.rmtree(destino)
    destino.mkdir(parents=True)

    manifesto = []
    vistos = {}
    contagem = defaultdict(lambda: defaultdict(int))
    problemas, duplicadas = [], 0

    for pasta_classe in classes:
        arquivos = sorted(p for p in pasta_classe.rglob("*") if p.is_file() and p.suffix.lower() in EXTENSOES)
        print(f"[{pasta_classe.name}] {len(arquivos)} arquivos")
        for arq in arquivos:
            rel = arq.relative_to(pasta_classe)
            fonte = rel.parts[0] if len(rel.parts) > 1 else "(soltas)"
            try:
                h = _hash(arq)
                if h in vistos:
                    duplicadas += 1
                    continue
                vistos[h] = str(arq)
                with Image.open(arq) as im:
                    im.load()
                    largura, altura = im.size
                    formato = im.format
                    arr = pp.pil_para_modelo(im, pp.MODO_PADRONIZADO)
            except Exception as e:  # arquivo corrompido etc.
                problemas.append(f"{arq}: {e}")
                continue

            # Subpasta de fonte é preservada (o train_model.py usa isso para dividir por fonte).
            # Arquivos soltos ficam direto na pasta da classe.
            pasta_saida = destino / pasta_classe.name / (fonte if fonte != "(soltas)" else "")
            pasta_saida.mkdir(parents=True, exist_ok=True)
            nome = f"{arq.stem}_{h[:8]}.png"
            Image.fromarray(arr.astype(np.uint8)).save(pasta_saida / nome, optimize=True)

            contagem[pasta_classe.name][fonte] += 1
            manifesto.append({
                "arquivo_original": str(arq), "arquivo_padronizado": str((pasta_saida / nome).relative_to(destino)),
                "classe": pasta_classe.name, "fonte": fonte, "formato_original": formato,
                "largura_original": largura, "altura_original": altura,
                "tamanho_kb_original": round(arq.stat().st_size / 1024, 1), "sha256": h,
            })

    with open(destino / "manifesto.csv", "w", newline="", encoding="utf-8") as f:
        campos = list(manifesto[0].keys()) if manifesto else ["arquivo_original"]
        w = csv.DictWriter(f, fieldnames=campos)
        w.writeheader()
        w.writerows(manifesto)
    (destino / MARCADOR).write_text(
        "Dataset padronizado com preprocessamento.py (modo padronizado_v2): RGB, EXIF corrigido, "
        "LANCZOS, 224x224, PNG.\n", encoding="utf-8")

    print("\n" + "=" * 60)
    print(f"Imagens padronizadas: {len(manifesto)}  |  duplicadas ignoradas: {duplicadas}  |  com erro: {len(problemas)}")
    for classe, fontes in contagem.items():
        resumo = ", ".join(f"{f}: {n}" for f, n in sorted(fontes.items()))
        print(f"  {classe}: {sum(fontes.values())} imagens em {len(fontes)} fonte(s)  ->  {resumo}")
    soltas_apenas = all(set(f) == {"(soltas)"} for f in contagem.values())
    if soltas_apenas:
        print("\nATENÇÃO: não há subpastas de fonte. O teste vai sair da MESMA fonte do treino e a acurácia")
        print("pode ficar inflada. Ao coletar novas fotos, guarde cada sessão/câmera/local em uma subpasta.")
    for p in problemas[:10]:
        print("  ERRO:", p)
    print(f"\nSalvo em: {destino}  (manifesto.csv com a origem de cada imagem)")


if __name__ == "__main__":
    main()