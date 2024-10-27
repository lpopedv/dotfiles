-- Save file
vim.keymap.set("n", "<leader>bs", ":w<CR>")

-- Insert mode keybindings
vim.keymap.set("i", "<C-h>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { silent = true })

-- set conceal
vim.cmd([[
  set conceallevel=0 
  set concealcursor=""
]])
