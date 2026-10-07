---
title: "Instalación de PostgreSQL en Debian 13"
author: "Sergio Mesa"
subject: "Bases de Datos"
description: "Guía de instalación, configuración y comprobación de PostgreSQL en Debian 13."
date: 2026-10-07
tags:
  - PostgreSQL
  - Debian 13
  - Bases de Datos
pdf: "bases-datos/instalacion-postgresql-debian13.pdf"
---
# Instalación y configuración de PostgreSQL 17 en Debian 13

## 1. Objetivo

En esta práctica se instala PostgreSQL en un equipo con Debian 13. Después se configura el servidor para aceptar conexiones TCP/IP desde la red local y se crea una base de datos con un usuario propio para realizar las pruebas.

La conexión se verifica usando la dirección IP de la red local del equipo:

```text
IP del servidor PostgreSQL: 192.168.0.251
Puerto PostgreSQL:          5432
Base de datos de pruebas:   sergio_db
Usuario de pruebas:         sergio
```

---

## 2. Entorno utilizado

| Elemento | Valor |
|---|---|
| Alumno | Sergio Mesa |
| Fecha | 7 de octubre de 2026 |
| Equipo servidor | Sergio-PC |
| Sistema operativo | Debian 13 |
| Servidor de base de datos | PostgreSQL 17.11 |
| Clúster | `17/main` |
| Puerto | `5432` |
| Directorio de datos | `/var/lib/postgresql/17/main` |
| Fichero de log | `/var/log/postgresql/postgresql-17-main.log` |
| Interfaz de red local | `wlp1s0` |
| IP de la red local | `192.168.0.251/24` |
| Red permitida | `192.168.0.0/24` |

---

## 3. Esquema de funcionamiento

```text
┌────────────────────────────────────────┐
│ Red local: 192.168.0.0/24              │
│                                        │
│ Clientes autorizados                    │
└────────────────────┬───────────────────┘
                     │ TCP/IP · puerto 5432
                     ▼
┌────────────────────────────────────────┐
│ Sergio-PC                               │
│ IP: 192.168.0.251                      │
│ Interfaz: wlp1s0                       │
│                                        │
│ PostgreSQL 17.11                        │
│ Clúster: 17/main                        │
│ Base de datos: sergio_db                │
└────────────────────────────────────────┘
```

---

## 4. Instalación de PostgreSQL

Se actualiza el índice de paquetes de Debian y se instalan PostgreSQL y el paquete de extensiones adicionales:

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
```

- `postgresql` instala el servidor, el cliente `psql` y el clúster principal de PostgreSQL.
- `postgresql-contrib` instala extensiones adicionales que pueden ser útiles en futuras prácticas.

Después de la instalación se comprueba que el servicio está configurado para iniciarse automáticamente y se encuentra activo:

```bash
sudo systemctl is-enabled postgresql
sudo systemctl is-active postgresql
sudo systemctl status postgresql --no-pager
```

Resultado obtenido:

```text
enabled
active
```

En Debian, `postgresql.service` puede aparecer como `active (exited)`. Esto es normal: esa unidad principal se encarga de gestionar los clústeres de PostgreSQL. El estado real del clúster se comprueba con `pg_lsclusters`.

Se comprueba la versión instalada:

```bash
psql --version
```

Resultado obtenido:

```text
psql (PostgreSQL) 17.11 (Debian 17.11-0+deb13u1)
```

Se comprueba el clúster creado por Debian:

```bash
pg_lsclusters
```

Resultado obtenido:

```text
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```

Este resultado confirma que el clúster `17/main` está en estado `online`, pertenece al usuario del sistema `postgres` y escucha en el puerto `5432`.

---

## 5. Comprobación local de PostgreSQL

Se accede a PostgreSQL usando el usuario administrador del sistema `postgres`:

```bash
sudo -u postgres psql
```

Dentro de la consola de PostgreSQL se ejecuta la consulta siguiente:

```sql
SELECT version();
```

Resultado obtenido:

```text
PostgreSQL 17.11 (Debian 17.11-0+deb13u1) on x86_64-pc-linux-gnu,
compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

También se puede comprobar la base de datos, el usuario y el puerto con esta consulta:

```sql
SELECT
  current_database() AS base_datos,
  current_user AS usuario,
  inet_server_addr() AS direccion_servidor,
  inet_server_port() AS puerto;
```

Para salir de `psql` se utiliza:

```sql
\q
```

---

## 6. Identificación de la red local

Antes de configurar el acceso remoto se revisan las direcciones de red del equipo:

```bash
hostname -I
ip -br a
```

La interfaz conectada a la red local es `wlp1s0` y tiene esta dirección:

```text
192.168.0.251/24
```

Por tanto, la red local utilizada es:

```text
192.168.0.0/24
```

El equipo también dispone de varias redes virtuales de libvirt y de una interfaz Tailscale. Estas direcciones no se utilizan para exponer PostgreSQL en la red local:

| Interfaz | Dirección | Uso |
|---|---|---|
| `wlp1s0` | `192.168.0.251/24` | Red local utilizada por PostgreSQL |
| `virbr10` | `192.168.100.1/24` | Red virtual de libvirt |
| `virbr0` | `192.168.122.1/24` | Red virtual de libvirt |
| `tailscale0` | `100.64.0.33/32` | Red privada de Tailscale |

---

## 7. Copia de seguridad de la configuración

Antes de modificar la configuración se crean copias de seguridad de los ficheros principales:

```bash
sudo cp /etc/postgresql/17/main/postgresql.conf \
  /etc/postgresql/17/main/postgresql.conf.bak

sudo cp /etc/postgresql/17/main/pg_hba.conf \
  /etc/postgresql/17/main/pg_hba.conf.bak
```

Los ficheros de configuración utilizados son:

```text
/etc/postgresql/17/main/postgresql.conf
/etc/postgresql/17/main/pg_hba.conf
```

- `postgresql.conf` contiene la configuración general del servidor, incluyendo las direcciones IP en las que escucha.
- `pg_hba.conf` controla qué clientes pueden conectarse, desde qué redes y con qué método de autenticación.

---

## 8. Configuración de escucha TCP/IP

Se abre el fichero principal de configuración:

```bash
sudo nano /etc/postgresql/17/main/postgresql.conf
```

En el fichero se añade o se modifica la siguiente línea:

```conf
listen_addresses = '127.0.0.1,192.168.0.251'
```

Con esta configuración PostgreSQL escucha en dos direcciones:

| Dirección | Función |
|---|---|
| `127.0.0.1` | Permite conexiones TCP/IP desde el propio equipo |
| `192.168.0.251` | Permite conexiones desde la red local a través de la interfaz Wi-Fi |

No se utiliza `0.0.0.0`, ya que eso expondría PostgreSQL en todas las interfaces de red del equipo, incluidas las redes virtuales y Tailscale.

---

## 9. Configuración de acceso en `pg_hba.conf`

Se abre el fichero de reglas de autenticación:

```bash
sudo nano /etc/postgresql/17/main/pg_hba.conf
```

Al final del fichero se añade la siguiente regla:

```conf
host    all    all    192.168.0.0/24    scram-sha-256
```

La regla se interpreta de la siguiente forma:

| Campo | Valor | Significado |
|---|---|---|
| Tipo | `host` | La regla se aplica a conexiones TCP/IP |
| Base de datos | `all` | Permite acceder a cualquier base de datos |
| Usuario | `all` | Permite acceder a cualquier rol con permisos válidos |
| Red | `192.168.0.0/24` | Solo admite clientes de la red local |
| Método | `scram-sha-256` | Solicita una contraseña usando autenticación segura |

Las reglas originales ya permitían conexiones locales mediante `127.0.0.1` y `::1`. La nueva regla añade acceso desde equipos de la misma red local.

---

## 10. Reinicio y comprobación del puerto

Después de modificar `postgresql.conf` es necesario reiniciar PostgreSQL:

```bash
sudo systemctl restart postgresql
```

Se comprueba que el servicio sigue activo:

```bash
sudo systemctl is-active postgresql
```

Resultado obtenido:

```text
active
```

Se comprueba que PostgreSQL escucha tanto en localhost como en la IP de la red local:

```bash
sudo ss -ltnp | grep ':5432'
```

Resultado obtenido:

```text
LISTEN 0 200 127.0.0.1:5432       0.0.0.0:* users:(("postgres",pid=27421,fd=6))
LISTEN 0 200 192.168.0.251:5432   0.0.0.0:* users:(("postgres",pid=27421,fd=7))
```

Este resultado confirma que PostgreSQL acepta conexiones TCP/IP por el puerto `5432` en la interfaz local y en la interfaz de red `192.168.0.251`.

---

## 11. Creación de usuario y base de datos

No se utiliza el usuario administrador `postgres` para las conexiones de prueba. Se crea un rol propio y una base de datos asociada.

Se abre `psql` como administrador:

```bash
sudo -u postgres psql
```

Dentro de PostgreSQL se ejecutan los siguientes comandos:

```sql
CREATE ROLE sergio LOGIN PASSWORD 'CONTRASEÑA_ELEGIDA_POR_EL_USUARIO';
CREATE DATABASE sergio_db OWNER sergio;
```

Para salir:

```sql
\q
```

El rol `sergio` tiene permiso de inicio de sesión y es propietario de la base de datos `sergio_db`.

> La contraseña no se muestra ni se guarda en este documento.

---

## 12. Prueba de conexión por la IP de red

La conexión se prueba usando la IP de la red local, no `localhost`. De este modo se comprueba que PostgreSQL acepta conexiones TCP/IP en la dirección configurada.

```bash
psql -h 192.168.0.251 -p 5432 -U sergio -d sergio_db
```

Después de introducir la contraseña del usuario `sergio`, se establece una conexión SSL con PostgreSQL:

```text
Conexión SSL (protocolo: TLSv1.3, cifrado: TLS_AES_256_GCM_SHA384,
compresión: desactivado, ALPN: postgresql)
```

Dentro de `psql` se ejecuta la consulta de validación:

```sql
SELECT
  current_database() AS base_datos,
  current_user AS usuario,
  inet_client_addr() AS cliente,
  inet_server_addr() AS servidor,
  inet_server_port() AS puerto;
```

Resultado obtenido:

```text
 base_datos | usuario |    cliente    |   servidor    | puerto
------------+---------+---------------+---------------+--------
 sergio_db  | sergio  | 192.168.0.251 | 192.168.0.251 |   5432
(1 fila)
```

La consulta confirma que:

- La conexión se ha realizado mediante TCP/IP.
- PostgreSQL recibe la conexión en `192.168.0.251`.
- El puerto utilizado es `5432`.
- La autenticación se realiza con el usuario `sergio`.
- La base de datos utilizada es `sergio_db`.

---

## 13. Comprobación final

Como comprobación final se revisa de nuevo el puerto de escucha:

```bash
sudo ss -ltnp | grep ':5432'
```

Resultado obtenido:

```text
LISTEN 0 200 127.0.0.1:5432       0.0.0.0:* users:(("postgres",pid=27421,fd=6))
LISTEN 0 200 192.168.0.251:5432   0.0.0.0:* users:(("postgres",pid=27421,fd=7))
```

PostgreSQL queda instalado, configurado para el inicio automático y preparado para aceptar conexiones desde la red local `192.168.0.0/24` por el puerto `5432`.

---

## 14. Problemas frecuentes

### PostgreSQL solo escucha en `127.0.0.1`

Comprobar que `postgresql.conf` contiene:

```conf
listen_addresses = '127.0.0.1,192.168.0.251'
```

Después reiniciar el servicio:

```bash
sudo systemctl restart postgresql
```

Y comprobar el puerto:

```bash
sudo ss -ltnp | grep ':5432'
```

### Error de autenticación desde otra máquina

Comprobar que `pg_hba.conf` incluye la regla:

```conf
host    all    all    192.168.0.0/24    scram-sha-256
```

Después se puede reiniciar PostgreSQL:

```bash
sudo systemctl restart postgresql
```

También se puede recargar la configuración sin reiniciar la instancia:

```bash
sudo systemctl reload postgresql
```

### No se puede conectar al puerto 5432

Comprobar el estado del clúster:

```bash
pg_lsclusters
```

Comprobar el servicio:

```bash
sudo systemctl status postgresql --no-pager
```

Comprobar la escucha de red:

```bash
sudo ss -ltnp | grep ':5432'
```

Si se utiliza UFW, permitir conexiones solamente desde la red local:

```bash
sudo ufw allow from 192.168.0.0/24 to any port 5432 proto tcp
```

---

## 15. Conclusión

Se ha instalado PostgreSQL 17.11 en Debian 13. El clúster `17/main` se encuentra activo, se inicia automáticamente y utiliza el puerto `5432`.

El servidor se ha configurado para escuchar en `127.0.0.1` y en la dirección de red local `192.168.0.251`. Además, `pg_hba.conf` permite conexiones desde la red `192.168.0.0/24` utilizando autenticación `scram-sha-256`.

Se creó el usuario `sergio` y la base de datos `sergio_db`. La conexión mediante TCP/IP a `192.168.0.251:5432` se realizó correctamente, confirmando que PostgreSQL está preparado para admitir acceso desde la red local.

---

## 16. Referencias

- PostgreSQL, [psql — PostgreSQL interactive terminal](https://www.postgresql.org/docs/current/app-psql.html).
- PostgreSQL, [Connection Settings](https://www.postgresql.org/docs/current/runtime-config-connection.html).
- PostgreSQL, [The pg_hba.conf File](https://www.postgresql.org/docs/17/auth-pg-hba-conf.html).
