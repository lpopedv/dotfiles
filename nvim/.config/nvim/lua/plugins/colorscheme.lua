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
          LineNr = { fg = "#a5a7ac" },
          CursorLineNr = { fg = "#eda160", bold = true },
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
