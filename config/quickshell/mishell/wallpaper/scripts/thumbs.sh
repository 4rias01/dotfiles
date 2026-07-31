#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  thumbs.sh  --  cache de miniaturas para el picker.
#
#  El problema: una tarjeta del carrusel mide ~480 px de alto, pero el archivo
#  original es un 4K de 3-6 MB. Peor con PNG, que no tiene decodificacion
#  escalada: Qt descomprime los 3840x2160 enteros para pintar la tarjeta. Por
#  eso las miniaturas tardaban segundos en aparecer.
#
#  La solucion: una copia chica en $CACHE/thumbs, y que el picker SOLO lea de
#  ahi. Se genera una vez; despues abrir el picker es instantaneo.
#
#  Uso:
#    thumbs.sh <cacheDir> <altura> <jobs> <wallpaperDir> <desde> <ext1> [ext2 ...]
#
#  Por stdout imprime la ruta ABSOLUTA de cada archivo cuya miniatura ya esta
#  lista, una por linea, a medida que se van generando. El picker escucha esas
#  lineas (SplitParser) y va rellenando las tarjetas.
#
#  <desde> es la ruta del wallpaper en el que el picker esta centrado (puede ir
#  vacia). El recorrido ARRANCA AHI y se abre hacia los dos lados: desde, +1,
#  -1, +2, -2... Asi las tarjetas que estas viendo son siempre las primeras en
#  reportarse, sin importar si el wallpaper actual esta al principio o al final
#  de la lista. Recorriendo en orden alfabetico, un wallpaper en el medio del
#  carrusel tenia que esperar a que pasaran las ~100 lineas previas.
#
#  El nombre de la miniatura es md5(ruta absoluta).jpg, que es lo mismo que
#  calcula Qt.md5() en WallpaperPicker.qml. Si cambias uno, cambia el otro.
# ---------------------------------------------------------------------------
set -uo pipefail

# --- modo interno: generar UNA miniatura -----------------------------------
#     Se invoca a si mismo por cada archivo via xargs -P (en paralelo).
if [ "${1:-}" = "--one" ]; then
    height="$2"; src="$3"; thumb="$4"

    # Se escribe a un temporal y se mueve al final. El mv es atomico dentro del
    # mismo filesystem, asi que el picker nunca ve un JPEG a medio escribir.
    # Esto importa de verdad: si recargas la config (o reinicias) mientras se
    # generan miniaturas, magick muere a mitad de archivo, y escribiendo directo
    # sobre la ruta final ese archivo roto se quedaria cacheado para siempre
    # (existe y es mas nuevo que el original, asi que nadie lo regeneraria).
    # El sufijo mantiene el .jpg: magick y ffmpeg deducen el formato de ahi.
    tmp="${thumb%.jpg}.part$$.jpg"

    case "${src,,}" in
        *.mp4|*.mkv|*.webm|*.mov)
            # Un frame del segundo 3; si el video es mas corto, el primero.
            ffmpeg -y -loglevel quiet -ss 3 -i "$src" \
                   -frames:v 1 -vf "scale=-2:$height" "$tmp" 2>/dev/null \
            || ffmpeg -y -loglevel quiet -i "$src" \
                   -frames:v 1 -vf "scale=-2:$height" "$tmp" 2>/dev/null
            ;;
        *)
            # [0] -> solo el primer frame (gif/webp animados).
            # x$height> -> solo reduce, nunca agranda.
            magick "$src[0]" -auto-orient -resize "x$height>" \
                   -quality 82 "$tmp" 2>/dev/null
            ;;
    esac

    # Solo se avisa si de verdad salio algo.
    if [ -s "$tmp" ] && mv -f "$tmp" "$thumb"; then
        printf '%s\n' "$src"
    else
        rm -f "$tmp"
    fi
    exit 0
fi

# --- modo normal ------------------------------------------------------------
cache="$1"; height="$2"; jobs="$3"; dir="$4"; desde="$5"; shift 5

# jobs <= 0 (o basura) -> tantos como nucleos.
[ "$jobs" -gt 0 ] 2>/dev/null || jobs="$(nproc)"

# La altura va en la ruta: cambiar thumbHeight invalida el cache solo, sin
# tener que acordarse de borrarlo a mano (el chequeo de frescura de mas abajo
# solo compara fechas contra el original, no sabria que la altura cambio).
thumbs="$cache/thumbs/$height"
mkdir -p "$thumbs" || exit 1

# Expresion de find a partir de las extensiones que pasa WallpaperConfig.
find_args=()
for ext in "$@"; do
    [ ${#find_args[@]} -gt 0 ] && find_args+=(-o)
    find_args+=(-iname "*.$ext")
done
[ ${#find_args[@]} -eq 0 ] && exit 0

queue="$(mktemp)"
trap 'rm -f "$queue"' EXIT

# Restos de una generacion que quedo a medias (proceso matado).
rm -f "$thumbs"/*.part*.jpg 2>/dev/null

# La lista completa, ordenada IGUAL que el scan del picker (LC_ALL=C sort -f):
# el indice en este array es el indice en el carrusel.
mapfile -d '' -t files < <(
    find -L "$dir" -type f \( "${find_args[@]}" \) -print0 | LC_ALL=C sort -zf
)
n=${#files[@]}
[ "$n" -eq 0 ] && exit 0

# Donde arrancar: el wallpaper actual si nos lo pasaron y sigue estando.
inicio=0
if [ -n "$desde" ]; then
    for i in "${!files[@]}"; do
        if [ "${files[$i]}" = "$desde" ]; then inicio="$i"; break; fi
    done
fi

# Orden de recorrido: inicio, +1, -1, +2, -2, ... o sea abriendose desde la
# tarjeta central hacia los dos lados.
orden=("$inicio")
for ((d = 1; d < n; d++)); do
    r=$((inicio + d)); l=$((inicio - d))
    [ "$r" -lt "$n" ] && orden+=("$r")
    [ "$l" -ge 0 ]    && orden+=("$l")
done

# Primera pasada: separar lo que ya esta hecho de lo que hay que generar.
# Las que ya existen se reportan al instante y no cuestan nada; asi abrir el
# picker por segunda vez no lanza ni un proceso de magick.
for i in "${orden[@]}"; do
    f="${files[$i]}"
    t="$thumbs/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
    if [ -s "$t" ] && [ "$t" -nt "$f" ]; then
        printf '%s\n' "$f"
    else
        printf '%s\0%s\0' "$f" "$t" >> "$queue"
    fi
done

# Segunda pasada: generar las que faltan, en paralelo.
[ -s "$queue" ] && xargs -0 -n2 -P "$jobs" "$0" --one "$height" < "$queue"

exit 0
