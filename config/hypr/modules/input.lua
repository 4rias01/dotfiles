-----------
--- INPUT ---
-----------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        -- Dos distribuciones: espanol latino e ingles (EE. UU.). Se cambia con
        -- SUPER + K (binds.lua) o con clic en el modulo ES/EN de la barra.
        -- La barra lee la activa del evento `activelayout` de Hyprland.
        kb_layout  = "latam,us",
        kb_variant = ",",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        accel_profile = "flat",   -- string: sin comillas era una variable Lua nil y se ignoraba
        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.4,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- gesture = 3, horizontal, workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = "special",
    workspace_name = "magic",  -- el mismo nombre que usás en toggle_special
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
