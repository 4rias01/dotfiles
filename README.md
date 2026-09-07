# dotfiles

Configuración personal de **Hyprland** sobre CachyOS (Arch), con un shell propio hecho en
**Quickshell** (`mishell`) que incluye la barra, launcher en Rofi, notificaciones con SwayNC
y tema propio de SDDM.

> **Estado: en migración.** La idea es mover todo lo que hoy son utilidades sueltas
> (wlogout, hyprlock, …) a componentes QML dentro de `mishell`.
> Ver [Estado de la migración](#estado-de-la-migración).

---

## Índice

- [Estado de la migración](#estado-de-la-migración)
- [Stack](#stack)
- [Dependencias](#dependencias)
- [Instalación](#instalación)
- [Estructura del repo](#estructura-del-repo)
- [Funcionamiento](#funcionamiento)
  - [Hyprland](#hyprland)
  - [Atajos de teclado](#atajos-de-teclado)
  - [mishell (Quickshell)](#mishell-quickshell)
  - [Selector de wallpapers](#selector-de-wallpapers)
  - [Barra (mishell)](#barra-mishell)
  - [Colores dinámicos (ucs)](#colores-dinámicos-ucs)
  - [Waybar](#waybar)
  - [Rofi](#rofi)
  - [Tema de SDDM](#tema-de-sddm)
- [Personalización rápida](#personalización-rápida)
- [Pendientes y notas](#pendientes-y-notas)

---

## Estado de la migración

| Componente | Antes | Ahora | Estado |
|---|---|---|---|
| Menú de apagado | `wlogout` | `mishell/logout/` | ✅ **Completo** |
| Selector de wallpapers | `waypaper` | `mishell/wallpaper/` | ✅ **Completo** |
| Barra | `waybar` | `mishell/bar/` | ✅ **Completo** (ver [Barra](#barra-mishell)) |
| Config de Hyprland | `.conf` (hyprlang) | `.lua` | ✅ **Completo** |
| Pantalla de bloqueo | `hyprlock` | `mishell/lock/` | 🚧 **Pendiente** |
| Login | — | `sddm/mi-sddm` (QML propio) | ✅ **Completo** |

`config/wlogout/` y `config/hypr/hyprlock.conf` siguen en el repo: el primero como
referencia histórica (el único resto vivo es el módulo `custom/power` de Waybar, que sigue
definido con `"on-click": "wlogout"` pero ya no está en ninguna barra), el segundo porque
**hyprlock todavía está en uso** hasta que exista el reemplazo en Quickshell. Hoy lo
llaman tres cosas:
`SUPER + L`, los *listeners* de `hypridle.conf` y el botón «Bloquear» del overlay de
logout — esos tres son los puntos a tocar cuando el lock nuevo esté listo.

Los `modules/*.conf` de Hyprland también quedan como respaldo de la config anterior;
el que se carga es `hyprland.lua`.

---

## Stack

| Rol | Programa |
|---|---|
| Compositor | Hyprland |
| Shell / widgets | Quickshell (`mishell`) |
| Barra | Quickshell (`mishell/bar`) |
| Launcher | Rofi |
| Notificaciones | SwayNC (config y estilo propios en `config/swaync/`) |
| Bloqueo / idle | hyprlock + hypridle |
| Login | SDDM (tema propio `mi-sddm`) |
| Fondos | awww (imágenes) + mpvpaper (video) |
| Colores del sistema | `ucs` (genera la paleta desde el wallpaper) |
| Terminal | kitty + fish + starship + fastfetch |
| Archivos | nemo |
| Tipografía | JetBrainsMono Nerd Font |

---

## Dependencias

### Repos oficiales

```bash
sudo pacman -S --needed \
  hyprland hyprlock hypridle hyprpaper hyprpolkitagent \
  quickshell waybar swaync sddm \
  awww mpvpaper waypaper imagemagick ffmpeg \
  grim slurp wl-clipboard brightnessctl playerctl wireplumber \
  rofi wofi zenity pavucontrol btop networkmanager blueman upower jq \
  kitty fish starship fastfetch nemo \
  qt6-5compat qt6-declarative gnome-keyring \
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
```

> `awww` y `quickshell` vienen de los repos de **CachyOS** (`cachyos-extra-v4`).
> En Arch puro habría que sacarlos del AUR.

### AUR

```bash
paru -S ucs-git wifi-manager-git
```

- **`ucs`** — genera la paleta de colores a partir del wallpaper y la escribe en los
  configs. Sin esto el sistema funciona, pero los colores dejan de seguir al fondo.
- **`wifi-manager`** — panel flotante de WiFi para Wayland (se lanza en el autostart).

### Opcionales

Solo para los scripts de `config/hypr/scripts/magic-launcher*.sh`, que llenan el
workspace especial `magic`:

```bash
paru -S spotify cava pipes.sh unimatrix-git
```

### Para qué se usa cada cosa

| Paquete | Dónde |
|---|---|
| `awww` | fondo estático (`awww img`), el daemon lo levanta el picker si no responde |
| `mpvpaper` | fondos en video |
| `imagemagick` | miniaturas del picker, `identify` para decidir crop/fit, recorte del fondo de Rofi |
| `ffmpeg` | extrae un frame de los videos para la miniatura |
| `grim` + `slurp` + `wl-clipboard` | capturas (`SUPER + A`, `SUPER + SHIFT + A`) |
| `brightnessctl` | teclas de brillo, `hypridle`, slider de la barra |
| `playerctl` | teclas multimedia y módulo de Spotify de Waybar |
| `wireplumber` (`wpctl`) | teclas de volumen |
| `wofi` | menú de redes de `wifi_menu.sh` |
| `zenity` | slider de brillo de Waybar |
| `jq` | scripts de `magic-launcher` |
| `qt6-5compat` | `Qt5Compat.GraphicalEffects`, que usa el tema de SDDM |
| `waypaper` | solo el bind `SUPER + SHIFT + Return` (selector viejo, de respaldo) |

---

## Instalación

### 1. Clonar

```bash
git clone git@github.com:4rias01/dotfiles.git ~/dotfiles
```

### 2. Enlazar los configs

Todo `config/` se enlaza a `~/.config` con symlinks, no se copia:

```bash
ln -s ~/dotfiles/config/hypr       ~/.config/hypr
ln -s ~/dotfiles/config/quickshell ~/.config/quickshell
ln -s ~/dotfiles/config/waybar     ~/.config/waybar   # respaldo, ya no arranca sola
ln -s ~/dotfiles/config/swaync     ~/.config/swaync
ln -s ~/dotfiles/config/wifi-manager ~/.config/wifi-manager
ln -s ~/dotfiles/config/rofi       ~/.config/rofi
ln -s ~/dotfiles/config/kitty      ~/.config/kitty
ln -s ~/dotfiles/config/fish       ~/.config/fish
ln -s ~/dotfiles/config/fastfetch  ~/.config/fastfetch
ln -s ~/dotfiles/config/starship.toml ~/.config/starship.toml
```

### 3. Tema de SDDM

```bash
~/dotfiles/sddm/mi-sddm/install.sh
```

El script **copia** el tema a `/usr/share/sddm/themes/mi-sddm` (no lo enlaza: el greeter
corre como el usuario `sddm`, que no puede leer tu `$HOME` — un symlink da pantalla negra
sin ningún error útil), lo registra en `/etc/sddm.conf.d/10-theme.conf` y desactiva el
teclado virtual. Para probarlo sin reiniciar:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/mi-sddm
```

### 4. Wallpapers

El picker lee `$WALLPAPER_DIR` si existe; si no, `~/.config/hypr/wp`. Puede haber
subcarpetas: cada una aparece sola como chip de filtro.

---

## Estructura del repo

```
dotfiles/
├── config/                          → se enlaza a ~/.config
│   ├── hypr/
│   │   ├── hyprland.lua             → punto de entrada (carga modules/)
│   │   ├── modules/*.lua            → binds, autostart, decoración, reglas…
│   │   ├── modules/*.conf           → respaldo de la config vieja
│   │   ├── hypridle.conf            → timeouts de brillo / dpms / suspensión
│   │   ├── hyprlock.conf            → a reemplazar por Quickshell
│   │   ├── scripts/                 → magic-launcher, smart_fill, rename_spaces
│   │   ├── shaders/night.frag       → filtro cálido del modo noche (swaync)
│   │   └── wp/                      → wallpapers activos (los que ve el picker)
│   ├── quickshell/mishell/
│   │   ├── shell.qml                → raíz: monta los overlays y expone el IPC
│   │   ├── config/Theme.qml         → paleta (la reescribe ucs)
│   │   ├── logout/                  → menú de apagado
│   │   ├── wallpaper/               → selector de wallpapers + scripts/thumbs.sh
│   │   └── bar/                     → barra: Bar.qml, modules/, popups/, services/, scripts/
│   ├── swaync/  (config.json, style.css, colors.css → ucs, scripts/ radio.sh night.sh airplane.sh sound.sh)
│   ├── wifi-manager/config.toml     → posición del panel (arriba a la derecha)
│   ├── waybar/  (config.jsonc, style.css, scripts/)   → respaldo
│   ├── rofi/    (config.rasi, launcher.sh)
│   ├── kitty/  fish/  fastfetch/  starship.toml
│   └── wlogout/                     → legado, ya reemplazado
├── sddm/mi-sddm/                    → tema de SDDM + install.sh
└── Wallpapers/                      → biblioteca completa (~1.2 GB)
```

Dos carpetas de fondos a propósito: `Wallpapers/` es la biblioteca entera y
`config/hypr/wp/` es el subconjunto que está en uso y que el picker escanea.

---

## Funcionamiento

### Hyprland

`hyprland.lua` es el punto de entrada y hace `require()` de cada módulo. En Lua ya no
existen las variables `$var` de hyprlang: `modules/programs.lua` **devuelve una tabla** que
los demás consumen.

```lua
-- modules/programs.lua
return {
    terminal    = "kitty",
    fileManager = "nemo",
    menu        = "~/.config/rofi/launcher.sh",
}
```

```lua
-- modules/binds.lua
local programs = require("modules/programs")
hl.bind("SUPER + E", hl.dsp.exec_cmd(programs.terminal))
```

`exec-once` se reemplaza por el evento `hyprland.start` en `modules/autostart.lua`, que
levanta: `wifi-manager`, `qs -c mishell` (que trae la barra), `blueman-applet`, `swaync`, `hypridle`,
`awww-daemon`, `hyprpolkitagent`, el keyring y las variables de dbus.

Otros detalles: layout `dwindle`, opacidad 0.8/0.75 con lista de excepciones en
`windowrules.lua` (navegadores, editores, Spotify, juegos de Steam… van opacos), blur
activo, teclado `latam` y gesto de 3 dedos para cambiar de workspace.

### Atajos de teclado

`mainMod` = **SUPER**.

| Atajo | Acción |
|---|---|
| `SUPER + E` | Terminal (kitty) |
| `SUPER + F` | Gestor de archivos (nemo) |
| `SUPER + W` | Launcher (Rofi) |
| `SUPER + ALT + Space` | Mostrar / ocultar la barra (`qs ipc -c mishell call bar toggle`) |
| `SUPER + Q` | Cerrar ventana |
| `SUPER + V` | Alternar flotante |
| `SUPER + P` | Pseudotile |
| `SUPER + Space` / `+ SHIFT` | Fullscreen / maximizar |
| `SUPER + ←↑↓→` | Mover el foco |
| `SUPER + SHIFT + ←↑↓→` | Mover la ventana |
| `SUPER + 1..0` | Ir al workspace |
| `SUPER + SHIFT + 1..0` | Mandar la ventana al workspace |
| `SUPER + Tab` | Workspace anterior |
| `SUPER + rueda` | Workspace siguiente / anterior |
| `SUPER + S` / `SUPER + SHIFT + S` | Workspace especial `magic` / mandar ventana ahí |
| `SUPER + arrastrar` (izq / der) | Mover / redimensionar |
| **`SUPER + ESC`** | **Menú de apagado (mishell)** |
| **`SUPER + Return`** | **Selector de wallpapers (mishell)** |
| `SUPER + SHIFT + Return` | Waypaper (selector viejo) |
| `SUPER + L` | Bloquear (hyprlock) |
| `SUPER + SHIFT + L` | Suspender |
| `SUPER + SHIFT + ESC` | Salir de la sesión |
| `SUPER + N` | Panel de notificaciones (SwayNC) |
| `SUPER + A` | Captura de pantalla completa → portapapeles |
| `SUPER + SHIFT + A` | Captura de una región → portapapeles |
| Teclas multimedia | Volumen, mute, brillo, play/pause, siguiente, anterior |

### mishell (Quickshell)

El shell vive en `config/quickshell/mishell/` y se arranca con `qs -c mishell` desde el
autostart. `shell.qml` monta los overlays y expone el control por **IPC**, que es lo que
usan los binds:

```bash
qs ipc -c mishell call logout    toggle|open|close
qs ipc -c mishell call wallpaper toggle|open|close
qs ipc -c mishell call bar       toggle|open|close
qs ipc -c mishell call bar       hora                  # cambia el formato del reloj
qs ipc -c mishell call bar       popup  bateria|reloj|media|brillo|volumen
qs ipc -c mishell call bar       probarBateria 10      # simula el aviso de batería baja
qs ipc -c mishell call bar       estadoBateria         # qué umbrales ya avisaron en esta sesión
```

> Los handlers se llaman `open`/`close` y no `show`/`hide` porque `show` es un subcomando
> de `qs ipc` y se lo come el CLI.

El patrón se repite en los dos módulos: un `Singleton` de estado (`LogoutState`,
`WallpaperState`) con `abierto`/`abrir()`/`cerrar()`/`alternar()`, el `IpcHandler` vive en
`shell.qml` y solo toca ese singleton. La ventana no necesita saber quién la abre, así que
agregar un módulo nuevo es: singleton de estado + overlay + un bloque `IpcHandler`.

**Menú de apagado** (`logout/`) — overlay a pantalla completa en la capa `Overlay` con
foco de teclado exclusivo, seis botones con icono Nerd Font, hover animado y atajo de una
letra cada uno: `L` bloquear, `E` cerrar sesión, `S` suspender, `H` hibernar, `R`
reiniciar, `P` apagar. `Esc` o clic fuera cierran.

### Selector de wallpapers

`wallpaper/WallpaperPicker.qml` — carrusel de tarjetas inclinadas, inspirado en el picker
de [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration).

**Controles**

| Tecla | Acción |
|---|---|
| `←` / `→` / rueda | Moverse por el carrusel |
| `Enter` | Aplicar el wallpaper centrado |
| `/` | Buscar por nombre (como en vim) |
| `Esc` | Cerrar (o salir del buscador) |
| Clic en un chip | Filtrar por carpeta, o solo videos |

**Cómo funciona por dentro**

1. **Escaneo recursivo.** `FolderListModel` no entra en subcarpetas, así que el listado lo
   hace `find` y se vuelca en un `ListModel`. Cada subcarpeta se convierte sola en un chip
   de filtro; lo que está suelto en la raíz cae en el chip `sueltos`.
2. **Miniaturas.** El carrusel **nunca** lee los archivos originales: un 4K de 6 MB tarda
   segundos en decodificar (y en PNG no hay decodificación escalada, Qt descomprime los
   3840×2160 enteros). `scripts/thumbs.sh` genera copias chicas en
   `~/.cache/quickshell-wallpaper/thumbs/<altura>/` con nombre `md5(ruta).jpg`, en paralelo
   (`xargs -P`), y las va reportando **abriéndose desde la tarjeta central hacia los dos
   lados**, para que lo que estás mirando se llene primero. Es incremental: la segunda vez
   no lanza ni un proceso.
3. **Aplicar.** Imágenes y gif por `awww` (levanta `awww-daemon` si no responde, transición
   al azar; los gif los anima él solo), videos por `mpvpaper` (matando el anterior **y
   apagando la capa de `awww` con `awww clear`**: no se va sola, se queda debajo con el
   último fondo, y por las barras de un video más panorámico que la pantalla se seguía
   viendo la imagen anterior). Los gif cuentan como imagen: salen en `Todos` y en su
   carpeta, pero no en el chip `Video`. El *crop* o *fit* se decide
   comparando la relación de aspecto de la imagen con la del monitor donde está abierto el
   picker: si la imagen es más "angosta" que la pantalla se recorta, si es más ancha entra
   completa con barras.
4. **Post-command.** Después de aplicar el fondo corre el script de
   `WallpaperConfig.postCommand` con `$WALLPAPER`, `$WALL_NAME`, `$WALL_THUMB` y
   `$CACHE_DIR` exportadas. Es el gancho para los colores (ver abajo).
5. **El fondo actual, para los de afuera.** La ruta del archivo queda en texto plano en
   `~/.cache/quickshell-wallpaper/current`, y al lado queda `current_symlink`, una ruta
   fija que apunta a la **miniatura** del fondo, no al original: así es siempre un JPEG y
   lo que solo sabe abrir imágenes (hyprlock, Rofi, `ucs`) funciona igual cuando el fondo
   es un mp4 o un gif. Es la misma miniatura que dibuja el carrusel, así que normalmente
   ya está hecha; si falta, se genera al aplicar. Si ni así se puede (archivo que
   ffmpeg/magick no digieren), el symlink cae al original antes que quedar roto.

**Todo lo configurable está en `wallpaper/WallpaperConfig.qml`**: carpeta, extensiones
(imágenes, gif y videos por separado), si se listan videos, alto y paralelismo de las
miniaturas, transiciones de awww, opciones de mpvpaper, modo de encaje y el post-command.

### Barra (mishell)

`bar/` — reescritura de la Waybar en Quickshell, misma disposición y mismos módulos,
con animaciones "burbuja" (todo lo que se mueve lo hace con `Easing.OutBack`: los
módulos rebotan al pasar el mouse y se aplastan al hacer clic —si la burbuja tiene un
solo módulo, como el reloj o el reproductor, rebota la burbuja entera—, las burbujas
entran en cascada al arrancar, el indicador del workspace activo se desliza entre botones, los
popups crecen desde la barra). Referencias: [serpantinum](https://github.com/ilyamiro/serpantinum)
para los acentos y [caelestia](https://github.com/caelestia-dots/shell) para el panel del reloj.

Arranca con `qs -c mishell` (no hay proceso aparte); `SUPER + ALT + Space` la muestra u
oculta. Si algún día vuelve Waybar al autostart, `BarConfig.ocultarSiHayWaybar = true`
hace que la barra arranque oculta cuando detecta un `waybar` corriendo.

**Colores y `ucs`.** La paleta de la barra es fija y vive en `bar/BarConfig.qml`; `ucs`
no la toca. Los colores que sí deben seguir al wallpaper están aparte, en
**`bar/BarColors.qml`** (hoy solo `logo`, el icono de CachyOS del launcher). Es el único
archivo de `bar/` que va en la lista de `ucs`, así el escáner no se lleva por delante el
resto de la paleta. Para que otro color siga al fondo: se declara ahí, se usa como
`BarColors.<nombre>` y listo. Está en `.gitignore` como `Theme.qml`.

```
[ 󰣇 launcher | 1 2 3 4 5 ] [ 󰁹 83% 󰾅 | cpu | ram | temp | mando ]      [ reloj ]      [ spotify ] [ compartir wifi bt brillo vol notif ]
```

| Módulo | Clic | Clic derecho | Rueda |
|---|---|---|---|
| Launcher (icono de CachyOS) | **menú de apagado** (`logout/`) | Rofi | — |
| Workspaces | ir al workspace | — | anterior / siguiente |
| Batería | popup: estado, restante, salud, consumo y **switch ahorro / balanceado / rendimiento** (power-profiles-daemon) | **siguiente perfil** (ahorro → balanceado → rendimiento → ahorro) | — |
| CPU | `kitty -e btop` | — | — |
| Reloj | popup: **calendario** (rueda cambia de mes, clic en el título vuelve a hoy) | cambia el formato (hora ↔ fecha corta) | — |
| Spotify | popup: carátula, **barra de progreso arrastrable**, aleatorio / anterior / play / siguiente / repetir (nada → lista → una canción); clic medio: traer la ventana | play / pause | siguiente / anterior |
| Compartir archivos | activa / desactiva | — | — |
| Wi-Fi | `wifi-manager --toggle` (con pulso; se abre debajo de la barra, arriba a la derecha) | apaga / enciende el wifi (desconecta el dispositivo, no la radio: en esta laptop apagar la radio wifi apaga también el bluetooth) | — |
| Bluetooth | `wifi-manager --toggle` (con pulso) | apaga / enciende el adaptador | — |
| Brillo | popup con slider | — | ±2 % |
| Volumen | popup con slider (clic en el icono = mute) | `pavucontrol` | ±2 % |
| Notificaciones | panel de SwayNC | no molestar | — |

Todos tienen tooltip. Solo puede haber un popup abierto; se cierra solo medio segundo
después de que el mouse sale del módulo y del popup (4 s si se abrió por IPC sin mouse).

**Espacio entre la barra y las ventanas.** La barra reserva `alto + margenSuperior +
margenInferior` px y Hyprland suma sus `gaps_out` (10). Para acercar las ventanas no hay
que bajar `margenInferior` (por debajo de 0 el contenido se recorta): se usa
`BarConfig.recorteZona`, que resta píxeles a la zona reservada y deja que las ventanas
entren en el margen transparente.

**Reproductor.** El módulo y los popups solo miran **Spotify** (`BarConfig.playerPreferido`);
Firefox, mpv o lo que sea que también exponga MPRIS se ignora aunque esté sonando
(`soloPlayerPreferido = false` vuelve al comportamiento «Spotify, si no el que suene»).
El panel de música vive en `popups/MediaPanel.qml` y lo muestra `MediaPopup.qml`.

**Avisos de batería baja (estilo Windows).** `bar/BatteryNotifier.qml` manda una
notificación por `notify-send` al cruzar **20 %, 10 %, 5 % y 1 %** mientras se descarga
(una sola vez por umbral; al enchufar el cargador se reinician) y la acompaña con un
sonido (`sonidoAviso` / `sonidoCritico` en `BarConfig`, los `.oga` de
`sound-theme-freedesktop`; `""` lo apaga). Desde el 5 % la urgencia es `critical`. Todas
usan el mismo id sincrónico, así que el aviso del 10 % reemplaza al del 20 % en vez de
apilarse. La memoria de «este umbral ya sonó» está en un **archivo** en
`$XDG_RUNTIME_DIR` (`mishell-bateria.json`), no en el shell: cada cambio de wallpaper
corre `ucs`, que reescribe `Theme.qml`/`BarColors.qml` y recarga `qs`, y con
`PersistentProperties` esa recarga doble se llevaba la memoria y el aviso volvía a sonar.
El archivo lo borra el sistema al cerrar sesión. Se prueba sin descargar nada con
`qs ipc -c mishell call bar probarBateria 10`; `estadoBateria` muestra la memoria.

**Cómo está armado.** `Bar.qml` es una `PanelWindow` por monitor con tres zonas; cada
grupo es un `Bubble` (el pill oscuro) y cada módulo hereda de `Module.qml` (icono + texto,
hover, rebote, tooltip, señales `clic`/`clicDerecho`/`rueda`). Los popups son
`PopupWindow` (xdg_popup de la barra) anclados al módulo (`Popup.qml`). Lo que necesita
datos del sistema vive en singletons en `bar/services/`: `SysStats` (CPU/RAM/temp desde
`/proc` y hwmon), `Brightness` (`brightnessctl`), `Players` (el reproductor MPRIS de Spotify y sus
acciones: play, siguiente, aleatorio, repetir, seek), `Swaync` (`swaync-client -swb` en tail), `Ds4`,
`FileSharing`. Batería, perfiles de energía, red, bluetooth, audio y workspaces salen
directo de los servicios de Quickshell (`UPower`, `PowerProfiles`, `Networking`,
`Bluetooth`, `Pipewire`, `Hyprland`).

**Todo lo configurable está en `bar/BarConfig.qml`**: `escala` (0.9 = la barra y su tooltip un
10 % más chicos; los popups tienen tamaño fijo y no la siguen; las medidas en px pasan por `s()`), geometría, fuente, paleta (fija, no
la toca `ucs`), duraciones y overshoot de las animaciones, workspaces persistentes por
monitor, umbrales de batería, formatos del reloj, reproductor preferido, velocidad del
marquee, pasos de brillo/volumen y todos los comandos.

Tres trampas que se llevaron su tiempo (documentadas en los archivos):

- Con la config de Hyprland en **Lua**, `hyprctl dispatch workspace 2` ya no vale: lo
  envuelve en `hl.dispatch(...)` y espera Lua. Hay que mandar
  `hl.dsp.focus({ workspace = 2 })` (ver `modules/Workspaces.qml`).
- El escáner de Quickshell deja de buscar `pragma Singleton` si encuentra una `{` antes,
  **aunque esté en un comentario**. Por eso el pragma va en la primera línea de todos los
  singletons de `bar/`.
- Los iconos de Font Awesome del Nerd Font (`U+F000–U+F2E0`) van como `\uXXXX` o se pierden
  fácil al copiar; los de Material Design (`U+F0000+`) pueden ir literales.

### Colores dinámicos (ucs)

El post-command del picker es:

```bash
ucs automatic --from-image "$WALL_THUMB" --mode shading --colors 7
```

Va `$WALL_THUMB` (la miniatura cacheada) y no `$WALLPAPER` a propósito: siempre es un
JPEG, así que la paleta sale igual de un mp4 o un gif. Con el original, `ucs` fallaba en
silencio y te quedabas con los colores del fondo anterior.

`ucs` saca una paleta de 7 colores del wallpaper y reescribe los archivos listados en
`~/.config/ucs/config.json`:

- `~/.config/starship.toml`
- `~/.config/waybar/style.css`
- `~/.config/fastfetch/config.jsonc`
- `~/.config/quickshell/mishell/config/Theme.qml`
- `~/.config/hypr/modules/decoration.lua`

Por eso esos archivos están en el `.gitignore`: cambian con cada wallpaper y no tiene
sentido versionarlos. Hace backup en `~/.config-colors-backup` (`ucs restore` deshace) y
reinicia Waybar al terminar.

### SwayNC

`config/swaync/` — `config.json` (panel a la derecha, 400 px, textos en español) y
`style.css` con el mismo look de la barra: fondo oscuro (0.9 de opacidad; SwayNC es una
capa layer-shell, así que las windowrules de Hyprland no le aplican y la transparencia se
decide en el CSS), bordes redondeados, acento teal, JetBrainsMono. Las notificaciones
`critical` (como la de batería al 5 %) llevan el borde rojo, y la barra de progreso que
manda `notify-send -h int:value:N` se pinta con el acento. Se recarga sin reiniciar con
`swaync-client -R` (config) y `swaync-client -rs` (estilo).

**Colores y `ucs`.** `style.css` no tiene ningún color: los importa de **`colors.css`**
(primera línea, `@import`), que es el archivo para poner en la lista de `ucs`. Ahí están
como `#hex` (los translúcidos como `alpha(#hex, 0.9)`) para que `ucs` los pueda reescribir;
lo que no deba seguir al wallpaper se deja fijo o se mueve a `style.css`. Está en
`.gitignore` como `BarColors.qml` (se trackea una vez con `git add -f`).

El panel ocupa casi todo el alto (`fit-to-screen`, 8 px del borde inferior). De arriba
abajo: título + «Limpiar», la lista de notificaciones (crece), el **reproductor** de SwayNC
(carátula, anterior / play / siguiente, aleatorio, repetir) y abajo del todo una rejilla de
**6 botones en 2 filas** (`buttons-grid`); todos menos el último son toggles que leen su
estado real al abrir el panel:

| Botón | Qué hace |
|---|---|
| 󰤨 Wi-Fi | `nmcli radio wifi on/off` (`scripts/radio.sh wifi`) |
| 󰂯 Bluetooth | `bluetoothctl power on/off` (`scripts/radio.sh bt`) |
| 󰂛 No molestar | `swaync-client -dn/-df` (`scripts/radio.sh dnd`); reemplaza al switch de arriba |
| 󰖔 Modo noche | filtro cálido para la pantalla: `scripts/night.sh` pone `decoration:screen_shader` con `hypr/shaders/night.frag` (ahí se ajusta la calidez); `modules/night.lua` lo repone tras un `hyprctl reload` |
| 󰀝 Modo avión | `rfkill block/unblock all` (`scripts/airplane.sh`, hace falta el grupo `rfkill`) |
| 󰐥 Apagar | cierra el panel y abre el menú de apagado de mishell |

**Sonido.** Cada notificación suena (`scripts` en `config.json` → `scripts/sound.sh`):
`message.oga` para las normales, `dialog-warning.oga` para las `critical`, nada para las
`low` ni con «No molestar». Las de batería están excluidas ahí porque ya las hace sonar
la barra (`BarConfig.sonidoAviso` / `sonidoCritico`), así suenan aunque swaync no esté.

Los comandos de los toggles viven en scripts porque SwayNC parte el `command` con su
propio parser y se atraganta con `$(...)` y comillas anidadas. SwayNC no tiene barra de
progreso para el reproductor ni acepta clic derecho en los botones: wifi-manager se abre
desde el clic izquierdo de wifi/bluetooth en la barra (debajo de ella, arriba a la
derecha, `config/wifi-manager/config.toml`, entra con `popin` por layerrule).

### Waybar

> Ya no arranca: la reemplazó la [barra de mishell](#barra-mishell). Queda en el repo como
> respaldo (`~/.config/waybar/scripts/launch.sh` la levanta a mano).

Tres grupos: **izquierda** launcher + workspaces y batería/CPU/RAM/temperatura/mando DS4;
**centro** reloj con calendario en el tooltip; **derecha** compartir archivos, red,
bluetooth, brillo, volumen y notificaciones.

Scripts en `waybar/scripts/`:

| Script | Qué hace |
|---|---|
| `wifi_menu.sh` | Escanea y conecta redes con `nmcli` + `wofi` (reusa la clave guardada si existe) |
| `brightness_slider.sh` | Slider de brillo con `zenity`, aplica en vivo |
| `ds4-battery.sh` | Batería del mando de PS4 desde `/sys/class/power_supply` |
| `mpd-waybar.sh` | Título de Spotify con scroll horizontal (ventana de 25 caracteres) |
| `file-sharing.sh` | Vigila `~/Shadow` y manda al portapapeles lo que aparezca ahí |
| `launch.sh` | Arranca o mata Waybar (`SUPER + ALT + Space`) |

`style.css` la regenera `ucs`.

### Rofi

`launcher.sh` lee el wallpaper actual por `current_symlink` (o sea la miniatura, que
siempre es un JPEG: con videos y gif funciona igual), lo recorta a la proporción del panel
lateral con ImageMagick y se lo pasa a Rofi por `-theme-str`. Resultado: el launcher
siempre muestra el fondo del momento.

El crop se cachea en `/tmp` y solo se rehace si cambió el fondo, pero lo que se compara es
**a dónde apunta** el symlink, no su ruta: la ruta es fija y nunca cambia, así que
comparándola el crop se generaba una vez y se quedaba congelado para siempre.

### Tema de SDDM

`sddm/mi-sddm/` — tema QML propio: reloj + formulario a un lado, con blur parcial en una
banda del fondo.

Todo se toca desde **`theme.conf`** sin abrir QML: posición y ancho del formulario, blur
(radio, ancho, alto, redondeo, suavidad del borde), tamaños de fuente e iconos, formato de
hora y fecha, y la paleta completa.

**Independiente de la resolución.** Las medidas están escritas contra una resolución de
referencia (`designWidth`/`designHeight`, 1366×768) y `Main.qml` las multiplica por

```
escala = min(anchoReal / designWidth, altoReal / designHeight)
```

antes de usarlas, así que la misma config se ve igual en 1366×768, en 1080p y en 4K sin
tocar un número. Se usa el mínimo de las dos razones: con la misma relación de aspecto da
proporción exacta, y con una distinta manda el eje más ajustado, así el formulario nunca se
sale de pantalla. `uiScale` es un multiplicador extra por gusto. En multimonitor no hay
nada que hacer: SDDM instancia el tema una vez por pantalla y cada una calcula su escala.

Las medidas que conceptualmente son *una porción de la pantalla* (`formPadding`,
`blurWidth`, `blurHeight`) aceptan además porcentaje: `blurHeight="120%"` garantiza que la
banda llegue de borde a borde en cualquier relación de aspecto.

⚠️ Tres trampas que están documentadas en los archivos: **todo lo de `theme.conf` llega a
QML como string** (de ahí los `parseInt()`/`parseFloat()`); los colores **necesitan
comillas** o el `#` se lee como comentario; y las fuentes van en **píxeles, no en puntos**
(un punto es una medida física que Qt convierte usando los DPI de la pantalla, y como el
tema ya escala por su cuenta el DPI se contaría dos veces). Las fuentes tienen que estar en
`/usr/share/fonts`, porque el usuario `sddm` no lee tu `$HOME`.

Para depurar el QML: Qt manda `console.log` y los warnings al journal, no a la terminal.
Con `QT_FORCE_STDERR_LOGGING=1` los ves donde esperás.

---

## Personalización rápida

| Quiero cambiar… | Archivo |
|---|---|
| Terminal, gestor de archivos, launcher | `config/hypr/modules/programs.lua` |
| Atajos de teclado | `config/hypr/modules/binds.lua` |
| Qué arranca con la sesión | `config/hypr/modules/autostart.lua` |
| Gaps, bordes, blur, opacidad | `config/hypr/modules/decoration.lua` |
| Reglas de ventanas / opacidades por app | `config/hypr/modules/windowrules.lua` |
| Timeouts de brillo, bloqueo, suspensión | `config/hypr/hypridle.conf` |
| Colores de los widgets de Quickshell | `config/quickshell/mishell/config/Theme.qml` |
| Carpeta de fondos, miniaturas, transiciones, post-command | `config/quickshell/mishell/wallpaper/WallpaperConfig.qml` |
| Barra (geometría, animaciones, comandos, umbrales) | `config/quickshell/mishell/bar/BarConfig.qml` |
| Colores de la barra que siguen al wallpaper | `config/quickshell/mishell/bar/BarColors.qml` |
| Notificaciones (posición, timeouts, estilo, botones rápidos) | `config/swaync/config.json`, `config/swaync/style.css` |
| Colores de SwayNC (los que puede tocar ucs) | `config/swaync/colors.css` |
| Calidez del modo noche | `config/hypr/shaders/night.frag` |
| Dónde aparece wifi-manager | `config/wifi-manager/config.toml` (posición/márgenes; reiniciar `wifi-manager`, `--reload` no la aplica) |
| Pantalla de login | `sddm/mi-sddm/theme.conf` |

Quickshell recarga en caliente: al guardar un `.qml` el shell se refresca solo. Si algo
revienta, el error aparece en la salida de `qs -c mishell` (`shell.qml` deja los errores a
propósito y solo silencia el popup de recarga exitosa).

---

## Pendientes y notas

- [ ] **ucs:** en `~/.config/ucs/config.json` cambiar `waybar/style.css` por
      `~/.config/swaync/colors.css` (BarColors.qml ya está).
- [ ] **Lock screen en Quickshell** para reemplazar hyprlock. Tocar los tres puntos que
      hoy lo invocan: `SUPER + L` en `binds.lua`, los listeners de `hypridle.conf` y el
      botón «Bloquear» de `logout/LogoutOverlay.qml`.
- [ ] Después de eso se pueden borrar `hyprlock.conf` y `config/wlogout/`, junto con el
      módulo `custom/power` que quedó huérfano en `waybar/config.jsonc`.
- [ ] Los `modules/*.conf` viejos siguen ahí como respaldo de la migración a Lua; se van
      cuando la config en Lua esté rodada.
- [ ] Los archivos que genera `ucs` están en `.gitignore` **pero ya estaban trackeados**,
      esto es así para no ensuciar commits con los cambios de colores.
- [ ] `smart_fill.sh` quedó obsoleto: el picker aplica la misma regla, pero sacando el
      tamaño de pantalla del monitor en vez de tenerlo hardcodeado en 1920×1080.
- [ ] `hyprpaper.conf` sigue en el repo pero no se usa (los fondos los pone `awww`).
- La rama por defecto es `main`; `laptop` es la de esta máquina.
