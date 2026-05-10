require('nvim-treesitter').install({ 'lua', 'typescript', 'elixir' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua', 'typescript', 'elixir' },
  callback = function() pcall(vim.treesitter.start) end,
})
