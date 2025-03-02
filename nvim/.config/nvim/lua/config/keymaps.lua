-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Indent with tab
vim.api.nvim_set_keymap("v", "<Tab>", ">gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- move in lines in insert mode
vim.keymap.set("i", "<C-h>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { silent = true })
