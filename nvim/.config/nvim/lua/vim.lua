-- General options
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set hidden")
vim.cmd("set relativenumber")
vim.cmd("set inccommand=split")
vim.cmd("set clipboard+=unnamedplus")
vim.opt.list = true

-- Leader key
vim.g.mapleader = " "

-- General keybidings
vim.keymap.set('n', '<leader>wc', ':q<CR>')
vim.keymap.set('n', '<leader>wv', ':vsplit<CR>')
vim.keymap.set('n', '<leader>ws', ':split<CR>')
vim.keymap.set('n', '<leader>bs', ':w<CR>')
vim.keymap.set('n', '<leader>sr', ':registers<CR>')

-- Insert mode keybindings
vim.keymap.set('i', '<C-h>', '<Left>', { silent = true })
vim.keymap.set('i', '<C-j>', '<Down>', { silent = true })
vim.keymap.set('i', '<C-k>', '<Up>', { silent = true })
vim.keymap.set('i', '<C-l>', '<Right>', { silent = true })

-- Navigate vim panes better
vim.keymap.set('n', '<leader>wk', ':wincmd k<CR>')
vim.keymap.set('n', '<leader>wj', ':wincmd j<CR>')
vim.keymap.set('n', '<leader>wh', ':wincmd h<CR>')
vim.keymap.set('n', '<leader>wl', ':wincmd l<CR>')

-- Show file path
vim.keymap.set('n', '<leader>fp', ":echo expand('%:p')<CR>")

-- Coppy file path
vim.keymap.set('n', '<leader>fy', ":let @+ = expand('%:p')<CR>")

