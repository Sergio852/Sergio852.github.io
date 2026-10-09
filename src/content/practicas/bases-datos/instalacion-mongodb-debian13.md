---
title: "Instalación de MongoDB en Debian 13"
subject: "Bases de Datos"
description: "Instalación y configuración de MongoDB Community Edition en Debian 13."
date: 2026-10-09
pdf: "bases-datos/instalacion-mongodb-debian13.pdf"
---

# Documentación: instalación y configuración de MongoDB en Debian 13 Trixie

En esta documentación voy a explicar cómo he instalado y configurado **MongoDB Community Edition 8.0** en mi máquina virtual Debian 13 Trixie, llamada `bd-sergio`. El objetivo es que MongoDB quede instalado como servicio, con autenticación activada y accesible remotamente desde mi portátil y desde otros equipos de la misma red.

## 1. Añadir el repositorio oficial de MongoDB

MongoDB no está disponible en los repositorios normales de Debian, así que tengo que añadir el repositorio oficial de MongoDB. Como estoy usando Debian 13 Trixie, utilizo el repositorio preparado para Debian 12 Bookworm, que es compatible para instalar MongoDB 8.0.

Primero instalo los paquetes necesarios para descargar la clave GPG y gestionar repositorios:

```bash
sudo apt update
sudo apt install -y curl gnupg ca-certificates
```

Después descargo e importo la clave pública oficial de MongoDB:

```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
```

Esta clave sirve para que APT pueda comprobar que los paquetes que descargo realmente vienen de MongoDB y no han sido modificados.

Ahora añado el repositorio de MongoDB:

```bash
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

Este comando crea el archivo:

```text
/etc/apt/sources.list.d/mongodb-org-8.0.list
```

Y dentro deja esta línea:

```text
deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main
```

## 2. Instalar MongoDB

Actualizo la lista de paquetes:

```bash
sudo apt update
```

E instalo MongoDB:

```bash
sudo apt install -y mongodb-org
```

En mi caso, la instalación descargó e instaló los siguientes paquetes:

```text
mongodb-org
mongodb-org-server
mongodb-org-database
mongodb-org-mongos
mongodb-org-shell
mongodb-org-tools
mongodb-org-database-tools-extra
mongodb-database-tools
mongodb-mongosh
```

La versión instalada fue:

```text
MongoDB 8.0.32
mongosh 2.13.0
```

El paquete principal es `mongodb-org`, que funciona como metapaquete e instala todo lo necesario para tener el servidor, el shell y las herramientas de MongoDB.

## 3. Activar e iniciar el servicio

Una vez instalado, activo MongoDB para que se inicie automáticamente al arrancar la máquina y lo arranco ahora mismo:

```bash
sudo systemctl enable --now mongod
```

Compruebo que el servicio está funcionando:

```bash
sudo systemctl status mongod --no-pager
```

La salida correcta debe mostrar:

```text
Active: active (running)
```

En mi instalación apareció esto:

```text
● mongod.service - MongoDB Database Server
     Loaded: loaded (/usr/lib/systemd/system/mongod.service; enabled; preset: enabled)
     Active: active (running)
```

También puedo comprobar que MongoDB está escuchando en su puerto por defecto, el `27017`:

```bash
sudo ss -tulnp | grep 27017
```

Al principio, antes de configurar el acceso remoto, la salida mostraba que MongoDB escuchaba en `127.0.0.1:27017`, es decir, solo aceptaba conexiones locales.

## 4. Configurar acceso remoto

Para que pueda conectarme desde mi portátil o desde otro equipo de la red, tengo que modificar el archivo de configuración de MongoDB:

```bash
sudo nano /etc/mongod.conf
```

Dentro del archivo busco la sección `net` y la dejo así:

```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
```

Esto significa:

- `port: 27017`: MongoDB escuchará en su puerto por defecto.
- `bindIp: 0.0.0.0`: MongoDB aceptará conexiones desde cualquier interfaz de red disponible.

Si dejara `bindIp: 127.0.0.1`, solo podría conectarme desde la propia máquina virtual, no desde mi portátil.

Mi archivo `/etc/mongod.conf` quedó así:

```yaml
# mongod.conf

storage:
  dbPath: /var/lib/mongodb

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
```

Es muy importante respetar la indentación de YAML. Las líneas `port`, `bindIp` y `authorization` deben llevar dos espacios al principio. No se pueden usar tabuladores.

## 5. Reiniciar MongoDB

Después de modificar la configuración, reinicio el servicio:

```bash
sudo systemctl restart mongod
```

Vuelvo a comprobar que está activo:

```bash
sudo systemctl status mongod --no-pager
```

Y compruebo que ahora escucha en todas las interfaces:

```bash
sudo ss -tulnp | grep 27017
```

La salida correcta es:

```text
tcp   LISTEN 0   4096   0.0.0.0:27017   0.0.0.0:*   users:(("mongod",pid=6883,fd=9))
```

Esto confirma que MongoDB ya está escuchando en `0.0.0.0:27017`, por lo que acepta conexiones remotas.

## 6. Crear el usuario administrador

Como he activado la autenticación con `authorization: enabled`, necesito un usuario para poder administrar MongoDB.

Entro al shell de MongoDB:

```bash
mongosh
```

Una vez dentro, selecciono la base de datos `admin`, que es donde se crean los usuarios administradores:

```javascript
use admin
```

Después creo mi usuario:

```javascript
db.createUser({
  user: "sergio",
  pwd: "sergio1223",
  roles: [ { role: "root", db: "admin" } ]
})
```

La respuesta correcta es:

```javascript
{ ok: 1 }
```

Este usuario tiene el rol `root` sobre la base de datos `admin`, por lo que puede administrar MongoDB completamente.

Salgo del shell:

```javascript
exit
```

## 7. Probar la autenticación local

Ahora compruebo que puedo entrar usando mi usuario y contraseña:

```bash
mongosh "mongodb://sergio:sergio1223@127.0.0.1:27017/?authSource=admin"
```

En mi caso la conexión fue correcta y entré en el prompt:

```text
test>
```

MongoDB mostró algunos avisos al arrancar:

```text
Using the XFS filesystem is strongly recommended with the WiredTiger storage engine.
We suggest setting swappiness to 0 or 1.
```

Estos avisos no son errores. Son recomendaciones de rendimiento para servidores en producción. Para una máquina virtual de prácticas no es necesario cambiar el sistema de archivos ni la configuración de swap.

## 8. Probar MongoDB

Dentro de `mongosh` puedo crear una base de datos de prueba:

```javascript
use prueba
```

Inserto un documento en una colección llamada `alumnos`:

```javascript
db.alumnos.insertOne({
  nombre: "Sergio",
  curso: "ASIR"
})
```

Compruebo que se ha guardado:

```javascript
db.alumnos.find()
```

Debería devolver algo parecido a esto:

```javascript
[
  {
    _id: ObjectId('...'),
    nombre: 'Sergio',
    curso: 'ASIR'
  }
]
```

Para salir:

```javascript
exit
```

## 9. Conexión remota desde el portátil

Primero compruebo la IP de mi máquina virtual en la interfaz `br0`:

```bash
ip -4 addr show br0
```

Supongamos que la IP de la VM es:

```text
192.168.1.50
```

Desde mi portátil me conecto así:

```bash
mongosh "mongodb://sergio:sergio1223@192.168.1.50:27017/?authSource=admin"
```

La parte importante de la cadena de conexión es:

```text
?authSource=admin
```

Porque mi usuario `sergio` está creado en la base de datos `admin`.

## 10. Firewall

Si uso UFW en la máquina virtual, permito el puerto de MongoDB solo desde mi red local:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 27017 proto tcp
```

Si UFW no estaba activado y quiero activarlo:

```bash
sudo ufw enable
```

Compruebo las reglas:

```bash
sudo ufw status numbered
```

## 11. Comandos útiles

Comprobar el estado del servicio:

```bash
sudo systemctl status mongod --no-pager
```

Reiniciar MongoDB:

```bash
sudo systemctl restart mongod
```

Parar MongoDB:

```bash
sudo systemctl stop mongod
```

Iniciar MongoDB:

```bash
sudo systemctl start mongod
```

Ver los últimos registros si algo falla:

```bash
sudo journalctl -u mongod -n 50 --no-pager
```

Ver el archivo de configuración:

```bash
cat /etc/mongod.conf
```

## 12. Resultado final

Con esta configuración he conseguido:

- Instalar MongoDB Community Edition 8.0 desde su repositorio oficial.
- Dejar el servicio `mongod` activado e iniciado automáticamente.
- Configurar MongoDB para aceptar conexiones remotas en el puerto `27017`.
- Crear el usuario administrador `sergio` con contraseña `sergio1223`.
- Activar la autenticación con `authorization: enabled`.
- Conectarme correctamente de forma local y remota usando `mongosh`.

El comando final para conectarme desde mi portátil es:

```bash
mongosh "mongodb://sergio:sergio1223@IP_DE_LA_VM:27017/?authSource=admin"
```
