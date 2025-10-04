-- Transparent tabline appearance
vim.cmd([[
  hi TabLineFill guibg=NONE ctermfg=242 ctermbg=NONE
]])

-- Custom tabline function
function _G.custom_tabline()
  local s = ''
  for i = 1, vim.fn.tabpagenr('$') do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)

    -- Format: just filename, or [No Name] if empty
    local label = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'

    -- Highlight current tab
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end

    -- Add tab number and label
    s = s .. ' ' .. i .. ':' .. label .. ' '
  end

  -- Fill remaining space
  s = s .. '%#TabLineFill#'

  return s
end

vim.o.tabline = '%!v:lua.custom_tabline()'
