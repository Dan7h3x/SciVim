local lsp = require("lsp-zero")
local luals = lsp.nvim_lua_ls()
local null_ls = require("null-ls")
local capabilities = require("cmp_nvim_lsp").default_capabilities

require("neodev").setup({})

lsp.set_sign_icons({
	error = "",
	warn = "",
	hint = "",
	info = "",
})

require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = { "pyright", "lua_ls", "jsonls", "cssls" },
	handlers = {
		lsp.default_setup,
	},
})

require("lspconfig").lua_ls.setup({
	settings = {
		Lua = {
			completion = {
				callSnippet = "Replace",
			},
		},
	},
})
local util = require("lspconfig.util")

local root_files = {
	"pyproject.toml",
	"setup.py",
	"setup.cfg",
	"requirements.txt",
	"Pipfile",
	"pyrightconfig.json",
	".git",
}

local function organize_imports()
	local params = {
		command = "pyright.organizeimports",
		arguments = { vim.uri_from_bufnr(0) },
	}
	vim.lsp.buf.execute_command(params)
end

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
	default_config = {
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
		root_dir = "src",
		root = "src",
		executionEnvironments = "root",
		single_file_support = true,
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
				},
			},
		},
	},
	commands = {
		PyrightOrganizeImports = {
			organize_imports,
			description = "Organize Imports",
		},
		PyrightSetPythonPath = {
			set_python_path,
			description = "Reconfigure pyright with the provided python path",
			nargs = 1,
			complete = "file",
		},
	},
	docs = {
		description = [[
https://github.com/microsoft/pyright

`pyright`, a static type checker and language server for python
]],
	},
})

-- Latex Support
local texlab_build_status = vim.tbl_add_reverse_lookup({
	Success = 0,
	Error = 1,
	Failure = 2,
	Cancelled = 3,
})

local texlab_forward_status = vim.tbl_add_reverse_lookup({
	Success = 0,
	Error = 1,
	Failure = 2,
	Unconfigured = 3,
})

local function buf_build(bufnr)
	bufnr = util.validate_bufnr(bufnr)
	local texlab_client = util.get_active_client_by_name(bufnr, "texlab")
	local pos = vim.api.nvim_win_get_cursor(0)
	local params = {
		textDocument = { uri = vim.uri_from_bufnr(bufnr) },
		position = { line = pos[1] - 1, character = pos[2] },
	}
	if texlab_client then
		texlab_client.request("textDocument/build", params, function(err, result)
			if err then
				error(tostring(err))
			end
			print("Build " .. texlab_build_status[result.status])
		end, bufnr)
	else
		print("method textDocument/build is not supported by any servers active on the current buffer")
	end
end

local function buf_search(bufnr)
	bufnr = util.validate_bufnr(bufnr)
	local texlab_client = util.get_active_client_by_name(bufnr, "texlab")
	local pos = vim.api.nvim_win_get_cursor(0)
	local params = {
		textDocument = { uri = vim.uri_from_bufnr(bufnr) },
		position = { line = pos[1] - 1, character = pos[2] },
	}
	if texlab_client then
		texlab_client.request("textDocument/forwardSearch", params, function(err, result)
			if err then
				error(tostring(err))
			end
			print("Search " .. texlab_forward_status[result.status])
		end, bufnr)
	else
		print("method textDocument/forwardSearch is not supported by any servers active on the current buffer")
	end
end

-- bufnr isn't actually required here, but we need a valid buffer in order to
-- be able to find the client for buf_request.
-- TODO find a client by looking through buffers for a valid client?
-- local function build_cancel_all(bufnr)
--   bufnr = util.validate_bufnr(bufnr)
--   local params = { token = "texlab-build-*" }
--   lsp.buf_request(bufnr, 'window/progress/cancel', params, function(err, method, result, client_id)
--     if err then error(tostring(err)) end
--     print("Cancel result", vim.inspect(result))
--   end)
-- end

require("lspconfig").texlab.setup({
	default_config = {
		cmd = { "texlab" },
		filetypes = { "tex", "plaintex", "bib" },
		root_dir = function(fname)
			return util.root_pattern(".latexmkrc")(fname) or util.find_git_ancestor(fname)
		end,
		single_file_support = true,
		settings = {
			texlab = {
				rootDirectory = nil,
				build = {
					executable = "pdflatex",
					args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
					onSave = false,
					forwardSearchAfter = false,
				},
				auxDirectory = ".",
				forwardSearch = {
					executable = nil,
					args = {},
				},
				chktex = {
					onOpenAndSave = false,
					onEdit = false,
				},
				diagnosticsDelay = 300,
				latexFormatter = "latexindent",
				latexindent = {
					modifyLineBreaks = true,
				},
				bibtexFormatter = "texlab",
				formatterLineLength = 82,
			},
		},
	},
	commands = {
		TexlabBuild = {
			function()
				buf_build(0)
			end,
			description = "Build the current buffer",
		},
		TexlabForward = {
			function()
				buf_search(0)
			end,
			description = "Forward search from current position",
		},
	},
	docs = {
		description = [[
https://github.com/latex-lsp/texlab

A completion engine built from scratch for (La)TeX.

See https://github.com/latex-lsp/texlab/wiki/Configuration for configuration options.
]],
	},
})
require("lspconfig").matlab_ls.setup({})
null_ls.setup({
	debug = true,
	border = "rounded",
	sources = {
		null_ls.builtins.formatting.prettier.with({
			filetypes = { "vue", "typescript", "javascript", "css", "markdown" },
		}),
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.diagnostics.ruff,
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
		timeout_ms = 500,
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
