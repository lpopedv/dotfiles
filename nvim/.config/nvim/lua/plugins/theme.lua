require('ayu').setup({
  overrides = {
    Normal        = { bg = 'NONE' },
    NormalNC      = { bg = 'NONE' },
    NormalFloat   = { bg = 'NONE' },
    SignColumn    = { bg = 'NONE' },
    LineNr        = { bg = 'NONE', fg = '#8faab8' },
    CursorLineNr  = { bg = 'NONE', fg = '#e5e1cf' },
    StatusLine    = { bg = 'NONE' },
    StatusLineNC  = { bg = 'NONE' },
  },
})

vim.cmd('colorscheme ayu-dark')
