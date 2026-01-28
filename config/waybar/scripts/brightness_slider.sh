#!/bin/bash

current=$(brightnessctl get)
max=$(brightnessctl max)
percent=$((100 * current / max))

zenity --scale \
  --title="Brightness" \
  --text="Brillo del sistema" \
  --min-value=1 \
  --max-value=100 \
  --value=$percent \
  --width=300 \
  --timeout=0 \
  --print-partial \
| while read -r value; do
    brightnessctl set "${value}%"
  done
