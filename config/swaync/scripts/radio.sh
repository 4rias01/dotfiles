#!/usr/bin/env bash
# radio.sh  --  toggles de wifi / bluetooth / no molestar para los botones de swaync.
# swaync parte el `command` con su propio parser y se atraganta con $(...) y
# comillas anidadas, por eso esto vive en un script y no inline en config.json.
#
#   radio.sh wifi|bt|dnd status   -> "true"/"false"      (update-command)
#   radio.sh wifi|bt|dnd set      -> lee $SWAYNC_TOGGLE_STATE (command del toggle)
#   radio.sh wifi|bt|dnd on|off
que="$1"; accion="${2:-status}"
[ "$accion" = set ] && { [ "$SWAYNC_TOGGLE_STATE" = true ] && accion=on || accion=off; }

case "$que:$accion" in
    wifi:status) [ "$(LC_ALL=C nmcli radio wifi)" = enabled ] && echo true || echo false ;;
    wifi:on)     nmcli radio wifi on ;;
    wifi:off)    nmcli radio wifi off ;;
    bt:status)   bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo true || echo false ;;
    bt:on)       bluetoothctl power on >/dev/null ;;
    bt:off)      bluetoothctl power off >/dev/null ;;
    dnd:status)  swaync-client -D ;;
    dnd:on)      swaync-client -dn ;;
    dnd:off)     swaync-client -df ;;
    *) echo "uso: $0 wifi|bt|dnd status|set|on|off" >&2; exit 1 ;;
esac
