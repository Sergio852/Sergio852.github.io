---
title: "Práctica: Repositorio Git"
subject: "Implantación de Aplicaciones Web"
description: "Inicialización y uso de un repositorio Git para gestionar el historial y los cambios de un proyecto."
date: 2026-09-22
tags:
  - Git
  - GitHub
  - Control de versiones
  - Aplicaciones web
pdf: "implantacion-aplicaciones-web/repositorios-git.pdf"
---

# Práctica: Repositorio Git

**Alumno:** Sergio Mesa Mejías  
**Módulo:** Implantación de Aplicaciones Web  
**Curso:** 2.º ASIR

## 1. Inicialización del repositorio

Creamos la carpeta con el nombre indicado y entramos en ella:

```bash
mkdir sergio_mesa_mejias
git init sergio_mesa_mejias
cd sergio_mesa_mejias
```

`mkdir` crea la carpeta. `git init` crea dentro de ella la carpeta oculta `.git`, que contiene el historial y la configuración del repositorio. No debemos modificar `.git` manualmente.

Salida aproximada:

```text
Initialized empty Git repository in .../sergio_mesa_mejias/.git/
```

## 2. Creación de los primeros archivos

Creamos archivos mínimos mediante una redirección de texto:

```bash
printf '<!doctype html>\n<html>\n<head><title>Mi sitio web</title></head>\n<body><h1>Página principal</h1></body>\n</html>\n' > index.html
printf '/* Estilos iniciales */\nbody { font-family: sans-serif; }\n' > estilos.css
printf 'Anotaciones personales de trabajo\n' > notas.txt
```

La redirección `>` guarda la salida del comando en el archivo. Si el archivo ya existe, lo sobrescribe; por eso debemos usarla con cuidado.

## 3. Estado antes de añadir archivos

```bash
git status
```

Salida relevante:

```text
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        estilos.css
        index.html
        notas.txt

nothing added to commit but untracked files present
```

Los tres archivos aparecen como `untracked` porque Git los ve, pero todavía no los controla.

## 4. Primer commit

Añadimos solamente los archivos que deben formar parte del repositorio:

```bash
git add index.html estilos.css
git status
```

Salida relevante:

```text
Changes to be committed:
  new file:   estilos.css
  new file:   index.html

Untracked files:
  notas.txt
```

El área de preparación, o *staging*, es una zona intermedia donde seleccionamos exactamente qué cambios entrarán en el siguiente commit.

Realizamos el commit:

```bash
git commit -m "Estructura inicial del sitio web"
```

`-m` permite escribir el mensaje del commit directamente. El mensaje debe describir el cambio realizado.

## 5. Ignorar archivos con `.gitignore`

Es conveniente excluir archivos que no deben compartirse, como notas personales, contraseñas, claves, archivos temporales, configuraciones locales o carpetas generadas automáticamente. Así evitamos publicar información privada y no tenemos que acordarnos de excluir esos archivos en cada commit.

Creamos `.gitignore` con esta línea:

```bash
printf 'notas.txt\n' > .gitignore
git add .gitignore
git commit -m "Configurar archivos ignorados"
```

El contenido es:

```text
notas.txt
```

Desde este momento, Git ignorará `notas.txt`. Si ya se hubiera añadido anteriormente al repositorio, `.gitignore` no bastaría: habría que retirarlo del seguimiento con `git rm --cached notas.txt` y después confirmar el cambio. En esta práctica no es necesario porque nunca lo añadimos.

Comprobamos el resultado:

```bash
git status
```

La salida debería indicar que el árbol de trabajo está limpio. `notas.txt` sigue existiendo en el ordenador, pero ya no aparece como archivo pendiente.

## 6. Modificación y comparación

Editamos `index.html` y añadimos un pie de página:

```bash
cat > index.html <<'EOF'
<!doctype html>
<html>
<head><title>Mi sitio web</title></head>
<body>
<h1>Página principal</h1>
<footer>© 2026 Sergio Mesa Mejías</footer>
</body>
</html>
EOF
```

Para ver las líneas modificadas respecto al último commit usamos:

```bash
git diff
```

Salida aproximada:

```diff
 diff --git a/index.html b/index.html
 index ...
 --- a/index.html
 +++ b/index.html
 @@
 <body><h1>Página principal</h1></body>
+<footer>© 2026 Sergio Mesa Mejías</footer>
```

En un diff, las líneas que empiezan por `+` se han añadido y las que empiezan por `-` se han eliminado. `git diff` muestra cambios todavía no preparados. Para comparar lo que ya está en *staging* usaríamos `git diff --staged`.

## 7. Segundo commit

```bash
git add index.html
git commit -m "Añadido footer a la página principal"
```

Comprobamos el historial abreviado:

```bash
git log --oneline
```

Salida aproximada:

```text
<id> Añadido footer a la página principal
<id> Configurar archivos ignorados
<id> Estructura inicial del sitio web
```

Cada línea representa un commit. La cadena inicial es su identificador abreviado.

## 8. Renombrar un archivo

Usamos `git mv`, que cambia el nombre en el sistema de archivos y prepara el renombrado para Git:

```bash
git mv estilos.css styles.css
git status
```

Salida relevante:

```text
Changes to be committed:
  renamed:    estilos.css -> styles.css
```

Esto es preferible a borrar y crear archivos por separado porque expresa claramente la intención del cambio. Git puede detectar renombrados comparando contenidos, pero `git mv` deja la operación preparada de forma explícita.

Confirmamos:

```bash
git commit -m "Renombrar estilos.css a styles.css"
```

## 9. Eliminar `index.html`

Lo eliminamos del disco y del índice de Git con un solo comando:

```bash
git rm index.html
git status
git commit -m "Eliminar index.html"
```

`git rm` equivale a borrar el archivo y preparar su eliminación. La salida de `status` debe mostrar:

```text
deleted:    index.html
```

## 10. Deshacer el último commit

El último commit es el que elimina `index.html`. Antes de elegir una opción debemos comprobar si el commit se ha compartido en un repositorio remoto. No conviene reescribir un historial que otras personas ya estén usando.

### Opción recomendada si el commit ya se compartió: `git revert`

```bash
git revert HEAD
```

`HEAD` representa el commit actual. `git revert` crea un commit nuevo que invierte los cambios del anterior. En este caso recupera `index.html` sin borrar el historial existente. Git abrirá un editor para confirmar el mensaje; también podemos usar:

```bash
git revert --no-edit HEAD
```

Después comprobaremos:

```bash
git status
git log --oneline
```

### Opción para corregir el último commit local: `git reset`

Si nadie ha descargado todavía el commit y queremos quitarlo del historial:

```bash
git reset --soft HEAD~1
```

`HEAD~1` significa el commit anterior. Con `--soft`, el commit desaparece del historial, pero los cambios quedan preparados en *staging*. Podemos corregirlos y crear otro commit.

Otra variante es:

```bash
git reset --hard HEAD~1
```

`--hard` mueve el historial y también modifica los archivos y el área de preparación. Puede descartar cambios de forma irreversible, por lo que no debemos usarlo si no estamos seguros.

Para este caso concreto, como queremos recuperar `index.html`, `git revert HEAD` es la opción más segura cuando el commit ya se ha publicado. `git reset --soft HEAD~1` sirve para corregir un commit todavía local y conservar los cambios para volver a confirmarlos.

## Secuencia completa de comandos

```bash
mkdir sergio_mesa_mejias
git init sergio_mesa_mejias
cd sergio_mesa_mejias
printf '<!doctype html>\n<html>\n<head><title>Mi sitio web</title></head>\n<body><h1>Página principal</h1></body>\n</html>\n' > index.html
printf '/* Estilos iniciales */\nbody { font-family: sans-serif; }\n' > estilos.css
printf 'Anotaciones personales de trabajo\n' > notas.txt
git status
git add index.html estilos.css
git status
git commit -m "Estructura inicial del sitio web"
printf 'notas.txt\n' > .gitignore
git add .gitignore
git commit -m "Configurar archivos ignorados"
git status
cat > index.html <<'EOF'
<!doctype html>
<html>
<head><title>Mi sitio web</title></head>
<body>
<h1>Página principal</h1>
<footer>© 2026 Sergio Mesa Mejías</footer>
</body>
</html>
EOF
git diff
git add index.html
git commit -m "Añadido footer a la página principal"
git log --oneline
git mv estilos.css styles.css
git status
git commit -m "Renombrar estilos.css a styles.css"
git rm index.html
git status
git commit -m "Eliminar index.html"
git revert --no-edit HEAD
# Alternativa si el último commit aún no se ha compartido:
git reset --soft HEAD~1
```

> La última alternativa no debe ejecutarse después de `git revert`, porque ambas son formas alternativas de deshacer el mismo commit. Para la demostración final conviene elegir una de las dos.