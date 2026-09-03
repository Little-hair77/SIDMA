import hashlib
import json
from collections import defaultdict
from pathlib import Path

from PIL import Image, UnidentifiedImageError

BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"
EXTENSOES_VALIDAS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

# Limites de referência para os alertas do relatório (ajustáveis).
RAZAO_DESBALANCEAMENTO_MAX = 2.5  # classe majoritária não devia ter mais que 2.5x a minoritária
MINIMO_RECOMENDADO_POR_CLASSE = 80  # abaixo disso, o aviso de "poucas imagens" aparece


def _hash_arquivo(caminho: Path) -> str:
    """Hash do conteúdo do arquivo, para detectar imagens duplicadas
    (mesmo que renomeadas ou copiadas para classes diferentes por engano)."""
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(8192), b""):
            h.update(bloco)
    return h.hexdigest()


def validar_dataset():
    if not DATASET_DIR.exists():
        raise SystemExit(f"Pasta não encontrada: {DATASET_DIR}")

    classes = sorted([d.name for d in DATASET_DIR.iterdir() if d.is_dir()])
    if not classes:
        raise SystemExit(
            f"Nenhuma subpasta de classe encontrada em {DATASET_DIR}. "
            "Esperado algo como dataset/saudavel/ e dataset/com_mastite/."
        )

    print(f"Classes encontradas: {classes}\n")

    relatorio = {
        "classes": {},
        "problemas": [],
        "avisos": [],
    }

    hashes_vistos = {}  # hash -> (classe, caminho) — para detectar duplicatas entre classes/arquivos
    contagem_por_classe = {}
    dimensoes_todas = []
    formatos_todos = defaultdict(int)

    for classe in classes:
        pasta = DATASET_DIR / classe
        arquivos = [f for f in pasta.iterdir() if f.is_file()]

        validos = 0
        corrompidos = []
        extensao_invalida = []
        dimensoes_classe = []
        tamanhos_bytes = []

        for arquivo in arquivos:
            if arquivo.suffix.lower() not in EXTENSOES_VALIDAS:
                extensao_invalida.append(arquivo.name)
                continue

            try:
                with Image.open(arquivo) as img:
                    img.verify()  # checa integridade sem carregar todo o conteúdo
                # precisa reabrir depois do verify() para conseguir ler .size
                with Image.open(arquivo) as img:
                    dimensoes_classe.append(img.size)
                    formatos_todos[img.format] += 1
                tamanhos_bytes.append(arquivo.stat().st_size)
                validos += 1

                h = _hash_arquivo(arquivo)
                if h in hashes_vistos:
                    classe_anterior, caminho_anterior = hashes_vistos[h]
                    relatorio["problemas"].append(
                        f"Imagem duplicada: '{arquivo.relative_to(DATASET_DIR)}' é idêntica a "
                        f"'{caminho_anterior.relative_to(DATASET_DIR)}'"
                        + (" (classes diferentes!)" if classe_anterior != classe else "")
                    )
                else:
                    hashes_vistos[h] = (classe, arquivo)

            except (UnidentifiedImageError, OSError):
                corrompidos.append(arquivo.name)

        if corrompidos:
            relatorio["problemas"].append(
                f"{classe}: {len(corrompidos)} arquivo(s) corrompido(s) ou ilegível(eis): {corrompidos[:10]}"
                + (" ... (mais)" if len(corrompidos) > 10 else "")
            )
        if extensao_invalida:
            relatorio["avisos"].append(
                f"{classe}: {len(extensao_invalida)} arquivo(s) com extensão não suportada, ignorados: {extensao_invalida[:10]}"
            )

        contagem_por_classe[classe] = validos
        dimensoes_todas.extend(dimensoes_classe)

        largura_media = sum(d[0] for d in dimensoes_classe) / len(dimensoes_classe) if dimensoes_classe else 0
        altura_media = sum(d[1] for d in dimensoes_classe) / len(dimensoes_classe) if dimensoes_classe else 0
        tamanho_medio_kb = (sum(tamanhos_bytes) / len(tamanhos_bytes) / 1024) if tamanhos_bytes else 0

        relatorio["classes"][classe] = {
            "imagens_validas": validos,
            "dimensao_media": f"{largura_media:.0f}x{altura_media:.0f}",
            "tamanho_medio_kb": round(tamanho_medio_kb, 1),
        }

        print(f"[{classe}]")
        print(f"  Imagens válidas: {validos}")
        print(f"  Dimensão média: {largura_media:.0f}x{altura_media:.0f} px")
        print(f"  Tamanho médio de arquivo: {tamanho_medio_kb:.1f} KB")
        if validos < MINIMO_RECOMENDADO_POR_CLASSE:
            aviso = (
                f"{classe}: apenas {validos} imagens (recomendado >= {MINIMO_RECOMENDADO_POR_CLASSE}). "
                "Com poucas imagens, considere data augmentation mais agressivo e/ou "
                "validação cruzada em vez de um único split fixo de teste."
            )
            relatorio["avisos"].append(aviso)
            print(f"  AVISO: {aviso}")
        print()

    # Balanceamento entre classes
    valores = list(contagem_por_classe.values())
    if valores and min(valores) > 0:
        razao = max(valores) / min(valores)
        if razao > RAZAO_DESBALANCEAMENTO_MAX:
            classe_maior = max(contagem_por_classe, key=contagem_por_classe.get)
            classe_menor = min(contagem_por_classe, key=contagem_por_classe.get)
            aviso = (
                f"Classes desbalanceadas: '{classe_maior}' tem {razao:.1f}x mais imagens que "
                f"'{classe_menor}'. Isso tende a enviesar o modelo para a classe majoritária. "
                "Opções: coletar mais imagens da classe minoritária, usar class_weight no "
                "treinamento, ou undersampling da classe majoritária."
            )
            relatorio["avisos"].append(aviso)
    elif 0 in valores:
        relatorio["problemas"].append("Há uma classe sem nenhuma imagem válida — o treinamento não pode começar assim.")

    # Diversidade de formato/dimensão (informativo)
    if len(formatos_todos) > 1:
        relatorio["avisos"].append(
            f"Mais de um formato de imagem no dataset: {dict(formatos_todos)}. "
            "Não é um problema em si (o script de treino padroniza tudo), mas vale "
            "confirmar que não há incompatibilidades entre as fontes das imagens."
        )

    total = sum(contagem_por_classe.values())
    print("=" * 60)
    print(f"TOTAL DE IMAGENS VÁLIDAS: {total}")
    print(f"Distribuição: {contagem_por_classe}")
    print()

    if relatorio["problemas"]:
        print("PROBLEMAS ENCONTRADOS (resolver antes de treinar):")
        for p in relatorio["problemas"]:
            print(f"  ✗ {p}")
        print()
    else:
        print("Nenhum problema crítico encontrado.\n")

    if relatorio["avisos"]:
        print("AVISOS (não impedem o treino, mas vale considerar):")
        for a in relatorio["avisos"]:
            print(f"  ! {a}")
        print()

    with open(BASE_DIR / "relatorio_dataset.json", "w", encoding="utf-8") as f:
        json.dump(relatorio, f, ensure_ascii=False, indent=2)
    print(f"Relatório completo salvo em: {BASE_DIR / 'relatorio_dataset.json'}")

    if total < 150:
        print(
            "\nOBS: com um total abaixo de ~150-200 imagens, é esperado que as métricas "
            "no TCC sejam apresentadas com a ressalva de dataset reduzido — mencione isso "
            "explicitamente na seção de limitações do trabalho."
        )


if __name__ == "__main__":
    validar_dataset()
