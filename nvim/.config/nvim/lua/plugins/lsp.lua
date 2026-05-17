vim.lsp.config('elixir_ls', {
  cmd = { 'elixir-ls' },
  filetypes = { 'elixir', 'heex' },
  root_markers = { 'mix.exs' },
})

vim.lsp.enable({ 'lua_ls', 'elixir_ls', 'ts_ls' })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
    end
  end,
})

-- Track LSP progress per client (used by both notifications and lsp_info)
local progress = vim.defaulttable()

vim.api.nvim_create_autocmd('LspProgress', {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin"|"report"|"end"}]]
    if not client or type(value) ~= 'table' then return end

    local p = progress[client.id]
    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ('[%3d%%] %s%s'):format(
            value.kind == 'end' and 100 or value.percentage or 100,
            value.title or '',
            value.message and (' · %s'):format(value.message) or ''
          ),
          done = value.kind == 'end',
        }
        break
      end
    end

    local msg = {}
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
    vim.notify(table.concat(msg, '\n'), vim.log.levels.INFO, {
      id = 'lsp_progress_' .. client.id,
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and ' '
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

local function lsp_info()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local lines = { '' }

  if #clients == 0 then
    vim.list_extend(lines, { '  No LSP clients attached to this buffer.', '' })
  else
    for _, client in ipairs(clients) do
      local pending = progress[client.id] or {}
      local status_icon = #pending > 0 and '⠿' or '●'
      lines[#lines + 1] = ('  %s %s  (id: %d)'):format(status_icon, client.name, client.id)
      lines[#lines + 1] = ('    root:      %s'):format(client.root_dir or '(none)')
      if client.config.filetypes then
        lines[#lines + 1] = ('    filetypes: %s'):format(table.concat(client.config.filetypes, ', '))
      end
      if #pending > 0 then
        lines[#lines + 1] = '    progress:'
        for _, p in ipairs(pending) do
          lines[#lines + 1] = ('      %s'):format(p.msg)
        end
      else
        lines[#lines + 1] = '    status:    idle'
      end
      lines[#lines + 1] = ''
    end
  end

  -- Footer hint
  lines[#lines + 1] = '  [q] close  [r] restart'
  lines[#lines + 1] = ''

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win_w = math.max(50, math.floor(vim.o.columns * 0.5))
  local win_h = math.min(#lines, math.floor(vim.o.lines * 0.5))
  local win = vim.api.nvim_open_win(buf, true, {
    relative  = 'editor',
    width     = win_w,
    height    = win_h,
    col       = math.floor((vim.o.columns - win_w) / 2),
    row       = math.floor((vim.o.lines - win_h) / 2),
    style     = 'minimal',
    border    = 'rounded',
    title     = ' LSP Info ',
    title_pos = 'center',
  })
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].signcolumn = 'no'

  local opts = { buffer = buf, nowait = true }
  vim.keymap.set('n', 'q',     '<cmd>close<cr>', opts)
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', opts)
  vim.keymap.set('n', 'r', function()
    vim.cmd('close')
    vim.schedule(function()
      local attached = vim.lsp.get_clients({ bufnr = 0 })
      vim.lsp.stop_client(attached)
      vim.schedule(function() vim.cmd('edit') end)
      vim.notify('LSP restarting…', vim.log.levels.INFO)
    end)
  end, opts)
end

vim.keymap.set('n', 'gd',        vim.lsp.buf.definition, { desc = 'Go to definition' })
vim.keymap.set('n', '<leader>li', lsp_info, { desc = 'LSP info' })
vim.keymap.set('n', '<leader>ll', function()
  vim.cmd('tabedit ' .. vim.lsp.get_log_path())
end, { desc = 'LSP log' })
vim.keymap.set('n', '<leader>lr', function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  vim.lsp.stop_client(clients)
  vim.schedule(function() vim.cmd('edit') end)
  vim.notify('LSP restarting…', vim.log.levels.INFO)
end, { desc = 'LSP restart' })
