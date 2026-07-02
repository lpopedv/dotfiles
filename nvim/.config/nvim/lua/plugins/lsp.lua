-- LSP
vim.lsp.config('elixir_ls', {
  cmd = { 'elixir-ls' },
  filetypes = { 'elixir', 'heex' },
  root_markers = { 'mix.exs' },
})

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          '${3rd}/luv/library',
        },
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable({ 'elixir_ls', 'lua_ls' })


-- AUTOCOMPLETE
vim.autocomplete = true

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, {autotrigger = true})
    end
  end
})

vim.opt.complete:append('o')

vim.opt.completeopt = {'menuone', 'noselect'}
vim.o.pumheight = 6

