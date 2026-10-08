---
title: "Instalación de un servidor LAMP"
subject: "Implantación de Aplicaciones Web"
description: "Instalación y configuración de una pila LAMP formada por Linux, Apache, MariaDB y PHP en Debian."
date: 2026-10-08
pdf: "implantacion-aplicaciones-web/instalacion-servidor-lamp.pdf"
---

# Práctica: instalación de un servidor LAMP

En esta práctica he instalado y configurado una pila **LAMP** en un servidor Debian. LAMP está formada por Linux, Apache, MariaDB/MySQL y PHP. También he comprobado el funcionamiento del servidor web, he creado una base de datos, he configurado el acceso mediante el nombre `sergiomesamejias.com` y he revisado los logs de Apache.



## 1. Preparación del sistema

Primero actualicé los repositorios y paquetes de mi servidor Debian:



`sudo apt update sudo apt upgrade -y`



![](/home/sergio/.config/marktext/images/2026-10-08-13-04-02-image.png)

Consulté la dirección IP de mi servidor, ya que la necesitaría más adelante para configurar el acceso desde el equipo cliente:

`hostname -I`

![](/home/sergio/.config/marktext/images/2026-10-08-13-04-59-image.png)

## 2. Instalación de MariaDB

MariaDB será el gestor de bases de datos utilizado en mi pila LAMP.

Instalé el servidor MariaDB con el siguiente comando:

`sudo apt install mariadb-server -y`

![](/home/sergio/.config/marktext/images/2026-10-08-13-05-34-image.png)

Una vez instalado, comprobé que el servicio estaba funcionando correctamente:

`sudo systemctl status mariadb`

![](/home/sergio/.config/marktext/images/2026-10-08-13-06-10-image.png)

También activé el servicio para que MariaDB se inicie automáticamente cada vez que arranque el servidor:

`sudo systemctl enable --now mariadb`

![](/home/sergio/.config/marktext/images/2026-10-08-13-07-14-image.png)

## Configuración segura de MariaDB

A continuación ejecuté el script de seguridad de MariaDB:

`sudo mariadb-secure-installation`

Durante la configuración realicé las siguientes acciones:

- Establecí o configuré la contraseña del usuario administrador de MariaDB.

- Eliminé los usuarios anónimos.

- Impedí el acceso remoto del usuario `root`.

- Eliminé la base de datos de prueba.

- Recargué los privilegios de MariaDB.

Estas opciones permiten dejar la instalación de MariaDB más segura.

## Creación de base de datos y usuario

Después accedí a MariaDB como administrador:

`sudo mariadb`

Dentro de la consola de MariaDB creé una base de datos llamada `lampdb`:

`CREATE DATABASE lampdb;`

![](/home/sergio/.config/marktext/images/2026-10-08-13-10-18-image.png)

Creé un usuario llamado `lampuser`, con acceso desde el propio servidor:

`CREATE USER 'lampuser'@'localhost' IDENTIFIED BY 'ContraseñaSegura123!';`

![](/home/sergio/.config/marktext/images/2026-10-08-13-10-48-image.png)

Asigné todos los permisos sobre la base de datos `lampdb` a dicho usuario:

`GRANT ALL PRIVILEGES ON lampdb.* TO 'lampuser'@'localhost';`

![](/home/sergio/.config/marktext/images/2026-10-08-13-11-06-image.png)

Actualicé los privilegios:

`FLUSH PRIVILEGES;`

![](/home/sergio/.config/marktext/images/2026-10-08-13-11-21-image.png)

Y para salir usamos:

`EXIT;`

![](/home/sergio/.config/marktext/images/2026-10-08-13-12-34-image.png)

---

## 3. Instalación de Apache

A continuación instalé Apache, que será el servidor web encargado de servir las páginas de mi servidor LAMP.

Ejecuté:

`sudo apt install apache2 -y`

![](/home/sergio/.config/marktext/images/2026-10-08-13-13-01-image.png)

Después comprobé el estado del servicio:

`sudo systemctl status apache2`

![](/home/sergio/.config/marktext/images/2026-10-08-13-13-26-image.png)

También configuré Apache para que se inicie automáticamente cuando arranque el sistema:

`sudo systemctl enable apache2`

![](/home/sergio/.config/marktext/images/2026-10-08-13-14-10-image.png)

Reinicié Apache:

`sudo systemctl restart apache2`

Por último, comprobé desde el propio servidor que Apache respondía correctamente:

`curl -I http://localhost`

![](/home/sergio/.config/marktext/images/2026-10-08-13-15-09-image.png)

---

## 4. Instalación de PHP

Una vez instalado Apache, instalé PHP y los módulos necesarios para que Apache pueda interpretar código PHP y PHP pueda conectarse con MariaDB.

Ejecuté el siguiente comando:

`sudo apt install apache2 libapache2-mod-php php php-mysql -y`

![](/home/sergio/.config/marktext/images/2026-10-08-13-15-36-image.png)

También instalé algunos módulos adicionales de PHP que pueden ser necesarios en aplicaciones web:

`sudo apt install php-cli php-curl php-mbstring php-xml php-zip -y`

![](/home/sergio/.config/marktext/images/2026-10-08-13-16-45-image.png)

Después comprobé la versión instalada de PHP:

`php -v`

![](/home/sergio/.config/marktext/images/2026-10-08-13-17-22-image.png)

También revisé los módulos cargados:

`php -m`

![](/home/sergio/.config/marktext/images/2026-10-08-13-17-40-image.png)

Para verificar específicamente que PHP podía trabajar con MariaDB/MySQL, ejecuté:

`php -m | grep -i mysql`

![](/home/sergio/.config/marktext/images/2026-10-08-13-18-01-image.png)

Finalmente reinicié Apache para que cargara correctamente el módulo de PHP:

bash

`sudo systemctl restart apache2`

---

## 5. Comprobación de PHP

Para comprobar que Apache podía ejecutar código PHP, creé el archivo `info.php` dentro del directorio principal del servidor web, que por defecto es `/var/www/html`.

Creé el fichero:

`sudo nano /var/www/html/info.php`

Dentro escribí el siguiente código:

`<?php phpinfo(); ?>`

![](/home/sergio/.config/marktext/images/2026-10-08-13-22-51-image.png)

Guardé el archivo y le asigné como propietario el usuario y grupo utilizados por Apache:

`sudo chown www-data:www-data /var/www/html/info.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-23-13-image.png)

Después abrí la página desde el navegador utilizando la IP del servidor:

`http://192.168.122.198/info.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-24-24-image.png)

La página mostró la información de PHP, incluyendo la versión instalada, el servidor Apache, los módulos cargados y los datos de configuración.

## 6. Creación de la página principal

Para mostrar una página propia desde mi servidor, creé un archivo llamado `index.php`:

`sudo nano /var/www/html/index.php`

Introduje el siguiente contenido:

![](/home/sergio/.config/marktext/images/2026-10-08-13-26-55-image.png)

Guardé el archivo y le asigné los permisos correctos:

`sudo chown www-data:www-data /var/www/html/index.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-27-29-image.png)

Por último, comprobé el resultado desde el propio servidor:

`curl http://localhost/index.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-27-57-image.png)

---

## 7. Configuración del dominio local

Para acceder a mi web mediante el nombre `sergiomesamejias.com`, configuré una resolución estática utilizando el archivo `/etc/hosts`.

En mi caso, la IP utilizada es:

`192.168.122.198`

Después, desde el equipo cliente —el ordenador desde el que iba a abrir la página web— edité el fichero `/etc/hosts`:

`sudo nano /etc/hosts`

Añadí la siguiente línea:

`192.168.121.10 sergiomesamejias.com www.sergiomesamejias.com`

El contenido relevante del fichero quedó así:

`127.0.0.1       localhost 192.168.121.10  sergiomesamejias.com www.sergiomesamejias.com`

![](/home/sergio/.config/marktext/images/2026-10-08-13-30-14-image.png)

De esta forma, mi ordenador asocia el nombre `sergiomesamejias.com` con la dirección IP privada del servidor, sin necesidad de tener un servidor DNS propio.

Comprobé que el nombre resolvía correctamente:

`ping -c 4 sergiomesamejias.com`

![](/home/sergio/.config/marktext/images/2026-10-08-13-30-46-image.png)

Finalmente accedí desde el navegador a:

`http://sergiomesamejias.com/`

![](/home/sergio/.config/marktext/images/2026-10-08-13-31-52-image.png)

También pude acceder a la página de PHP mediante:

`http://sergiomesamejias.com/info.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-32-17-image.png)

La resolución estática mediante `/etc/hosts` permite asociar manualmente una IP con un nombre de dominio cuando no se utiliza un servidor DNS.[Parte-1-Introduccion-a-PHP.pdf](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/158403573/f5ea9820-a394-4b20-ba46-1e007343e558/Parte-1-Introduccion-a-PHP.pdf)

## 8. Prueba de conexión entre PHP y MariaDB

Para comprobar que PHP podía conectarse correctamente a MariaDB, creé un archivo llamado `bd.php`:

`sudo nano /var/www/html/bd.php`

Introduje el siguiente código, utilizando el usuario y la base de datos creados anteriormente:

![](/home/sergio/.config/marktext/images/2026-10-08-13-41-50-image.png)

Después establecí el propietario adecuado para Apache:

`sudo chown www-data:www-data /var/www/html/bd.php`

Abrí la página desde el navegador:

`http://sergiomesamejias.com/bd.php`

![](/home/sergio/.config/marktext/images/2026-10-08-13-42-09-image.png)

## 9. Consulta de logs de Apache

Por último, revisé los logs de Apache para comprobar los accesos, los posibles errores y los mensajes del servicio.

Los archivos principales de Apache en Debian son:

text

`/var/log/apache2/access.log /var/log/apache2/error.log`

## Log de accesos

Mostré las últimas 20 líneas del log de accesos:

bash

`sudo tail -n 20 /var/log/apache2/access.log`

También lo visualicé en tiempo real:

bash

`sudo tail -f /var/log/apache2/access.log`

Mientras el comando estaba activo, abrí la página `http://sergiomesamejias.com/` desde el navegador. De esta forma aparecieron nuevas peticiones registradas en el log.

Una línea típica fue similar a esta:

text

`192.168.121.20 - - [08/Oct/2026:13:20:10 +0200] "GET / HTTP/1.1" 200 2456`

En ella se puede ver la IP del cliente, la fecha y hora, el recurso solicitado y el código HTTP de respuesta.

Para salir de la visualización en tiempo real pulsé:

text

`Ctrl + C`

## Log de errores

Después consulté el archivo de errores:

bash

`sudo tail -n 20 /var/log/apache2/error.log`

También podía verlo en tiempo real con:

bash

`sudo tail -f /var/log/apache2/error.log`

Si no aparecían errores recientes, significaba que Apache estaba funcionando correctamente.

## Logs del servicio Apache

Finalmente consulté los mensajes del servicio Apache mediante `journalctl`:

bash

`sudo journalctl -u apache2`

Para mostrar solamente las últimas líneas utilicé:

bash

`sudo journalctl -u apache2 -n 30 --no-pager`

También consulté los mensajes de Apache desde el último arranque:

bash

`sudo journalctl -u apache2 -b --no-pager`

Los logs de Apache y los mensajes de `journalctl -u apache2` son los métodos indicados en el material de clase para localizar accesos, errores y problemas en el servicio web.[Parte-1-Introduccion-a-PHP.pdf](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/158403573/f5ea9820-a394-4b20-ba46-1e007343e558/Parte-1-Introduccion-a-PHP.pdf)

---

## 10. Comprobación final

Para terminar la práctica, comprobé que todos los servicios y componentes de la pila LAMP estaban funcionando correctamente.

Comprobé el estado de Apache:

bash

`sudo systemctl status apache2`

Comprobé el estado de MariaDB:

bash

`sudo systemctl status mariadb`

Comprobé la versión de PHP:

bash

`php -v`

Comprobé la configuración de Apache:

bash

`sudo apache2ctl configtest`

La respuesta fue:

text

`Syntax OK`

Comprobé la página desde el nombre configurado:

bash

`curl -I http://sergiomesamejias.com/`

La respuesta correcta fue similar a esta:

text

`HTTP/1.1 200 OK`

Por último, revisé los puertos de Apache y MariaDB:

bash

`sudo ss -tulpn | grep -E ':80|:3306'`

Con este comando comprobé que Apache estaba utilizando el puerto 80 y que MariaDB estaba disponible en el puerto 3306, normalmente limitado al propio servidor.

---

## Conclusión

En esta práctica he instalado y configurado correctamente una pila LAMP en Debian. He instalado MariaDB como servidor de bases de datos, Apache como servidor web y PHP junto con los módulos necesarios para conectarlo con MariaDB.

Además, he creado una base de datos llamada `lampdb` y un usuario llamado `lampuser`, he comprobado que Apache interpreta correctamente código PHP mediante `info.php` y he realizado una prueba de conexión entre PHP y MariaDB.

Por último, he configurado el nombre `sergiomesamejias.com` mediante el archivo `/etc/hosts`, por lo que he podido acceder al servidor web desde el equipo cliente usando un nombre en lugar de la dirección IP. También he consultado los logs de acceso, errores y del servicio Apache para comprobar y diagnosticar el funcionamiento del servidor.
