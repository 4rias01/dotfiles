#!/bin/bash
WALLPAPER=$(grep 'wallpaper =' ~/.config/waypaper/config.ini | cut -d' ' -f3 | sed "s|~|$HOME|")
CROPPED="/tmp/rofi_wallpaper.jpg"
LAST_USED="/tmp/rofi_last_wallpaper"

# Solo recortar si el wallpaper cambió o no existe el crop
if [ ! -f "$CROPPED" ] || [ ! -f "$LAST_USED" ] || [ "$WALLPAPER" != "$(cat $LAST_USED)" ]; then
    HEIGHT=$(magick identify -format "%h" "$WALLPAPER")
    WIDTH=$(echo "$HEIGHT * 1.1" | bc | cut -d'.' -f1)
    magick "$WALLPAPER" -gravity Center -crop "${WIDTH}x${HEIGHT}+0+0" +repage "$CROPPED"
    echo "$WALLPAPER" > "$LAST_USED"
fi

rofi -no-config -theme ~/.config/rofi/config.rasi \
     -theme-str "imagebox { background-image: url(\"$CROPPED\", height); }" \
     -scroll-method 1 \
     -show drun