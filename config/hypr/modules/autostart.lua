-----------------
--- AUTOSTART ---
-----------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- `exec-once` se reemplaza por el evento "hyprland.start".
-- hl.exec_cmd() lanza el proceso de forma asincrona (no hace falta `& disown`).

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

-- local programs = require("modules/programs")
-- hl.on("hyprland.start", function()
--     hl.exec_cmd(programs.terminal)
--     hl.exec_cmd("nm-applet")
--     hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)

-- Mis llamados
hl.on("hyprland.start", function()
    hl.exec_cmd("wifi-manager")
    hl.exec_cmd("qs -c mishell")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd("waybar & swaync & hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")

    -- hl.exec_cmd('mpvpaper -s -o "no-audio loop" eDP-1 ~/.config/hypr/wp/mpvpaper2.mp4')
    -- hl.exec_cmd("~/.config/hypr/scripts/magic-launcher.sh")
    -- hl.exec_cmd("hyprpaper")
end)
