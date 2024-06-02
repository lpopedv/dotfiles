return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },

  config = function()
    vim.opt.termguicolors = true

    require("nvim-tree").setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 30,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })

      --keymaps
      vim.keymap.set('n', '<leader>op', ':NvimTreeOpen<CR>')
      vim.keymap.set('n', '<leader>cp', ':NvimTreeClose<CR>')
  end
}
