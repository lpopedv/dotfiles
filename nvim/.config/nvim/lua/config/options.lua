-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- scroll options
vim.opt.scrolloff = 8

-- Backup files, swap files and undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Manually set PATH to include ASDF shims
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.asdf/shims")
