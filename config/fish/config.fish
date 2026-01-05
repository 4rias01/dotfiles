source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# SSH agent (fish)
if not set -q SSH_AUTH_SOCK
	ssh-agent -c | source
	ssh-add ~/.shh/id_ed25519 >/dev/null 2>&1
end
