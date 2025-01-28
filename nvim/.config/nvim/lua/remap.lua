vim.g.mapleader = " "

-- general keymaps
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<C-s>", ":w <cr>")
vim.keymap.set("n", "<leader>q", ":q <cr>")

-- fzf lua
vim.keymap.set("n", "<leader><leader>", ":FzfLua files <cr>")
vim.keymap.set("n", "<leader>.", ":FzfLua grep<cr>")
vim.keymap.set("n", "<leader>sb", ":lua require('fzf-lua').live_grep({ cwd = vim.fn.expand('%:p:h') })<CR>")

-- move in lines in insert mode
vim.keymap.set("i", "<C-h>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { silent = true })

-- move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Paste without overwriting the clipboard in visual mode
vim.keymap.set("x", "<leader>p", '"_dP')

-- Window management
vim.keymap.set("n", "<leader>ws", ":split <CR>")
vim.keymap.set("n", "<leader>wv", ":vsplit <CR>")

-- Navigate between splits
vim.keymap.set("n", "<leader>wh", "<C-w>h")
vim.keymap.set("n", "<leader>wj", "<C-w>j")
vim.keymap.set("n", "<leader>wk", "<C-w>k")
vim.keymap.set("n", "<leader>wl", "<C-w>l")

-- Use <C-j> and <C-k> for navigating the popup menu only when it is visible
vim.keymap.set("i", "<C-j>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Down>"
end, { expr = true, noremap = true, silent = true })

vim.keymap.set("i", "<C-k>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<Up>"
end, { expr = true, noremap = true, silent = true })

-- Exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-N>]], { noremap = true, silent = true })

-- small terminal
local term_buf = nil
local term_win = nil

vim.keymap.set("n", "<leader>st", function()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
  else
    if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
      vim.cmd("belowright new")
      vim.cmd("term")
      term_buf = vim.api.nvim_get_current_buf()
    else
      vim.cmd("belowright split | buffer " .. term_buf)
    end
    term_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(term_win, 10)
  end
end)

-- Buffer terminal
vim.keymap.set("n", "<leader>bt", function()
  vim.cmd.term()
end)

vim.keymap.set("n", "<leader>gg", function()
  vim.cmd("term lazygit")
  vim.cmd("startinsert")
end)

-- Indent with tab
vim.api.nvim_set_keymap("v", "<Tab>", ">gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- LSP
vim.keymap.set("n", "<leader>l", vim.lsp.buf.format, {})
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, {})

-- Open Ex mode on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("custom-vim-enter", { clear = true }),
  callback = function()
    vim.cmd.Ex()
  end,
})

-- Open lazy package manager
vim.keymap.set("n", "<leader>lz", ":Lazy <cr>")
