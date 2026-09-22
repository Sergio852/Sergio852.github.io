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

mapfile -t MARKDOWNS < <(find "$PRACTICA_DIR" -maxdepth 1 -type f \( -iname '*.md' -o -iname '*.markdown' \) -print)
mapfile -t PDFS < <(find "$PRACTICA_DIR" -maxdepth 1 -type f -iname '*.pdf' -print)

if [[ ${#MARKDOWNS[@]} -ne 1 ]]; then
  echo "ERROR: debe existir exactamente un archivo Markdown en la carpeta." >&2
  exit 1
fi

if [[ ${#PDFS[@]} -ne 1 ]]; then
  echo "ERROR: debe existir exactamente un archivo PDF en la carpeta." >&2
  exit 1
fi

MD="${MARKDOWNS[0]}"
PDF="${PDFS[0]}"
SUBJECT_DIR="$(basename "$(dirname "$PRACTICA_DIR")")"
SLUG="$(basename "$PRACTICA_DIR")"

case "$SUBJECT_DIR" in
  administracion-sistemas-operativos) SUBJECT_SLUG="administracion-sistemas-operativos" ;;
  implantacion-aplicaciones-web) SUBJECT_SLUG="implantacion-aplicaciones-web" ;;
  seguridad-alta-disponibilidad) SUBJECT_SLUG="seguridad-alta-disponibilidad" ;;
  infraestructura-virtual) SUBJECT_SLUG="infraestructura-virtual" ;;
  servicios-red-internet) SUBJECT_SLUG="servicios-red-internet" ;;
  bases-datos) SUBJECT_SLUG="bases-datos" ;;
  ingles) SUBJECT_SLUG="ingles" ;;
  *)
    echo "ERROR: asignatura no reconocida: $SUBJECT_DIR" >&2
    exit 1
    ;;
esac

DEST_MD="$PROJECT_DIR/src/content/practicas/$SUBJECT_SLUG/$SLUG.md"
DEST_IMAGES="$PROJECT_DIR/src/content/practicas/$SUBJECT_SLUG/imagenes/$SLUG"
DEST_PDF="$PROJECT_DIR/public/pdfs/$SUBJECT_SLUG/$SLUG.pdf"

mkdir -p "$(dirname "$DEST_MD")" "$DEST_IMAGES" "$(dirname "$DEST_PDF")"

if grep -Eq '(^|["\x27(])(/home/|file://)' "$MD"; then
  echo "ERROR: el Markdown contiene rutas absolutas o file://: $MD" >&2
  exit 1
fi

if ! grep -Eq '^---[[:space:]]*$' "$MD"; then
  echo "ERROR: el Markdown no tiene frontmatter YAML." >&2
  exit 1
fi

python3 - "$MD" "$PRACTICA_DIR" <<'PY'
from pathlib import Path
import re
import sys

md = Path(sys.argv[1])
base = Path(sys.argv[2])
text = md.read_text(encoding="utf-8")
refs = set(re.findall(r'!\[[^\]]*\]\(([^)]+)\)', text))
refs.update(re.findall(r'<img[^>]+src=["\x27]([^"\x27]+)', text))
missing = []
for ref in refs:
    ref = ref.split('#', 1)[0].strip()
    if not ref or ref.startswith(('http://', 'https://', 'data:')):
        continue
    if not (base / ref).resolve().exists():
        missing.append(ref)
if missing:
    print("ERROR: faltan recursos:", file=sys.stderr)
    for item in sorted(missing):
        print(f"  {item}", file=sys.stderr)
    raise SystemExit(1)
PY

cp "$MD" "$DEST_MD"
cp "$PDF" "$DEST_PDF"

if [[ -d "$PRACTICA_DIR/imagenes" ]]; then
  find "$PRACTICA_DIR/imagenes" -maxdepth 1 -type f -exec cp {} "$DEST_IMAGES/" \;
fi

if [[ -d "$PRACTICA_DIR/imagenes" ]]; then
  python3 - "$DEST_MD" "$SLUG" <<'PY'
from pathlib import Path
import re
import sys

md = Path(sys.argv[1])
slug = sys.argv[2]
text = md.read_text(encoding="utf-8")
text = text.replace("./imagenes/", f"./imagenes/{slug}/")
md.write_text(text, encoding="utf-8")
PY
fi

cd "$PROJECT_DIR"
npm run build

echo
echo "OK: práctica preparada correctamente."
echo "Markdown: $DEST_MD"
echo "PDF:      $DEST_PDF"
echo "Imágenes: $DEST_IMAGES"
echo
echo "No se ha ejecutado git commit ni git push."
