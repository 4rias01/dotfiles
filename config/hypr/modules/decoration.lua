---------------------
--- LOOK AND FEEL ---
---------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    -- https://wiki.hypr.land/Configuring/Basics/Variables/#general
    general = {
        gaps_in  = 2,
        gaps_out = 10,

        border_size = 2,

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#variable-types for info about colors
        col = {
            active_border   = "rgba(6d5033ee)",
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.8,
        inactive_opacity = 0.75,

        -- shadow = {
        --     enabled      = true,
        --     range        = 4,
        --     render_power = 3,
        --     color        = "rgba(1a1a1aee)",
        -- },

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
        blur = {
            enabled = true,
            size    = 1,
            passes  = 1,

            -- My blur presets
            ignore_opacity    = true,
            noise             = 0,
            contrast          = 0.4,
            brightness        = 0.8,
            xray              = false,
            new_optimizations = true,

            -- vibrancy = 0.1696,
            vibrancy = 0.3,
        },
    },
})
