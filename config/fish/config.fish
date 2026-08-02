source /usr/share/cachyos-fish-config/cachyos-config.fish

# Alias corregidos (sin el signo '=' y con argumentos separados)
alias peaclock "peaclock --config-dir ~/.config/peaclock"
alias aq "asciiquarium"

# Overwrite greeting
function fish_greeting
    # Tu configuración personalizada aquí (vacío deshabilita el saludo)
end

# Inicialización de Starship Prompt
starship init fish | source

# SSH agent (fish) - Corregido error tipográfico en la ruta (.ssh)
#if not set -q SSH_AUTH_SOCK
#    ssh-agent -c | source
#    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
#end
