# COMANDOS.md — Trazabilidad de la migración de dotfiles

Registro de cada comando ejecutado (en orden) durante la instalación de los dotfiles
de la rama `lenovo` sobre CachyOS + Hyprland (que venía con Noctalia Shell).

Equipo: Lenovo LOQ 15ARP9 (83JC) · AMD Ryzen 5 7235HS (sin iGPU) · NVIDIA RTX 4050 Max-Q · CachyOS · Hyprland 0.57.2

---

## 1. Reconocimiento del sistema (solo lectura)

```bash
# Estado de home, configs, herramientas y hardware
cd ~ && ls -la && ls ~/.config && git --version && which stow quickshell qs hyprctl
cat /etc/os-release | head -3
lspci | grep -Ei 'vga|3d|display'
cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name /sys/class/dmi/id/product_version

# Paquetes relevantes ya instalados y configs actuales
pacman -Qq | grep -Ei 'noctalia|quickshell|hypr|nvidia|power|tlp|ideapad|lenovo|brightness|cliphist|stow|matugen|swww|awww|rofi|wofi|fuzzel'
ls -la ~/.config/hypr ~/.config/noctalia
ls /usr/bin | grep -Ei 'qs$|quickshell|noctalia'

# Interfaces de batería / perfiles de energía
ls /sys/bus/platform/drivers/ideapad_acpi/
ls /sys/bus/platform/devices/ | grep -i -E 'ideapad|VPC'
cat /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
ls /sys/class/power_supply/
cat /sys/class/power_supply/BAT*/charge_control_end_threshold
cat /sys/firmware/acpi/platform_profile_choices /sys/firmware/acpi/platform_profile
powerprofilesctl list

# Configs de Hyprland/Noctalia que venían por defecto
cat ~/.config/hypr/hyprland.lua
ls -la ~/.config/hypr/config
cat ~/.config/noctalia/config.toml
ls -la /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
grep -rl conservation /etc/udev /usr/lib/udev /etc/tmpfiles.d /usr/lib/tmpfiles.d /usr/share/polkit-1

# ¿Cómo limita Noctalia la batería? -> vía D-Bus de UPower (EnableChargeThreshold)
pacman -Ql noctalia
strings $(which noctalia) | grep -i -E 'conservation|charge_control|pkexec|ideapad'
strings $(which noctalia) | grep -i -B3 -A3 'charge_control_end_threshold'
upower --version
upower -i /org/freedesktop/UPower/devices/battery_BAT1
ls /sys/class/power_supply/BAT1/
cat /sys/class/power_supply/BAT1/charge_types   # -> Fast Standard [Long_Life]

# GPU NVIDIA
nvidia-smi --query-gpu=name,utilization.gpu,memory.used,temperature.gpu --format=csv,noheader
cat /proc/driver/nvidia/gpus/*/power
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
lspci -k | grep -A3 -i 'vga\|display'

# Config Lua por defecto de CachyOS
cd ~/.config/hypr/config && for f in *.lua; do echo "=== $f"; cat $f; done
cat ~/.config/hypr/xdph.conf
hyprctl version | head -3
pacman -Si quickshell
pacman -Ss quickshell
```

## 2. Descarga de los dotfiles (HTTPS)

```bash
git clone --branch lenovo https://github.com/4rias01/dotfiles.git ~/dotfiles
```
# (tardó varios minutos: el historial pesa ~1.5 GB por los wallpapers)

cd ~/dotfiles && git log --oneline | head -8 && git branch -a && du -sh .git
find . -path ./.git -prune -o -type f -print | grep -v -E '\.(png|jpg|jpeg|webp|gif|mp4)$'

# ¿Existía ya un módulo de teclado en alguna rama? -> No, se creó desde cero
git grep -n -i -E 'kb_layout|switchxkblayout|keyboard|xkb|layout' $(git for-each-ref --format='%(refname)' refs/remotes) -- 'config/quickshell' 'config/hypr'
git log --all --oneline -i --grep='teclado\|keyboard\|layout'

# Lectura de la config (README, hypr/*.lua, mishell/*.qml)
cat README.md .gitignore config/hypr/hyprland.lua config/hypr/modules/*.lua
cd config/quickshell/mishell && wc -l $(find . -name '*.qml' -o -name '*.sh') && cat shell.qml config/Theme.qml
cd bar && cat BarConfig.qml Bar.qml BarState.qml Module.qml Bubble.qml Popup.qml modules/*.qml popups/BatteryPopup.qml services/SysStats.qml BarColors.qml
cat ../logout/LogoutState.qml ../logout/LogoutOverlay.qml
```

## 3. Diagnóstico de sesión, permisos y paquetes faltantes

```bash
sudo -n true                       # -> pide contraseña: los pacman los tiene que correr el usuario
grep -A12 'enable-charging-limit' /usr/share/polkit-1/actions/org.freedesktop.upower.policy   # allow_active = yes
cat /sys/module/nvidia_drm/parameters/modeset /sys/module/nvidia_drm/parameters/fbdev          # Y Y
ls ~/.config/uwsm; cat ~/.config/uwsm/env*
ps -eo pid,ppid,cmd | grep -E 'Hyprland|start-hyprland|uwsm|noctalia|sddm|greetd'             # greetd -> start-hyprland (sin uwsm)
env | grep -E 'LIBVA|GLX|GBM|NVD|ELECTRON|XDG_SESSION|WAYLAND'
grep -rs GBM_BACKEND /etc/environment /etc/profile.d /etc/environment.d ~/.config/environment.d /usr/lib/environment.d
cat /etc/profile.d/Hyprland.sh && pacman -Qo /etc/profile.d/Hyprland.sh                        # lo pone cachyos-hypr-noctalia
for p in hyprland hyprlock hypridle ... ; do pacman -Qq $p >/dev/null 2>&1 || echo "FALTA: $p"; done
pacman -Qq | grep -i -E 'nerd|jetbrains|font'
pacman -Si awww waypaper paru
```

## 4. Quickshell de prueba en el scratchpad (sin instalar nada en el sistema)

Para poder probar el QML antes de que el usuario instale `quickshell`, se bajó el paquete y
se extrajo en una carpeta temporal (`$S` = scratchpad de la sesión de Claude Code):

```bash
pacman -Sp quickshell                                   # URLs del paquete y dependencias
mkdir -p $S/qs-pkgs $S/qs-root && cd $S/qs-pkgs
for u in $(pacman -Sp quickshell); do curl -sSfLO "$u"; done
for f in *.pkg.tar.zst; do tar --zstd -xf "$f" -C $S/qs-root; done
tar --force-local --zstd -xf "$S/qs-pkgs/libdwarf-1:2.3.3-1.1-x86_64_v3.pkg.tar.zst" -C $S/qs-root   # el ":" confundía a tar
# $S/qs-test.sh = wrapper que exporta LD_LIBRARY_PATH / QML_IMPORT_PATH / QT_PLUGIN_PATH y ejecuta $S/qs-root/usr/bin/quickshell
$S/qs-test.sh --version                                  # Quickshell 0.3.2
timeout 8 $S/qs-test.sh -p ~/dotfiles/config/quickshell/mishell   # prueba base: carga sin errores
```

## 5. Verificaciones de hardware para las funciones nuevas

```bash
# Teclado
hyprctl devices -j      # teclado principal, active_keymap = "Spanish (Latin American)"
hyprctl getoption input:kb_layout

# Batería / límite de carga (UPower)
upower -e | grep battery_BAT
busctl get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.UPower.Device \
    ChargeThresholdSupported ChargeThresholdEnabled ChargeStartThreshold ChargeEndThreshold ChargeThresholdSettingsSupported
# Prueba del switch: encender, apagar y volver a encender (quedó ENCENDIDO, como estaba)
busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.UPower.Device EnableChargeThreshold b true
busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.UPower.Device EnableChargeThreshold b false
busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.UPower.Device EnableChargeThreshold b true
cat /sys/class/power_supply/BAT1/charge_types                               # Fast Standard [Long_Life]
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode     # 1

# Sensores (el CPU AMD usa k10temp, no coretemp)
for h in /sys/class/hwmon/hwmon*; do echo "$h $(cat $h/name) $(cat $h/temp1_input)"; done
grep -m1 'model name' /proc/cpuinfo
hyprctl monitors | head -4

# Modos de energía: se probaron los 3 y se dejó en balanceado
for p in power-saver performance balanced; do
    powerprofilesctl set $p && sleep 1 && echo "$p -> $(powerprofilesctl get) $(cat /sys/firmware/acpi/platform_profile) $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
done
systemctl is-enabled power-profiles-daemon     # disabled (arranca por D-Bus)
systemctl is-active power-profiles-daemon      # active

# Parser de red y disco que usa SysStats
awk 'NR>2 { sub(/^ +/, ""); split($0, a, /[: ]+/); if (a[1] != "lo") { rx += a[2]; tx += a[10] } } END { print "NET", rx+0, tx+0 }' /proc/net/dev
df -B1 --output=used,size / | tail -1

# NVIDIA
nvidia-smi --query-gpu=driver_version,name,pci.bus_id --format=csv,noheader     # 620.73.04
cat /sys/module/nvidia_drm/initstate                                            # live
ls /sys/module/ | grep -E '^(i915|xe|amdgpu)$' || echo "sin iGPU"
pacman -Q libva-nvidia-driver

# uwsm: ¿la sesión la maneja uwsm?
uwsm check is-active                                       # exit 0 -> falso positivo (mira graphical-session.target)
systemctl --user list-units --no-pager 'wayland-*' 'graphical-session*'
systemctl --user -q is-active 'wayland-wm@*.service'       # exit 4 -> no hay uwsm (esta es la que se usa)
```

## 6. Cambios en los dotfiles (archivos editados / creados)

Las ediciones de archivos se hicieron con las herramientas de edición de Claude Code y con
pequeños scripts `python3` de reemplazo exacto de texto. El detalle exacto está en `git diff`.

```bash
# Renombres para evitar choques de nombres entre qs.bar.modules y qs.bar.services
mv bar/services/Gpu.qml bar/services/GpuStats.qml
mv bar/modules/Teclado.qml bar/modules/Idioma.qml

# Los iconos Font Awesome de Cpu/Memory/Temperature se perdieron al reescribir esos
# archivos (la trampa que avisa el README); se recuperaron desde git:
git show HEAD:config/quickshell/mishell/bar/modules/{Cpu,Memory,Temperature}.qml   # (vía python3, línea `icono:`)
git diff | python3 -c '...'      # comprobación: ningún glifo de uso privado eliminado

sed -i 's#...bateria | reloj | media | brillo | volumen#...| sistema#' config/quickshell/mishell/shell.qml
```

| Archivo | Cambio |
|---|---|
| `bar/services/SysStats.qml` | Reescrito: + swap, red, loadavg, uptime, disco, modelo de CPU, SO, kernel, **historial** para gráficas; temperatura por nombre de hwmon (k10temp) |
| `bar/services/GpuStats.qml` | **Nuevo**: NVIDIA (`nvidia-smi`, sin despertar la dGPU si está suspendida) o AMD (sysfs) |
| `bar/services/Teclado.qml` | **Nuevo**: distribución activa (evento `activelayout`) y `switchxkblayout all next` |
| `bar/services/LimiteCarga.qml` | **Nuevo**: límite de carga por UPower `EnableChargeThreshold` |
| `bar/Grafica.qml` | **Nuevo**: gráfica de líneas (Canvas) |
| `bar/popups/SystemPopup.qml` | **Nuevo**: panel «Sistema» (CPU, Memoria, GPU, Red, Sistema, Recursos) |
| `bar/modules/Idioma.qml` | **Nuevo**: módulo `ES`/`EN` |
| `bar/modules/Gpu.qml` | **Nuevo**: temperatura de la GPU en la barra |
| `bar/modules/{Cpu,Memory,Temperature}.qml` | Clic abre el panel de sistema (CPU: clic derecho = btop) |
| `bar/modules/Battery.qml` | Estado «enchufada · carga en pausa» (límite alcanzado) |
| `bar/popups/BatteryPopup.qml` | Switch «Limitar carga al 80 %» |
| `bar/Bar.qml` | Módulos Gpu e Idioma + popup `sistema` |
| `bar/BarConfig.qml` | Intervalos, historial, sensores, colores del panel, etiquetas de teclado |
| `logout/LogoutOverlay.qml` | Cerrar sesión sin uwsm (`hl.dsp.exit()`) |
| `hypr/modules/input.lua` | `kb_layout = "latam,us"`; `accel_profile = "flat"` (antes era `nil`) |
| `hypr/modules/binds.lua` | `SUPER + K` cambia el teclado |
| `hypr/modules/env.lua` | Variables de NVIDIA si es la única GPU |
| `README.md` | Documentación de todo lo anterior |

## 7. Instalación de los configs (symlinks)

```bash
# Respaldo de lo que traía CachyOS/noctalia
mkdir -p ~/.config-backup-noctalia-20261122
cd ~/.config && mv hypr kitty fish ~/.config-backup-noctalia-20261122/
# Enlaces (como indica el README)
for d in hypr quickshell waybar swaync wifi-manager rofi kitty fish fastfetch starship.toml; do
    ln -s ~/dotfiles/config/$d ~/.config/$d
done

# Verificación
hyprctl reload && hyprctl configerrors          # sin errores
hyprctl getoption input:kb_layout               # latam,us
hyprctl getoption input:accel_profile           # flat
hyprctl binds -j | python3 -c '...'             # SUPER + K registrado
```

## 8. Pruebas en vivo con el quickshell de prueba

```bash
# Panel de sistema y batería abiertos por IPC + captura de pantalla
timeout 40 $S/qs-test.sh -p ~/dotfiles/config/quickshell/mishell &
$S/qs-test.sh ipc -p ~/dotfiles/config/quickshell/mishell call bar popup sistema
grim -o eDP-1 $S/shot-sistema.png
$S/qs-test.sh ipc -p ~/dotfiles/config/quickshell/mishell call bar popup bateria
grim -o eDP-1 $S/shot-bateria.png

# Módulo de teclado: ES -> EN -> ES
hyprctl switchxkblayout all next ; grim -g "1100,0 820x110" $S/kb-2.png
hyprctl switchxkblayout all next ; grim -g "1100,0 820x110" $S/kb-3.png
ffmpeg -loglevel error -y -i $S/kb-1.png -i $S/kb-2.png -i $S/kb-3.png -filter_complex vstack=inputs=3 $S/kb-all.png

# Carga final: sin errores ni warnings (salvo swaync-client, aún no instalado)
timeout 12 $S/qs-test.sh -p ~/dotfiles/config/quickshell/mishell
git -C ~/dotfiles status --short
```

---

## 9. PENDIENTE: lo que tiene que correr el usuario (pide sudo)

```bash
# Paquetes que faltan (repos oficiales + CachyOS)
sudo pacman -S --needed quickshell swaync hyprlock hypridle hyprpolkitagent \
    awww mpvpaper waypaper imagemagick playerctl rofi wofi zenity blueman \
    starship nemo ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols paru
sudo systemctl enable power-profiles-daemon

# AUR (ucs = colores desde el wallpaper; wifi-manager = panel de WiFi)
paru -S ucs-git wifi-manager-git

# Cerrar sesión y volver a entrar (SUPER + SHIFT + ESC) para que arranque mishell
# y se apliquen las variables de NVIDIA de env.lua.
```

## 10. Cómo volver atrás

```bash
cd ~/.config && rm hypr kitty fish quickshell waybar swaync wifi-manager rofi fastfetch starship.toml
mv ~/.config-backup-noctalia-20261122/* ~/.config/
hyprctl reload
```

## 11. Después de instalar los paquetes (revisión de la fuente)

```bash
# ¿Quedó todo instalado? (sí: los 21 paquetes, incluidos ucs-git y wifi-manager-git)
for p in quickshell swaync ... ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols paru ucs-git wifi-manager-git; do pacman -Qq $p; done
fc-list | grep -i -E 'jetbrains|symbols nerd'
fc-match "JetBrainsMono Nerd Font"          # JetBrainsMonoNerdFont-Regular.ttf
fc-match "Symbols Nerd Font"
ps -eo pid,cmd | grep -E 'quickshell|qs -c|noctalia|swaync'    # mishell y swaync corriendo, noctalia no
tail -30 /var/log/pacman.log
# Capturas de la barra y del panel de sistema ya con la fuente
grim -g "0,0 1920x60" $S/bar-now.png
qs ipc -c mishell call bar popup sistema && grim -g "0,0 1100x700" $S/sis-now.png
grep -n -i font ~/.config/kitty/kitty.conf ~/.config/rofi/config.rasi ~/.config/swaync/style.css
```

## 12. Repo por SSH y commits

```bash
git -C ~/dotfiles remote set-url origin git@github.com:4rias01/dotfiles.git   # (lo hizo el usuario)
git remote -v && git branch -vv
git status --short
git diff config/fish/fish_variables config/hypr/modules/monitors.lua   # cambios del usuario/fish: NO se commitean
git config user.name "4rias01"                              # solo en este repo (no --global)
git config user.email "$(git log -1 --format=%ae)"          # el mismo de los commits anteriores

git add config/hypr/modules/input.lua config/hypr/modules/binds.lua && git commit -m "Hyprland: teclado latam + us con SUPER+K; ..."
git add config/hypr/modules/env.lua && git commit -m "Hyprland: variables de NVIDIA cuando es la única GPU"
git add config/quickshell/mishell/logout/LogoutOverlay.qml && git commit -m "mishell: cerrar sesión sin uwsm"
# Bar.qml y BarConfig.qml mezclaban cambios de varias funciones: para el commit del
# teclado se armó una versión intermedia (HEAD + solo lo del teclado) y se puso en el índice
git hash-object -w --stdin < version-intermedia && git update-index --cacheinfo 100644,<hash>,<ruta>   # (vía python3)
git add .../services/Teclado.qml .../modules/Idioma.qml && git commit -m "mishell: módulo de teclado ES/EN en la barra"
git add <SysStats GpuStats Grafica SystemPopup Gpu Cpu Memory Temperature Bar BarConfig shell.qml> && git commit -m "mishell: panel de sistema con gráficas y soporte de GPU"
git add .../LimiteCarga.qml .../BatteryPopup.qml .../Battery.qml && git commit -m "mishell: limitar carga de la batería al 80 %"
git add README.md COMANDOS.md && git commit -m "Docs: README de la rama lenovo y COMANDOS.md"
git log -7 --format=%B | grep -i -E 'claude|co-authored|anthropic'   # -> nada: sin autoría de Claude
git commit --amend --no-edit      # para incluir esta sección en el commit de docs
```
