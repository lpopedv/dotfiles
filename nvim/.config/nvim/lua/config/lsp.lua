-- Function to find project root
local function find_root(patterns)
  local path = vim.fn.expand('%:p:h')
  local root = vim.fs.find(patterns, { path = path, upward = true })[1]
  return root and vim.fn.fnamemodify(root, ':h') or path
end

-- TypeScript LSP setup (for language features)
local function setup_typescript_lsp()
  vim.lsp.start({
    name = 'ts_ls',
    cmd = {'typescript-language-server', '--stdio'},
    filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact'},
    root_dir = find_root({'package.json', 'tsconfig.json', 'jsconfig.json', '.git'}),
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        }
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        }
      }
    },
    on_attach = function(client, bufnr)
      -- Disable TypeScript's formatting (Biome will handle it)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

-- Biome LSP setup (for formatting and linting only)
local function setup_biome_lsp()
  local client_id = vim.lsp.start({
    name = 'biome',
    cmd = {'biome', 'lsp-proxy'},
    filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc'},
    root_dir = find_root({'biome.json', 'biome.jsonc', 'package.json', '.git'}),
  })

  if client_id then
    local bufnr = vim.api.nvim_get_current_buf()

    -- Auto-fix and format on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      callback = function()
        -- Format first
        vim.lsp.buf.format({ async = false, name = 'biome' })
        -- Then apply code actions
        vim.lsp.buf.code_action({
          context = {
            only = {'source.fixAll.biome'},
            diagnostics = {},
          },
          apply = true,
        })
      end,
    })
  end
end

-- Auto-start both LSPs for TypeScript/JavaScript files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'javascript,javascriptreact,typescript,typescriptreact',
  callback = function()
    setup_typescript_lsp()
    setup_biome_lsp()
  end,
  desc = 'Start TypeScript LSP and Biome'
})

-- Auto-start Biome only for JSON files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'json,jsonc',
  callback = setup_biome_lsp,
  desc = 'Start Biome LSP for JSON'
})

-- Formatting function
local function format_code()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype

  -- Check if Biome LSP is attached
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = 'biome' })

  if #clients > 0 then
    -- Format with Biome LSP
    vim.lsp.buf.format({ async = false, name = 'biome' })
    print("Formatted with Biome")
    return
  end

  print("No formatter available for " .. filetype)
end

vim.api.nvim_create_user_command("FormatCode", format_code, {
  desc = "Format current file"
})

vim.keymap.set('n', '<leader>fm', format_code, { desc = 'Format file' })

-- LSP keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = {buffer = event.buf}

    -- Navigation
    vim.keymap.set('n', 'gD', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gs', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)

    -- Information
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

    -- Code actions
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

    -- Diagnostics
    vim.keymap.set('n', '<leader>nd', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>pd', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
  end,
})

-- Better LSP UI
vim.diagnostic.config({
  virtual_text = { prefix = '●' },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✗",
      [vim.diagnostic.severity.WARN] = "⚠",
      [vim.diagnostic.severity.INFO] = "ℹ",
      [vim.diagnostic.severity.HINT] = "💡",
    }
  }
})

vim.api.nvim_create_user_command('LspInfo', function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("No LSP clients attached to current buffer")
  else
    for _, client in ipairs(clients) do
      print("LSP: " .. client.name .. " (ID: " .. client.id .. ")")
    end
  end
end, { desc = 'Show LSP client info' })
