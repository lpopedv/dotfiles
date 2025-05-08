local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "move lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "move lines up in visual selection" })

vim.keymap.set("n", "J", "mzJ`z")

-- Go to after and before results in match
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Indent lines
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Past without replacing clipboard content
vim.keymap.set("x", "<leader>p", [["_dP"]])

-- Move in insert mode
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "move cursor left in insert mode" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "move cursor down in insert mode" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "move cursor up in insert mode" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "move cursor right in insert mode" })

-- Exit insert mode
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Clear search hl
vim.keymap.set("n", "<Esc><Esc>", ":nohl<CR>", { desc = "Clear search hl", silent = true })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- Replace the word cursor is on globally
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word cursor is on globally" })

-- Hightlight yanking
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Exit
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "close current split" })

-- Save buffer
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "vertical split" })

-- Vertical split
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "vertical split" })

-- Horizontal split
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "horizontal split" })

-- Move between splits
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "move to left split" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "move to below split" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "move to above split" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "move to right split" })

-- Copy filepath to the clipboard
vim.keymap.set("n", "<leader>fy", function()
  local filePath = vim.fn.expand("%:~")                -- Gets the file path relative to the home directory
  vim.fn.setreg("+", filePath)                         -- Copy the file path to the clipboard register
  print("File path copied to clipboard: " .. filePath) -- Optional: print message to confirm
end, { desc = "Copy file path to clipboard" })

-- LSP
vim.keymap.set("n", "<leader>l", vim.lsp.buf.format, {})
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, {})

-- Toggle LSP diagnostics visibility
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
  isLspDiagnosticsVisible = not isLspDiagnosticsVisible
  vim.diagnostic.config({
    virtual_text = isLspDiagnosticsVisible,
    underline = isLspDiagnosticsVisible
  })
end, { desc = "Toggle LSP diagnostics" })


-- fzf lua
vim.keymap.set("n", "<leader><leader>", ":FzfLua files <cr>")
vim.keymap.set("n", "<leader>.", ":FzfLua grep<cr>")
vim.keymap.set("n", "<leader>sb", ":lua require('fzf-lua').live_grep({ cwd = vim.fn.expand('%:p:h') })<CR>")
