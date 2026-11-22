#!/usr/bin/env bash
# toggle-skip.sh — alterna skip-worktree en archivos de configuración
set -euo pipefail

FILES=(
  config/fastfetch/config.jsonc
  config/hypr/modules/decoration.conf
  config/hypr/modules/decoration.lua
  config/peaclock/config
  config/quickshell/mishell/bar/BarColors.qml
  config/quickshell/mishell/config/Theme.qml
  config/starship.toml
  config/swaync/colors.css
  config/waybar/style.css
)

# Ejecutar siempre desde la raíz del repo
cd "$(git rev-parse --show-toplevel)"

is_skipped() {
  [[ "$(git ls-files -v -- "$1" | cut -c1)" == [Ss] ]]
}

count_skipped() {
  local n=0
  for f in "${FILES[@]}"; do
    is_skipped "$f" && n=$((n + 1))
  done
  echo "$n"
}

show_status() {
  for f in "${FILES[@]}"; do
    if is_skipped "$f"; then
      printf '  \e[33m[skip]\e[0m %s\n' "$f"
    else
      printf '  \e[32m[ ok ]\e[0m %s\n' "$f"
    fi
  done
}

skip_on() {
  git update-index --skip-worktree -- "${FILES[@]}"
  echo "→ skip-worktree ACTIVADO (Git ignora los cambios)"
}

skip_off() {
  git update-index --no-skip-worktree -- "${FILES[@]}"
  echo "→ skip-worktree DESACTIVADO (Git vuelve a ver los cambios)"
}

case "${1:-toggle}" in
  on)     skip_on ;;
  off)    skip_off ;;
  status) show_status; exit 0 ;;
  toggle)
    if (( $(count_skipped) > 0 )); then skip_off; else skip_on; fi
    ;;
  *)
    echo "Uso: $(basename "$0") [toggle|on|off|status]"
    exit 1
    ;;
esac

show_status
