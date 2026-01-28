#!/bin/bash

# ---- CONFIGURACION ----
TERMINAL="kitty"
SLEEP_TIME=0.3

sleep 5

apps=(
	"spotify|Spotify"
	"kitty --class cava -e cava|cava"
	"kitty --class Pipes.sh -e pipes.sh|Pipes.sh"
	"kitty --class Peaclock -e peaclock|Peaclock"
	)

move_to_magic() {
  local class="$1"

  addr=$(hyprctl clients -j | jq -r \
    ".[] | select(.class==\"$class\") | .address" | tail -n1)

  [ -n "$addr" ] && \
    hyprctl dispatch movetoworkspace special:magic,address:"$addr"
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


