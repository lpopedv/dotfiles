return {
  'akinsho/toggleterm.nvim',
  version = "*",

  config = function()
    require("toggleterm").setup({
      size = 13,
      open_mapping = [[<c-\>]],
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = '1',
      start_in_insert = true,
      persist_size = true,
      direction = 'horizontal'
    })

    local Terminal = require('toggleterm.terminal').Terminal

    local toggle_lazygit = function()
      local lazygit = Terminal:new({ cmd = 'lazygit', direction = "float" })
      return lazygit:toggle()
    end


    --keymaps
    vim.keymap.set('n', '<leader>gg', toggle_lazygit)
    vim.keymap.set('n', '<leader>ot', ':ToggleTerm<CR>')
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { noremap = true })
  end
}
