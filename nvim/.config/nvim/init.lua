-- ============================================================================
-- NEOVIM CONFIGURATION - Lucas Pope
-- ============================================================================

-- Theme & transparency
vim.cmd.colorscheme("unokai")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- Load configuration modules
require("config.settings")    -- Basic vim settings
require("config.keymaps")     -- Key mappings
require("config.autocmds")    -- Autocommands
require("config.terminal")    -- Floating terminal
require("config.statusline")  -- Custom statusline
require("config.lsp")         -- LSP configuration
require("config.tabs")        -- Tab management
