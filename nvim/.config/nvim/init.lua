-- ============================================================================
-- NEOVIM CONFIGURATION - Lucas Pope
-- ============================================================================

-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Theme & transparency
vim.cmd.colorscheme("unokai")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- Load lazy.nvim plugin manager
require("config.lazy")

-- Load configuration modules
require("config.settings")    -- Basic vim settings
require("config.keymaps")     -- Key mappings
require("config.autocmds")    -- Autocommands
require("config.terminal")    -- Floating terminal
require("config.lazygit")     -- Floating lazygit
require("config.statusline")  -- Custom statusline
require("config.lsp")         -- LSP configuration
require("config.tabs")        -- Tab management
