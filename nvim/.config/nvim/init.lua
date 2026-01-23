vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load lazy.nvim plugin manager
require("config.lazy")

-- Theme
vim.cmd.colorscheme("gruvbox")

-- Load configuration modules
require("config.settings")    -- Basic vim settings
require("config.keymaps")     -- Key mappings
require("config.terminal")    -- Floating terminal
require("config.lazygit")     -- Floating lazygit
require("config.lsp")         -- LSP
require("config.dashboard").setup()  -- Dashboard
