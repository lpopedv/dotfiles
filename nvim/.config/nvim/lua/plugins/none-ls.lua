return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- Lua
				null_ls.builtins.formatting.stylua,

				-- Elixir
				null_ls.builtins.diagnostics.credo,

				-- Protos
				null_ls.builtins.formatting.protolint,

				-- Biome js
				null_ls.builtins.formatting.biome,

        --null_ls.builtins.formatting.prettier,
        --require("none-ls.diagnostics.eslint")
			},
		})
	end,
}
