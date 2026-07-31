#!/usr/bin/env bash
# Copia el tema a /usr/share/sddm/themes/ con los permisos correctos.
#
# Por que copiar y no symlinkear: el greeter corre como el usuario `sddm`,
# que no puede atravesar tu $HOME. Un symlink a ~/dotfiles apunta a un
# lugar que el greeter no puede leer, y el resultado es pantalla negra
# sin ningun mensaje de error util.

set -euo pipefail

NAME="mi-sddm"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sddm/themes/$NAME"

echo ":: Instalando en $DEST"

sudo rm -rf "$DEST"
sudo mkdir -p "$DEST/Components" "$DEST/Backgrounds"

sudo install -Dm644 "$SRC/metadata.desktop" "$DEST/metadata.desktop"
sudo install -Dm644 "$SRC/theme.conf"       "$DEST/theme.conf"
sudo install -Dm644 "$SRC/Main.qml"         "$DEST/Main.qml"
sudo install -Dm644 "$SRC"/Components/*.qml "$DEST/Components/"

# Wallpapers: cualquier imagen que hayas puesto en Backgrounds/
shopt -s nullglob
for img in "$SRC"/Backgrounds/*.{png,jpg,jpeg,webp}; do
    sudo install -Dm644 "$img" "$DEST/Backgrounds/$(basename "$img")"
done
shopt -u nullglob

# Registrar el tema como activo (drop-in, no sobreescribe /etc/sddm.conf)
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "$NAME" | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null

# Desactivar el teclado virtual. SDDM trae InputMethod=qtvirtualkeyboard
# como DEFAULT, asi que hay que ponerlo explicitamente vacio.
# El numero 30- importa: los drop-ins se leen en orden y el ultimo gana.
printf '[General]\nInputMethod=\n' | sudo tee /etc/sddm.conf.d/30-no-virtualkbd.conf >/dev/null
sudo rm -f /etc/sddm.conf.d/20-virtualkbd.conf

echo ":: Listo. Probalo con:"
echo "   sddm-greeter-qt6 --test-mode --theme $DEST"