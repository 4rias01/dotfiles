-------------------
--- MY PROGRAMS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Start/

-- Las variables `$var` de hyprlang ya no existen. Este modulo devuelve una tabla
-- que otros archivos consumen con: local programs = require("modules/programs")

return {
    terminal    = "kitty",
    fileManager = "nemo",
    menu        = "~/.config/rofi/launcher.sh",
}
