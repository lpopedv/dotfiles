require('options')
require('keymaps')

vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/Shatur/neovim-ayu',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/folke/snacks.nvim',
})

require('plugins.theme')
require('plugins.statusline')
require('plugins.fzf')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.snacks')
