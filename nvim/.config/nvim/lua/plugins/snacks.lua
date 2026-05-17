require('snacks').setup({
  explorer = {
    tree = true,
    git_status = true,
    diagnostics = true,
    watch = true,
    hidden = true,
    ignored = true,
  },
  picker = {
    sources = {
      explorer = {
        hidden = true,
        ignored = true,
        layout = { preset = 'sidebar', preview = false },
      },
    },
  },
})

vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File explorer' })
