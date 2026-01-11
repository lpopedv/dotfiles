return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 500,
  },
  config = function()
    local wk = require("which-key")
    wk.setup({
      delay = 500,
    })

    -- Register group names
    wk.add({
      { "<leader>b", group = "Buffer" },
      { "<leader>w", group = "Window" },
      { "<leader>f", group = "File" },
      { "<leader>s", group = "Source" },
      { "<leader>o", group = "Open" },
    })
  end,
}
