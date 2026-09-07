-- SOURCES
-- En lua se usa require() en lugar de `source =`.
-- Las rutas son relativas a la ubicacion de este archivo (~/.config/hypr/).

require("modules/programs")
require("modules/autostart")
require("modules/binds")
require("modules/monitors")
require("modules/env")
require("modules/decoration")
-- por aca irian los permisos algun dia
-- require("modules/animations")
require("modules/workspaces")
require("modules/input")
require("modules/windowrules")
require("modules/night")        -- repone el modo noche (swaync) tras un reload



-------------------
--- PERMISSIONS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--     ecosystem = {
--         enforce_permissions = true,
--     },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
