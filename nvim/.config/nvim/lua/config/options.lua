-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- scroll options
vim.opt.scrolloff = 8

-- Backup files, swap files and undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

vim.g.snacks_animate = false

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
