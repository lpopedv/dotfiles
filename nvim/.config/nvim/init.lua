require('options')
require('keymaps')

vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/stevearc/oil.nvim',
})

require('plugins.fzf')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.oil')
