#!/usr/bin/env bash
# Vigila WirePlumber y, si se cae el enlace de voz (SCO/HFP) de unos audífonos
# Bluetooth en plena llamada, los reconecta y devuelve las apps a ellos.
#
# En el AX201 el SCO con mSBC muere solo ("Failure in Bluetooth audio transport
# .../fdN") y Meet/Discord quedan pegados a un nodo muerto: sin audio ni micro.
# Cambiar de perfil no revive el micro; reconectar sí.
#
# Solo reacciona a transportes SCO (".../dev_XX/fdN"). Los A2DP (".../sepN/fdN")
# fallan en cada cambio automático A2DP -> HFP y son inofensivos.

COOLDOWN=20      # s sin reaccionar tras una recuperación (la reconexión también loguea fallos)
MAX_TRIES=3      # recuperaciones máximas por ventana
WINDOW=300       # s

last=0
tries=()

notify() { notify-send -a "Audífonos" -i audio-headset-bluetooth "$@" 2>/dev/null; }

# El sink usa la MAC con "_" y la fuente con ":" (bluez_input.84:AC:...), según
# el perfil; se aceptan ambas.
bt_node() { # $1 = sinks|sources, $2 = prefijo, $3 = MAC
    pactl list short "$1" | awk -v p="$2" -v a="$3" -v b="${3//:/_}" \
        'index($2, p) == 1 && $2 !~ /\.monitor$/ && (index($2, a) || index($2, b)) {print $2; exit}'
}

recover() {
    local mac="$1" # 84:AC:60:04:25:37

    notify "Se cayó el micrófono Bluetooth" "Reconectando los audífonos…"
    bluetoothctl disconnect "$mac" >/dev/null
    sleep 2
    bluetoothctl connect "$mac" >/dev/null

    local sink="" source=""
    for _ in $(seq 20); do
        sink=$(bt_node sinks bluez_output. "$mac")
        source=$(bt_node sources bluez_input. "$mac")
        [ -n "$sink" ] && [ -n "$source" ] && break
        sleep 0.5
    done
    if [ -z "$sink" ] || [ -z "$source" ]; then
        notify -u critical "No se pudieron reconectar los audífonos" "Reconéctalos a mano."
        return
    fi

    pactl set-default-sink "$sink"
    pactl set-default-source "$source"

    pactl list short sink-inputs | while read -r id _; do
        pactl move-sink-input "$id" "$sink"
    done

    # Mover solo capturas de micrófonos: las de monitores (cava, visualizadores)
    # no, o forzarían el modo manos libres para siempre.
    local monitors
    monitors=$(pactl list short sources | awk '$2 ~ /\.monitor$/ {print $1}')
    pactl list short source-outputs | while read -r id src _; do
        grep -qx "$src" <<<"$monitors" || pactl move-source-output "$id" "$source"
    done

    notify "Audífonos reconectados" "El micrófono debería volver en unos segundos."
}

journalctl --user -f -n 0 -o cat -u wireplumber | while read -r line; do
    [[ "$line" =~ Failure\ in\ Bluetooth\ audio\ transport\ /org/bluez/hci[0-9]+/dev_([0-9A-F_]+)/fd[0-9]+$ ]] || continue

    now=$(date +%s)
    (( now - last < COOLDOWN )) && continue

    recent=()
    for t in "${tries[@]}"; do (( now - t < WINDOW )) && recent+=("$t"); done
    tries=("${recent[@]}")
    if (( ${#tries[@]} >= MAX_TRIES )); then
        notify -u critical "El micrófono Bluetooth sigue fallando" \
            "Usa el micrófono del laptop para esta llamada."
        last=$now
        continue
    fi

    mac="${BASH_REMATCH[1]//_/:}"
    last=$now
    tries+=("$now")
    recover "$mac"
done
