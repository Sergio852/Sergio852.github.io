---
title: "Introducción a Django"
subject: "Implantación de Aplicaciones Web"
description: "Puesta en marcha de la aplicación Guestbook en Django: fork y clonado, entorno virtual, migraciones con SQLite, servidor de desarrollo y panel de administración."
date: 2026-11-12
pdf: "implantacion-aplicaciones-web/introduccion-django.pdf"
tags:
  - django
  - python
  - entorno virtual
  - sqlite
---

# Práctica 1 - Introducción a Django

Nov 12, 2026 · @Sergio

## 1. Preparar el repositorio y el entorno virtual

### Fork del repositorio

Lo primero que he hecho es entrar en el repositorio de Guestbook (josedom24/guestbook\_django) en GitHub y pulsar **Fork**, para tener una copia del proyecto en mi cuenta (Sergio852) y poder trabajar sobre ella sin tocar el original.

![Creacion del fork en mi cuenta Sergio852](./imagenes/introduccion-django/Captura%20desde%202026-11-12%2012-22-11.png)

### Clonado en mi equipo

Despues he descargado mi copia en el equipo. Como tengo configurada mi clave SSH en GitHub, lo clono por SSH, asi no me pide usuario ni contraseña:

```
git clone git@github.com:Sergio852/guestbook_django.git
```

```
Clonando en 'guestbook_django'...
remote: Enumerating objects: 53, done.
remote: Counting objects: 100% (53/53), done.
remote: Compressing objects: 100% (38/38), done.
remote: Total 53 (delta 9), reused 49 (delta 8), pack-reused 0 (from 0)
Recibiendo objetos: 100% (53/53), 12.54 KiB | 4.18 MiB/s, listo.
Resolviendo deltas: 100% (9/9), listo.
```

Compruebo que se ha descargado bien mirando lo que hay dentro de la carpeta:

```
sergio@Sergio-PC:~$ ls guestbook_django
guestbook_project  README.md
```

Dentro esta la carpeta del proyecto Django (guestbook\_project) y el README.

Miro tambien dentro de guestbook\_project, que es donde estan los ficheros importantes de la aplicacion: el manage.py (con el que se maneja Django) y el requirements.txt (la lista de librerias que necesita):

```
sergio@Sergio-PC:~$ ls guestbook_django/guestbook_project
guestbook  guestbook_project  manage.py  README.md  requirements.txt  static  templates
```

### Entorno virtual

Cada proyecto Django deberia tener su propio entorno virtual, que es como una carpeta aislada donde se instalan las librerias de esa aplicacion sin mezclarse con las del sistema. Asi cada app puede usar sus propias versiones sin dar problemas.

Primero me aseguro de tener instalado venv, que es lo que crea los entornos (en mi caso ya estaba):

```
sergio@Sergio-PC:~$ sudo apt install python3-venv
python3-venv ya está en su versión más reciente (3.13.5-1).
```

Creo el entorno llamado guestbook (fuera del repositorio, para no subirlo a GitHub sin querer) y lo activo:

```
python3 -m venv guestbook
source guestbook/bin/activate
```

### Instalacion de dependencias

Con el entorno activo, entro en la carpeta del proyecto e instalo lo que pide el requirements.txt:

```
cd guestbook_django/guestbook_project
pip install -r requirements.txt
```

```
Collecting Django<6,>=4.2 (from -r requirements.txt (line 1))
  Downloading django-5.2.19-py3-none-any.whl.metadata (4.1 kB)
...
Installing collected packages: sqlparse, asgiref, Django
Successfully installed Django-5.2.19 asgiref-3.13.0 sqlparse-0.6.1
```

Se ha instalado Django 5.2 junto con las dos librerias que necesita. Lo compruebo con pip list, donde solo aparecen esos paquetes, señal de que se han instalado dentro del entorno y no en el sistema:

```
Package  Version
-------- -------
asgiref  3.13.0
Django   5.2.19
pip      25.1.1
sqlparse 0.6.1
```

## 2. Creacion de la base de datos

La aplicacion guarda los mensajes en una base de datos SQLite, que es una base de datos sencilla que va en un solo fichero. Antes de usarla hay que crear las tablas, y para eso Django tiene el comando migrate:

```
python3 manage.py migrate
```

```
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, guestbook, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  ...
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying guestbook.0001_initial... OK
  Applying sessions.0001_initial... OK
```

Todas salen con OK. Las de admin, auth y sessions son tablas que Django trae de serie (usuarios, permisos, sesiones...), y la de guestbook es la tabla propia de la aplicacion, donde se guardaran los mensajes.

Compruebo que se ha creado el fichero de la base de datos:

```
sergio@Sergio-PC:~/guestbook_django/guestbook_project (main)$ ls -l db.sqlite3
-rw-r--r-- 1 sergio sergio 135168 nov 12 12:26 db.sqlite3
```

El fichero db.sqlite3 ya existe, asi que la base de datos esta lista.

## 3. Servidor de desarrollo

Django trae su propio servidor web para hacer pruebas, asi que no hace falta instalar Apache ni Nginx para ver la aplicacion funcionando. Lo arranco con:

```
python3 manage.py runserver
```

```
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).
November 12, 2026 - 12:27:08
Django version 5.2.19, using settings 'guestbook_project.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.

WARNING: This is a development server. Do not use it in a production setting.
```

El servidor arranca sin errores y se queda escuchando en http://127.0.0.1:8000 (el puerto por defecto es el 8000). El propio Django avisa de que este servidor es solo para desarrollo y no se debe usar en produccion. Ademas tiene la ventaja de que si cambio algo del codigo se reinicia solo.

Entro desde el navegador a esa direccion, escribo un mensaje ("holaaa") y le doy a Submit. En la terminal se ve todo lo que va pidiendo el navegador:

```
[12/Nov/2026 12:27:17] "GET / HTTP/1.1" 200 994
[12/Nov/2026 12:27:17] "GET /static/style.css HTTP/1.1" 200 1042
Not Found: /favicon.ico
[12/Nov/2026 12:27:17] "GET /favicon.ico HTTP/1.1" 404 2536
[12/Nov/2026 12:27:27] "POST /add/ HTTP/1.1" 302 0
[12/Nov/2026 12:27:27] "GET / HTTP/1.1" 200 981
```

Primero carga la pagina y la hoja de estilos (codigo 200, todo bien). El 404 del favicon es solo porque la web no tiene icono, no es ningun problema. Cuando envio el mensaje se hace un POST a /add/, que lo guarda en la base de datos y me redirige otra vez a la pagina principal (el 302), donde ya aparece mi mensaje publicado.

![Guestbook funcionando con mi mensaje publicado](./imagenes/introduccion-django/Captura%20desde%202026-11-12%2012-27-41.png)

## 4. Panel de administracion

Una de las ventajas de Django es que trae un panel de administracion ya hecho, desde el que se pueden ver y modificar los datos de la base de datos por web, sin escribir SQL. Para entrar necesito un usuario con privilegios (superusuario).

### Creacion del superusuario

Como el servidor esta ocupando la otra terminal, abro una nueva, activo otra vez el entorno y creo el usuario:

```
source ~/guestbook/bin/activate
cd ~/guestbook_django/guestbook_project
python3 manage.py createsuperuser
```

```
Nombre de usuario (leave blank to use 'sergio'): 
Dirección de correo electrónico: sergiomesamejias@gmail.com
Password: 
Password (again): 
Superuser created successfully.
```

Dejo el nombre por defecto (sergio), pongo mi correo y la contraseña dos veces. El usuario se crea correctamente.

### Acceso a la zona de administracion

Entro en http://127.0.0.1:8000/admin/ e inicio sesion con el usuario sergio. Dentro del panel aparecen dos apartados: el de usuarios y grupos, que viene con Django, y el de GUESTBOOK, que es el de nuestra aplicacion, con la tabla Entrys donde se guardan los mensajes.

![Panel de administracion de Django con el usuario sergio](./imagenes/introduccion-django/Captura%20desde%202026-11-12%2012-29-22.png)

### Comprobacion del mensaje

Entro en GUESTBOOK > Entrys y ahi aparece el mensaje "holaaa" que escribi antes desde la pagina. Con esto compruebo que el mensaje se guardo de verdad en la base de datos, y que desde el panel podria editarlo, borrarlo o añadir otros nuevos.

![Tabla Entrys con el mensaje holaaa](./imagenes/introduccion-django/Captura%20desde%202026-11-12%2012-29-45.png)

## Conclusion

Con esta practica he puesto en marcha una aplicacion Django desde cero: he hecho un fork y la he clonado, he aislado sus librerias en un entorno virtual, he creado la base de datos con migrate, la he probado con el servidor de desarrollo y he comprobado los datos desde el panel de administracion que trae Django. Lo que mas me ha llamado la atencion es que con muy pocos comandos se tiene una web funcionando, con base de datos y panel de gestion incluidos.
