#!/usr/bin/env bash
# sound.sh  --  sonido de las notificaciones (lo llama swaync por "scripts" en
# config.json, una vez por notificacion recibida).
#
#   sound.sh normal | critical
#
# En "No molestar" no suena nada. Las de bateria NO pasan por aqui: las hace
# sonar la barra (bar/BatteryNotifier.qml, BarConfig.sonidoAviso) para que
# suenen aunque swaync no este.
[ "$(swaync-client -D 2>/dev/null)" = "true" ] && exit 0

case "${1:-normal}" in
    critical) f=/usr/share/sounds/freedesktop/stereo/dialog-warning.oga ;;
    *)        f=/usr/share/sounds/freedesktop/stereo/message.oga ;;
esac
exec paplay "$f"
