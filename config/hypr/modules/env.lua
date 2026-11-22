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

-------------
--- NVIDIA ---
-------------
-- Se detecta al cargar la config, asi el mismo archivo sirve en las dos
-- laptops (ver /sys/module/*: un modulo del kernel cargado tiene "initstate").
--
--  * NVIDIA como UNICA GPU (Lenovo LOQ 15ARP9: el Ryzen 5 7235HS no trae
--    grafica integrada, la RTX 4050 dibuja la pantalla): Hyprland, Xwayland
--    y la aceleracion de video tienen que ir por el driver de NVIDIA.
--  * Hibrida (iGPU Intel/AMD + NVIDIA): la iGPU dibuja y la NVIDIA queda
--    para lo que se lance con `prime-run`; no se fuerza nada, si no la dGPU
--    no se duerme nunca.
--
-- Antes esto lo ponia /etc/profile.d/Hyprland.sh del paquete
-- cachyos-hypr-noctalia; ahora vive en los dotfiles por si ese paquete se va.
local function moduloCargado(nombre)
    local f = io.open("/sys/module/" .. nombre .. "/initstate", "r")
    if f then f:close() return true end
    return false
end

local hayNvidia = moduloCargado("nvidia_drm")
local hayIgpu   = moduloCargado("i915") or moduloCargado("xe") or moduloCargado("amdgpu")

if hayNvidia and not hayIgpu then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")            -- VA-API (videos en el navegador, mpv)
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")    -- OpenGL de Xwayland
    hl.env("GBM_BACKEND", "nvidia-drm")              -- GBM del compositor
    hl.env("NVD_BACKEND", "direct")                  -- nvidia-vaapi-driver
    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")   -- Electron (VSCodium, Discord) en Wayland nativo
end
