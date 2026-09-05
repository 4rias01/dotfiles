--------------------------
--- MODO NOCHE (shader) ---
--------------------------
-- El boton de la luna del centro de notificaciones (swaync/scripts/night.sh)
-- pone decoration:screen_shader en caliente con `hyprctl eval`. Como un
-- `hyprctl reload` vuelve a evaluar toda la config, aqui se repone el shader
-- si el modo noche quedo encendido (existe el archivo de estado).
--
-- Shader: ~/.config/hypr/shaders/night.frag  (ahi se ajusta la calidez)

local home  = os.getenv("HOME") or ""
local state = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/mishell/night-mode"

local f = io.open(state, "r")
if f then
    f:close()
    hl.config({
        decoration = {
            screen_shader = home .. "/.config/hypr/shaders/night.frag",
        },
    })
end
