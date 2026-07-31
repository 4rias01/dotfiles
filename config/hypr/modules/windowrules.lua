------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

-- Example windowrules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",

    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({ match = { class = "(firefox|brave-browser|zen)" },        opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "code" },                              opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "libreoffice-writer" },                opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "spotify" },                           opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "claude-desktop" },                    opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "cohesion" },                          opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "obsidian" },                          opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "drracket" },                          opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "org.kde.okular" },                    opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "com.github.xournalpp.xournalpp" },    opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "waypaper" },                          opacity = "0.9 override 0.9 override" })
hl.window_rule({ match = { class = "zoom" },                              opacity = "0.9 override 0.9 override" })

-- Juegos Steam (XWayland)
hl.window_rule({ match = { class = "^steam_app_.*$" }, opacity = "1.0 override 1.0 override" })

-- Fix Zoom popups en Hyprland 0.54+
hl.window_rule({ match = { class = "^(zoom)$", title = "^(menu window)$" },    stay_focused = true })
hl.window_rule({ match = { class = "^(zoom)$", title = "^(confirm window)$" }, stay_focused = true })
