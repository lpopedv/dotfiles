-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Relative line numbers
vim.o.relativenumber = true
vim.o.number = true

-- Case insenstive searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Sync clipboards
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Raise dialog if unsaved buffer
vim.o.confirm = true

-- Snappy escape
vim.o.ttimeoutlen = 1

-- Folding
vim.o.foldlevelstart = 99

-- Indentation
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.softtabstop = 2

-- Vim diagnostics
vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	float = {source = 'if_many' },
	jump = {float = true},
})

-- Show diagnostics
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, {desc = 'Show diagnostics'})

-- Easily move between windows
vim.keymap.set('n', '<leader>wh', '<C-w>h', {desc = 'Move to left window'})
vim.keymap.set('n', '<leader>wj', '<C-w>j', {desc = 'Move to bottom window'})
vim.keymap.set('n', '<leader>wk', '<C-w>k', {desc = 'Move to top window'})
vim.keymap.set('n', '<leader>wl', '<C-w>l', {desc = 'Move to right window'})

-- Splits
vim.keymap.set('n', '<leader>wv', '<C-w>v', {desc = 'Vertical split'})
vim.keymap.set('n', '<leader>ws', '<C-w>s', {desc = 'Horizontal split'})

-- Move windows
vim.keymap.set('n', '<leader>wH', '<C-w>H', {desc = 'Move window far left'})
vim.keymap.set('n', '<leader>wJ', '<C-w>J', {desc = 'Move window far bottom'})
vim.keymap.set('n', '<leader>wK', '<C-w>K', {desc = 'Move window far top'})
vim.keymap.set('n', '<leader>wL', '<C-w>L', {desc = 'Move window far right'})

-- Windows
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', {desc = 'Close window'})

-- Buffers
vim.keymap.set('n', '<C-s>', '<cmd>w<cr>', {desc = 'Save buffer'})

-- Folding
vim.keymap.set('n', '<leader>zo', 'zo', {desc = 'Open fold'})
vim.keymap.set('n', '<leader>zc', 'zc', {desc = 'Close fold'})
vim.keymap.set('n', '<leader>zO', 'zO', {desc = 'Open all folds recursively'})
vim.keymap.set('n', '<leader>zC', 'zC', {desc = 'Close all folds recursively'})

-- Jump between matching pairs
vim.keymap.set({'n', 'v'}, '<Tab>', '%', {desc = 'Jump to matching pair'})

-- Insert mode navigation
vim.keymap.set('i', '<C-h>', '<Left>',  {desc = 'Move cursor left'})
vim.keymap.set('i', '<C-j>', '<Down>',  {desc = 'Move cursor down'})
vim.keymap.set('i', '<C-k>', '<Up>',    {desc = 'Move cursor up'})
vim.keymap.set('i', '<C-l>', '<Right>', {desc = 'Move cursor right'})

-- Highlight yanks
vim.api.nvim_create_autocmd('TextYankPost', { 
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.highlight.on_yank() end
})

-- Plugs
vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/neovim/nvim-lspconfig'
})

-- FzfLua
require("fzf-lua").setup {
  keymap = {
    builtin = {
      ["<C-d>"] = 'preview-page-down',
      ["<C-u>"] = 'preview-page-up',
    }
  }
}

vim.keymap.set('n', '<leader><leader>', '<cmd>FzfLua files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>/', '<cmd>FzfLua live_grep<cr>', { desc = 'Find live grep' })

-- Treesitter parsers
require('nvim-treesitter').install({ 'lua', 'typescript', 'elixir' })

-- Treesitter
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua', 'typescript', 'elixir' },
  callback = function() pcall(vim.treesitter.start) end,
})

-- LSP
vim.lsp.config('elixir_ls', {
  cmd = { 'elixir-ls' },
  filetypes = { 'elixir', 'heex' },
  root_markers = { 'mix.exs' },
})

vim.lsp.enable({ 'lua_ls', 'elixir_ls' })
vim.o.signcolumn = 'yes'
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
