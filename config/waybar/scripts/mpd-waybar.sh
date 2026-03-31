#!/bin/bash

WIDTH=25
MODULE_WIDTH=29
SPEED=0.2  # segundos por frame

# Icons
PREFIX_PLAY=" | "
PREFIX_PAUSE=" | "
PREFIX_STOP=" | "
STOP_TEXT="Music Off"

status=$(playerctl status 2>/dev/null || echo "Stopped")

case "$status" in
    "Playing"|"Paused")
        song=$(playerctl metadata --format '{{artist}} - {{title}}')
        ;;
    *)
        echo "${PREFIX_STOP}${STOP_TEXT}"
        exit 0
        ;;
esac

[ -z "$song" ] && song="Unknown"
msg="${song} "
len=${#msg}

# Guardar índice en archivo para continuidad
STATE="$HOME/.cache/spotify_scroll"
[ -f "$STATE" ] && start=$(cat "$STATE") || start=0

# Obtener el próximo frame
slice=""
for ((i=0; i<WIDTH; i++)); do
    idx=$(( (start+i) % len ))
    slice="$slice${msg:idx:1}"
done

# Guardar próximo índice
echo $(( (start+1) % len )) > "$STATE"

if [ "$status" = "Playing" ]; then
    output="${PREFIX_PLAY}${slice}"
else
    output="${PREFIX_PAUSE}${slice}"
fi

# Control de velocidad REAL
sleep "$SPEED"

echo "$output"