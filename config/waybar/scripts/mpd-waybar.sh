#!/bin/bash

WIDTH=25
STATE="$HOME/.cache/spotify_scroll"
SPEED=0.3

status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")
song=$(playerctl -p spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null)

if [[ "$status" == "Stopped" ]]; then
    echo " | Music Off"
    exit 0
fi

[ -z "$song" ] && song="Unknown"
msg="${song} "
len=${#msg}

# índice del scroll
[ -f "$STATE" ] && i=$(cat "$STATE") || i=0

# construir ventana
out=""
for ((k=0; k<WIDTH; k++)); do
    idx=$(( (i+k) % len ))
    out="$out${msg:idx:1}"
done

# guardar nuevo índice
echo $(( (i+1) % len )) > "$STATE"

# prefijo
if [[ "$status" == "Playing" ]]; then
    echo -n " | "
else
    echo -n " | "
fi


# salida final (UNA línea)
echo -n "$out"