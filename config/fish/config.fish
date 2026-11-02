source /usr/share/cachyos-fish-config/cachyos-config.fish

# Alias corregidos (sin el signo '=' y con argumentos separados)
alias peaclock "peaclock --config-dir ~/.config/peaclock"
alias aq "asciiquarium"
alias revivir-audio "! pactl set-card-profile bluez_card.84_AC_60_04_25_37 a2dp-sink && sleep 2 && pactl set-card-profile bluez_card.84_AC_60_04_25_37 headset-head-unit"
alias dcrm-exited 'docker container rm $(docker ps -aq -f status=exited)'
alias dcrm-running 'docker container rm $(docker container stop $(docker ps -q))'
# Overwrite greeting
function fish_greeting
    # Tu configuración personalizada aquí (vacío deshabilita el saludo)
end

function mkcd
    mkdir -p $argv[1]
    cd $argv[1]
end

function dcr
    docker container run $argv
end


# Inicialización de Starship Prompt
starship init fish | source

# SSH agent (fish) - Corregido error tipográfico en la ruta (.ssh)
#if not set -q SSH_AUTH_SOCK
#    ssh-agent -c | source
#    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
#end
