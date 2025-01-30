-- Enable lines
vim.opt.nu = true

-- Enable lines relative numbers
vim.opt.relativenumber = true

-- Indenting options
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Line warp
vim.opt.wrap = false

-- Backup files, swap files and undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Clipboard
vim.opt.clipboard:append("unnamedplus")

-- search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- term colors
vim.opt.termguicolors = true

-- scroll options
vim.opt.scrolloff = 8

-- update time
vim.opt.updatetime = 50

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.api.nvim_buf_set_option(0, 'number', false)
    vim.api.nvim_buf_set_option(0, 'relativenumber', false)
  end
})
