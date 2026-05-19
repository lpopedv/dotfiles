local function ayu_transparent()
  local t = require('lualine.themes.ayu_dark')
  for _, mode in pairs(t) do
    if type(mode) == 'table' and mode.c then
      mode.c.bg = 'NONE'
    end
  end
  return t
end

require('lualine').setup({
  options = {
    theme = ayu_transparent(),
    globalstatus = true,
    section_separators    = { left = '', right = '' },
    component_separators  = { left = '', right = '' },
    disabled_filetypes = {
      statusline = { 'snacks_dashboard' },
      winbar     = { 'oil', 'snacks_picker_list', 'snacks_terminal' },
    },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { { 'branch', icon = '' } },
    lualine_c = {
      {
        'filetype',
        icon_only = true,
        separator = '',
        padding   = { left = 1, right = 0 },
      },
      {
        'filename',
        path = 1,
        symbols = {
          modified = '  ',
          readonly = ' ',
          unnamed  = '[No Name]',
          newfile  = '[New]',
        },
      },
      {
        'diagnostics',
        symbols = {
          error = ' ',
          warn  = ' ',
          info  = ' ',
          hint  = '󰝶 ',
        },
      },
    },
    lualine_x = {
      {
        'diff',
        symbols = {
          added    = ' ',
          modified = ' ',
          removed  = ' ',
        },
      },
      {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return '' end
          local names = vim.tbl_map(function(c) return c.name end, clients)
          return ' ' .. table.concat(names, ', ')
        end,
      },
    },
    lualine_y = {
      { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
      { 'location', padding = { left = 0, right = 1 } },
    },
    lualine_z = {
      { function() return ' ' .. os.date('%R') end },
    },
  },
  extensions = { 'quickfix', 'fzf' },
})
