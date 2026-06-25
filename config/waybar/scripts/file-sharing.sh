#!/bin/bash

DIRECTORY=~/Shadow
CONTROL_FILE=~/.config/cache/file-sharing/.file-sharing-enabled
LOCK_FILE=~/.config/cache/file-sharing/.file-sharing.lock

toggle() {
    if [[ -f "$CONTROL_FILE" ]]; then
        rm "$CONTROL_FILE"
        rm "$LOCK_FILE"
        echo "Disabled file sharing"
    else
        touch "$CONTROL_FILE"
        echo "Enabled file sharing"
        start_loop &
    fi
}

start_loop() {
    if [[ -f "$LOCK_FILE" ]]; then
		exit 0
    fi
    touch "$LOCK_FILE"

    while [[ -f "$CONTROL_FILE" ]]; do
        if [ -d "$DIRECTORY" ] && [ "$(ls -A $DIRECTORY)" ]; then
            for file in "$DIRECTORY"/*; do
				case "$file" in
				    *.png)  mime="image/png" ;;
				    *.jpg|*.jpeg) mime="image/png" ;;
				    *.webp) mime="image/webp" ;;
				    *) mime="application/octet-stream" ;; # fallback genérico
				esac
				
				wl-copy --type "$mime" < "$file"
                rm "$file"
            done
        fi
        sleep 3
    done

    rm -f "$LOCK_FILE"
}

status() {
    if [[ -f "$CONTROL_FILE" ]]; then
        echo "󰒖"   # activo
    else
        echo "󰼣"   # inactivo
    fi
}

case "$1" in
    toggle)
        toggle
        pkill -RTMIN+11 waybar
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {toggle|status}"
        ;;
esac
