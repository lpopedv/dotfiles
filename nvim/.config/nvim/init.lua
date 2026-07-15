require('options')
require('keymaps')

vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/Shatur/neovim-ayu',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
})

require('plugins.theme')
require('plugins.fzf')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.oil')
require('plugins.statusline')
require('plugins.markdown')
require('plugins.gitsigns')
