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

vim.lsp.config('ts_ls', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
})

vim.lsp.config('marksman', {
  cmd = { 'marksman', 'server' },
  filetypes = { 'markdown', 'markdown.mdx' },
  root_markers = { '.marksman.toml', '.git' },
})

vim.lsp.config('biome', {
  cmd = function(dispatchers, config)
    local cmd = 'biome'
    -- prefer the project-local binary (node_modules/.bin/biome) over a global install
    if config.root_dir then
      local local_cmd = vim.fs.joinpath(config.root_dir, 'node_modules/.bin/biome')
      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end
    return vim.lsp.rpc.start({ cmd, 'lsp-proxy' }, dispatchers)
  end,
  filetypes = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'json', 'jsonc', 'css', 'graphql', 'vue', 'svelte', 'astro', 'html',
  },
  -- intentionally *not* package.json/.git: only attach in projects that actually
  -- have a biome.json(c), so it doesn't try to run in every JS/TS repo
  root_markers = { 'biome.json', 'biome.jsonc' },
})

vim.lsp.enable({ 'elixir_ls', 'lua_ls', 'ts_ls', 'marksman', 'biome' })


-- AUTOCOMPLETE
vim.autocomplete = true

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, {autotrigger = true})
    end
    if client:supports_method('textDocument/definition') then
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Go to definition' })
    end
    if client:supports_method('textDocument/formatting') then
      -- re-creating the group (keyed by buffer) on every LspAttach dedupes it:
      -- when biome and ts_ls both attach to the same buffer, only the last
      -- registration survives, so we never format twice on save.
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp.format.' .. ev.buf, { clear = true }),
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({
            bufnr = ev.buf,
            async = false,
            filter = function(c)
              -- prefer biome over ts_ls when both are attached to the same buffer
              local has_biome = #vim.lsp.get_clients({ bufnr = ev.buf, name = 'biome' }) > 0
              if has_biome then
                return c.name == 'biome'
              end
              return true
            end,
          })
        end,
      })
    end
  end
})

vim.opt.complete:append('o')

vim.opt.completeopt = {'menuone', 'noselect'}
vim.o.pumheight = 6

