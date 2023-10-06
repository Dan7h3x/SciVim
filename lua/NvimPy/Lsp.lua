local lsp = require("lsp-zero")
local null_ls = require("null-ls")
lsp.extend_lspconfig()
require("neodev").setup({})

lsp.set_sign_icons({
	error = "",
	warn = "",
	hint = "",
	info = "",
})

require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = { "pyright", "lua_ls", "jsonls", "cssls", "texlab" },
	handlers = {
		lsp.default_setup,
	},
})

require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls())
local util = require("lspconfig.util")
require("lspconfig").texlab.setup({
  filetypes = {'tex','bib'},
})

require("lspconfig").pyright.setup({})
null_ls.setup({
	debug = true,
	border = "rounded",
	sources = {
		null_ls.builtins.formatting.prettier.with({
			filetypes = { "vue", "typescript", "javascript", "css", "markdown" },
		}),
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.latexindent,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.shfmt,
		null_ls.builtins.diagnostics.write_good,
		null_ls.builtins.formatting.jq,
	},
})

lsp.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "gD", function()
		vim.lsp.buf.declaration()
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "gI", function()
		vim.lsp.buf.implementation()
	end, opts)
	vim.keymap.set("n", "<leader>ld", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_prev()
	end, opts)
	vim.keymap.set("n", "<leader>lf", function()
		vim.lsp.buf.format({ async = false, timeout_ms = 500 })
	end, opts)

	vim.keymap.set({ "n", "i" }, "<C-k>", function()
		vim.lsp.buf.signature_help()
	end, opts)

	vim.keymap.set("n", "<leader>la", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "gr", function()
		vim.lsp.buf.references()
	end, opts)
	vim.keymap.set("n", "<leader>lr", function()
		vim.lsp.buf.rename()
	end, opts)
end)

lsp.format_on_save({
	format_opts = {
		async = false,
		timeout_ms = 1000,
	},
	servers = {
		["black"] = { "python" },
		["stylua"] = { "lua" },
		["beautysh"] = { "sh", "zsh" },
	},
})

lsp.setup()

vim.diagnostic.config({
	virtual_text = true,
})
