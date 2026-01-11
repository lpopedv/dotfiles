local M = {}

local logo = {
  "        ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄        ",
  "       █       █  █ █  █  ▄    █       █   ▄  █       ",
  "       █       █  █▄█  █ █▄█   █    ▄▄▄█  █ █ █       ",
  "       █     ▄▄█       █       █   █▄▄▄█   █▄▄█▄      ",
  "       █    █  █▄     ▄█  ▄   ██    ▄▄▄█    ▄▄  █     ",
  "       █    █▄▄  █   █ █ █▄█   █   █▄▄▄█   █  █ █     ",
  "       █▄▄▄▄▄▄▄█  █▄█  █▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄█  █▄█     ",
}

local menu = {
  "[e] Explore Files",
  "[f] Find File",
  "[r] Recent Files",
  "[c] Config",
  "[q] Quit",
}

local function max_width(sections)
  local max = 0
  for _, section in ipairs(sections) do
    for _, line in ipairs(section) do
      max = math.max(max, vim.fn.strdisplaywidth(line))
    end
  end
  return max
end

local function center_block(lines, width)
  local win_width = vim.api.nvim_win_get_width(0)
  local shift = math.floor((win_width - width) / 2)
  local out = {}
  for _, line in ipairs(lines) do
    table.insert(out, string.rep(" ", math.max(0, shift)) .. line)
  end
  return out
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'DashboardLogo1', { fg = '#fb4934', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardLogo2', { fg = '#fe8019', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardLogo3', { fg = '#fabd2f', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardLogo4', { fg = '#b8bb26', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardLogo5', { fg = '#8ec07c', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardDir',   { fg = '#83a598', bold = true })
  vim.api.nvim_set_hl(0, 'DashboardKey',   { fg = '#fabd2f', bold = true })
end

function M.open()
  require("lazy").load({ plugins = { "oil.nvim", "fzf-lua" } })
  setup_highlights()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.cursorline = false

  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  local sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local dir_section = { sep, cwd, sep }

  local width = max_width({ logo, dir_section, menu })

  local content = {}
  local height = vim.api.nvim_win_get_height(0)
  local padding = math.floor((height - (#logo + #dir_section + #menu + 2)) / 2)

  for _ = 1, padding do table.insert(content, "") end
  vim.list_extend(content, center_block(logo, width))
  table.insert(content, "")
  vim.list_extend(content, center_block(dir_section, width))
  table.insert(content, "")
  local menu_start = #content + 1
  vim.list_extend(content, center_block(menu, width))
  local menu_end = #content

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false

  local base = padding
  local logo_hls = {
    'DashboardLogo1','DashboardLogo2','DashboardLogo3',
    'DashboardLogo4','DashboardLogo5','DashboardLogo4','DashboardLogo3'
  }
  for i, hl in ipairs(logo_hls) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl, base + i, 0, -1)
  end

  local dir_line = base + #logo + 2
  vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardLogo2', dir_line, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardDir',   dir_line + 1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardLogo4', dir_line + 2, 0, -1)

  for i = menu_start - 1, menu_end - 1 do
    vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardKey', i, 0, -1)
  end

  vim.api.nvim_win_set_cursor(0, { menu_start, 0 })

  local function move(delta)
    local row = vim.api.nvim_win_get_cursor(0)[1] + delta
    row = math.max(menu_start, math.min(menu_end, row))
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  end

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set("n", "j", function() move(1) end, opts)
  vim.keymap.set("n", "k", function() move(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move(-1) end, opts)

  vim.keymap.set("n", "e", function()
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.cmd("Oil " .. vim.fn.getcwd())
  end, opts)
  vim.keymap.set("n", "f", "<cmd>FzfLua files<CR>", opts)
  vim.keymap.set("n", "r", "<cmd>FzfLua oldfiles<CR>", opts)
  vim.keymap.set("n", "c", "<cmd>edit ~/.config/nvim/init.lua<CR>", opts)
  vim.keymap.set("n", "q", "<cmd>quit<CR>", opts)
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc() == 0 and vim.fn.expand("%") == "" then
        M.open()
      end
    end,
  })
end

return M

