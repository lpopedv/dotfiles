local function load_direnv()
  if vim.fn.executable("direnv") == 1 then
    local handle = io.popen("direnv exec . env")
    if handle then
      local result = handle:read("*a")
      handle:close()

      for line in result:gmatch("[^\r\n]+") do
        local key, value = line:match("([^=]+)=(.*)")
        if key and value and key == "OPENROUTER_API_KEY" then
          vim.env[key] = value
          break
        end
      end
    end
  end
end

load_direnv()

vim.api.nvim_create_autocmd("DirChanged", {
  callback = load_direnv,
})
