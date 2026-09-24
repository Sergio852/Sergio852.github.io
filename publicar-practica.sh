#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 RUTA_DE_LA_PRACTICA" >&2
  exit 2
fi

PRACTICA_DIR="$(realpath "$1")"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$PRACTICA_DIR" ]]; then
  echo "ERROR: no existe la carpeta: $PRACTICA_DIR" >&2
  exit 1
fi

mapfile -t MARKDOWNS < <(
  find "$PRACTICA_DIR" -maxdepth 1 -type f -iname "*.md" -print
)

mapfile -t PDFS < <(
  find "$PRACTICA_DIR" -maxdepth 1 -type f -iname "*.pdf" -print
)

if [[ ${#MARKDOWNS[@]} -ne 1 ]]; then
  echo "ERROR: debe existir exactamente un archivo Markdown." >&2
  exit 1
fi

if [[ ${#PDFS[@]} -ne 1 ]]; then
  echo "ERROR: debe existir exactamente un archivo PDF." >&2
  exit 1
fi

MD="${MARKDOWNS[0]}"
PDF="${PDFS[0]}"
SUBJECT_DIR="$(basename "$(dirname "$PRACTICA_DIR")")"
SLUG="$(basename "$PRACTICA_DIR")"

case "$SUBJECT_DIR" in
  administracion-sistemas-operativos)
    SUBJECT_SLUG="administracion-sistemas-operativos"
    ;;
  implantacion-aplicaciones-web|AppWeb|appweb)
    SUBJECT_SLUG="implantacion-aplicaciones-web"
    ;;
  seguridad-alta-disponibilidad)
    SUBJECT_SLUG="seguridad-alta-disponibilidad"
    ;;
  infraestructura-virtual)
    SUBJECT_SLUG="infraestructura-virtual"
    ;;
  servicios-red-internet|Servicios|servicios)
    SUBJECT_SLUG="servicios-red-internet"
    ;;
  bases-datos)
    SUBJECT_SLUG="bases-datos"
    ;;
  ingles)
    SUBJECT_SLUG="ingles"
    ;;
  Ansible|ansible|ProyectoIntermodular|proyecto-intermodular)
    SUBJECT_SLUG="proyecto-intermodular"
    ;;
  *)
    echo "ERROR: asignatura no reconocida: $SUBJECT_DIR" >&2
    exit 1
    ;;
esac

DEST_MD="$PROJECT_DIR/src/content/practicas/$SUBJECT_SLUG/$SLUG.md"
DEST_IMAGES="$PROJECT_DIR/src/content/practicas/$SUBJECT_SLUG/imagenes/$SLUG"
DEST_PDF="$PROJECT_DIR/public/pdfs/$SUBJECT_SLUG/$SLUG.pdf"

mkdir -p "$(dirname "$DEST_MD")"
mkdir -p "$DEST_IMAGES"
mkdir -p "$(dirname "$DEST_PDF")"

python3 - "$MD" "$PRACTICA_DIR" "$DEST_MD" "$SLUG" <<'PY'
from pathlib import Path
import re
import shutil
import sys

source_md = Path(sys.argv[1])
source_dir = Path(sys.argv[2])
destination_md = Path(sys.argv[3])
slug = sys.argv[4]

text = source_md.read_text(encoding="utf-8")

text = text.replace(
    "file:///home/sergio/.config/marktext/images/",
    "./imagenes/"
)

text = text.replace(
    "/home/sergio/.config/marktext/images/",
    "./imagenes/"
)

references = set()
references.update(re.findall(r'!\[[^\]]*\]\(([^)]+)\)', text))
references.update(re.findall(r'<img[^>]+src="([^"]+)', text))
references.update(re.findall(r"<img[^>]+src='([^']+)", text))

missing = []

for reference in references:
    reference = reference.strip()

    if not reference:
        continue

    if reference.startswith(("http://", "https://", "data:")):
        continue

    if reference.startswith("./imagenes/"):
        filename = reference.removeprefix("./imagenes/")
        image_path = source_dir / "imagenes" / filename
    else:
        image_path = source_dir / reference

    if not image_path.exists():
        missing.append(reference)

if missing:
    print("ERROR: faltan estos recursos:", file=sys.stderr)
    for item in sorted(missing):
        print(f"  {item}", file=sys.stderr)
    raise SystemExit(1)

destination_md.parent.mkdir(parents=True, exist_ok=True)
destination_md.write_text(text, encoding="utf-8")
PY

cp "$PDF" "$DEST_PDF"

if [[ -d "$PRACTICA_DIR/imagenes" ]]; then
  find "$PRACTICA_DIR/imagenes" -maxdepth 1 -type f \
    -exec cp {} "$DEST_IMAGES/" \;
fi

python3 - "$DEST_MD" "$SLUG" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
slug = sys.argv[2]

text = path.read_text(encoding="utf-8")
text = text.replace("./imagenes/", f"./imagenes/{slug}/")

path.write_text(text, encoding="utf-8")
PY

cd "$PROJECT_DIR"
npm run build

echo
echo "OK: práctica preparada correctamente."
echo "Markdown: $DEST_MD"
echo "PDF:      $DEST_PDF"
echo "Imágenes: $DEST_IMAGES"
echo
echo "No se ha ejecutado git commit ni git push."
