hl.monitor({
    output   = "HDMI-A-1",
    mode     = "2560x1080@74.99",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-- Any other screen: its own preferred mode, placed to the right, scaled by its
-- PPI. Per-machine layouts go in local.lua (see hyprland.lua).
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
