---
title: "Instalación de MariaDB en Debian 13"
author: "Sergio Mesa"
subject: "Bases de Datos"
description: "Guía de instalación, configuración y comprobación de MariaDB en Debian 13."
date: 2026-10-07
tags:
  - MariaDB
  - Debian 13
  - Bases de Datos
pdf: "bases-datos/instalacion-mariadb-debian13.pdf"
---
# Instalación y configuración de MariaDB 11 en Debian 13

## 1. Objetivo

En esta práctica se instala MariaDB en Debian 13 y se configura para aceptar conexiones TCP/IP desde la red local. Se crea una base de datos y un usuario de trabajo con permisos limitados a esa base de datos.

La conexión final se realiza contra la IP local del servidor:

```text
IP del servidor MariaDB: 192.168.0.251
Puerto MariaDB:          3306
Base de datos:           sergio_db
Usuario de trabajo:      sergio
```

---

## 2. Entorno utilizado

| Elemento | Valor |
|---|---|
| Alumno | Sergio Mesa |
| Fecha | 7 de octubre de 2026 |
| Equipo servidor | Sergio-PC |
| Sistema operativo | Debian 13 |
| Servidor de base de datos | MariaDB 11.8.6 |
| Puerto | `3306` |
| Interfaz de red local | `wlp1s0` |
| IP local del servidor | `192.168.0.251/24` |
| Red permitida para el usuario | `192.168.0.0/24` |
| Base de datos de pruebas | `sergio_db` |
| Usuario de pruebas | `sergio@192.168.0.%` |

---

## 3. Esquema de funcionamiento

```text
┌────────────────────────────────────────┐
│ Red local: 192.168.0.0/24              │
│                                        │
│ Clientes autorizados                    │
└────────────────────┬───────────────────┘
                     │ TCP/IP · puerto 3306
                     ▼
┌────────────────────────────────────────┐
│ Sergio-PC                               │
│ IP: 192.168.0.251                      │
│ Interfaz: wlp1s0                       │
│                                        │
│ MariaDB 11.8.6                          │
│ Base de datos: sergio_db                │
└────────────────────────────────────────┘
```

---

## 4. Instalación de MariaDB

Se actualiza la información de paquetes de Debian y se instalan el servidor y el cliente de MariaDB:

```bash
sudo apt update
sudo apt install -y mariadb-server mariadb-client
```

- `mariadb-server` instala el servicio de base de datos.
- `mariadb-client` instala el cliente de terminal `mariadb`.

Una vez instalada, se puede acceder localmente como administrador mediante:

```bash
sudo mariadb
```

MariaDB utiliza en Debian la autenticación local del sistema para la cuenta administrativa. Por este motivo, la cuenta `root` de MariaDB se utiliza localmente mediante `sudo mariadb` y no se habilita para conexiones remotas.

---

## 5. Comprobación inicial

Se accede a la consola de MariaDB:

```bash
sudo mariadb
```

Se comprueba la versión instalada:

```sql
SELECT VERSION();
```

Resultado obtenido:

```text
11.8.6-MariaDB-0+deb13u1 from Debian
```

Se comprueba el usuario conectado, el servidor y el puerto:

```sql
SELECT
  USER() AS usuario_conexion,
  CURRENT_USER() AS usuario_autenticado,
  @@hostname AS servidor,
  @@port AS puerto;
```

Resultado obtenido:

```text
usuario_conexion:    root@localhost
usuario_autenticado: root@localhost
servidor:            Sergio-PC
puerto:              3306
```

Se muestran las bases de datos iniciales:

```sql
SHOW DATABASES;
```

Resultado obtenido:

```text
information_schema
mysql
performance_schema
sys
```

Se puede salir de la consola mediante:

```sql
EXIT;
```

---

## 6. Asegurar la instalación

Se ejecuta el asistente de seguridad de MariaDB:

```bash
sudo mariadb-secure-installation
```

En Debian 13 aparece un aviso indicando que MariaDB ya es segura por defecto. Aun así, el asistente permite comprobar y aplicar los ajustes básicos de seguridad.

Las opciones seleccionadas fueron:

| Pregunta | Respuesta |
|---|---|
| Cambiar a autenticación `unix_socket` | Sí |
| Cambiar la contraseña de root | No |
| Eliminar usuarios anónimos | Sí |
| Bloquear inicio remoto de root | Sí |
| Eliminar la base de pruebas | Sí |
| Recargar las tablas de privilegios | Sí |

Con esta configuración, la cuenta `root` se mantiene para administración local y no se permite su acceso remoto.

---

## 7. Configuración de red de MariaDB

### 7.1. Localización de los ficheros de configuración

Se consulta el orden de lectura de los ficheros de configuración de MariaDB:

```bash
sudo mariadbd --help --verbose 2>/dev/null | \
  grep -A 1 -i 'Default options are read from'
```

Resultado obtenido:

```text
/etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf
```

En Debian, la configuración del servidor utilizada para esta práctica se encuentra en:

```text
/etc/mysql/mariadb.conf.d/50-server.cnf
```

Antes de modificarla se crea una copia de seguridad:

```bash
sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf \
  /etc/mysql/mariadb.conf.d/50-server.cnf.bak
```

### 7.2. Dirección de escucha

Inicialmente MariaDB estaba configurado para escuchar solamente en la dirección local:

```conf
bind-address            = 127.0.0.1
```

Se abre el fichero de configuración del servidor:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Dentro de ese fichero se sustituye la línea anterior por esta:

```conf
bind-address            = 192.168.0.251
```

Esta configuración hace que MariaDB escuche solamente en la interfaz Wi-Fi de la red local. No se utiliza `0.0.0.0`, por lo que el servicio no queda expuesto en las interfaces virtuales de libvirt ni en la interfaz de Tailscale.

Después de guardar el fichero se reinicia el servicio:

```bash
sudo systemctl restart mariadb
```

Se comprueba que sigue activo:

```bash
sudo systemctl is-active mariadb
```

Resultado obtenido:

```text
active
```

Se comprueba la dirección y puerto de escucha:

```bash
sudo ss -ltnp | grep ':3306'
```

Resultado obtenido:

```text
LISTEN 0 80 192.168.0.251:3306 0.0.0.0:* users:(("mariadbd",pid=30027,fd=28))
```

Este resultado confirma que MariaDB escucha conexiones TCP/IP en la dirección `192.168.0.251` y en el puerto `3306`.

---

## 8. Creación de base de datos y usuario

Se accede a MariaDB como administrador:

```bash
sudo mariadb
```

Dentro de la consola se crea la base de datos de prácticas:

```sql
CREATE DATABASE sergio_db;
```

Se crea un usuario permitido desde la red local:

```sql
CREATE USER 'sergio'@'192.168.0.%'
IDENTIFIED BY 'CONTRASEÑA_PERSONAL';
```

La contraseña real no se muestra en este documento.

El patrón `192.168.0.%` limita el acceso de esta cuenta a direcciones de la red local `192.168.0.x`.

Se conceden permisos sobre la base de datos creada:

```sql
GRANT ALL PRIVILEGES ON sergio_db.*
TO 'sergio'@'192.168.0.%';

FLUSH PRIVILEGES;
```

Se puede comprobar que la cuenta existe mediante:

```sql
SELECT User, Host
FROM mysql.user
WHERE User = 'sergio';
```

Resultado obtenido:

```text
User: sergio
Host: 192.168.0.%
```

También se pueden revisar los permisos con:

```sql
SHOW GRANTS FOR 'sergio'@'192.168.0.%';
```

La salida confirma que el usuario dispone de privilegios sobre `sergio_db`.

---

## 9. Prueba de conexión TCP/IP

La conexión se realiza usando la dirección IP de la red local en lugar de `localhost`. Esto permite comprobar que MariaDB acepta conexiones TCP/IP en la interfaz configurada.

```bash
mariadb -h 192.168.0.251 -P 3306 -u sergio -p sergio_db
```

El cliente solicita la contraseña del usuario `sergio`. Una vez autenticado, se ejecuta la siguiente consulta de comprobación:

```sql
SELECT DATABASE() AS bd, USER() AS usuario, @@hostname AS servidor, @@port AS puerto;
```

Resultado obtenido:

```text
+-----------+----------------------+-----------+--------+
| bd        | usuario              | servidor  | puerto |
+-----------+----------------------+-----------+--------+
| sergio_db | sergio@192.168.0.251 | Sergio-PC |   3306 |
+-----------+----------------------+-----------+--------+
```

El resultado confirma que:

- La conexión utiliza la base de datos `sergio_db`.
- El usuario autenticado es `sergio`.
- La conexión llega al servidor `Sergio-PC`.
- MariaDB utiliza el puerto `3306`.
- La conexión se realiza a través de la IP `192.168.0.251`.

Para salir de la consola de MariaDB se utiliza:

```sql
EXIT;
```

---

## 10. Comprobación final

La instalación queda configurada de la siguiente forma:

| Elemento | Resultado |
|---|---|
| MariaDB | Instalado y activo |
| Versión | `11.8.6-MariaDB-0+deb13u1` |
| Puerto | `3306` |
| Dirección de escucha | `192.168.0.251` |
| Cuenta root remota | Bloqueada |
| Usuarios anónimos | Eliminados |
| Base de datos de prácticas | `sergio_db` |
| Usuario de prácticas | `sergio@192.168.0.%` |
| Permisos | Solo sobre `sergio_db` |
| Acceso TCP/IP | Comprobado correctamente |

---

## 11. Problemas frecuentes

### MariaDB solo escucha en `127.0.0.1`

Abrir el fichero:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Comprobar que contiene:

```conf
bind-address            = 192.168.0.251
```

Reiniciar el servicio:

```bash
sudo systemctl restart mariadb
```

Verificar el puerto:

```bash
sudo ss -ltnp | grep ':3306'
```

### Error `Access denied` al conectar

Comprobar que existe una cuenta permitida desde la red local:

```sql
SELECT User, Host
FROM mysql.user
WHERE User = 'sergio';
```

Comprobar los privilegios:

```sql
SHOW GRANTS FOR 'sergio'@'192.168.0.%';
```

### No se puede conectar al puerto 3306

Comprobar que el servicio está activo:

```bash
sudo systemctl is-active mariadb
```

Comprobar la escucha TCP:

```bash
sudo ss -ltnp | grep ':3306'
```

Si se utiliza UFW, permitir solamente la red local:

```bash
sudo ufw allow from 192.168.0.0/24 to any port 3306 proto tcp
```

---

## 12. Conclusión

Se ha instalado MariaDB 11.8.6 en Debian 13. La instalación se ha asegurado eliminando usuarios anónimos, la base de pruebas y bloqueando el acceso remoto de la cuenta administrativa `root`.

MariaDB se ha configurado para escuchar únicamente en la dirección `192.168.0.251` y en el puerto `3306`. Se ha creado la base de datos `sergio_db` y el usuario `sergio`, limitado a conexiones desde la red local `192.168.0.x` y con permisos sobre esa base de datos.

La prueba final confirma que el usuario puede conectarse por TCP/IP a `192.168.0.251:3306` y utilizar correctamente la base de datos `sergio_db`.

---

## 13. Referencias

- MariaDB, [mariadb-secure-installation](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-secure-installation).
- MariaDB, [Configuring MariaDB for Remote Client Access](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-remote-connection-guide).
- MariaDB, [CREATE USER](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/create-user).
- MariaDB, [SHOW GRANTS](https://mariadb.com/docs/server/reference/sql-statements/administrative-sql-statements/show/show-grants).
