---
title: "Práctica de router: SNAT y DNAT — Parte 1"
subject: "Servicios de Red e Internet"
description: "Configuración de un router para realizar traducción de direcciones mediante SNAT y DNAT."
date: 2026-09-24
tags:
  - Redes
  - Router
  - SNAT
  - DNAT
  - NAT
pdf: "servicios-de-red-e-internet/practica-router-snat-dnat-parte1.pdf"
---

# Práctica: Configuración de un router (SNAT, DNAT y DHCP)

> **Parte 1: configuración con direccionamiento estático**
>
> Este documento recoge una configuración completa para las máquinas y redes indicadas. No se usa `MASQUERADE`: se utiliza `SNAT` con la IP fija del router en la red NAT.

## Topología

| Máquina | Nombre/FQDN | Sistema | Red | Dirección IP |
|---|---|---|---|---|
| Router | `router.sergio.org` | Debian sin entorno gráfico | `br-nat` | DHCP/NAT (ejemplo: `192.168.105.2`) |
| Router | `router.sergio.org` | Debian sin entorno gráfico | `br-red1` | `10.10.10.2/24` |
| Router | `router.sergio.org` | Debian sin entorno gráfico | `br-red2` | `192.168.0.2/16` |
| Servidor web | `web.sergio.org` | Ubuntu Server | `br-red1` | `10.10.10.3/24` |
| Cliente 1 | `cliente1.sergio.org` | Fedora | `br-red2` | `192.168.0.3/16` |
| Cliente 2 | `cliente2.sergio.org` | Windows 11 | `br-red2` | `192.168.0.4/16` |

> Sustituye `sergio.org` por tu dominio si tu profesor pide otro formato. Las direcciones de `br-red1` y `br-red2` se han elegido de forma estática, como pide el enunciado.

## Redes virtuales

- **br-nat**: red NAT, conectada únicamente al router. Da salida a Internet y no tiene DHCP propio dentro de la práctica.
- **br-red1**: red aislada `/24`, sin DHCP. Conecta `router` y `web`.
- **br-red2**: red muy aislada `/16`. Conecta `router`, `cliente1` y `cliente2`.

## Router Debian

### Interfaces

Primero identifica los nombres reales de las interfaces:

```bash
ip -br addr
```

En este ejemplo se usan:

- `enp1s0`: `br-nat`
- `enp7s0`: `br-red1`
- `enp8s0`: `br-red2`

Edita `/etc/network/interfaces` como root:

```bash
sudo nano /etc/network/interfaces
```

Configuración de ejemplo:

```text
auto lo
iface lo inet loopback

# br-nat: obtiene conectividad exterior mediante la red NAT
auto enp1s0
iface enp1s0 inet dhcp

# br-red1: router - servidor web
auto enp7s0
iface enp7s0 inet static
    address 10.10.10.2/24

# br-red2: router - cliente1 - cliente2
auto enp8s0
iface enp8s0 inet static
    address 192.168.0.2/16
```

Aplica o reinicia el sistema:

```bash
sudo systemctl restart networking
```

Comprueba:

```bash
ip -br addr
ip route
ping -c 3 8.8.8.8
```

### FQDN

```bash
sudo hostnamectl set-hostname router.sergio.org
sudo nano /etc/hosts
```

Añade una línea como esta:

```text
127.0.1.1 router.sergio.org router
```

Comprueba:

```bash
hostnamectl
hostname -f
```

### Usuario con sudo sin contraseña

Crea el usuario si no existe:

```bash
sudo adduser sergio
```

Añádelo al grupo sudo:

```bash
sudo usermod -aG sudo sergio
```

Crea la regla de sudo sin contraseña:

```bash
sudo visudo -f /etc/sudoers.d/sergio
```

Contenido:

```text
sergio ALL=(ALL) NOPASSWD: ALL
```

Asegura permisos correctos:

```bash
sudo chmod 440 /etc/sudoers.d/sergio
```

Prueba con el usuario:

```bash
sudo -k
sudo whoami
```

Debe mostrar `root` sin pedir contraseña.

### Acceso SSH con clave pública

Instala y habilita OpenSSH:

```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
```

Desde el equipo desde el que administras, copia tu clave pública al router:

```bash
ssh-copy-id sergio@192.168.105.2
```

Comprueba:

```bash
ssh sergio@192.168.105.2
```

### Activar reenvío IPv4

Actívalo de forma persistente:

```bash
sudo tee /etc/sysctl.d/99-router.conf > /dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF
sudo sysctl --system
```

Comprueba:

```bash
sysctl net.ipv4.ip_forward
```

Debe mostrar `net.ipv4.ip_forward = 1`.

### Reglas SNAT sin MASQUERADE

La interfaz exterior es `enp1s0`. En la configuración usada durante la práctica tenía la IP `192.168.105.2`; esa es la IP que se usa en `--to-source`.

```bash
# Salida a Internet para br-red2
sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -o enp1s0 -j SNAT --to-source 192.168.105.2

# Salida a Internet para br-red1
sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp1s0 -j SNAT --to-source 192.168.105.2
```

Estas reglas cambian la IP de origen de los equipos internos por la IP exterior del router. Así las respuestas de Internet vuelven al router, que deshace la traducción y las entrega al equipo interno correcto. No se usa `MASQUERADE` porque se conoce y se utiliza una IP de origen concreta (`192.168.105.2`).

### Reglas FORWARD

```bash
# Permitir conexiones nuevas desde br-red1 y br-red2 hacia el exterior
sudo iptables -A FORWARD -i enp7s0 -o enp1s0 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -i enp8s0 -o enp1s0 -m conntrack --ctstate NEW -j ACCEPT

# Permitir el tráfico de respuesta desde el exterior hacia las redes internas
sudo iptables -A FORWARD -i enp1s0 -o enp7s0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i enp1s0 -o enp8s0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

### DNAT para el servidor web

El servidor web está en `10.10.10.3` y Apache escucha en el puerto 80. La siguiente regla redirige conexiones TCP que lleguen al puerto 80 del router desde la red exterior hacia el servidor web:

```bash
sudo iptables -t nat -A PREROUTING -i enp1s0 -p tcp --dport 80 -j DNAT --to-destination 10.10.10.3:80
```

Permite el paso del tráfico redirigido:

```bash
sudo iptables -A FORWARD -i enp1s0 -o enp7s0 -p tcp -d 10.10.10.3 --dport 80 -m conntrack --ctstate NEW -j ACCEPT
```

Comprobación de reglas:

```bash
sudo iptables -L -n -v --line-numbers
sudo iptables -t nat -L -n -v --line-numbers
```

En particular:

```bash
sudo iptables -t nat -L POSTROUTING -n -v --line-numbers
sudo iptables -t nat -L PREROUTING -n -v --line-numbers
```

### Persistencia de reglas iptables

Instala el paquete que guarda y restaura las reglas automáticamente:

```bash
sudo apt update
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent
```

Comprueba tras reiniciar:

```bash
sudo iptables -t nat -L -n -v
```

## Servidor web Ubuntu

### Configuración de red estática

Identifica la interfaz:

```bash
ip -br addr
```

Edita el archivo de Netplan, normalmente uno dentro de `/etc/netplan/`:

```bash
ls /etc/netplan/
sudo nano /etc/netplan/01-netcfg.yaml
```

Ejemplo usando `enp1s0`:

```yaml
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
        - 10.10.10.3/24
      routes:
        - to: default
          via: 10.10.10.2
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

Aplica la configuración:

```bash
sudo netplan apply
```

Comprueba:

```bash
ip addr show
ip route
ping -c 3 10.10.10.2
ping -c 3 8.8.8.8
ping -c 3 google.com
```

### FQDN y usuario

```bash
sudo hostnamectl set-hostname web.sergio.org
sudo nano /etc/hosts
```

Añade:

```text
127.0.1.1 web.sergio.org web
```

Crea el usuario y permite sudo sin contraseña:

```bash
sudo adduser sergio
sudo usermod -aG sudo sergio
sudo visudo -f /etc/sudoers.d/sergio
```

Contenido:

```text
sergio ALL=(ALL) NOPASSWD: ALL
```

```bash
sudo chmod 440 /etc/sudoers.d/sergio
```

### SSH con clave pública

```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
```

Desde el equipo administrador o desde el router usando agent forwarding:

```bash
ssh-copy-id sergio@10.10.10.3
```

### Apache

```bash
sudo apt update
sudo apt install apache2 -y
sudo systemctl enable --now apache2
```

Crea una página sencilla:

```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>www.sergio.org</title>
</head>
<body>
  <h1>Servidor web funcionando</h1>
  <p>Esta página está alojada en web.sergio.org.</p>
</body>
</html>
EOF
```

Comprobaciones:

```bash
curl -I http://localhost
curl http://10.10.10.3
```

## Cliente 1 Fedora

### Red estática con NetworkManager

Identifica la conexión y la interfaz:

```bash
nmcli connection show
ip -br addr
```

En este ejemplo, la conexión se llama `red-red2` y la interfaz es `enp1s0`:

```bash
sudo nmcli connection modify "red-red2" ipv4.method manual ipv4.addresses "192.168.0.3/16" ipv4.gateway "192.168.0.2"
sudo nmcli connection modify "red-red2" ipv4.dns "8.8.8.8 1.1.1.1"
sudo nmcli connection modify "red-red2" ipv4.ignore-auto-dns yes
sudo nmcli connection up "red-red2"
```

Comprueba red y DNS:

```bash
ip addr show
ip route show
resolvectl status
ping -c 3 192.168.0.2
ping -c 3 10.10.10.3
ping -c 3 8.8.8.8
ping -c 3 google.com
```

### FQDN, usuario y SSH

```bash
sudo hostnamectl set-hostname cliente1.sergio.org
sudo nano /etc/hosts
```

Añade:

```text
127.0.1.1 cliente1.sergio.org cliente1
```

```bash
sudo useradd -m -G wheel sergio
sudo passwd sergio
sudo visudo -f /etc/sudoers.d/sergio
```

Contenido:

```text
sergio ALL=(ALL) NOPASSWD: ALL
```

```bash
sudo chmod 440 /etc/sudoers.d/sergio
sudo dnf install openssh-server -y
sudo systemctl enable --now sshd
```

Desde el equipo administrador:

```bash
ssh-copy-id sergio@192.168.0.3
```

## Cliente 2 Windows 11

### Direccionamiento estático

Abre PowerShell como administrador. Primero muestra las interfaces:

```powershell
Get-NetIPConfiguration
```

Sustituye `<ID>` por el `InterfaceIndex` de la tarjeta conectada a `br-red2`:

```powershell
New-NetIPAddress -InterfaceIndex <ID> -IPAddress 192.168.0.4 -PrefixLength 16 -DefaultGateway 192.168.0.2
Set-DnsClientServerAddress -InterfaceIndex <ID> -ServerAddresses 8.8.8.8,1.1.1.1
```

Comprobaciones:

```powershell
ipconfig /all
ping 192.168.0.2
ping 10.10.10.3
ping 8.8.8.8
ping google.com
```

> Si ya hay una IP previa en esa interfaz, elimínala o configura la tarjeta desde las propiedades IPv4 antes de ejecutar `New-NetIPAddress`.

### Nombre de equipo y entrada de hosts

Para cambiar el nombre del equipo:

```powershell
Rename-Computer -NewName "cliente2" -Restart
```

Como Windows no usa FQDN de la misma manera sin un DNS o dominio configurado, se puede añadir la resolución estática requerida para la práctica en el fichero `hosts`. Abre PowerShell como administrador:

```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

Añade:

```text
192.168.0.2 router.sergio.org router
10.10.10.3 web.sergio.org web
192.168.105.2 www.sergio.org
192.168.0.3 cliente1.sergio.org cliente1
192.168.0.4 cliente2.sergio.org cliente2
```

## Resolución estática de nombres

Para acceder a la web desde el exterior y desde los equipos conectados a `br-red2`, `www.sergio.org` debe resolver a la IP exterior del router: `192.168.105.2`.

En Linux, edita `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Añade en `router`, `web` y `cliente1`:

```text
192.168.105.2 router.sergio.org router www.sergio.org
10.10.10.3 web.sergio.org web
192.168.0.3 cliente1.sergio.org cliente1
192.168.0.4 cliente2.sergio.org cliente2
```

En el equipo externo que se encuentre en `br-nat`, añade al archivo `/etc/hosts` o a su equivalente:

```text
192.168.105.2 www.sergio.org
```

Pruebas:

```bash
getent hosts www.sergio.org
curl -I http://www.sergio.org
```

En Windows:

```powershell
ping www.sergio.org
curl.exe -I http://www.sergio.org
```

## Acceso SSH usando ssh -A

Desde el equipo externo, conecta al router activando el reenvío del agente SSH:

```bash
ssh -A sergio@192.168.105.2
```

Una vez dentro del router, conecta a las máquinas internas sin copiar la clave privada al router:

```bash
ssh sergio@10.10.10.3
ssh sergio@192.168.0.3
```

Puedes comprobar que el agente está reenviado con:

```bash
ssh-add -l
```

`ssh -A` evita tener que guardar la clave privada en el router. La clave se mantiene en el equipo local y el router solo utiliza el agente SSH de forma temporal; si el router se compromete, la clave privada no queda almacenada allí para que puedan robarla.

## Comprobaciones para la entrega

### Conectividad entre redes

Desde `cliente1`:

```bash
ping -c 3 192.168.0.2
ping -c 3 10.10.10.3
ping -c 3 192.168.105.2
```

### FQDN

En cada máquina Linux:

```bash
hostname -f
```

Resultados esperados:

```text
router.sergio.org
web.sergio.org
cliente1.sergio.org
```

### Sudo sin contraseña

En cada máquina Linux, con el usuario creado:

```bash
sudo -k
sudo whoami
```

Debe responder `root` sin pedir contraseña.

### Internet y DNS

En `web` y `cliente1`:

```bash
ping -c 3 8.8.8.8
ping -c 3 google.com
curl -I https://example.com
```

En Windows:

```powershell
ping 8.8.8.8
ping google.com
curl.exe -I https://example.com
```

### Web mediante DNAT

Desde un equipo de `br-red2` y desde un equipo externo en `br-nat`:

```bash
curl -I http://www.sergio.org
```

También se puede probar directamente con:

```bash
curl -I http://192.168.105.2
```

### ¿Se puede acceder al servidor web desde el exterior sin acceder por el router?

No. El servidor web tiene una IP privada (`10.10.10.3`) dentro de `br-red1`, así que desde el exterior no se puede enrutar directamente hacia él. El tráfico llega primero a la IP exterior del router (`192.168.105.2`). La regla DNAT cambia el destino de las conexiones al puerto 80 y las manda a `10.10.10.3:80`:

```bash
sudo iptables -t nat -A PREROUTING -i enp1s0 -p tcp --dport 80 -j DNAT --to-destination 10.10.10.3:80
```

Por tanto, para acceder desde fuera siempre se pasa por el router; el router es quien redirige el tráfico hacia el servidor web interno.

## Ver reglas actuales

En el router:

```bash
sudo iptables -L -n -v --line-numbers
sudo iptables -t nat -L -n -v --line-numbers
```

Para ver solo las reglas SNAT:

```bash
sudo iptables -t nat -L POSTROUTING -n -v --line-numbers
```

Para ver solo la regla DNAT:

```bash
sudo iptables -t nat -L PREROUTING -n -v --line-numbers
```
