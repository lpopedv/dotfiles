return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>Oil<cr>", desc = "Open file explorer" },
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      columns = {
        "icon",
      },
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 2,
        max_width = 90,
        max_height = 0,
      },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-s>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-r>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
      },
    })
  end,
}
