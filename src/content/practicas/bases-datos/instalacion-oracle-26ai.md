---
title: "Instalación de Oracle 26ai en una máquina virtual Debian y conexión con SQL Developer"
subject: "Bases de Datos"
description: "Guía de instalación de Oracle Database 26ai en Debian dentro de una máquina virtual y conexión desde SQL Developer."
date: 2026-10-05
tags:
  - Oracle
  - Oracle Database 26ai
  - Debian
  - SQL Developer
  - Virtualización
pdf: "bases-datos/instalacion-oracle-26ai.pdf"
---

# Oracle AI Database 26ai Free en una VM y SQL Developer en el host

> Guía práctica completa para instalar, arrancar y validar Oracle AI Database 26ai Free en una máquina virtual Linux, y conectarse desde Oracle SQL Developer instalado en el equipo anfitrión.
>
> **Escenario validado en esta práctica:**
>
> - Servidor Oracle (VM): `oracle26ai`
> - IP de la VM: `192.168.122.54`
> - Listener: TCP `1521`
> - Servicio de la PDB: `FREEPDB1`
> - Cliente: Oracle SQL Developer 26.2.0 instalado en el host Linux
> - JDK del host: OpenJDK `21.0.12.1`
> - Usuario usado para comprobar la conectividad: `SYSTEM`

---

## 1. Objetivo y arquitectura

La base de datos Oracle se ejecuta dentro de una máquina virtual; Oracle SQL Developer se ejecuta en el sistema host. SQL Developer accede a la VM mediante TCP/IP a través del *listener* de Oracle.

```text
┌──────────────────────────────────┐
│ Host Linux                       │
│                                  │
│ Oracle SQL Developer 26.2.0      │
└───────────────┬──────────────────┘
                │
                │ TCP/IP
                │ 192.168.122.54:1521
                │ Service name: FREEPDB1
                ▼
┌──────────────────────────────────┐
│ Máquina virtual Linux            │
│ Hostname: oracle26ai             │
│                                  │
│ Oracle AI Database 26ai Free     │
│ Listener + CDB FREE + PDB        │
│ FREEPDB1                         │
└──────────────────────────────────┘
```

La práctica se considera terminada cuando desde SQL Developer se puede conectar a `FREEPDB1` y ejecutar una consulta que confirme la base de datos, servicio, host y usuario.

---

## 2. Consideraciones sobre Debian

Oracle AI Database Free para Linux se distribuye oficialmente para plataformas compatibles con paquetes RPM. La documentación oficial de instalación 26ai para Linux debe ser siempre la fuente principal para la versión de paquete, los prerrequisitos y los nombres de servicio.[^oracle26ai]

Si la VM es Debian, **documenta el método real con el que se instaló Oracle en tu entorno**. No es recomendable instalar un RPM de Oracle directamente en Debian sin un procedimiento soportado: los scripts de configuración, dependencias y servicios están preparados para sistemas RPM compatibles.

Esta guía separa dos cosas:

1. El flujo general y verificable de Oracle Database dentro de la VM.
2. La configuración real completada en el host Linux para usar SQL Developer y conectarse a la VM.

---

## 3. Preparación de la máquina virtual

Antes de instalar o intentar una conexión remota, comprueba que la VM tiene una red accesible desde el host y que su nombre e IP son correctos.

Ejecuta dentro de la VM:

```bash
hostname
hostname -f
ip -br a
getent hosts "$(hostname -f)"
```

En este caso, el servidor se identificó como:

```text
Hostname: oracle26ai
IP:       192.168.122.54
```

### Recursos recomendados

| Recurso | Recomendación práctica |
|---|---|
| RAM | Para laboratorio, asignar al menos 2 GB y disponer de swap. Más memoria mejora el arranque y la administración |
| CPU | Dos vCPU o más si el host tiene recursos disponibles |
| Disco | Reservar espacio para el software, ficheros de datos, logs y futuras prácticas |
| Red | Usar una red desde la que el host pueda alcanzar la IP de la VM |
| Nombre de host | Mantener una resolución local coherente para el hostname de la VM |

### Prueba de red desde el host

Desde el host, antes de configurar SQL Developer:

```bash
ping -c 3 192.168.122.54
nc -vz 192.168.122.54 1521
```

- Si `ping` falla, revisa el modo de red de la VM, la IP y el firewall.
- Si `ping` funciona pero `nc` falla en el puerto 1521, revisa el listener de Oracle o el firewall del servidor.
- Si ambos funcionan, existe conectividad básica y el puerto Oracle es accesible.

---

## 4. Instalación y configuración de Oracle AI Database 26ai Free

> Los nombres exactos del paquete y del servicio pueden variar entre compilaciones y plataformas. Compruébalos siempre en la documentación y en el paquete descargado.

El flujo estándar en una distribución Linux RPM compatible es:

1. Instalar los prerrequisitos de Oracle.
2. Instalar el paquete de Oracle AI Database Free.
3. Ejecutar el script de configuración inicial.
4. Definir las contraseñas de las cuentas administrativas cuando el instalador lo solicite.
5. Habilitar el servicio y comprobar el listener.

Ejemplo de referencia para una plataforma RPM compatible:

```bash
sudo dnf install -y oracle-ai-database-preinstall-26ai
sudo dnf install -y ./oracle-ai-database-free-26ai-*.rpm
sudo /etc/init.d/oracle-free-26ai configure
sudo systemctl enable --now oracle-free-26ai
sudo systemctl status oracle-free-26ai
```

Durante la configuración inicial, Oracle crea normalmente:

- La base contenedora (**CDB**) `FREE`.
- La base pluggable por defecto (**PDB**) `FREEPDB1`.
- El listener Oracle, normalmente en el puerto TCP `1521`.

### Variables de entorno administrativas

En la VM, ajusta estas variables a la ruta de tu instalación para administrar Oracle con sus herramientas:

```bash
export ORACLE_HOME=/opt/oracle/product/26ai/dbhomeFree
export ORACLE_SID=FREE
export PATH="$ORACLE_HOME/bin:$PATH"
```

> La ruta de `ORACLE_HOME` puede diferir. Confirma el valor real en tu instalación antes de añadirlo a `.bashrc` o a otro fichero de perfil.

---

## 5. Comprobación del servidor Oracle

### 5.1. Verificar el listener

En la VM, como usuario con el entorno de Oracle cargado:

```bash
lsnrctl status
```

También resulta útil:

```bash
lsnrctl services
```

El resultado debe mostrar que el listener está activo, normalmente en el puerto `1521`, y debe registrar los servicios de base de datos correspondientes. La conectividad remota hacia Oracle Database Free se realiza a través del listener TCP/IP.[^oracleconnect]

### 5.2. Verificar que las PDB están abiertas

```bash
sqlplus / as sysdba
```

Dentro de SQL*Plus:

```sql
SHOW PDBS;

SELECT name, open_mode
FROM v$pdbs;
```

Se espera ver la PDB `FREEPDB1` en estado `READ WRITE` para poder conectarse a ella normalmente.

### 5.3. Abrir la PDB si fuera necesario

Si `FREEPDB1` no está abierta:

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
```

`SAVE STATE` ayuda a que la PDB conserve su estado de apertura después de reiniciar la instancia, según la configuración del entorno.

### 5.4. Abrir el firewall de la VM

Si se utiliza `firewalld`, abre el puerto del listener:

```bash
sudo firewall-cmd --permanent --add-port=1521/tcp
sudo firewall-cmd --reload
```

Comprueba la regla:

```bash
sudo firewall-cmd --list-ports
```

---

## 6. Instalación de Oracle SQL Developer en el host

SQL Developer es un cliente gráfico gratuito que permite explorar objetos de base de datos, ejecutar SQL y administrar conexiones.[^sqldev]

SQL Developer 26.2 requiere un JDK 17 o superior.[^sqldevjdk]

### 6.1. Instalar Java y JavaFX

En el host Linux basado en Debian se utilizó OpenJDK 21 y OpenJFX:

```bash
sudo apt update
sudo apt install -y openjdk-21-jdk openjfx
```

Verifica el JDK:

```bash
/usr/lib/jvm/java-21-openjdk-amd64/bin/java -version
```

Resultado observado:

```text
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-deb13u1-Debian)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-deb13u1-Debian, mixed mode, sharing)
```

Verifica que JavaFX se instaló:

```bash
ls -l /usr/share/openjfx/lib/javafx.base.jar
```

En el sistema de esta práctica, el fichero apareció como enlace simbólico a la biblioteca JavaFX del sistema.

### 6.2. Descomprimir SQL Developer

Descarga el ZIP de SQL Developer para Linux desde Oracle y extráelo en un directorio de tu usuario. En esta práctica se utilizó:

```text
$HOME/Aplicaciones/sqldeveloper
```

La estructura importante fue:

```text
$HOME/Aplicaciones/sqldeveloper/sqldeveloper.sh
$HOME/Aplicaciones/sqldeveloper/sqldeveloper/bin/jdk.conf
$HOME/Aplicaciones/sqldeveloper/ide/bin/launcher.sh
```

El arranque estándar de SQL Developer en Linux consiste en ejecutar `sqldeveloper.sh` después de descomprimir el kit.[^sqldevinstall]

---

## 7. Configurar SQL Developer con JDK 21 y JavaFX

### 7.1. Configurar la ruta del JDK

Edita el fichero:

```bash
nano "$HOME/Aplicaciones/sqldeveloper/sqldeveloper/bin/jdk.conf"
```

Añade o deja activa la directiva:

```text
SetJavaHome /usr/lib/jvm/java-21-openjdk-amd64
```

Esta directiva obliga al lanzador a usar el JDK del sistema que has verificado.

### 7.2. Solucionar el error `Module javafx.base not found`

En este entorno, SQL Developer llegó a iniciar el JDK, pero falló con:

```text
Error occurred during initialization of boot layer
java.lang.module.FindException: Module javafx.base not found
```

La causa era que JavaFX estaba instalado en el host, pero sus módulos no se encontraban en el *module path* con el que SQL Developer construía el proceso Java.

La solución aplicada fue editar:

```bash
nano "$HOME/Aplicaciones/sqldeveloper/ide/bin/launcher.sh"
```

Busca esta zona dentro de la función de lanzamiento:

```bash
CheckJDK
CheckLibraryPath
AppendVMSpecificOptions
AppendCommandlineVMOptions
```

Justo después de `AppendCommandlineVMOptions`, añade:

```bash
# JavaFX modules for Java 21
AddVMOption --module-path=/usr/share/openjfx/lib
AddVMOption --add-modules=javafx.controls,javafx.fxml,javafx.web,javafx.swing
```

Estas opciones incorporan al proceso Java los módulos JavaFX requeridos por el cliente.

> **Mantenimiento:** `launcher.sh` pertenece a la instalación de SQL Developer. Si actualizas o reinstalas SQL Developer, revisa que estas dos líneas siguen presentes, porque una actualización puede sobrescribir el fichero.

### 7.3. Crear un lanzador cómodo en el PATH

Crea el fichero `~/.local/bin/sqldeveloper`:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/sqldeveloper <<'EOF'
#!/bin/sh

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"

exec "$HOME/Aplicaciones/sqldeveloper/sqldeveloper.sh" "$@"
EOF

chmod +x ~/.local/bin/sqldeveloper
```

Confirma que el directorio forma parte de tu `PATH`:

```bash
echo "$PATH"
command -v sqldeveloper
```

En la práctica, el comando resolvía a:

```text
/home/sergio/.local/bin/sqldeveloper
```

Arranca SQL Developer con:

```bash
sqldeveloper
```

En el primer inicio puede aparecer el diálogo para importar preferencias de otra instalación. Si no se muestra ninguna instalación anterior, pulsa **No**; se crearán preferencias nuevas y esto no impide conectarte a Oracle.

---

## 8. Crear la conexión a la VM desde SQL Developer

En SQL Developer:

1. Ve al panel **Conexiones**.
2. Pulsa el icono **+** para crear una conexión.
3. Selecciona el tipo de conexión **Básico**.
4. Introduce los valores siguientes.

| Campo | Valor de la práctica |
|---|---|
| Nombre de conexión | `Oracle-VM` o cualquier nombre descriptivo |
| Usuario | `SYSTEM` para la comprobación inicial |
| Contraseña | La definida durante la configuración de Oracle |
| Tipo de conexión | `Básico` |
| Nombre del host | `192.168.122.54` |
| Puerto | `1521` |
| Método de identificación | **Nombre del Servicio** |
| Nombre del Servicio | `FREEPDB1` |
| Rol | `Predeterminado` |

Pulsa **Probar**. Si aparece el estado correcto, pulsa **Conectar**.

### No usar el SID `xe`

En la primera prueba se indicó lo siguiente:

```text
SID: xe
```

El resultado fue:

```text
ORA-12505: No se puede conectar a la base de datos.
El SID xe no está registrado con el listener.
```

La corrección fue cambiar de **SID** a **Nombre del Servicio** e introducir:

```text
FREEPDB1
```

`FREEPDB1` es el servicio asociado a la PDB creada por defecto en Oracle Database Free.[^freepdb1]

---

## 9. Validación final de la práctica

Una conexión verde o el mensaje de prueba correcta confirman la conectividad, pero es recomendable ejecutar una consulta de validación que deje evidencia del resultado.

En una **Hoja de Trabajo SQL** de la conexión creada, ejecuta:

```sql
SELECT
  SYS_CONTEXT('USERENV', 'DB_NAME') AS base_datos,
  SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS servicio,
  SYS_CONTEXT('USERENV', 'SERVER_HOST') AS servidor,
  USER AS usuario
FROM dual;
```

Resultado obtenido durante la práctica:

| BASE_DATOS | SERVICIO | SERVIDOR | USUARIO |
|---|---|---|---|
| `FREEPDB1` | `freepdb1` | `oracle26ai` | `SYSTEM` |

Este resultado confirma todos los puntos relevantes:

- SQL Developer está ejecutándose en el host.
- El host alcanza la máquina virtual en la IP configurada.
- El listener Oracle acepta la conexión en el puerto 1521.
- La sesión se ha abierto contra el servicio correcto: `FREEPDB1`.
- La PDB está disponible y acepta consultas.
- El usuario `SYSTEM` se ha autenticado correctamente.

Guarda una captura de esta consulta y su resultado como evidencia de la práctica.

---

## 10. Errores comunes y soluciones

### 10.1. `Module javafx.base not found`

**Mensaje típico:**

```text
Error occurred during initialization of boot layer
java.lang.module.FindException: Module javafx.base not found
```

**Causa:** SQL Developer utiliza un JDK sin JavaFX disponible en el *module path*, o se ha seleccionado un JDK que no integra JavaFX.

**Solución aplicada:**

```bash
sudo apt install -y openjfx
```

Y en `ide/bin/launcher.sh`:

```bash
AddVMOption --module-path=/usr/share/openjfx/lib
AddVMOption --add-modules=javafx.controls,javafx.fxml,javafx.web,javafx.swing
```

Además, comprueba `SetJavaHome` en `sqldeveloper/bin/jdk.conf`:

```text
SetJavaHome /usr/lib/jvm/java-21-openjdk-amd64
```

---

### 10.2. `Unrecognized option: --module-path`

**Mensaje típico:**

```text
Unrecognized option: --module-path
Error: Could not create the Java Virtual Machine.
```

**Causa:** Las opciones se añadieron mediante `JAVA_TOOL_OPTIONS` o `_JAVA_OPTIONS`, pero SQL Developer terminó invocando otro Java que no entiende esa opción o procesó la variable antes de seleccionar el JDK adecuado.

**Qué no conviene mantener:**

```bash
export JAVA_TOOL_OPTIONS="--module-path ..."
```

Ni:

```bash
export _JAVA_OPTIONS="--module-path ..."
```

**Solución:** elimina esas variables del lanzador de usuario y añade los módulos con `AddVMOption` dentro de `launcher.sh`, tal como se indicó en la sección anterior.

---

### 10.3. Avisos `AddWindowsVM11OrHigherOption: orden no encontrada`

**Mensaje típico:**

```text
./jdk.conf: línea 74: AddWindowsVM11OrHigherOption: orden no encontrada
./java11.conf: línea 8: AddWindowsVM11OrHigherOption: orden no encontrada
```

**Causa:** El lanzador de Linux está leyendo líneas de configuración previstas para Windows o directivas no reconocidas por esa versión concreta del script.

**Impacto:** en esta práctica estos mensajes fueron advertencias; SQL Developer arrancó correctamente una vez configurado JavaFX.

**Acción recomendada:** no tocar estas líneas si la aplicación arranca y funciona. Si una versión futura no arrancara, revisa las notas de versión de SQL Developer y la configuración del launcher antes de eliminar directivas.

---

### 10.4. `ORA-12505`: SID no registrado

**Mensaje típico:**

```text
ORA-12505: No se puede conectar a la base de datos.
El SID xe no está registrado con el listener.
```

**Causa:** Se está solicitando un SID que el listener no conoce. En esta práctica se usó erróneamente `xe`, propio de entornos Oracle XE antiguos.

**Solución en SQL Developer:**

- Seleccionar **Nombre del Servicio**.
- Introducir `FREEPDB1`.
- Mantener host `192.168.122.54` y puerto `1521`.

Si el error ocurre incluso con `FREEPDB1`, ejecuta en la VM:

```bash
lsnrctl status
lsnrctl services
```

Y como `SYSDBA`:

```sql
SHOW PDBS;
SELECT name, open_mode FROM v$pdbs;
ALTER SYSTEM REGISTER;
```

`ALTER SYSTEM REGISTER` fuerza a la instancia a registrar sus servicios con el listener, cuando corresponde.

---

### 10.5. `ORA-12514`: servicio no conocido por el listener

**Causa posible:** La PDB no está abierta, el listener aún no conoce el servicio o se ha escrito un nombre de servicio incorrecto.

**Comprobación:**

```bash
lsnrctl services
```

**Solución en SQL*Plus como SYSDBA:**

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
ALTER SYSTEM REGISTER;
```

Después, vuelve a intentar la conexión con `FREEPDB1`.

---

### 10.6. SQL Developer no llega a la VM

**Síntoma:** tiempo de espera, `Network Adapter could not establish the connection`, `Connection refused` o fallo de prueba sin llegar a Oracle.

**Comprobaciones, en orden:**

```bash
# En el host
ping -c 3 192.168.122.54
nc -vz 192.168.122.54 1521
```

```bash
# En la VM
ip -br a
lsnrctl status
ss -ltnp | grep 1521
```

Si el puerto no está disponible desde el host:

- Comprueba el modo de red del hipervisor: NAT, bridge, red privada o reenvío de puertos.
- Confirma la IP actual de la VM; puede cambiar si recibe DHCP.
- Revisa el firewall de la VM.
- Comprueba que el listener está iniciado.

---

### 10.7. La PDB aparece cerrada después de reiniciar

Abre la PDB y guarda su estado:

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
```

Verifica después:

```sql
SHOW PDBS;
```

---

## 11. Buenas prácticas posteriores

### Crear un usuario de trabajo propio

`SYSTEM` se utilizó únicamente para comprobar que la instalación y la conectividad estaban bien. No es recomendable usarlo como cuenta de desarrollo diario.

Conéctate como `SYSTEM` a `FREEPDB1` y crea un usuario específico para las prácticas:

```sql
CREATE USER practica_user IDENTIFIED BY "Cambia_Esta_Clave_2026";

GRANT CREATE SESSION TO practica_user;
GRANT CREATE TABLE, CREATE SEQUENCE, CREATE VIEW TO practica_user;
ALTER USER practica_user QUOTA UNLIMITED ON USERS;
```

> Ajusta privilegios y cuota a la política del curso o del entorno. En producción aplica el principio de mínimo privilegio; no concedas más permisos de los necesarios.

### Guardar los datos de conexión

Registra para futuras prácticas:

```text
Host:           192.168.122.54
Puerto:         1521
Service name:   FREEPDB1
Servidor:       oracle26ai
Cliente:        SQL Developer 26.2.0
```

### Hacer copia de los cambios de SQL Developer

Si has personalizado estos ficheros:

```text
$HOME/Aplicaciones/sqldeveloper/sqldeveloper/bin/jdk.conf
$HOME/Aplicaciones/sqldeveloper/ide/bin/launcher.sh
~/.local/bin/sqldeveloper
```

haz una copia antes de actualizar SQL Developer:

```bash
mkdir -p ~/backup-sqldeveloper-config
cp "$HOME/Aplicaciones/sqldeveloper/sqldeveloper/bin/jdk.conf" ~/backup-sqldeveloper-config/
cp "$HOME/Aplicaciones/sqldeveloper/ide/bin/launcher.sh" ~/backup-sqldeveloper-config/
cp ~/.local/bin/sqldeveloper ~/backup-sqldeveloper-config/
```

---

## 12. Checklist final

Marca estos puntos antes de dar la práctica por terminada:

- [x] La VM está encendida y tiene IP accesible desde el host.
- [x] La IP de la VM es `192.168.122.54`.
- [x] El listener de Oracle escucha en el puerto TCP `1521`.
- [x] La PDB `FREEPDB1` está abierta.
- [x] SQL Developer se inicia en el host.
- [x] SQL Developer utiliza un JDK 17 o superior; en esta práctica, OpenJDK 21.
- [x] JavaFX está disponible para SQL Developer.
- [x] La conexión utiliza `Nombre del Servicio`, no el SID `xe`.
- [x] El nombre de servicio es `FREEPDB1`.
- [x] La prueba de conexión es correcta.
- [x] La consulta de validación devuelve `FREEPDB1`, `oracle26ai` y `SYSTEM`.

---

## Fuentes

[^oracle26ai]: Oracle, [Oracle AI Database Free Installation Guide, 26ai for Linux](https://docs.oracle.com/en/database/oracle/oracle-database/26/xeinl/index.html).
[^oracleconnect]: Oracle, [Connecting to Oracle Database Free](https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/connecting-oracle-database-free.html).
[^sqldev]: Oracle, [Oracle SQL Developer](https://docs.oracle.com/en/database/oracle/sql-developer/).
[^sqldevjdk]: Oracle, [SQL Developer System Recommendations](https://docs.oracle.com/en/database/oracle/sql-developer/26.2/rptig/sql-developer-system-recommendations.html).
[^sqldevinstall]: Oracle, [Installing and Starting SQL Developer](https://docs.oracle.com/en/database/oracle/sql-developer/26.2/rptig/installing-and-starting-sql-developer.html).
[^freepdb1]: Oracle, [Connecting to Oracle Database Free](https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinw/connecting-oracle-database-xe.html).
