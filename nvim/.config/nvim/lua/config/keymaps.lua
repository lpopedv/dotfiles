-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Disable C-k of LSP
local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<C-k>", false, mode = { "i" } }

-- Move in lines in insert mode
vim.keymap.set("i", "<C-h>", "<Left>", { silent = true, desc = "Move left" })
vim.keymap.set("i", "<C-j>", "<Down>", { silent = true, desc = "Move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { silent = true, desc = "Move up" })
vim.keymap.set("i", "<C-l>", "<Right>", { silent = true, desc = "Move right" })

--  Copy full file path
vim.keymap.set("n", "<leader>fy", ":let @+ = expand('%:p')<CR>", {
  noremap = true,
  silent = true,
  desc = "Copy full file path to clipboard",
})

-- Copy Relative file path
vim.keymap.set("n", "<leader>fY", ":let @+ = expand('%:.')<CR>", {
  noremap = true,
  silent = true,
  desc = "Copy relative file path to clipboard",
})
