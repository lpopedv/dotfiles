return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader><leader>", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>sb", "<cmd>FzfLua blines<cr>", desc = "Search in Buffer" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
    { "<leader>fc", "<cmd>FzfLua grep_cword<cr>", desc = "Find Word Under Cursor" },
    { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols" },
    { "<leader>fd", "<cmd>FzfLua lsp_definitions<cr>", desc = "Go to Definition" },
    { "<leader>ft", "<cmd>FzfLua lsp_type_definitions<cr>", desc = "Go to Type Definition" },
  },
  config = function()
    require("fzf-lua").setup({
      "default",
      winopts = {
        height = 0.85,
        width = 0.80,
        preview = {
          default = "bat",
          layout = "vertical",
          vertical = "down:45%",
        },
      },
      files = {
        prompt = "Files❯ ",
        git_icons = true,
        file_icons = true,
        color_icons = true,
        fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules",
      },
    })
  end,
}
