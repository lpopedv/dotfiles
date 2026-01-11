-- ============================================================================
-- GENERAL KEYMAPS
-- ============================================================================

-- Clear search highlights
vim.keymap.set("n", "<leader>c", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll half page up (centered)" })

-- Delete without yanking to clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to black hole register" })

-- Join lines keeping cursor position
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (preserve cursor)" })

-- ============================================================================
-- BUFFER MANAGEMENT
-- ============================================================================

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Buffer: next" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Buffer: previous" })

-- Save and reload buffer
vim.keymap.set({ "n", "i" }, "<C-s>", "<Esc>:w<CR>", { desc = "Save buffer" })
vim.keymap.set("n", "<leader>br", ":edit<CR>", { desc = "Buffer: reload from disk" })

-- Close buffer and window
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit window" })

-- ============================================================================
-- TAB MANAGEMENT
-- ============================================================================

-- Tab navigation
vim.keymap.set("n", "<leader><tab>n", ":tabnext<CR>", { desc = "Tab: next" })
vim.keymap.set("n", "<leader><tab>p", ":tabprevious<CR>", { desc = "Tab: previous" })
vim.keymap.set("n", "<leader><tab><tab>", ":tabnew<CR>", { desc = "Tab: new" })
vim.keymap.set("n", "<leader><tab>d", ":tabclose<CR>", { desc = "Tab: close" })
vim.keymap.set("n", "<leader><tab>o", ":tabonly<CR>", { desc = "Tab: close others" })
vim.keymap.set("n", "<leader><tab>l", ":tabs<CR>", { desc = "Tab: list all" })

-- Direct tab navigation (1-9)
for i = 1, 9 do
  vim.keymap.set("n", "<leader><tab>" .. i, i .. "gt", { desc = "Tab: go to " .. i })
end

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================

-- Window navigation
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Window: focus left" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Window: focus down" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Window: focus up" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Window: focus right" })

-- Window splitting
vim.keymap.set("n", "<leader>wv", ":vsplit<CR>", { desc = "Window: split vertical" })
vim.keymap.set("n", "<leader>ws", ":split<CR>", { desc = "Window: split horizontal" })

-- Window resizing
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Window: increase height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Window: decrease height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Window: decrease width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Window: increase width" })

-- ============================================================================
-- EDITING
-- ============================================================================

-- Insert mode navigation
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move cursor left" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move cursor up" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move cursor right" })

-- Move lines up/down
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left (keep selection)" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- ============================================================================
-- FILE NAVIGATION
-- ============================================================================

-- Quick file navigation (oil.nvim overrides <leader>e)
vim.keymap.set("n", "<leader>ff", ":find ", { desc = "Find file by name" })

-- Copy file path to clipboard
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "File: copy full path" })

-- ============================================================================
-- CONFIG MANAGEMENT
-- ============================================================================

-- Quick config editing
vim.keymap.set("n", "<leader>fc", ":e ~/.config/nvim/init.lua<CR>", { desc = "File: edit nvim config" })

-- Source current file
vim.keymap.set("n", "<leader>sc", ":so<CR>", { desc = "Source current file" })

-- ============================================================================
-- TERMINAL
-- ============================================================================

-- Open terminal in full buffer
vim.keymap.set("n", "<leader>oT", ":term<CR>", { desc = "Open terminal buffer" })
