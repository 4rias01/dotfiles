#!/bin/bash

# ---- CONFIGURACION ----
TERMINAL="kitty"
SLEEP_TIME=0.6

sleep 5

apps=(
	"spotify|Spotify"
	"kitty --class cava -e cava|cava"
	"kitty --class Pipes.sh -e pipes.sh|Pipes.sh"
	"kitty --class cmatrix -e cmatrix|cmatrix"
	)

move_to_magic() {
  local class="$1"

  addr=$(hyprctl clients -j | jq -r \
    ".[] | select(.class==\"$class\") | .address" | tail -n1)

  [ -n "$addr" ] && \
    hyprctl dispatch movetoworkspace special:magic,address:"$addr"
}

resize_spotify() {
  local width=804
  local height=716

  addr=$(hyprctl clients -j | jq -r \
    '.[] | select(.class=="spotify") | .address' | tail -n1)

  if [ -n "$addr" ]; then
    hyprctl dispatch resizewindowpixel exact $width $height,address:"$addr"
  fi
}


for entry in "${apps[@]}"; do
  cmd="${entry%%|*}"
  eval "$cmd &"
done

sleep "$SLEEP_TIME"

for entry in "${apps[@]}"; do
  class="${entry##*|}"
  move_to_magic "$class"
done

sleep 2

hyprctl dispatch focuswindow class:spotify
hyprctl dispatch swapwindow u
hyprctl dispatch focuswindow class:spotify
hyprctl dispatch swapwindow l

sleep 0.3
resize_spotify


