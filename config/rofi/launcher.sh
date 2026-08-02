#!/bin/bash
# El fondo actual lo publica el picker de quickshell en una ruta fija. Ese
# symlink apunta a la MINIATURA cacheada, no al original: siempre es un JPEG,
# asi que esto sigue funcionando cuando el fondo es un mp4 o un gif (magick no
# abre ninguno de los dos).
LINK=~/.cache/quickshell-wallpaper/current_symlink
CROPPED="/tmp/rofi_wallpaper.jpg"
LAST_USED="/tmp/rofi_last_wallpaper"

# Lo que hay que comparar es a DONDE apunta el symlink, no el symlink en si: su
# ruta es fija y no cambia nunca, asi que comparandola el crop se generaba una
# sola vez y se quedaba congelado para siempre por mas que cambiaras de fondo.
# El destino si cambia con cada uno (la miniatura lleva el md5 del original en
# el nombre). -e ademas devuelve vacio si el link esta roto o no existe.
WALLPAPER=$(readlink -e "$LINK")

# Solo recortar si el wallpaper cambió o no existe el crop
if [ -n "$WALLPAPER" ] && { [ ! -f "$CROPPED" ] || [ "$WALLPAPER" != "$(cat "$LAST_USED" 2>/dev/null)" ]; }; then
    HEIGHT=$(magick identify -format "%h" "$WALLPAPER" 2>/dev/null)
    if [ -n "$HEIGHT" ]; then
        WIDTH=$(echo "$HEIGHT * 1.1" | bc | cut -d'.' -f1)
        # El marcador solo se escribe si el crop de verdad salio: si falla, el
        # proximo lanzamiento lo reintenta en vez de dar por bueno el de antes.
        magick "$WALLPAPER" -gravity Center -crop "${WIDTH}x${HEIGHT}+0+0" +repage "$CROPPED" \
            && printf '%s\n' "$WALLPAPER" > "$LAST_USED"
    fi
fi

rofi -no-config -theme ~/.config/rofi/config.rasi \
     -theme-str "imagebox { background-image: url(\"$CROPPED\", height); }" \
     -scroll-method 1 \
     -show drun
