---
title: "Compilación con Make"
subject: "Administración de Sistemas Operativos"
description: "Uso de GNU Make para automatizar la compilación y gestionar las dependencias de un proyecto."
date: 2026-09-25
tags:
  - GNU Make
  - Compilación
  - Linux
  - Automatización
pdf: "administracion-sistemas-operativos/compilacion-con-make.pdf"
---

# Compilación e instalación de GNU gperf

## Programa elegido

He elegido GNU gperf, un programa escrito en C que sirve para generar funciones hash perfectas.

Antes de empezar comprobé que no estaba instalado en Debian.

```bash
cd ~/compilacion
which gperf
dpkg -s gperf
```

## Descarga de las fuentes

Instalé las herramientas necesarias para compilar y descargué el código fuente desde el servidor oficial de GNU:

```bash
sudo apt update
sudo apt install build-essential wget ca-certificates

wget https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz
tar -xzf gperf-3.3.tar.gz
cd gperf-3.3
```

## Comprobación de los ficheros

Comprobé que las fuentes incluían los ficheros necesarios para preparar la compilación:

```bash
ls -l configure
ls -l Makefile.in
ls -l INSTALL
test -x configure && echo "configure existe y es ejecutable"
```

- `configure`: comprueba el sistema y prepara la compilación.
- `Makefile.in`: plantilla usada para generar el `Makefile`.
- `INSTALL`: contiene instrucciones del proyecto.

## Configuración

Configuré la instalación en `/opt/gperf` para no interferir con los paquetes de Debian:

```bash
./configure --prefix=/opt/gperf
ls -l Makefile
```

El script `configure` generó el fichero `Makefile`, que contiene las reglas para compilar, probar, instalar y desinstalar el programa.

## Compilación

```bash
make
```

Comprobé que el programa compilado funcionaba:

```bash
./src/gperf --version
```

La salida mostró la versión GNU gperf 3.3.

## Pruebas

```bash
make check
```

Las pruebas terminaron correctamente. Se probaron diferentes casos de gperf y no aparecieron errores.

## Instalación

Instalé el programa en `/opt/gperf`:

```bash
sudo make install
```

Comprobé el contenido instalado:

```bash
ls -l /opt/gperf
ls -l /opt/gperf/bin
ls -l /opt/gperf/share/info
ls -l /opt/gperf/share/man/man1
ls -l /opt/gperf/share/doc
```

Los ficheros principales instalados fueron:

```text
/opt/gperf/bin/gperf
/opt/gperf/share/info/gperf.info
/opt/gperf/share/man/man1/gperf.1
/opt/gperf/share/doc/gperf.html
```

- `/opt/gperf/bin/gperf`: ejecutable principal.
- `gperf.info`: documentación para GNU Info.
- `gperf.1`: página de manual.
- `gperf.html`: documentación en formato HTML.

Comprobé el ejecutable instalado:

```bash
/opt/gperf/bin/gperf --version
```

También añadí temporalmente la ruta al `PATH`:

```bash
export PATH="/opt/gperf/bin:$PATH"
which gperf
gperf --version
```

## Desinstalación

La desinstalación se realizó desde el mismo directorio de las fuentes:

```bash
cd ~/compilacion/gperf-3.3
sudo make uninstall
```

Después comprobé que `/opt/gperf` ya no existía:

```bash
ls -l /opt/gperf
```

El comando indicó que el directorio no existía, por lo que los ficheros instalados se habían eliminado correctamente.

## Limpieza final

Después de desinstalar el programa ejecuté `make distclean` para eliminar los ficheros generados durante la configuración y la compilación:

```bash
make distclean
```

Este comando elimina ficheros como `Makefile`, `config.log`, `config.status`, `config.h` y los ficheros compilados.

Finalmente eliminé las fuentes y el archivo descargado:

```bash
cd ~/compilacion
rm -rf gperf-3.3
rm -f gperf-3.3.tar.gz
```

## Resultado

GNU gperf fue comprobado, compilado desde sus fuentes, probado, instalado en `/opt/gperf` sin interferir con Debian y desinstalado correctamente. También se limpiaron los ficheros generados y las fuentes descargadas.