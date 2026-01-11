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
