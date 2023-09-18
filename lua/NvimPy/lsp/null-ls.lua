local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics
local completion = null_ls.builtins.completion
local actions = null_ls.builtins.code_actions
local sources = null_ls.setup({
	debug = false,
	border = "rounded",

	sources = {
		formatting.prettier.with({
			filetypes = {
				"vue",
				"typescript",
				"javascript",
				"css",
				"markdown",
			},
		}),
		diagnostics.flake8,
		diagnostics.pydocstyle,
		formatting.black,
		formatting.isort,
		formatting.stylua,
		formatting.beautysh,
		completion.tags,
		formatting.latexindent,
		actions.shellcheck,
	},
})
