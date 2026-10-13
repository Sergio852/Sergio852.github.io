---
title: "Instalación y configuración de Redis en Debian 13"
subject: "Bases de Datos"
description: "Instalación, configuración, autenticación y acceso remoto a Redis en Debian 13."
date: 2026-10-13
pdf: "bases-datos/instalacion-redis.pdf"
---

# Práctica: Instalación, configuración y acceso remoto seguro a Redis

**Alumno:** Sergio  
**Máquina servidor Redis:** `redis-bd` — IP: `192.168.122.163`  
**Máquina cliente:** `Sergio-PC`  
**Sistema operativo:** Debian GNU/Linux trixie  
**Versión de Redis:** 8.0.2  
**Puerto:** 6379  
**Fecha:** 13 de octubre de 2026  

---

## 1. Objetivo

El objetivo de esta práctica es instalar y configurar un servidor Redis en una máquina virtual Debian, crear un usuario ACL con permisos restringidos, habilitar el acceso remoto desde el equipo anfitrión y comprobar el funcionamiento mediante operaciones de lectura y escritura.

Se han cumplido los siguientes puntos:

- Instalación de Redis Server y Redis Tools.
- Comprobación del servicio mediante `systemd`.
- Creación de claves, consulta, eliminación y caducidad temporal.
- Creación de un usuario Redis llamado `sergio` mediante ACL.
- Configuración de una contraseña para el usuario `default`.
- Persistencia de las ACL en `/etc/redis/users.acl`.
- Habilitación del acceso remoto manteniendo `protected-mode yes`.
- Comprobación de conectividad desde el host con `nc`.
- Autenticación remota del usuario `sergio`.
- Escritura y lectura remota de una clave permitida.

---

## 2. Instalación de Redis en la máquina servidor

En la máquina `redis-bd` se actualizaron los repositorios y se instaló Redis:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y redis-server redis-tools
```

Salida relevante:

```text
redis-server 8.0.2
redis-tools 8.0.2
liblzf1 3.6-4+b3
```

Se comprobó la versión instalada:

```bash
redis-server --version
redis-cli --version
```

Resultado:

```text
Redis server v=8.0.2 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=b843bbd074c0e1da
redis-cli 8.0.2
```

---

## 3. Activación y comprobación del servicio

Se habilitó el servicio para que se iniciase automáticamente con el sistema y se arrancó de inmediato:

```bash
sudo systemctl enable --now redis-server
```

Se comprobó su estado:

```bash
sudo systemctl status redis-server --no-pager
```

Salida:

```text
● redis-server.service - Advanced key-value store
     Loaded: loaded (/usr/lib/systemd/system/redis-server.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-10-13 19:40:22 CEST
     Main PID: 1497 (redis-server)
     Status: "Ready to accept connections"
```

El servicio quedó habilitado y en ejecución.

---

## 4. Comprobación inicial del puerto de escucha

Inicialmente, Redis solo escuchaba en la interfaz de loopback:

```bash
sudo ss -ltnp | grep ':6379'
```

Salida:

```text
LISTEN 0 511 127.0.0.1:6379 0.0.0.0:* users:(("redis-server",pid=1497,fd=8))
LISTEN 0 511 [::1]:6379 [::]:* users:(("redis-server",pid=1497,fd=9))
```

Esto significa que, en un primer momento, Redis solo aceptaba conexiones locales desde la propia máquina `redis-bd`.

---

## 5. Pruebas básicas de Redis

Se realizaron pruebas locales de creación, consulta, existencia y borrado de claves.

### Crear y consultar una clave

```bash
redis-cli SET practica:alumno "Sergio"
redis-cli GET practica:alumno
```

Resultado:

```text
OK
"Sergio"
```

### Comprobar si existe una clave

```bash
redis-cli EXISTS practica:alumno
```

Resultado:

```text
(integer) 1
```

### Eliminar una clave

```bash
redis-cli DEL practica:alumno
redis-cli EXISTS practica:alumno
```

Resultado:

```text
(integer) 1
(integer) 0
```

### Clave con caducidad

Se creó una clave con un tiempo de vida de 30 segundos:

```bash
redis-cli SET practica:sesion "activa" EX 30
redis-cli TTL practica:sesion
redis-cli GET practica:sesion
```

Resultados:

```text
OK
(integer) 24
"activa"
```

Pasados los 30 segundos, la clave desapareció automáticamente:

```bash
redis-cli GET practica:sesion
```

Resultado:

```text
(nil)
```

Esto demuestra el funcionamiento de las claves efímeras mediante el parámetro `EX`.

---

## 6. Creación del usuario ACL `sergio`

Se generó una contraseña segura mediante Redis:

```bash
redis-cli ACL GENPASS
```

Se creó el usuario `sergio` con permisos limitados:

```bash
redis-cli ACL SETUSER sergio \
  on \
  '>CONTRASENA_DE_SERGIO' \
  '~practica:*' \
  '+@read' \
  '+@write' \
  '+ping' \
  '+select'
```

El usuario quedó configurado con las siguientes características:

| Elemento | Valor |
|---|---|
| Usuario | `sergio` |
| Estado | Activado (`on`) |
| Claves permitidas | `practica:*` |
| Comandos permitidos | Lectura, escritura, `PING` y `SELECT` |
| Contraseña | Configurada mediante ACL |
| Acceso a otras claves | Denegado |

Se comprobó la configuración:

```bash
redis-cli ACL GETUSER sergio
```

Salida relevante, ocultando el hash de la contraseña:

```text
flags: on, sanitize-payload
passwords: <HASH_OCULTO>
commands: -@all +@read +@write +ping +select
keys: ~practica:*
```

---

## 7. Prueba local del usuario `sergio`

Se comprobó que el usuario podía autenticarse y operar sobre claves permitidas:

```bash
redis-cli \
  --user sergio \
  --askpass \
  -n 1 \
  SET practica:cliente "acceso_autenticado"
```

Resultado:

```text
OK
```

Posteriormente:

```bash
redis-cli \
  --user sergio \
  --askpass \
  -n 1 \
  GET practica:cliente
```

Resultado:

```text
"acceso_autenticado"
```

---

## 8. Configuración del fichero ACL persistente

Se creó el fichero de usuarios ACL con permisos seguros:

```bash
sudo install -o redis -g redis -m 640 /dev/null /etc/redis/users.acl
```

Se comprobó su creación:

```bash
sudo ls -l /etc/redis/users.acl
```

Salida:

```text
-rw-r----- 1 redis redis 0 oct 13 20:05 /etc/redis/users.acl
```

El fichero pertenece al usuario y grupo `redis`, y tiene permisos `640`, de modo que solo el propietario puede modificarlo y el grupo puede leerlo.

En `/etc/redis/redis.conf` se configuró la siguiente directiva:

```conf
aclfile /etc/redis/users.acl
```

Después se reinició el servicio:

```bash
sudo systemctl restart redis-server
```

---

## 9. Persistencia de los usuarios ACL

Se volvieron a definir los usuarios y se guardaron en el fichero ACL:

```bash
redis-cli ACL SETUSER sergio \
  on \
  '>CONTRASENA_DE_SERGIO' \
  '~practica:*' \
  '+@read' \
  '+@write' \
  '+ping' \
  '+select'

redis-cli ACL SAVE
```

Resultado:

```text
OK
```

El comando `ACL SAVE` escribe la configuración actual de los usuarios en el fichero indicado por `aclfile`.

---

## 10. Configuración del usuario `default`

Para permitir conexiones remotas manteniendo `protected-mode yes`, fue necesario asignar una contraseña al usuario `default`.

Se generó una contraseña:

```bash
redis-cli ACL GENPASS
```

Se configuró el usuario:

```bash
redis-cli ACL SETUSER default \
  on \
  '>CONTRASENA_DE_DEFAULT' \
  '~*' \
  '+@all'
```

Después se guardó la configuración:

```bash
redis-cli \
  --user default \
  --askpass \
  ACL SAVE
```

Resultado:

```text
OK
```

Esto es importante porque Redis, con `protected-mode yes`, bloquea las conexiones remotas si el usuario `default` no tiene contraseña configurada.

---

## 11. Verificación del fichero ACL

Se comprobó el contenido del fichero ocultando los hashes de las contraseñas:

```bash
sudo sed -E 's/(#[0-9a-fA-F]{64})/<HASH_OCULTO>/g' /etc/redis/users.acl
```

Salida:

```text
user default on sanitize-payload <HASH_OCULTO> ~* &* +@all
user sergio on sanitize-payload <HASH_OCULTO> ~practica:* resetchannels -@all +@read +@write +ping +select
```

Esto confirma que ambos usuarios quedaron persistidos correctamente.

---

## 12. Ajuste final de permisos del usuario `sergio`

Para la prueba final se ajustó el usuario `sergio` con una contraseña más corta y permisos concretos:

```bash
redis-cli \
  --user default \
  --askpass
```

Una vez autenticado como `default`:

```bash
ACL SETUSER sergio on resetpass \
  '>sergio1223' \
  '~practica:*' \
  '+set' \
  '+get' \
  '+del' \
  '+ping' \
  '+select'

ACL SAVE
```

Resultado:

```text
OK
OK
```

La regla `resetpass` elimina las contraseñas anteriores del usuario y `>sergio1223` añade la nueva contraseña.

Se verificó la configuración:

```bash
ACL GETUSER sergio
```

Salida relevante:

```text
flags: on, sanitize-payload
passwords: <HASH_OCULTO>
commands: -@all +@read +@write +set +get +del +ping +select
keys: ~practica:*
```

---

## 13. Habilitación del acceso remoto

En `/etc/redis/redis.conf` se modificó la directiva `bind` para que Redis escuchase también en la interfaz de red de la máquina virtual:

```conf
bind 127.0.0.1 192.168.122.163
```

Se mantuvo activado el modo protegido:

```conf
protected-mode yes
```

Después se reinició el servicio:

```bash
sudo systemctl restart redis-server
sudo systemctl status redis-server --no-pager
sudo ss -ltnp | grep ':6379'
```

Salida final:

```text
● redis-server.service - Advanced key-value store
     Active: active (running)
     Status: "Ready to accept connections"
     Main PID: 2162 (redis-server)

LISTEN 0 511 127.0.0.1:6379 0.0.0.0:* users:(("redis-server",pid=2162,fd=8))
LISTEN 0 511 [::1]:6379 [::]:* users:(("redis-server",pid=2162,fd=9))
```

Redis quedó a la escucha en `127.0.0.1:6379` y en la interfaz de red configurada.

---

## 14. Comprobación de conectividad desde el host

Desde el equipo anfitrión `Sergio-PC` se comprobó que el puerto Redis de la máquina virtual era accesible:

```bash
nc -vz 192.168.122.163 6379
```

Resultado:

```text
Connection to 192.168.122.163 6379 port [tcp/redis] succeeded!
```

---

## 15. Prueba remota de autenticación

Desde el host se realizó una conexión remota usando el usuario `sergio`:

```bash
redis-cli \
  -h 192.168.122.163 \
  -p 6379 \
  --user sergio \
  --askpass \
  -n 1 \
  PING
```

La contraseña se introdujo de forma interactiva.

Resultado:

```text
PONG
```

Esto confirma que:

- El host puede alcanzar la máquina virtual.
- Redis acepta conexiones remotas.
- El usuario `sergio` puede autenticarse correctamente.
- El modo protegido no bloquea la conexión porque el usuario `default` tiene contraseña.

---

## 16. Prueba remota de escritura y lectura

### Escritura remota

```bash
redis-cli \
  -h 192.168.122.163 \
  -p 6379 \
  --user sergio \
  --askpass \
  -n 1 \
  SET practica:remota "conexion_desde_host_correcta"
```

Resultado:

```text
OK
```

### Lectura remota

```bash
redis-cli \
  -h 192.168.122.163 \
  -p 6379 \
  --user sergio \
  --askpass \
  -n 1 \
  GET practica:remota
```

Resultado:

```text
"conexion_desde_host_correcta"
```

---

## 17. Conclusiones

La práctica se completó correctamente.

Se instaló Redis 8.0.2 en una máquina virtual Debian, se habilitó su servicio mediante `systemd` y se comprobaron operaciones básicas sobre claves, incluyendo creación, consulta, borrado y caducidad temporal.

Se creó un usuario ACL llamado `sergio`, con acceso restringido a las claves que comienzan por `practica:` y con permisos limitados a los comandos necesarios para la práctica.

Se configuró el usuario `default` con contraseña, requisito necesario para permitir conexiones remotas sin desactivar `protected-mode`.

Finalmente, se habilitó la escucha de Redis en la interfaz de red de la máquina virtual y se comprobó desde el equipo anfitrión que era posible autenticarse y realizar operaciones de escritura y lectura remotas.

La configuración final garantiza que:

- Redis no acepta conexiones anónimas remotas.
- El usuario `default` está protegido por contraseña.
- El usuario `sergio` tiene permisos restringidos.
- Las ACL se guardan de forma persistente en `/etc/redis/users.acl`.
- El acceso remoto funciona desde el host mediante autenticación.

---

## 18. Consideraciones de seguridad

Para esta práctica se utilizó una contraseña corta y fácil de recordar, `sergio1223`, con el fin de facilitar las pruebas. En un entorno real no sería recomendable, ya que es demasiado corta y predecible.

En producción se recomienda:

- Usar contraseñas generadas con `ACL GENPASS`.
- No escribir contraseñas en la línea de comandos con `--pass`.
- Usar `--askpass` o variables de entorno temporales.
- Limitar los comandos disponibles de cada usuario ACL.
- Restringir los patrones de claves con `~`.
- Mantener `protected-mode yes`.
- No exponer Redis directamente a Internet.
- Restringir el acceso mediante firewall cuando sea necesario.
- Revisar periódicamente los usuarios con `ACL LIST` y `ACL GETUSER`.
