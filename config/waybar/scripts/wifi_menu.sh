#!/bin/bash

nmcli device wifi rescan

chosen=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list \
  | sed 's/^*/* /' \
  | awk -F: '{printf "%s: %s (%s) %s\n", $2, $4, $3, $1}' \
  | wofi --dmenu --prompt "Wi-Fi")

[ -z "$chosen" ] && exit

ssid=$(echo "$chosen" | cut -d':' -f1)

security=$(nmcli -t -f SSID,SECURITY device wifi list | grep -F "$ssid")

if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    # Usa la contraseña guardada
    nmcli device wifi connect "$ssid"
    echo "clave ya guardada"
elif [ -n "$security" ] && [ "$security" != "--" ]; then
  password=$(wofi --dmenu --password --prompt "Password")
  nmcli device wifi connect "$ssid" password "$password"
  echo "wifi no registrado, ingresando clave"
else
  nmcli device wifi connect "$ssid"
  echo "wifi sin clave, conectando"
fi
