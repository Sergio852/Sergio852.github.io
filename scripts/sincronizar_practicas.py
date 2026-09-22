from pathlib import Path
import re
import shutil

DOCUMENTOS = Path.home() / "Documentos"
PROYECTO = Path.home() / "proyectos" / "blog-practicas"

ASIGNATURAS = {
    "Sistemas": {
        "slug": "administracion-sistemas-operativos",
        "nombre": "Administración de Sistemas Operativos"
    },
    "Base-Datos": {
        "slug": "bases-datos",
        "nombre": "Bases de Datos"
    },
    "Seguridad": {
        "slug": "seguridad-alta-disponibilidad",
        "nombre": "Seguridad y Alta Disponibilidad"
    },
    "Ingles": {
        "slug": "ingles",
        "nombre": "Inglés"
    },
    "AppWeb": {
        "slug": "implantacion-aplicaciones-web",
        "nombre": "Implantación de Aplicaciones Web"
    },
    "InfraVirtual": {
        "slug": "infraestructura-virtual",
        "nombre": "Infraestructura Virtual"
    },
    "Servicios": {
        "slug": "servicios-red-internet",
        "nombre": "Servicios de Red e Internet"
    }
}


def convertir_slug(nombre):
    nombre = nombre.lower()
    nombre = nombre.replace("á", "a")
    nombre = nombre.replace("é", "e")
    nombre = nombre.replace("í", "i")
    nombre = nombre.replace("ó", "o")
    nombre = nombre.replace("ú", "u")
    nombre = nombre.replace("ñ", "n")
    nombre = re.sub(r"[^a-z0-9]+", "-", nombre)
    return nombre.strip("-")


def limpiar_titulo(nombre):
    nombre = Path(nombre).stem
    nombre = re.sub(r"[-_]+", " ", nombre)
    nombre = re.sub(r"\s+", " ", nombre)
    return nombre.strip().title()


def crear_markdown(pdf, asignatura):
    nombre_pdf = pdf.stem
    slug = convertir_slug(nombre_pdf)

    carpeta_md = (
        PROYECTO
        / "src"
        / "content"
        / "practicas"
        / asignatura["slug"]
    )

    carpeta_pdf = (
        PROYECTO
        / "public"
        / "pdfs"
        / asignatura["slug"]
    )

    carpeta_md.mkdir(parents=True, exist_ok=True)
    carpeta_pdf.mkdir(parents=True, exist_ok=True)

    destino_pdf = carpeta_pdf / f"{slug}.pdf"
    archivo_md = carpeta_md / f"{slug}.md"

    if archivo_md.exists():
        print(f"Ya existe, se ignora: {archivo_md}")
        return

    shutil.copy2(pdf, destino_pdf)

    contenido = f"""---
title: "{limpiar_titulo(pdf.name)}"
subject: "{asignatura['nombre']}"
description: "Práctica de {limpiar_titulo(pdf.name)}."
date: 2026-09-22
tags:
  - {asignatura['nombre']}
pdf: "{asignatura['slug']}/{slug}.pdf"
---

## De qué trata

Esta práctica pertenece a la asignatura de {asignatura['nombre']}.

El documento completo puede consultarse o descargarse en formato PDF.

## Documento completo

La práctica completa está disponible en el siguiente documento:

- PDF con el desarrollo completo y las capturas de pantalla.
"""

    archivo_md.write_text(contenido, encoding="utf-8")

    print(f"Publicada localmente: {pdf}")
    print(f"  Markdown: {archivo_md}")
    print(f"  PDF: {destino_pdf}")


def main():
    for carpeta, asignatura in ASIGNATURAS.items():
        origen = DOCUMENTOS / carpeta

        if not origen.exists():
            print(f"No existe la carpeta: {origen}")
            continue

        pdfs = origen.glob("*.pdf")

        for pdf in pdfs:
            crear_markdown(pdf, asignatura)


if __name__ == "__main__":
    main()
