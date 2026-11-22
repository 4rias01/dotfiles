--------------
--- MONITORS ---
--------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- monitor=,preferred,auto,1
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })
