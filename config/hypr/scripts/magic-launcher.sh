#!/bin/bash

# ---- CONFIGURACIÓN ----
TERMINAL="kitty"
MAX_WAIT=30
CHECK_INTERVAL=0.3  # Un poco más de tiempo entre checks
MOVE_DELAY=0.5      # Delay después de mover cada ventana

sleep 5

# Aplicaciones en orden de lanzamiento
declare -A apps=(
    ["spotify"]="spotify"
    ["cava"]="kitty --class cava -e cava"
    ["Pipes.sh"]="kitty --class Pipes.sh -e pipes.sh"
    ["cmatrix"]="kitty --class cmatrix -e unimatrix -c red -s 94"
)

# Orden específico de procesamiento
app_order=("spotify" "cava" "Pipes.sh" "cmatrix")

# Función mejorada para esperar ventanas
wait_for_window() {
    local class="$1"
    local elapsed=0
    local search_pattern="${class,,}"  # lowercase
    
    echo "  Buscando patrón: $search_pattern"
    
    while (( $(echo "$elapsed < $MAX_WAIT" | bc -l) )); do
        # Buscar por clase o título (algunas apps usan title en lugar de class)
        local addr=$(hyprctl clients -j | jq -r \
            ".[] | select(
                (.class | ascii_downcase | contains(\"$search_pattern\")) or 
                (.title | ascii_downcase | contains(\"$search_pattern\"))
            ) | .address" | head -n1)
        
        if [ -n "$addr" ]; then
            echo "  ✓ Encontrada en ${elapsed}s: $addr"
            return 0
        fi
        
        sleep "$CHECK_INTERVAL"
        elapsed=$(echo "$elapsed + $CHECK_INTERVAL" | bc)
    done
    
    echo "  ✗ No encontrada después de ${MAX_WAIT}s"
    return 1
}

# Función para verificar si una ventana está en el workspace correcto
check_workspace() {
    local addr="$1"
    local workspace=$(hyprctl clients -j | jq -r \
        ".[] | select(.address==\"$addr\") | .workspace.name")
    echo "$workspace"
}

# Función para mover con verificación
move_to_magic() {
    local addr="$1"
    local class="$2"
    
    # Verificar workspace actual
    local current_ws=$(check_workspace "$addr")
    echo "  Workspace actual: $current_ws"
    
    if [ "$current_ws" = "special:magic" ]; then
        echo "  Ya está en special:magic, omitiendo..."
        return 0
    fi
    
    # Intentar mover
    hyprctl dispatch movetoworkspace special:magic,address:"$addr" > /dev/null 2>&1
    sleep "$MOVE_DELAY"
    
    # Verificar que se movió
    local new_ws=$(check_workspace "$addr")
    if [ "$new_ws" = "special:magic" ]; then
        echo "  ✓ Movida correctamente a special:magic"
        return 0
    else
        echo "  ✗ Error al mover (workspace: $new_ws)"
        return 1
    fi
}

# Función para redimensionar Spotify
resize_spotify() {
    local width=804
    local height=716
    local addr=$(hyprctl clients -j | jq -r \
        '.[] | select(.class | ascii_downcase | contains("spotify")) | .address' | head -n1)
    
    if [ -n "$addr" ]; then
        hyprctl dispatch resizewindowpixel exact $width $height,address:"$addr" > /dev/null 2>&1
        echo "✓ Spotify redimensionado"
    fi
}

echo "=== Iniciando script de setup de workspace ==="

# Lanzar todas las aplicaciones
echo -e "\n[1/3] Lanzando aplicaciones..."
for class in "${app_order[@]}"; do
    echo "  Lanzando: $class"
    eval "${apps[$class]} &"
    sleep 0.3  # Pequeño delay entre lanzamientos
done

# Esperar y mover cada ventana
echo -e "\n[2/3] Esperando y moviendo ventanas..."
for class in "${app_order[@]}"; do
    echo "Procesando: $class"
    
    if wait_for_window "$class"; then
        addr=$(hyprctl clients -j | jq -r \
            ".[] | select(
                (.class | ascii_downcase | contains(\"${class,,}\")) or 
                (.title | ascii_downcase | contains(\"${class,,}\"))
            ) | .address" | head -n1)
        
        move_to_magic "$addr" "$class"
    fi
    echo ""
done

# Acomodar ventanas
echo "[3/3] Acomodando ventanas..."
sleep 1

# Verificar que Spotify existe antes de intentar manipularla
spotify_addr=$(hyprctl clients -j | jq -r \
    '.[] | select(.class | ascii_downcase | contains("spotify")) | .address' | head -n1)

if [ -n "$spotify_addr" ]; then
    echo "Acomodando Spotify..."
    hyprctl dispatch focuswindow address:"$spotify_addr" > /dev/null 2>&1
    sleep 0.2
    hyprctl dispatch swapwindow u > /dev/null 2>&1
    sleep 0.1
    hyprctl dispatch focuswindow address:"$spotify_addr" > /dev/null 2>&1
    sleep 0.1
    hyprctl dispatch swapwindow l > /dev/null 2>&1
    sleep 0.3
    resize_spotify
else
    echo "⚠ Spotify no encontrado, omitiendo acomodo"
fi

echo -e "\n=== Script completado ==="
