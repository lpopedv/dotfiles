require('oil').setup({
  default_file_explorer = true,
  columns = { 'icon' },
  view_options = {
    show_hidden = true,
  },
  -- Auto-reload the listing when files are created/removed on disk
  -- outside of nvim (e.g. by an external tool or AI agent).
  watch_for_changes = true,
})

vim.keymap.set('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'File explorer' })
vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Open Oil when nvim is launched with no file arguments',
  callback = function()
    if vim.fn.argc() == 0 then
      require('oil').open()
      -- :edit doesn't trigger BufReadCmd here since v:vim_did_enter is
      -- already 1 by VimEnter, so the startup buffer looks "already loaded".
      -- Mirror oil's own internal workaround and force the load manually.
      require('oil').load_oil_buffer(vim.api.nvim_get_current_buf())
    end
  end,
})
