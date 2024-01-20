local lsp = require("lsp-zero")
local null_ls = require("null-ls")
local Hover = require("hover")
local util = require("lspconfig.util")
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
lsp.extend_lspconfig()

lsp.set_sign_icons({
	error = " ",
	warn = " ",
	hint = " ",
	info = " ",
})

local plugin = require("lazy.core.config").spec.plugins["neoconf.nvim"]
require("neoconf").setup(require("lazy.core.plugin").values(plugin, "opts", false))

require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = { "bashls", "pyright", "lua_ls", "jsonls", "vimls", "texlab", "marksman", "typst_lsp" },
	handlers = {
		lsp.default_setup,
	},
})
local root_files = {
	"pyproject.toml",
	"setup.py",
	"setup.cfg",
	"requirements.txt",
	"Pipfile",
	"pyrightconfig.json",
	".git",
}
local function set_python_path(path)
	local clients = vim.lsp.get_active_clients({
		bufnr = vim.api.nvim_get_current_buf(),
		name = "pyright",
	})
	for _, client in ipairs(clients) do
		client.config.settings =
			vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
		client.notify("workspace/didChangeConfiguration", { settings = nil })
	end
end

require("lspconfig").pyright.setup({
	capabilities = capabilities,
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_dir = function(fname)
		return util.root_pattern(unpack(root_files))(fname)
	end,
	single_file_support = true,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
			},
		},
	},
	PyrightSetPythonPath = {
		set_python_path,
		description = "Reconfigure pyright with the provided python path",
		nargs = 1,
		complete = "file",
	},
})
require("lspconfig").clangd.setup({})
require("lspconfig").marksman.setup({})
require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls())
require("lspconfig").texlab.setup({
	filetypes = { "tex", "plaintex", "bib" },
	single_file_support = true,
	settings = {
		texlab = {
			auxDirectory = ".",
			bibtexFormatter = "texlab",
			build = {
				args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
				executable = "latexmk",
				forwardSearchAfter = false,
				onSave = false,
			},
			chktex = {
				onEdit = false,
				onOpenAndSave = true,
			},
			diagnosticsDelay = 300,
			formatterLineLength = 80,
			forwardSearch = {
				args = {},
			},
			latexFormatter = "latexindent",
			latexindent = {
				modifyLineBreaks = false,
			},
		},
	},
})
require("lspconfig").typst_lsp.setup({
  settings = {
    exportPdf = "onSave",
  }
})
null_ls.setup({
	debug = true,
	border = "rounded",
	sources = {
		null_ls.builtins.formatting.prettier.with({
			filetypes = { "vue", "typescript", "html", "javascript", "css", "markdown" },
		}),
		null_ls.builtins.formatting.yapf,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.diagnostics.ruff,
		null_ls.builtins.formatting.latexindent,
		null_ls.builtins.diagnostics.write_good,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.clang_format,
		null_ls.builtins.formatting.shfmt,
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
		-- vim.lsp.buf.hover()
		Hover.hover()
	end, opts)
	vim.keymap.set("n", "gK", function()
		Hover.hover_select()
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
		vim.lsp.buf.format({ async = true, timeout_ms = 100 })
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


lsp.setup()

vim.diagnostic.config({
	virtual_text = true,
})
