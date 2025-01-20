return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    files = {
      cmd = "rg --files --hidden --glob '!.git/*' --glob '!node_modules/*'",
    },
  },
}
