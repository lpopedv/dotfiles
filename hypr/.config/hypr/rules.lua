hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
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

hl.window_rule({
    name      = "rofi-float",
    match     = { class = "^(rofi)$" },

    float     = true,
    center    = true,
    animation = "popin 78%",
})

hl.window_rule({
    name      = "impala-float",
    match     = { class = "^(org.dotfiles.impala)$" },

    float     = true,
    center    = true,
    size      = { "875", "600" },
    animation = "popin 78%",
})

hl.window_rule({
    name    = "emacs-blur",
    match   = { class = "Emacs" },

    opacity = "0.92 override 0.85 override",
})

hl.window_rule({
    name  = "flameshot-gui",
    match = { class = "^(flameshot)$" },

    float = true,
    move  = { 0, 0 },
    pin   = true,
    suppress_event = "fullscreen",
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = { "20", "monitor_h-120" },
    float = true,
})

hl.layer_rule({
    name         = "waybar-blur",
    match        = { namespace = "^waybar$" },

    blur         = true,
    ignore_alpha = 0.2,
})
