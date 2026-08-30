hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 4,

        border_size = 1,

        col = {
            active_border   = { colors = { "rgba(989898ff)", "rgba(4a4a4aff)", "rgba(989898ff)" }, angle = 45 },
            inactive_border = "rgba(3a3a3aaa)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        active_opacity   = 1.0,
        inactive_opacity = 0.93,

        shadow = {
            enabled        = true,
            range          = 14,
            render_power   = 4,
            color          = "rgba(050505ee)",
            color_inactive = "rgba(00000066)",
        },

        blur = {
            enabled           = true,
            size              = 5,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            vibrancy          = 0.22,
            vibrancy_darkness = 0.5,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("overshoot",    { type = "bezier", points = { { 0.05, 0.9 }, { 0.1,  1.12 } } })
hl.curve("fluent",       { type = "bezier", points = { { 0.25, 1   }, { 0.5,  1    } } })
hl.curve("easeOutExpo",  { type = "bezier", points = { { 0.16, 1   }, { 0.3,  1    } } })
hl.curve("easeInExpo",   { type = "bezier", points = { { 0.7,  0   }, { 0.84, 0    } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1   }, { 0.32, 1    } } })
hl.curve("easeInQuint",  { type = "bezier", points = { { 0.64, 0   }, { 0.78, 0    } } })
hl.curve("linear",       { type = "bezier", points = { { 0,    0   }, { 1,    1    } } })

hl.animation({ leaf = "windows",       enabled = true, speed = 3.5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.5,  bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2.2,  bezier = "easeInQuint",  style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 3,    bezier = "fluent" })

hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3.5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2.2,  bezier = "easeInQuint" })
hl.animation({ leaf = "fade",          enabled = true, speed = 2.5,  bezier = "easeOutExpo" })

hl.animation({ leaf = "layers",        enabled = true, speed = 3,    bezier = "overshoot" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3,    bezier = "overshoot",   style = "popin 85%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.8,  bezier = "easeOutExpo", style = "popin 85%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2.5,  bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2,    bezier = "easeOutExpo" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.5,  bezier = "overshoot",   style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5,  bezier = "overshoot",   style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.5,  bezier = "easeOutExpo", style = "slidefade 15%" })

hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 100,  bezier = "linear",      style = "loop" })

hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 3,    bezier = "overshoot" })

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})
