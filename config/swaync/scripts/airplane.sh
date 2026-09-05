#!/usr/bin/env bash
# airplane.sh  --  modo avion: bloquea/desbloquea TODAS las radios (wifi,
# bluetooth, wwan) con rfkill. Hace falta estar en el grupo `rfkill`.
#
#   airplane.sh on | off | toggle
#   airplane.sh status   -> "true" si no queda ninguna radio sin bloquear
#   airplane.sh set      -> lee $SWAYNC_TOGGLE_STATE (boton toggle de swaync)
is_on() { ! rfkill list | grep -q "Soft blocked: no"; }

case "${1:-toggle}" in
    on)     rfkill block all ;;
    off)    rfkill unblock all ;;
    toggle) if is_on; then rfkill unblock all; else rfkill block all; fi ;;
    status) if is_on; then echo true; else echo false; fi ;;
    set)    if [ "$SWAYNC_TOGGLE_STATE" = "true" ]; then rfkill block all; else rfkill unblock all; fi ;;
    *)      echo "uso: $0 on|off|toggle|status|set" >&2; exit 1 ;;
esac
