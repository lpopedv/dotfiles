local M = {}

------------------------------------------------------------
-- STATIC DATA
------------------------------------------------------------
local LOGO = {
  "        ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄        ",
  "       █       █  █ █  █  ▄    █       █   ▄  █       ",
  "       █       █  █▄█  █ █▄█   █    ▄▄▄█  █ █ █       ",
  "       █     ▄▄█       █       █   █▄▄▄█   █▄▄█▄      ",
  "       █    █  █▄     ▄█  ▄   ██    ▄▄▄█    ▄▄  █     ",
  "       █    █▄▄  █   █ █ █▄█   █   █▄▄▄█   █  █ █     ",
  "       █▄▄▄▄▄▄▄█  █▄█  █▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄█  █▄█     ",
}

local MENU_ITEMS = {
  { key = "e", label = "Explore Files" },
  { key = "f", label = "Find File" },
  { key = "r", label = "Recent Files" },
  { key = "c", label = "Config" },
  { key = "q", label = "Quit" },
}

local LOGO_HIGHLIGHTS = {
  "DashboardLogoError",
  "DashboardLogoWarn",
  "DashboardLogoInfo",
  "DashboardLogoHint",
  "DashboardLogoSuccess",
  "DashboardLogoHint",
  "DashboardAccent",
}

------------------------------------------------------------
-- UTILS
------------------------------------------------------------
local function get_git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null")
  if not handle then return nil end
  local branch = handle:read("*l")
  handle:close()
  return (branch and branch ~= "") and branch or nil
end

local function display_width(text)
  return vim.fn.strdisplaywidth(text)
end

------------------------------------------------------------
-- HIGHLIGHTS
------------------------------------------------------------
local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  hl(0, "DashboardLogoError",   { link = "DiagnosticError" })
  hl(0, "DashboardLogoWarn",    { link = "DiagnosticWarn" })
  hl(0, "DashboardLogoInfo",    { link = "DiagnosticInfo" })
  hl(0, "DashboardLogoHint",    { link = "DiagnosticHint" })
  hl(0, "DashboardLogoSuccess", { fg = "#8ec07c", bold = true })

  hl(0, "DashboardAccent", { link = "Directory" })

  hl(0, "DashboardDir",   { link = "DashboardAccent" })
  hl(0, "DashboardMenu", { link = "DashboardAccent" })

  hl(0, "DashboardNoGit", { link = "Comment" })
end

------------------------------------------------------------
-- HIGHLIGHT HELPERS
------------------------------------------------------------
local function highlight_text(bufnr, line_idx, text, group)
  local first_char = text:find("%S")
  if not first_char then return end

  vim.api.nvim_buf_add_highlight(
    bufnr,
    -1,
    group,
    line_idx,
    first_char - 1,
    #text
  )
end

------------------------------------------------------------
-- MAIN DASHBOARD
------------------------------------------------------------
function M.open()
  require("lazy").load({ plugins = { "oil.nvim", "fzf-lua" } })
  setup_highlights()

  ----------------------------------------------------------
  -- BUFFER
  ----------------------------------------------------------
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = true

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.cursorline = true

  ----------------------------------------------------------
  -- HEADER (DIR + BRANCH)
  ----------------------------------------------------------
  local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local branch = get_git_branch()

  local header_line
  local header_highlight = "DashboardDir"

  if branch then
    header_line = cwd_name .. "  •   " .. branch
  else
    header_line = cwd_name .. "  •  No git repository"
    header_highlight = "DashboardNoGit"
  end

  local menu_lines = {}
  for _, item in ipairs(MENU_ITEMS) do
    menu_lines[#menu_lines + 1] =
      ("[%s] %s"):format(item.key, item.label)
  end

  ----------------------------------------------------------
  -- BUILD BLOCK
  ----------------------------------------------------------
  local block_lines = {}
  vim.list_extend(block_lines, LOGO)

  block_lines[#block_lines + 1] = ""
  local header_block_index = #block_lines + 1
  block_lines[#block_lines + 1] = header_line
  block_lines[#block_lines + 1] = ""

  local menu_start_in_block = #block_lines + 1
  vim.list_extend(block_lines, menu_lines)
  local menu_end_in_block = #block_lines

  ----------------------------------------------------------
  -- HORIZONTAL CENTERING
  ----------------------------------------------------------
  local win_width = vim.api.nvim_win_get_width(0)

  local logo_left_pad = LOGO[1]:match("^(%s*)") or ""
  local logo_text_width =
    display_width(LOGO[1]:gsub("^%s*", ""))

  local logo_center_col =
    #logo_left_pad + math.floor(logo_text_width / 2)

  local win_center_col = math.floor(win_width / 2)
  local hpad = math.max(0, win_center_col - logo_center_col)

  local prefix = string.rep(" ", hpad)
  for i, line in ipairs(block_lines) do
    block_lines[i] = prefix .. line
  end

  ----------------------------------------------------------
  -- VERTICAL CENTERING
  ----------------------------------------------------------
  local win_height = vim.api.nvim_win_get_height(0)
  local vpad =
    math.max(0, math.floor((win_height - #block_lines) / 2))

  local buffer_lines = {}
  for _ = 1, vpad do
    buffer_lines[#buffer_lines + 1] = ""
  end

  local logo_start_line = #buffer_lines
  vim.list_extend(buffer_lines, block_lines)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, buffer_lines)
  vim.bo[bufnr].modifiable = false

  ----------------------------------------------------------
  -- APPLY HIGHLIGHTS
  ----------------------------------------------------------
  assert(#LOGO == #LOGO_HIGHLIGHTS, "Logo highlight mismatch")

  for i, hl_group in ipairs(LOGO_HIGHLIGHTS) do
    local line_idx = logo_start_line + i - 1
    highlight_text(
      bufnr,
      line_idx,
      buffer_lines[line_idx + 1],
      hl_group
    )
  end

  highlight_text(
    bufnr,
    logo_start_line + header_block_index - 1,
    buffer_lines[logo_start_line + header_block_index],
    header_highlight
  )

  for line_idx = logo_start_line + menu_start_in_block - 1,
                 logo_start_line + menu_end_in_block - 1 do
    highlight_text(
      bufnr,
      line_idx,
      buffer_lines[line_idx + 1],
      "DashboardMenu"
    )
  end

  ----------------------------------------------------------
  -- INTERACTION
  ----------------------------------------------------------
  local menu_start_line = logo_start_line + menu_start_in_block
  local menu_end_line   = logo_start_line + menu_end_in_block

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(0, { menu_start_line, 0 })
  end)

  local function move_cursor(delta)
    local row = vim.api.nvim_win_get_cursor(0)[1] + delta
    row = math.max(menu_start_line, math.min(menu_end_line, row))
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  end

  local opts = { buffer = bufnr, silent = true, nowait = true }

  vim.keymap.set("n", "j", function() move_cursor(1) end, opts)
  vim.keymap.set("n", "k", function() move_cursor(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move_cursor(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move_cursor(-1) end, opts)

  local function execute_selection()
    local index =
      vim.api.nvim_win_get_cursor(0)[1] - menu_start_line + 1
    local item = MENU_ITEMS[index]
    if not item then return end

    vim.api.nvim_buf_delete(bufnr, { force = true })

    if item.key == "e" then
      vim.cmd("Oil " .. vim.fn.getcwd())
    elseif item.key == "f" then
      vim.cmd("FzfLua files")
    elseif item.key == "r" then
      vim.cmd("FzfLua oldfiles")
    elseif item.key == "c" then
      vim.cmd("edit ~/.config/nvim/init.lua")
    elseif item.key == "q" then
      vim.cmd("quit")
    end
  end

  vim.keymap.set("n", "<CR>", execute_selection, opts)
  vim.keymap.set("n", "e", execute_selection, opts)
  vim.keymap.set("n", "f", "<cmd>FzfLua files<CR>", opts)
  vim.keymap.set("n", "r", "<cmd>FzfLua oldfiles<CR>", opts)
  vim.keymap.set("n", "c", "<cmd>edit ~/.config/nvim/init.lua<CR>", opts)
  vim.keymap.set("n", "q", "<cmd>quit<CR>", opts)
end

------------------------------------------------------------
-- AUTOCMD
------------------------------------------------------------
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

