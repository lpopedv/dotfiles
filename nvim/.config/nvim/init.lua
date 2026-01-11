-- ============================================================================
-- NEOVIM CONFIGURATION - Lucas Pope
-- ============================================================================

-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load lazy.nvim plugin manager
require("config.lazy")

-- Theme
vim.cmd.colorscheme("gruvbox")

-- Load configuration modules
require("config.settings")    -- Basic vim settings
require("config.keymaps")     -- Key mappings
require("config.autocmds")    -- Autocommands
require("config.terminal")    -- Floating terminal
require("config.lazygit")     -- Floating lazygit
require("config.statusline")  -- Custom statusline
require("config.lsp")         -- LSP configuration
require("config.tabs")        -- Tab management
require("config.dashboard").setup()  -- Dashboard
