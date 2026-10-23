require("monitors")
require("environment")
require("autostart")
require("look-and-feel")
require("input")
require("keybinds")
require("rules")

-- This machine's own settings (the installer writes its keyboard layout here):
-- not part of the repo, so updates never touch it, and loaded last so it wins.
-- Checked first because require() of a missing module stops this file.
local overrides = io.open((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/local.lua")
if overrides then
    overrides:close()
    require("local")
end
