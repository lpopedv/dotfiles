-- Windows
vim.keymap.set('n', '<leader>wh', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { desc = 'Move to bottom window' })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { desc = 'Move to top window' })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>ws', '<C-w>s', { desc = 'Horizontal split' })
vim.keymap.set('n', '<leader>wH', '<C-w>H', { desc = 'Move window far left' })
vim.keymap.set('n', '<leader>wJ', '<C-w>J', { desc = 'Move window far bottom' })
vim.keymap.set('n', '<leader>wK', '<C-w>K', { desc = 'Move window far top' })
vim.keymap.set('n', '<leader>wL', '<C-w>L', { desc = 'Move window far right' })
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { desc = 'Close window' })

-- Buffers
vim.keymap.set({ 'n', 'i' }, '<C-s>', '<cmd>w<cr>', { desc = 'Save buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>enew<cr>', { desc = 'New buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>fY', function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path)
end, { desc = 'Copy relative file path' })

-- JSON Formatting
vim.keymap.set('n', '<leader>fj', ':%!python3 -m json.tool<CR>', { desc = 'Format JSON' })

-- Search
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlights' })

-- Diagnostics
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostics' })

-- Folding
vim.keymap.set('n', '<leader>zo', 'zo', { desc = 'Open fold' })
vim.keymap.set('n', '<leader>zc', 'zc', { desc = 'Close fold' })
vim.keymap.set('n', '<leader>zO', 'zO', { desc = 'Open all folds recursively' })
vim.keymap.set('n', '<leader>zC', 'zC', { desc = 'Close all folds recursively' })

-- Navigation
vim.keymap.set({ 'n', 'v' }, '<Tab>', '%', { desc = 'Jump to matching pair' })
vim.keymap.set('i', '<C-h>', '<Left>',  { desc = 'Move cursor left' })
vim.keymap.set('i', '<C-j>', '<Down>',  { desc = 'Move cursor down' })
vim.keymap.set('i', '<C-k>', '<Up>',    { desc = 'Move cursor up' })
vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move cursor right' })

-- Lazygit
vim.keymap.set('n', '<leader>gg', function()
  local buf = vim.api.nvim_create_buf(false, true)
  local width  = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width    = width,
    height   = height,
    col      = math.floor((vim.o.columns - width) / 2),
    row      = math.floor((vim.o.lines - height) / 2),
    style    = 'minimal',
    border   = 'rounded',
  })
  vim.fn.termopen('lazygit', {
    on_exit = function() vim.api.nvim_buf_delete(buf, { force = true }) end,
  })
  vim.cmd('startinsert')
end, { desc = 'Open lazygit' })

-- Highlight yanks
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})
