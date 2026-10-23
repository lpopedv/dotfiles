hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_IM_MODULE", "simple")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("TERMINAL", "ghostty")

-- NVIDIA's own driver (an installer choice) needs these, but only when it
-- drives the sole GPU: on a hybrid laptop they would push every app onto the
-- discrete card, battery and all. Nouveau, AMD and Intel need none of them.
local function nvidia_only()
    local module = io.open("/sys/module/nvidia/version")
    if not module then return false end
    module:close()
    local cards = io.popen("cat /sys/class/drm/card*/device/vendor 2>/dev/null")
    local vendors = cards:read("*a")
    cards:close()
    for vendor in vendors:gmatch("%S+") do
        if vendor ~= "0x10de" then return false end
    end
    return true
end

if nvidia_only() then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end
