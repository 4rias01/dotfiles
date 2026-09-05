#!/usr/bin/env bash
# night.sh  --  modo noche (filtro calido) con el screen_shader de Hyprland.
#
#   night.sh on | off | toggle   -> aplicar
#   night.sh status              -> "true"/"false"  (update-command de swaync)
#   night.sh set                 -> lee $SWAYNC_TOGGLE_STATE (boton toggle de swaync)
#
# El estado queda en $XDG_STATE_HOME/mishell/night-mode para que
# hypr/modules/night.lua lo reponga al recargar Hyprland (hyprctl reload).
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/mishell/night-mode"
SHADER="$HOME/.config/hypr/shaders/night.frag"

on()  { mkdir -p "$(dirname "$STATE")"; : > "$STATE"
        hyprctl eval "hl.config({ decoration = { screen_shader = \"$SHADER\" } })" >/dev/null; }
off() { rm -f "$STATE"
        hyprctl eval 'hl.config({ decoration = { screen_shader = "" } })' >/dev/null; }
is_on() { [ -e "$STATE" ]; }

case "${1:-toggle}" in
    on)     on ;;
    off)    off ;;
    toggle) if is_on; then off; else on; fi ;;
    status) if is_on; then echo true; else echo false; fi ;;
    set)    if [ "$SWAYNC_TOGGLE_STATE" = "true" ]; then on; else off; fi ;;
    *)      echo "uso: $0 on|off|toggle|status|set" >&2; exit 1 ;;
esac
