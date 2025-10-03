-- Floating lazygit state
local lazygit_state = {
  buf = nil,
  win = nil,
  is_open = false
}

local function FloatingLazygit()
  -- If lazygit is already open, close it (toggle behavior)
  if lazygit_state.is_open and vim.api.nvim_win_is_valid(lazygit_state.win) then
    vim.api.nvim_win_close(lazygit_state.win, false)
    lazygit_state.is_open = false
    return
  end

  -- Create buffer if it doesn't exist or is invalid
  if not lazygit_state.buf or not vim.api.nvim_buf_is_valid(lazygit_state.buf) then
    lazygit_state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(lazygit_state.buf, 'bufhidden', 'hide')
  end

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create the floating window
  lazygit_state.win = vim.api.nvim_open_win(lazygit_state.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  -- Set transparency for the floating window
  vim.api.nvim_win_set_option(lazygit_state.win, 'winblend', 0)
  vim.api.nvim_win_set_option(lazygit_state.win, 'winhighlight',
    'Normal:FloatingLazygitNormal,FloatBorder:FloatingLazygitBorder')

  -- Define highlight groups for transparency
  vim.api.nvim_set_hl(0, "FloatingLazygitNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatingLazygitBorder", { bg = "none" })

  -- Start lazygit if not already running
  local has_terminal = false
  local lines = vim.api.nvim_buf_get_lines(lazygit_state.buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line ~= "" then
      has_terminal = true
      break
    end
  end

  if not has_terminal then
    vim.fn.termopen('lazygit', {
      on_exit = function()
        -- Close window when lazygit exits
        if lazygit_state.is_open and vim.api.nvim_win_is_valid(lazygit_state.win) then
          vim.api.nvim_win_close(lazygit_state.win, false)
          lazygit_state.is_open = false
        end
        -- Delete the buffer to start fresh next time
        if lazygit_state.buf and vim.api.nvim_buf_is_valid(lazygit_state.buf) then
          vim.api.nvim_buf_delete(lazygit_state.buf, { force = true })
          lazygit_state.buf = nil
        end
      end
    })
  end

  lazygit_state.is_open = true
  vim.cmd("startinsert")
end

-- Key mapping
vim.keymap.set("n", "<leader>gg", FloatingLazygit, { noremap = true, silent = true, desc = "Toggle floating lazygit" })
