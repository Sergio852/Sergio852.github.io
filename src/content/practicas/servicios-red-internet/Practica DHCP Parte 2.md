---
title: "Práctica de router: SNAT, DNAT y DHCP — Parte 2"
subject: "Servicios de Red e Internet"
description: "Continuación de la configuración del router, con servicios de red y direccionamiento DHCP."
date: 2026-10-04
tags:
  - Redes
  - Router
  - DHCP
  - SNAT
  - DNAT
pdf: "servicios-red-internet/Practica DHCP Parte 2.pdf"
---

# Práctica: Configuración de un router (SNAT, DNAT y DHCP)

## Parte 2: DHCP, renovación de concesiones y cambios de red

## Introducción

En esta segunda parte se configura el router como servidor DHCP mediante Kea para la red muy aislada, se comprueba la configuración dinámica de los clientes y se realizan pruebas relacionadas con la renovación de concesiones. Posteriormente se crea un segundo ámbito DHCP para la red del servidor web, se configura una reserva DHCP y se adapta la interfaz pública del router para que use direccionamiento dinámico.

> **Nota:** se han incluido las salidas obtenidas durante la práctica. En los casos indicados, las salidas se han recortado para mostrar únicamente la información relevante.

## Tarea 1. Configuración del servidor DHCP

La configuración de Kea se realiza en el router. El fichero activo es `/etc/kea/kea-dhcp4.conf` y se guardó una copia de la configuración inicial para la entrega.

```bash
sergio@router:~$ sudo cat ~/kea-dhcp4-tarea1.conf
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "enp8s0" ]
    },
    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/kea-leases4.csv"
    },
    "valid-lifetime": 1800,
    "subnet4": [
      {
        "id": 1,
        "subnet": "192.168.0.0/16",
        "pools": [
          { "pool": "192.168.0.100 - 192.168.0.199" }
        ],
        "option-data": [
          { "name": "routers", "data": "192.168.0.2" },
          { "name": "domain-name-servers", "data": "192.168.105.1" },
          { "name": "broadcast-address", "data": "192.168.255.255" },
          {
            "name": "classless-static-route",
            "data": "0.0.0.0/0 - 192.168.0.2, 192.168.105.1/32 - 192.168.0.2"
          }
        ]
      }
    ]
  }
}
```

### Explicación de la configuración

- `interfaces-config`: Kea escucha en `enp8s0`, la interfaz del router conectada a la red de los clientes.
- `lease-database`: las concesiones se guardan en `/var/lib/kea/kea-leases4.csv`. Con `persist: true` se conservan al reiniciar el servicio.
- `valid-lifetime`: el tiempo de concesión inicial es de 1800 segundos, es decir, 30 minutos.
- `subnet4`: define la red `192.168.0.0/16`, con máscara `255.255.0.0`.
- `pools`: el servidor puede asignar direcciones entre `192.168.0.100` y `192.168.0.199`.
- `option-data`: además de una dirección IP, los clientes reciben puerta de enlace, DNS y dirección de broadcast.
- `classless-static-route`: comunica que la ruta por defecto y la ruta específica hacia el DNS `192.168.105.1` pasan por el router `192.168.0.2`. La ruta específica es necesaria porque con una máscara `/16` los clientes considerarían `192.168.105.1` como una dirección de su propia red, cuando realmente se alcanza a través del router.

El cliente Fedora recibió `192.168.0.100/16`, dentro del pool configurado.

## Tarea 2. Configuración dinámica de los clientes

### Cliente 2: Windows

Se cambió el direccionamiento estático a dinámico mediante `sconfig`. El servidor DHCP concedió la dirección `192.168.0.101`:

```text
sergio@CLIENTE2 C:\Users\sergio>ipconfig

Configuración IP de Windows


Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Puerta de enlace predeterminada . . . . . : 192.168.0.2
```

### Cliente 1: Fedora

En Fedora se cambió la configuración de estática a dinámica y se habilitó la aceptación del DNS recibido por DHCP:

```text
[sergio@cliente1 ~]$ ip a show enp1s0
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:56:d7:11 brd ff:ff:ff:ff:ff:ff
    altname enx52540056d711
    inet 192.168.0.100/16 brd 192.168.255.255 scope global dynamic noprefixroute enp1s0
       valid_lft 1141sec preferred_lft 1141sec
    inet6 fe80::5813:c483:186e:6ba0/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
[sergio@cliente1 ~]$ ip route
default via 192.168.0.2 dev enp1s0 proto dhcp src 192.168.0.100 metric 100 
192.168.0.0/16 dev enp1s0 proto kernel scope link src 192.168.0.100 metric 100 
192.168.105.1 via 192.168.0.2 dev enp1s0 proto dhcp src 192.168.0.100 metric 100 
[sergio@cliente1 ~]$ resolvectl status enp1s0
Link 2 (enp1s0)
    Current Scopes: DNS LLMNR/IPv4 LLMNR/IPv6
         Protocols: +DefaultRoute LLMNR=resolve -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.105.1
       DNS Servers: 192.168.105.1
     Default Route: yes
[sergio@cliente1 ~]$ 
```

Fedora recibió la dirección `192.168.0.100/16`, puerta de enlace `192.168.0.2`, DNS `192.168.105.1` y la ruta específica hacia dicho DNS mediante el router.

### Lista de concesiones

```text
sergio@router:~$ sudo column -s , -t /var/lib/kea/kea-leases4.csv
address        hwaddr             client_id             valid_lifetime  expire      subnet_id  fqdn_fwd  fqdn_rev  hostname              state  user_context  pool_id
192.168.0.100  52:54:00:56:d7:11  01:52:54:00:56:d7:11  1800            1790611332  1          0         0         cliente1              0                    0
192.168.0.101  52:54:00:71:b3:f8  01:52:54:00:71:b3:f8  1800            1790611498  1          0         0         cliente2.sergio.org.  0                    0
192.168.0.100  52:54:00:56:d7:11  01:52:54:00:56:d7:11  1800            1790612232  1          0         0         cliente1              0                    0
192.168.0.100  52:54:00:56:d7:11  01:52:54:00:56:d7:11  1800            1790612388  1          0         0         cliente1              0                    0
192.168.0.101  52:54:00:71:b3:f8  01:52:54:00:71:b3:f8  1800            1790612398  1          0         0         cliente2.sergio.org.  0                    0
192.168.0.101  52:54:00:71:b3:f8  01:52:54:00:71:b3:f8  1800            1790612455  1          0         0         cliente2.sergio.org.  0                    0
192.168.0.100  52:54:00:56:d7:11  01:52:54:00:56:d7:11  1800            1790613288  1          0         0         cliente1              0                    0
192.168.0.101  52:54:00:71:b3:f8  01:52:54:00:71:b3:f8  1800            1790613355  1          0         0         cliente2.sergio.org.  0                    0
192.168.0.100  52:54:00:56:d7:11  01:52:54:00:56:d7:11  1800            1790614188  1          0         0         cliente1              0                    0
192.168.0.101  52:54:00:71:b3:f8  01:52:54:00:71:b3:f8  1800            1790614255  1          0         0         cliente2.sergio.org.  0                    0
sergio@router:~$ 
```

El fichero de concesiones contiene varias entradas porque guarda eventos de creación y renovación de concesiones. También contiene registros obtenidos durante pruebas previas. No obstante, se observa claramente que `cliente1` recibe `192.168.0.100` y `cliente2` recibe `192.168.0.101`.

## Comunicación entre clientes

### Windows a Fedora

```text
PS C:\Users\sergio> ping cliente1

Haciendo ping a cliente1 [192.168.0.100] con 32 bytes de datos:
Respuesta desde 192.168.0.100: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.0.100: bytes=32 tiempo=1ms TTL=64
Respuesta desde 192.168.0.100: bytes=32 tiempo=1ms TTL=64

Estadísticas de ping para 192.168.0.100:
    Paquetes: enviados = 3, recibidos = 3, perdidos = 0
    (0% perdidos),
Tiempos aproximados de ida y vuelta en milisegundos:
    Mínimo = 0ms, Máximo = 1ms, Media = 0ms
Control-C
PS C:\Users\sergio> 
```

### Fedora a Windows

```text
[sergio@cliente1 ~]$ ping -c 3 cliente2
PING cliente2.sergio.org (192.168.0.101) 56(84) bytes de datos.
64 bytes desde cliente2.sergio.org (192.168.0.101): icmp_seq=1 ttl=128 tiempo=0.808 ms
64 bytes desde cliente2.sergio.org (192.168.0.101): icmp_seq=2 ttl=128 tiempo=0.890 ms
64 bytes desde cliente2.sergio.org (192.168.0.101): icmp_seq=3 ttl=128 tiempo=1.15 ms
```

Las dos pruebas demuestran la conectividad entre las máquinas de la red muy aislada y la resolución de nombres.

## Tarea 3. Conectividad exterior

### Cliente 2: Windows

```text
PS C:\Users\sergio> ping www.marca.com

Haciendo ping a unidadeditorial.map.fastly.net [199.232.197.50] con 32 bytes de datos:
Respuesta desde 199.232.197.50: bytes=32 tiempo=12ms TTL=55
Respuesta desde 199.232.197.50: bytes=32 tiempo=12ms TTL=55
Respuesta desde 199.232.197.50: bytes=32 tiempo=16ms TTL=55
```

### Cliente 1: Fedora

```text
[sergio@cliente1 ~]$ ping www.youtube.com
PING www.youtube.com (142.251.155.4) 56(84) bytes de datos.
64 bytes desde 142.251.155.4: icmp_seq=1 ttl=114 tiempo=12.2 ms
64 bytes desde 142.251.155.4: icmp_seq=2 ttl=114 tiempo=12.1 ms
64 bytes desde 142.251.155.4: icmp_seq=3 ttl=114 tiempo=16.8 ms
```

Ambos clientes resuelven nombres y tienen conectividad con el exterior a través del router.

## Tareas 4 y 5. Comportamiento de las concesiones DHCP

Para realizar las pruebas en un tiempo reducido se modificó temporalmente `valid-lifetime` a 120 segundos. Al finalizar, se restauró el valor habitual de 1800 segundos.

```json
"valid-lifetime": 120,
```

La configuración se aplicó reiniciando Kea:

```text
sergio@router:~$ sudo systemctl restart kea-dhcp4-server
```

### Tarea 4. El servidor DHCP deja de funcionar

#### Obtención de una concesión nueva

Con Kea activo se renovó la configuración de Windows:

```text
PS C:\Users\sergio> ipconfig /renew

Configuración IP de Windows


Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Puerta de enlace predeterminada . . . . . : 192.168.0.2
```

Se muestran las líneas relevantes de `ipconfig /all`:

```text
PS C:\Users\sergio> ipconfig /all
   Concesión obtenida. . . . . . . . . . . . : lunes, 28 de septiembre de 2026 17:04:58
   La concesión expira . . . . . . . . . . . : lunes, 28 de septiembre de 2026 19:06:54
```

En Fedora se renovó la dirección desconectando y conectando la interfaz:

```text
[sergio@cliente1 ~]$ sudo nmcli device disconnect enp1s0
El dispositivo «enp1s0» ha sido desconectado correctamente.
[sergio@cliente1 ~]$ sudo nmcli device connect enp1s0
[sergio@cliente1 ~]$ ip -4 addr show enp1s0
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    altname enx52540056d711
    inet 192.168.0.100/16 brd 192.168.255.255 scope global dynamic noprefixroute enp1s0
       valid_lft 110sec preferred_lft 110sec
[sergio@cliente1 ~]$ 
```

La salida exacta de la renovación no se pudo conservar porque al desconectar la interfaz se interrumpió la sesión SSH.

#### Detención del servicio

Una vez que los clientes tenían concesiones activas, se detuvo únicamente el servidor DHCP. El router continuó funcionando como encaminador, para no alterar la conectividad de la prueba.

```text
sergio@router:~$ sudo systemctl stop kea-dhcp4-server
```

#### Clientes mientras la concesión era válida

En Windows, la dirección seguía siendo válida y el router respondía al ping:

```text
PS C:\Users\sergio> ipconfig /all

Configuración IP de Windows

   Nombre de host. . . . . . . . . : cliente2
   Sufijo DNS principal  . . . . . : sergio.org
   Tipo de nodo. . . . . . . . . . : híbrido
   Enrutamiento IP habilitado. . . : no
   Proxy WINS habilitado . . . . . : no
   Lista de búsqueda de sufijos DNS: sergio.org

Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Descripción . . . . . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection
   Dirección física. . . . . . . . . . . . . : 52-54-00-71-B3-F8
   DHCP habilitado . . . . . . . . . . . . . : sí
   Configuración automática habilitada . . . : sí
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4(Preferido)
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101(Preferido)
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Concesión obtenida. . . . . . . . . . . . : lunes, 28 de septiembre de 2026 17:04:58
   La concesión expira . . . . . . . . . . . : lunes, 28 de septiembre de 2026 19:15:52
   Puerta de enlace predeterminada . . . . . : 192.168.0.2
   Servidor DHCP . . . . . . . . . . . . . . : 192.168.0.2
   IAID DHCPv6 . . . . . . . . . . . . . . . : 89281536
   DUID de cliente DHCPv6. . . . . . . . . . : 00-01-01-00-32-45-A0-A2-52-54-00-71-B3-F8
   Servidores DNS. . . . . . . . . . . . . . : 8.8.8.8
                                       1.1.1.1
   NetBIOS sobre TCP/IP. . . . . . : habilitado
PS C:\Users\sergio> ping 192.168.0.2

Haciendo ping a 192.168.0.2 con 32 bytes de datos:
Respuesta desde 192.168.0.2: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.0.2: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.0.2: 
Estadísticas de ping para 192.168.0.2:
    Paquetes: enviados = 3, recibidos = 2, perdidos = 1
    (33% perdidos),
Tiempos aproximados de ida y vuelta en milisegundos:
    Mínimo = 0ms, Máximo = 0ms, Media = 0ms
bytes=32 Control-C
PS C:\Users\sergio> 
```

En Fedora, la concesión seguía vigente durante los segundos que indicaba `valid_lft`, y se mantenía la conectividad con el router:

```text
[sergio@cliente1 ~]$ ip -4 addr show enp1s0
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    altname enx52540056d711
    inet 192.168.0.100/16 brd 192.168.255.255 scope global dynamic noprefixroute enp1s0
       valid_lft 20sec preferred_lft 20sec
[sergio@cliente1 ~]$ ping -c 2 192.168.0.2
PING 192.168.0.2 (192.168.0.2) 56(84) bytes de datos.
64 bytes desde 192.168.0.2: icmp_seq=1 ttl=64 tiempo=0.372 ms
64 bytes desde 192.168.0.2: icmp_seq=2 ttl=64 tiempo=0.523 ms

--- 192.168.0.2 estadísticas ping ---
2 paquetes transmitidos, 2 recibidos, 0% packet loss, time 1021ms
rtt min/avg/max/mdev = 0.372/0.447/0.523/0.075 ms
[sergio@cliente1 ~]$ 
```

#### Intentos de renovación y vencimiento

En otra consola del router se capturó el tráfico DHCP de la interfaz conectada a la red aislada:

```text
sergio@router:~$ sudo tcpdump -ni enp8s0 'udp port 67 or udp port 68'
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp8s0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
19:22:27.504101 IP 192.168.0.101.68 > 192.168.0.2.67: BOOTP/DHCP, Request from 52:54:00:71:b3:f8, length 313
19:22:28.512220 IP 192.168.0.101.68 > 192.168.0.2.67: BOOTP/DHCP, Request from 52:54:00:71:b3:f8, length 313
19:22:31.512831 IP 192.168.0.101.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 52:54:00:71:b3:f8, length 313
19:22:35.380975 IP 192.168.0.100.68 > 192.168.0.2.67: BOOTP/DHCP, Request from 52:54:00:56:d7:11, length 286
```

La captura muestra peticiones DHCP de ambos clientes sin que exista respuesta del servidor, ya que el servicio Kea estaba detenido. Una concesión válida no se elimina de forma inmediata al detener el servidor. Los clientes siguen usando sus parámetros mientras no expire la concesión; al intentar renovarla no reciben respuesta. Si finalmente vence sin renovación, dejan de poder utilizarla. En la prueba, Windows terminó utilizando una dirección APIPA y Fedora perdió la dirección DHCP.

Antes de la siguiente prueba se inició de nuevo Kea:

```text
sergio@router:~$ sudo systemctl start kea-dhcp4-server
```

### Tarea 5. Cambio de configuración DHCP con concesiones activas

Para esta prueba se mantuvo Kea encendido y se cambió temporalmente la opción DNS. Se eligió este cambio porque renovar una concesión no obliga necesariamente a cambiar de dirección IP, mientras que el DNS permite comprobar claramente la recepción de una nueva opción DHCP.

#### Configuración inicial

En Windows se corrigió el DNS estático y se solicitó una renovación:

```text
sergio@CLIENTE2 C:\Users\sergio>netsh interface ipv4 set dnsservers name="Ethernet" source=dhcp
sergio@CLIENTE2 C:\Users\sergio>ipconfig /renew
sergio@CLIENTE2 C:\Users\sergio>ipconfig /all
Servidores DNS. . . . . . . . . . . . . . : 192.168.105.1
```

En Fedora, antes del cambio, el DNS recibido por DHCP era `192.168.105.1`:

```text
[sergio@cliente1 ~]$ nmcli -f IP4 device show enp1s0
IP4.ADDRESS[1]:                         192.168.0.100/16
IP4.GATEWAY:                            192.168.0.2
IP4.ROUTE[1]:                           dst = 192.168.0.0/16, nh = 0.0.0.0, mt = 100
IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.0.2, mt = 100
IP4.ROUTE[3]:                           dst = 192.168.105.1/32, nh = 192.168.0.2, mt = 100
IP4.DNS[1]:                             192.168.105.1
[sergio@cliente1 ~]$ 
```

#### Cambio en Kea

Se modificó temporalmente la opción `domain-name-servers`:

```json
{ "name": "domain-name-servers", "data": "8.8.8.8" },
```

Y se reinició Kea para aplicar el cambio:

```text
sergio@router:~$ sudo systemctl restart kea-dhcp4-server
```

#### Clientes antes de renovar

Después de modificar el servidor, los clientes conservaron sus datos previamente recibidos hasta solicitar otra configuración. Windows aún mostraba el DNS anterior:

```text
sergio@CLIENTE2 C:\Users\sergio>ipconfig /all

Configuración IP de Windows

   Nombre de host. . . . . . . . . : cliente2
   Sufijo DNS principal  . . . . . : sergio.org
   Tipo de nodo. . . . . . . . . . : híbrido
   Enrutamiento IP habilitado. . . : no
   Proxy WINS habilitado . . . . . : no
   Lista de búsqueda de sufijos DNS: sergio.org

Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Descripción . . . . . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection
   Dirección física. . . . . . . . . . . . . : 52-54-00-71-B3-F8
   DHCP habilitado . . . . . . . . . . . . . : sí
   Configuración automática habilitada . . . : sí
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4(Preferido) 
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101(Preferido) 
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Concesión obtenida. . . . . . . . . . . . : lunes, 28 de septiembre de 2026 19:34:10
   La concesión expira . . . . . . . . . . . : lunes, 28 de septiembre de 2026 20:18:00
   Puerta de enlace predeterminada . . . . . : 192.168.0.2
   Servidor DHCP . . . . . . . . . . . . . . : 192.168.0.2
   IAID DHCPv6 . . . . . . . . . . . . . . . : 89281536
   DUID de cliente DHCPv6. . . . . . . . . . : 00-01-01-00-32-45-A0-A2-52-54-00-71-B3-F8
   Servidores DNS. . . . . . . . . . . . . . : 192.168.105.1
   NetBIOS sobre TCP/IP. . . . . . : habilitado

sergio@CLIENTE2 C:\Users\sergio>
```

Fedora también conservaba la configuración anterior:

```text
[sergio@cliente1 ~]$ nmcli -f IP4 device show enp1s0
IP4.ADDRESS[1]:                         192.168.0.100/16
IP4.GATEWAY:                            192.168.0.2
IP4.ROUTE[1]:                           dst = 192.168.0.0/16, nh = 0.0.0.0, mt = 100
IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.0.2, mt = 100
IP4.ROUTE[3]:                           dst = 192.168.105.1/32, nh = 192.168.0.2, mt = 100
IP4.DNS[1]:                             192.168.105.1
[sergio@cliente1 ~]$ 
```

#### Clientes después de renovar

Tras renovar Windows, recibió la nueva opción DNS sin cambiar su IP:

```text
sergio@CLIENTE2 C:\Users\sergio>ipconfig /renew

Configuración IP de Windows


Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Puerta de enlace predeterminada . . . . . : 192.168.0.2

sergio@CLIENTE2 C:\Users\sergio>ipconfig /all

Configuración IP de Windows

   Nombre de host. . . . . . . . . : cliente2
   Sufijo DNS principal  . . . . . : sergio.org
   Tipo de nodo. . . . . . . . . . : híbrido
   Enrutamiento IP habilitado. . . : no
   Proxy WINS habilitado . . . . . : no
   Lista de búsqueda de sufijos DNS: sergio.org

Adaptador de Ethernet Ethernet:

   Sufijo DNS específico para la conexión. . : sergio.org
   Descripción . . . . . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection
   Dirección física. . . . . . . . . . . . . : 52-54-00-71-B3-F8
   DHCP habilitado . . . . . . . . . . . . . : sí
   Configuración automática habilitada . . . : sí
   Vínculo: dirección IPv6 local. . . : fe80::b7e7:7c63:7526:cf3d%4(Preferido)
   Dirección IPv4. . . . . . . . . . . . . . : 192.168.0.101(Preferido) 
   Máscara de subred . . . . . . . . . . . . : 255.255.0.0
   Concesión obtenida. . . . . . . . . . . . : lunes, 28 de septiembre de 2026 19:34:10
   La concesión expira . . . . . . . . . . . : lunes, 28 de septiembre de 2026 20:32:48
   Puerta de enlace predeterminada . . . . . : 192.168.0.2
   Servidor DHCP . . . . . . . . . . . . . . : 192.168.0.2
   IAID DHCPv6 . . . . . . . . . . . . . . . : 89281536
   DUID de cliente DHCPv6. . . . . . . . . . : 00-01-01-00-32-45-A0-A2-52-54-00-71-B3-F8
   Servidores DNS. . . . . . . . . . . . . . : 8.8.8.8
   NetBIOS sobre TCP/IP. . . . . . : habilitado
```

Fedora recibió también el DNS `8.8.8.8`:

```text
[sergio@cliente1 ~]$ nmcli -f IP4 device show enp1s0
IP4.ADDRESS[1]:                         192.168.0.100/16
IP4.GATEWAY:                            192.168.0.2
IP4.ROUTE[1]:                           dst = 192.168.0.0/16, nh = 0.0.0.0, mt = 100
IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.0.2, mt = 100
IP4.ROUTE[3]:                           dst = 192.168.105.1/32, nh = 192.168.0.2, mt = 100
IP4.DNS[1]:                             8.8.8.8
[sergio@cliente1 ~]$ 
```

La modificación en el servidor no actualiza de manera inmediata una configuración ya recibida por un cliente. Al renovar la concesión, los clientes reciben las nuevas opciones DHCP. Por eso se compara el DNS antes del cambio, después del cambio sin renovar y después de la renovación.

Al finalizar estas pruebas se restauraron el DNS y el tiempo de concesión de la configuración habitual.

## Tareas 6, 7 y 8. Nuevo ámbito DHCP y reserva para servidorWeb

Se añadió un segundo ámbito DHCP para la red aislada `10.10.10.0/24`. La configuración incluye una reserva para que `servidorWeb` reciba mediante DHCP la dirección `10.10.10.3`.

```text
sergio@router:~$ sudo cat /etc/kea/kea-dhcp4.conf
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "enp8s0", "enp7s0" ]
    },
    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/kea-leases4.csv"
    },
    "valid-lifetime": 1800,
    "subnet4": [
      {
        "id": 1,
        "subnet": "192.168.0.0/16",
        "pools": [
          { "pool": "192.168.0.100 - 192.168.0.199" }
        ],
        "option-data": [
          { "name": "routers", "data": "192.168.0.2" },
          { "name": "domain-name-servers", "data": "8.8.8.8" },
          { "name": "broadcast-address", "data": "192.168.255.255" },
          {
            "name": "classless-static-route",
            "data": "0.0.0.0/0 - 192.168.0.2, 192.168.105.1/32 - 192.168.0.2"
          }
        ]
      },
      {
        "id": 2,
        "subnet": "10.10.10.0/24",
        "pools": [
          { "pool": "10.10.10.100 - 10.10.10.199" }
        ],
        "valid-lifetime": 86400,
        "option-data": [
          { "name": "routers", "data": "10.10.10.2" },
          { "name": "domain-name-servers", "data": "8.8.8.8" },
          { "name": "broadcast-address", "data": "10.10.10.255" }
        ],
        "reservations": [
          {
            "hw-address": "52:54:00:fc:59:a0",
            "ip-address": "10.10.10.3",
            "hostname": "servidorWeb"
          }
        ]
      }
    ]
  }
}
```

### Parámetros añadidos

- `enp7s0`: interfaz del router conectada a la red aislada del servidor web. Se añade sin eliminar `enp8s0`, que continúa atendiendo la red de clientes.
- `id: 2` y `subnet: 10.10.10.0/24`: identifican el nuevo ámbito DHCP.
- `pools`: define el rango dinámico `10.10.10.100 - 10.10.10.199`. La IP reservada `10.10.10.3` queda fuera de este pool.
- `valid-lifetime: 86400`: establece concesiones de 24 horas para este ámbito. El primer ámbito conserva la concesión global de 1800 segundos.
- `routers`: entrega `10.10.10.2` como puerta de enlace.
- `domain-name-servers`: entrega `8.8.8.8` como DNS.
- `broadcast-address`: entrega `10.10.10.255` como dirección de difusión.
- `reservations`: asocia la MAC `52:54:00:fc:59:a0` de `servidorWeb` con `10.10.10.3`, manteniendo la dirección por la que se accede al servidor web.

La configuración se aplicó reiniciando Kea:

```text
sergio@router:~$ sudo systemctl restart kea-dhcp4-server
```

### Configuración DHCP de servidorWeb

Se cambió la configuración de red estática del servidor web a DHCP:

```text
sergio@web:~$ sudo cat /etc/netplan/*.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: true
```

Después de aplicar Netplan, el servidor recibió la dirección reservada:

```text
sergio@web:~$ sudo netplan apply
sergio@web:~$ ip -br -4 addr
lo               UNKNOWN        127.0.0.1/8 
enp1s0           UP             10.10.10.3/24 metric 100 
sergio@web:~$ ip route
default via 10.10.10.2 dev enp1s0 proto dhcp src 10.10.10.3 metric 100 
8.8.8.8 via 10.10.10.2 dev enp1s0 proto dhcp src 10.10.10.3 metric 100 
10.10.10.0/24 dev enp1s0 proto kernel scope link src 10.10.10.3 metric 100 
10.10.10.2 dev enp1s0 proto dhcp scope link src 10.10.10.3 metric 100 
sergio@web:~$ 
```

### Comprobación HTTP desde distintas redes

#### Exterior

```text
sergio@Sergio-PC:~$ curl web.sergio.org
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Mi web</title>
</head>
<body>
  <h1>Hola, esto es mi servidor web en Ubuntu</h1>
  <p>Si ves esto, funciona.</p>
</body>
</html>
sergio@Sergio-PC:~$ curl 192.168.105.2
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Mi web</title>
</head>
<body>
  <h1>Hola, esto es mi servidor web en Ubuntu</h1>
  <p>Si ves esto, funciona.</p>
</body>
</html>
```

#### Cliente 1

```text
[sergio@cliente1 ~]$ curl web.sergio.org
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Mi web</title>
</head>
<body>
  <h1>Hola, esto es mi servidor web en Ubuntu</h1>
  <p>Si ves esto, funciona.</p>
</body>
</html>
[sergio@cliente1 ~]$ 
```

#### Cliente 2

```text
PS C:\Users\sergio> curl.exe http://web.sergio.org/ 
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Mi web</title>
</head>
<body>
  <h1>Hola, esto es mi servidor web en Ubuntu</h1>
  <p>Si ves esto, funciona.</p>
</body>
</html>
PS C:\Users\sergio> 
```

Se mantiene el acceso HTTP desde el exterior mediante el router y desde ambos clientes internos.

## Tarea 9. Interfaz pública del router con DHCP

La interfaz exterior del router es `enp1s0`. Inicialmente estaba conectada a la red `br-nat` y tenía configuración fija `192.168.105.2/24` con puerta de enlace `192.168.105.1`. Para usar direccionamiento dinámico, se conectó la interfaz a la red NAT `default` de libvirt y se actualizó `/etc/network/interfaces`.

### Cambio de red en libvirt

La interfaz exterior se identificó por la MAC `52:54:00:07:d2:2a`. En la definición de la máquina virtual `debian1`, esa interfaz se cambió de `br-nat` a `default`; las redes internas permanecieron conectadas a `br-red1` y `br-red2`.

```text
sergio@Sergio-PC:~$ virsh domiflist debian1
 Interfaz   Tipo      Fuente    Modelo   MAC
------------------------------------------------------------
 vnet0      network   br-nat    virtio   52:54:00:07:d2:2a
 vnet1      network   br-red1   virtio   52:54:00:c7:0e:84
 vnet2      network   br-red2   virtio   52:54:00:ca:b0:1f

sergio@Sergio-PC:~$ virsh shutdown debian1
sergio@Sergio-PC:~$ virsh list --all
Domain 'debian1' is being shutdown

 Id   Nombre            Estado
------------------------------------
 1    debian1           ejecutando
 2    fedora-cliente1   ejecutando
 3    ubuntu25.10       ejecutando
 4    win11-cliente2    ejecutando
 -    debian13          apagado

sergio@Sergio-PC:~$ virsh list --all
 Id   Nombre            Estado
------------------------------------
 2    fedora-cliente1   ejecutando
 3    ubuntu25.10       ejecutando
 4    win11-cliente2    ejecutando
 -    debian1           apagado
 -    debian13          apagado

sergio@Sergio-PC:~$ virsh edit debian1
Select an editor.  To change later, run select-editor again.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.tiny

Choose 1-2 [1]: 1
Domain 'debian1' XML configuration edited.

sergio@Sergio-PC:~$ virsh domiflist debian1
 Interfaz   Tipo      Fuente    Modelo   MAC
------------------------------------------------------------
 -          network   default   virtio   52:54:00:07:d2:2a
 -          network   br-red1   virtio   52:54:00:c7:0e:84
 -          network   br-red2   virtio   52:54:00:ca:b0:1f

sergio@Sergio-PC:~$ virsh start debian1
Domain 'debian1' started
```

### Configuración de interfaces del router

En `/etc/network/interfaces` se sustituyó la configuración fija de `enp1s0` por DHCP:

```text
sergio@router:~$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

auto enp1s0
allow-hotplug enp1s0
iface enp1s0 inet dhcp
auto enp7s0
allow-hotplug enp7s0
iface enp7s0 inet static
address 10.10.10.2
netmask 255.255.255.0

auto enp8s0
allow-hotplug enp8s0
iface enp8s0 inet static
address 192.168.0.2
netmask 255.255.0.0
sergio@router:~$ 
```

La interfaz pública recibió `192.168.122.56/24` por DHCP. Las interfaces internas se mantuvieron en `10.10.10.2/24` y `192.168.0.2/16`.

Tabla de rutas del router:

```text
sergio@router:~$ ip route
default via 192.168.122.1 dev enp1s0 proto dhcp src 192.168.122.56 metric 1002 
10.10.10.0/24 dev enp7s0 proto kernel scope link src 10.10.10.2 
192.168.0.0/16 dev enp8s0 proto kernel scope link src 192.168.0.2 
192.168.122.0/24 dev enp1s0 proto dhcp scope link src 192.168.122.56 metric 1002 
sergio@router:~$ 
```

La tabla contiene una única ruta por defecto recibida por DHCP a través de `enp1s0`, con puerta de enlace `192.168.122.1`.

## Tarea 10. Reglas SNAT/MASQUERADE y DNAT

Antes del cambio, las reglas de SNAT usaban la antigua dirección pública estática `192.168.105.2`:

```text
sergio@router:~$ sudo iptables -t nat -S POSTROUTING
-P POSTROUTING ACCEPT
-A POSTROUTING -s 192.168.0.0/16 -o enp1s0 -j SNAT --to-source 192.168.105.2
-A POSTROUTING -s 10.10.10.0/24 -o enp1s0 -j SNAT --to-source 192.168.105.2
sergio@router:~$ 
```

Al recibir una IP pública dinámica, se eliminaron las reglas SNAT estáticas y se sustituyeron por `MASQUERADE`, que utiliza automáticamente la dirección vigente de la interfaz de salida:

```text
sergio@router:~$ sudo iptables -t nat -D POSTROUTING -s 192.168.0.0/16 -o enp1s0 -j SNAT --to-source 192.168.105.2
sergio@router:~$ sudo iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o enp1s0 -j SNAT --to-source 192.168.105.2
sergio@router:~$ sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -o enp1s0 -j MASQUERADE
sergio@router:~$ sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp1s0 -j MASQUERADE
sergio@router:~$ sudo iptables -t nat -S POSTROUTING
-P POSTROUTING ACCEPT
-A POSTROUTING -s 192.168.0.0/16 -o enp1s0 -j MASQUERADE
-A POSTROUTING -s 10.10.10.0/24 -o enp1s0 -j MASQUERADE
sergio@router:~$ 
```

Las reglas se hicieron persistentes:

```text
sergio@router:~$ sudo netfilter-persistent save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/15-ip4tables save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/25-ip6tables save
```

También se actualizó la regla DNAT del servicio web, sustituyendo la antigua IP pública por la dirección recibida mediante DHCP:

```text
sergio@router:~$ sudo iptables -t nat -D PREROUTING -i enp1s0 -d 192.168.105.2 -p tcp --dport 80 -j DNAT --to-destination 10.10.10.3:80
sergio@router:~$ sudo iptables -t nat -A PREROUTING -i enp1s0 -d 192.168.122.56 -p tcp --dport 80 -j DNAT --to-destination 10.10.10.3:80
```

La modificación se guardó de nuevo:

```text
sergio@router:~$ sudo netfilter-persistent save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/15-ip4tables save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/25-ip6tables save
```

## Comprobación final de conectividad exterior

Para las dos redes se configuró la opción `domain-name-servers` de Kea con `192.168.122.1`, el DNS accesible desde la red `default` de libvirt.

### Cliente 1

```text
[sergio@cliente1 ~]$ ping google.com
PING google.com (216.58.205.46) 56(84) bytes de datos.
64 bytes desde lcmadb-ae-in-f14.1e100.net (216.58.205.46): icmp_seq=1 ttl=114 tiempo=12.2 ms
64 bytes desde lcmadb-ae-in-f14.1e100.net (216.58.205.46): icmp_seq=2 ttl=114 tiempo=17.3 ms
64 bytes desde lcmadb-ae-in-f14.1e100.net (216.58.205.46): icmp_seq=3 ttl=114 tiempo=13.5 ms
64 bytes desde lcmadb-ae-in-f14.1e100.net (216.58.205.46): icmp_seq=4 ttl=114 tiempo=20.4 ms
```

### Cliente 2

```text
sergio@CLIENTE2 C:\Users\sergio>ping 8.8.8.8 

Haciendo ping a 8.8.8.8 con 32 bytes de datos:
Respuesta desde 8.8.8.8: bytes=32 tiempo=17ms TTL=113
Respuesta desde 8.8.8.8: bytes=32 tiempo=13ms TTL=113
Respuesta desde 8.8.8.8: bytes=32 tiempo=15ms TTL=113

Estadísticas de ping para 8.8.8.8:
    Paquetes: enviados = 3, recibidos = 3, perdidos = 0
    (0% perdidos),
Tiempos aproximados de ida y vuelta en milisegundos:
    Mínimo = 13ms, Máximo = 17ms, Media = 15ms
Control-C
^C
sergio@CLIENTE2 C:\Users\sergio>
```

### Servidor web

```text
sergio@web:~$ ping marca.com
PING marca.com (34.147.120.111) 56(84) bytes of data.
64 bytes from 111.120.147.34.bc.googleusercontent.com (34.147.120.111): icmp_seq=1 ttl=101 time=94.0 ms
64 bytes from 111.120.147.34.bc.googleusercontent.com (34.147.120.111): icmp_seq=2 ttl=101 time=43.5 ms
64 bytes from 111.120.147.34.bc.googleusercontent.com (34.147.120.111): icmp_seq=3 ttl=101 time=139 ms
^C
--- marca.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 43.451/92.262/139.359/39.173 ms
sergio@web:~$ 
```

Las comprobaciones muestran que ambos clientes y el servidor web conservan conectividad con el exterior después de aplicar DHCP a la interfaz pública del router, cambiar las reglas SNAT por `MASQUERADE` y actualizar la regla DNAT.

## Conclusión

En esta parte de la práctica se configuró Kea para dar direccionamiento dinámico a dos redes. Se verificó que los clientes recibían IP, rutas, puerta de enlace y DNS; se analizaron el vencimiento y la renovación de concesiones; se creó una reserva DHCP para el servidor web; y se adaptó el encaminamiento y NAT a una interfaz pública con dirección dinámica. Finalmente, se comprobó la conectividad entre clientes, hacia el servidor web y hacia el exterior.
