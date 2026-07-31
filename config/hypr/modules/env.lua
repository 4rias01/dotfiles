---------------------------
--- ENVIRONMENT VARIABLES ---
---------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- `env = NOMBRE,VALOR` se reemplaza por hl.env("NOMBRE", "VALOR")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("SSH_AUTH_SOCK", "/run/user/1000/keyring/ssh")
