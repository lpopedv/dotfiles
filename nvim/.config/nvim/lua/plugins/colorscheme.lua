return {
  {
    "shatur/neovim-ayu",
    config = function()
      require("ayu").setup({
        mirage = true,
        overrides = {
          CursorLine = { bg = "#3c4048" },
          Directory = { fg = "#a5a7ac", bg = "none", bold = true },
          NonText = { fg = "#6c7a8b" },
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-mirage",
    },
  },
}
