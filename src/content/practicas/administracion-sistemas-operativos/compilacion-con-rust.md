---
title: "Compilación con Rust y Hyperfine"
subject: "Administración de Sistemas Operativos"
description: "Práctica de compilación con Rust y medición de tiempos con Hyperfine."
date: 2026-09-29
tags:
  - Rust
  - Compilación
  - Hyperfine
pdf: "administracion-sistemas-operativos/compilacion-con-rust.pdf"
---

# Compilación e instalación de hyperfine con Rust

Elegí **hyperfine 1.19.0**, un programa escrito en Rust que mide el tiempo de ejecución de comandos. Utilicé rustup para instalar las herramientas de Rust, compilé hyperfine desde sus fuentes y lo instalé en `/opt/hyperfine`, fuera de los directorios gestionados por los paquetes de Debian.

Este documento recoge las salidas que compartí durante la práctica. No se han inventado salidas para los pasos de los que no conservé una transcripción. El prompt de mis comandos es `sergio@Sergio-PC`.

## Comprobación inicial

```console
sergio@Sergio-PC:~$ command -v hyperfine
sergio@Sergio-PC:~$ command -v rustup
sergio@Sergio-PC:~$ command -v cargo
```

Ninguno de los tres comandos mostró una ruta en el `PATH`.

## Instalación y comprobación de Rust

Ejecuté el instalador oficial de rustup con el siguiente comando, pero no guardé su salida:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Después cargué el entorno de Cargo en la terminal:

```console
sergio@Sergio-PC:~$ source "$HOME/.cargo/env"
```

También comprobé que tenía Git y GCC:

```console
sergio@Sergio-PC:~$ command -v git
/usr/bin/git
sergio@Sergio-PC:~$ command -v gcc
/usr/bin/gcc
```

## Descarga de las fuentes

Entré en `~/compilacion` y descargué la etiqueta `v1.19.0` del repositorio de hyperfine:

```console
sergio@Sergio-PC:~$ cd ~/compilacion
sergio@Sergio-PC:~/compilacion$ git clone --depth 1 --branch v1.19.0 https://github.com/sharkdp/hyperfine.git hyperfine-1.19.0
Clonando en 'hyperfine-1.19.0'...
remote: Enumerating objects: 78, done.
remote: Counting objects: 100% (78/78), done.
remote: Compressing objects: 100% (73/73), done.
remote: Total 78 (delta 3), reused 35 (delta 2), pack-reused 0 (from 0)
Recibiendo objetos: 100% (78/78), 189.74 KiB | 601.00 KiB/s, listo.
Resolviendo deltas: 100% (3/3), listo.
Nota: cambiando a '12fec42098642a19855ead34c8cb1e0be28c8ead'.

Te encuentras en estado 'detached HEAD'. Puedes revisar por aquí, hacer
cambios experimentales y hacer commits, y puedes descartar cualquier
commit que hayas hecho en este estado sin impactar a tu rama realizando
otro checkout.

Si quieres crear una nueva rama para mantener los commits que has creado,
puedes hacerlo (ahora o después) usando -c con el comando checkout. Ejemplo:

  git switch -c <nombre-de-nueva-rama>

O deshacer la operación con:

  git switch -

Desactiva este aviso poniendo la variable de config advice.detachedHead en false
```

El aviso `detached HEAD` aparece porque descargué una versión concreta, no una rama de desarrollo. La salida compartida de este paso no incluía el prompt final.

## Comprobación de los ficheros

```console
sergio@Sergio-PC:~/compilacion$ cd ~/compilacion/hyperfine-1.19.0
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ ls -l Cargo.toml Cargo.lock src/main.rs
-rw-rw-r-- 1 sergio sergio 36350 sep 29 20:22 Cargo.lock
-rw-rw-r-- 1 sergio sergio  1674 sep 29 20:22 Cargo.toml
-rw-rw-r-- 1 sergio sergio  1406 sep 29 20:22 src/main.rs
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

`Cargo.toml` describe el proyecto para Cargo; `Cargo.lock` registra las versiones de sus dependencias y `src/main.rs` contiene el punto de entrada del ejecutable. En esta práctica se utiliza Cargo en lugar de `configure` y `make`.

## Compilación

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ cargo build --release
    Updating crates.io index
  Downloaded autocfg v0.1.8
  Downloaded ahash v0.7.8
  Downloaded is_terminal_polyfill v1.70.1
  Downloaded anstyle-query v1.1.2
  Downloaded anstyle v1.0.10
  Downloaded num v0.2.1
  Downloaded ptr_meta_derive v0.1.4
  Downloaded equivalent v1.0.1
  Downloaded shell-words v1.1.0
  Downloaded funty v2.0.0
  Downloaded itoa v1.0.11
  Downloaded uuid v1.11.0
  Downloaded errno v0.3.9
  Downloaded lazy_static v1.5.0
  Downloaded rand_isaac v0.1.1
  Downloaded num-iter v0.1.45
  Downloaded rand_chacha v0.3.1
  Downloaded rand_core v0.3.1
  Downloaded number_prefix v0.4.0
  Downloaded rend v0.4.2
  Downloaded bytecheck_derive v0.6.12
  Downloaded cfg-if v1.0.0
  Downloaded clap_lex v0.7.2
  Downloaded rand_chacha v0.1.1
  Downloaded radium v0.7.0
  Downloaded cfg_aliases v0.2.1
  Downloaded rand_hc v0.1.0
  Downloaded statistical v1.0.0
  Downloaded strsim v0.11.1
  Downloaded utf8parse v0.2.2
  Downloaded rand_pcg v0.1.2
  Downloaded proc-macro-crate v3.2.0
  Downloaded tap v1.0.1
  Downloaded terminal_size v0.4.0
  Downloaded tinyvec_macros v0.1.1
  Downloaded toml_datetime v0.6.8
  Downloaded anstream v0.6.18
  Downloaded bitflags v2.6.0
  Downloaded anstyle-parse v0.2.6
  Downloaded bytecheck v0.6.12
  Downloaded arrayvec v0.7.6
  Downloaded autocfg v1.4.0
  Downloaded colorchoice v1.0.3
  Downloaded colored v2.1.0
  Downloaded rand_jitter v0.1.4
  Downloaded byteorder v1.5.0
  Downloaded num-complex v0.2.4
  Downloaded num-integer v0.1.46
  Downloaded rand_core v0.6.4
  Downloaded rand_core v0.4.2
  Downloaded rand_os v0.1.3
  Downloaded wyz v0.5.1
  Downloaded ptr_meta v0.1.4
  Downloaded thiserror v2.0.3
  Downloaded thiserror-impl v2.0.3
  Downloaded num-rational v0.2.4
  Downloaded ppv-lite86 v0.2.20
  Downloaded rkyv_derive v0.7.45
  Downloaded seahash v4.1.0
  Downloaded simdutf8 v0.1.5
  Downloaded version_check v0.9.5
  Downloaded csv-core v0.1.11
  Downloaded getrandom v0.2.15
  Downloaded winnow v0.6.20
  Downloaded ryu v1.0.18
  Downloaded tinyvec v1.8.0
  Downloaded unicode-ident v1.0.13
  Downloaded num-traits v0.2.19
  Downloaded once_cell v1.20.2
  Downloaded quote v1.0.37
  Downloaded zerocopy-derive v0.7.35
  Downloaded anyhow v1.0.93
  Downloaded clap v4.5.20
  Downloaded clap_complete v4.5.37
  Downloaded console v0.15.8
  Downloaded proc-macro2 v1.0.89
  Downloaded zerocopy v0.7.35
  Downloaded serde_derive v1.0.214
  Downloaded bytes v1.8.0
  Downloaded indicatif v0.17.4
  Downloaded indexmap v2.6.0
  Downloaded rand v0.8.5
  Downloaded serde v1.0.214
  Downloaded hashbrown v0.12.3
  Downloaded num-bigint v0.2.6
  Downloaded rkyv v0.7.45
  Downloaded toml_edit v0.22.22
  Downloaded memchr v2.7.4
  Downloaded rand v0.6.5
  Downloaded rust_decimal v1.36.0
  Downloaded hashbrown v0.15.1
  Downloaded clap_builder v4.5.20
  Downloaded serde_json v1.0.132
  Downloaded portable-atomic v1.9.0
  Downloaded bitvec v1.0.1
  Downloaded syn v1.0.109
  Downloaded syn v2.0.87
  Downloaded unicode-width v0.1.14
  Downloaded nix v0.29.0
  Downloaded rustix v0.38.40
  Downloaded libc v0.2.162
  Downloaded csv v1.3.1
  Downloaded linux-raw-sys v0.4.14
  Downloaded borsh-derive v1.5.2
  Downloaded borsh v1.5.2
  Downloaded 106 crates (8.6MiB) in 0.73s (largest was `linux-raw-sys` at 1.7MiB)
   Compiling autocfg v1.4.0
   Compiling proc-macro2 v1.0.89
   Compiling unicode-ident v1.0.13
   Compiling rustix v0.38.40
   Compiling libc v0.2.162
   Compiling rand_core v0.4.2
   Compiling utf8parse v0.2.2
   Compiling bitflags v2.6.0
   Compiling linux-raw-sys v0.4.14
   Compiling anstyle v1.0.10
   Compiling anstyle-parse v0.2.6
   Compiling is_terminal_polyfill v1.70.1
   Compiling colorchoice v1.0.3
   Compiling rand_core v0.3.1
   Compiling anstyle-query v1.1.2
   Compiling clap_lex v0.7.2
   Compiling autocfg v0.1.8
   Compiling serde v1.0.214
   Compiling strsim v0.11.1
   Compiling anstream v0.6.18
   Compiling cfg-if v1.0.0
   Compiling num-traits v0.2.19
   Compiling num-bigint v0.2.6
   Compiling rand_chacha v0.1.1
   Compiling num-complex v0.2.4
   Compiling num-rational v0.2.4
   Compiling rand_pcg v0.1.2
   Compiling byteorder v1.5.0
   Compiling rand v0.6.5
   Compiling quote v1.0.37
   Compiling memchr v2.7.4
   Compiling syn v2.0.87
   Compiling portable-atomic v1.9.0
   Compiling cfg_aliases v0.2.1
   Compiling lazy_static v1.5.0
   Compiling nix v0.29.0
   Compiling num-integer v0.1.46
   Compiling rand_hc v0.1.0
   Compiling rand_xorshift v0.1.1
   Compiling getrandom v0.2.15
   Compiling rand_os v0.1.3
   Compiling rand_isaac v0.1.1
   Compiling num-iter v0.1.45
   Compiling rand_core v0.6.4
   Compiling rand_jitter v0.1.4
   Compiling anyhow v1.0.93
   Compiling thiserror v2.0.3
   Compiling itoa v1.0.11
   Compiling unicode-width v0.1.14
   Compiling serde_json v1.0.132
   Compiling rust_decimal v1.36.0
   Compiling terminal_size v0.4.0
   Compiling ryu v1.0.18
   Compiling console v0.15.8
   Compiling clap_builder v4.5.20
   Compiling csv-core v0.1.11
   Compiling number_prefix v0.4.0
   Compiling arrayvec v0.7.6
   Compiling num v0.2.1
   Compiling indicatif v0.17.4
   Compiling statistical v1.0.0
   Compiling colored v2.1.0
   Compiling shell-words v1.1.0
   Compiling serde_derive v1.0.214
   Compiling zerocopy-derive v0.7.35
   Compiling thiserror-impl v2.0.3
   Compiling clap v4.5.20
   Compiling clap_complete v4.5.37
   Compiling zerocopy v0.7.35
   Compiling hyperfine v1.19.0 (/home/sergio/compilacion/hyperfine-1.19.0)
   Compiling ppv-lite86 v0.2.20
   Compiling rand_chacha v0.3.1
   Compiling rand v0.8.5
   Compiling csv v1.3.1
warning: hiding a lifetime that's elided elsewhere is confusing
   --> src/benchmark/relative_speed.rs:99:14
    |
 99 |     results: &[BenchmarkResult],
    |              ^^^^^^^^^^^^^^^^^^ the lifetime is elided here
100 |     sort_order: SortOrder,
101 | ) -> Option<Vec<BenchmarkResultWithRelativeSpeed>> {
    |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ the same lifetime is hidden here
    |
    = help: the same lifetime is referred to in inconsistent ways, making the signature confusing
    = note: `#[warn(mismatched_lifetime_syntaxes)]` on by default
help: use `'_` for type paths
    |
101 | ) -> Option<Vec<BenchmarkResultWithRelativeSpeed<'_>>> {
    |                                                 ++++

warning: hiding a lifetime that's elided elsewhere is confusing
   --> src/benchmark/relative_speed.rs:113:14
    |
113 |     results: &[BenchmarkResult],
    |              ^^^^^^^^^^^^^^^^^^ the lifetime is elided here
114 |     sort_order: SortOrder,
115 | ) -> Vec<BenchmarkResultWithRelativeSpeed> {
    |          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ the same lifetime is hidden here
    |
    = help: the same lifetime is referred to in inconsistent ways, making the signature confusing
    = note: `#[warn(mismatched_lifetime_syntaxes)]` on by default
help: use `'_` for type paths
    |
115 | ) -> Vec<BenchmarkResultWithRelativeSpeed<'_>> {
    |                                          ++++

warning: `hyperfine` (bin "hyperfine") generated 2 warnings (run `cargo fix --bin "hyperfine" -p hyperfine` to apply 2 suggestions)
    Finished `release` profile [optimized] target(s) in 28.10s
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

Cargo descargó 106 dependencias y completó la compilación optimizada. Los dos avisos sobre *lifetimes* no impidieron generar el ejecutable.

## Pruebas y comprobación del ejecutable

Ejecuté `cargo test` y comuniqué que la salida mostró `ok`. No compartí la salida completa ni el número de pruebas, por lo que no los reproduzco aquí:

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ cargo test
```

Después comprobé que se había generado el ejecutable y consulté su versión:

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ ls -l target/release/hyperfine
./target/release/hyperfine --version
-rwxrwxr-x 2 sergio sergio 1294192 sep 29 20:23 target/release/hyperfine
hyperfine 1.19.0
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

## Instalación en /opt

Copié el ejecutable compilado a un directorio independiente de los paquetes de Debian:

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ sudo install -D -m 755 target/release/hyperfine /opt/hyperfine/bin/hyperfine
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

En esta instalación se copió **un único fichero**: `/opt/hyperfine/bin/hyperfine`. Los directorios `/opt/hyperfine` y `/opt/hyperfine/bin` sirven para alojarlo; no se instaló documentación en `/opt`.

## Comprobación del programa instalado

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ ls -l /opt/hyperfine/bin/hyperfine
/opt/hyperfine/bin/hyperfine --version
/opt/hyperfine/bin/hyperfine --runs 5 'sleep 0.1'
-rwxr-xr-x 1 root root 1294192 sep 29 20:26 /opt/hyperfine/bin/hyperfine
hyperfine 1.19.0
Benchmark 1: sleep 0.1
  Time (mean ± σ):     104.9 ms ±   3.8 ms    [User: 1.3 ms, System: 1.7 ms]
  Range (min … max):   103.1 ms … 111.6 ms    5 runs

  Warning: The first benchmarking run for this command was significantly slower than the rest (111.6 ms). This could be caused by (filesystem) caches that were not filled until after the first run. You should consider using the '--warmup' option to fill those caches before the actual benchmark. Alternatively, use the '--prepare' option to clear the caches before each timing run.

sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

El ejecutable instalado mostró la versión 1.19.0 e hizo cinco mediciones del comando `sleep 0.1`. El aviso indica que la primera medición fue más lenta y recomienda `--warmup` para mediciones más precisas; no indica un fallo.

## Desinstalación

Para retirar esta instalación manual se indicaron estos comandos:

```bash
sudo rm /opt/hyperfine/bin/hyperfine
sudo rmdir /opt/hyperfine/bin
sudo rmdir /opt/hyperfine
```

No compartí la salida de esos tres comandos. Sí compartí la siguiente comprobación posterior:

```console
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ ls -ld /opt/hyperfine
ls: no se puede acceder a '/opt/hyperfine': No existe el fichero o el directorio
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$
```

Por tanto, comprobé que el directorio de instalación `/opt/hyperfine` ya no existía.

## Limpieza de las fuentes

También se propuso borrar el directorio de fuentes y comprobar el contenido de `~/compilacion`, pero **no compartí una salida que confirme haber ejecutado estos comandos**:

```bash
sergio@Sergio-PC:~/compilacion/hyperfine-1.19.0$ cd ~/compilacion
sergio@Sergio-PC:~/compilacion$ rm -rf hyperfine-1.19.0
sergio@Sergio-PC:~/compilacion$ ls -l
total 0
```

Esta limpieza es distinta de la desinstalación del ejecutable en `/opt`. Rustup, rustc y Cargo permanecen instalados para mi usuario; no forman parte del fichero de hyperfine copiado a `/opt`.
