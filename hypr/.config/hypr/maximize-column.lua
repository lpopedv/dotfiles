-- Niri-style `maximize-column` for the scrolling layout.
-- Toggles the active column between full width and the width it had before,
-- keeping it on the tape so neighbouring columns stay reachable.

local M = {}

local FULL_WIDTH = 1.0

-- window address -> column width before it was maximized
local previous_widths = {}

local function active_column()
    local window = hl.get_active_window()
    if not window or window.floating then return nil end

    local layout = window.layout
    if type(layout) ~= "table" or layout.name ~= "scrolling" then return nil end

    return window, layout.column
end

local function default_width()
    return tonumber(hl.get_config("scrolling.column_width")) or 0.5
end

local function forget_closed_windows()
    local open = {}
    for _, window in ipairs(hl.get_windows()) do
        open[window.address] = true
    end

    for address in pairs(previous_widths) do
        if not open[address] then previous_widths[address] = nil end
    end
end

local function resize_column(width)
    hl.dispatch(hl.dsp.layout("colresize " .. width))
end

function M.toggle()
    local window, column = active_column()
    if not column then return end

    forget_closed_windows()

    if column.width < FULL_WIDTH then
        previous_widths[window.address] = column.width
        resize_column(FULL_WIDTH)
    else
        resize_column(previous_widths[window.address] or default_width())
        previous_widths[window.address] = nil
    end
end

return M
