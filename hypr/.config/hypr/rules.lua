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
    name      = "claude-usage-float",
    match     = { class = "^(org.dotfiles.claude-usage)$" },

    float     = true,
    center    = true,
    size      = { "760", "620" },
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

-- The bar and the dock are the layer surface itself; every panel they open
-- (notifications, dock settings, claude usage) is an xdg popup of it, and a
-- popup is not covered by `blur` - it needs `blur_popups` or it renders as a
-- flat black rectangle over the wallpaper.
hl.layer_rule({
    name         = "quickshell-blur",
    match        = { namespace = "^quickshell$" },

    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.2,
})
