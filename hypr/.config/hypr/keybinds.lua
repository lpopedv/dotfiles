local mainMod = "SUPER"

local terminal    = "ghostty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"
local browser     = "zen-browser"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(mainMod .. " + SHIFT + Q",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "Exit Hyprland" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(fileManager), { description = "Open file manager" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
hl.bind(mainMod .. " + T", hl.dsp.window.float(), { description = "Toggle floating" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu), { description = "App launcher" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize window" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen window" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Open browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("emacsclient -c -a 'emacs'"), { description = "Open Emacs" })
hl.bind(mainMod .. " + V",
    hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"),
    { description = "Clipboard history" })

hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 50, y = 50, relative = true }),
    { repeating = true, description = "Grow window" })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -50, y = -50, relative = true }),
    { repeating = true, description = "Shrink window" })

local directions = {
    { key = "H", arrow = "left",  dir = "l" },
    { key = "L", arrow = "right", dir = "r" },
    { key = "K", arrow = "up",    dir = "u" },
    { key = "J", arrow = "down",  dir = "d" },
}

for _, d in ipairs(directions) do
    hl.bind(mainMod .. " + " .. d.key, hl.dsp.focus({ direction = d.dir }),
        { description = "Focus " .. d.arrow })
    hl.bind(mainMod .. " + " .. d.arrow, hl.dsp.focus({ direction = d.dir }),
        { description = "Focus " .. d.arrow })
    hl.bind(mainMod .. " + SHIFT + " .. d.key, hl.dsp.window.move({ direction = d.dir }),
        { description = "Move window " .. d.arrow })
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { description = "Go to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { description = "Move window to workspace " .. i })
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),
    { description = "Move window to scratchpad" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

hl.bind(mainMod .. " + SHIFT + period", hl.dsp.exec_cmd("rofimoji --action type --skin-tone neutral"),
    { description = "Emoji picker" })

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })

hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"), { description = "Screenshot (region)" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("flameshot full -p ~/Pictures/Screenshots/"),
    { description = "Screenshot (full screen)" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true, description = "Mute output" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true, description = "Mute microphone" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
    { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
    { locked = true, repeating = true, description = "Brightness down" })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
