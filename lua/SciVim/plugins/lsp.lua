local icons = require("SciVim.extras.icons")
local function attacher(on_attach, name)
	return vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and (not name or client.name == name) then
				return on_attach(client, buffer)
			end
		end,
	})
end
local capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("blink.cmp").get_lsp_capabilities()
)
local capabilities_nosnip = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("blink.cmp").get_lsp_capabilities({
		textDocument = { completion = { completionItem = { snippetSupport = false } } },
	})
)
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		extend = { "ensure_installed" },
		opts = {
			ensure_installed = {
				"prettier",
				"shfmt",
				"isort",
				"ruff",
				"typstyle",
				"stylua",
				"debugpy",
			},
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufNewFile", "BufReadPre", "BufReadPost", "VeryLazy" },
		dependencies = {
			{ "mason-org/mason.nvim", version = "^1.0.0" },
			{ "mason-org/mason-lspconfig.nvim", version = "^1.0.0", config = function() end },
		},
		opts = function()
			---@class PluginLspOpts
			local ret = {

				-- Setup diagnostics
				diagnostics = {
					underline = true,
					update_in_insert = false,
					virtual_text = {
						spacing = 4,
						source = "if_many",
						prefix = "",
					},
					severity_sort = true,
					float = {
						border = "rounded",
						source = "if_many",
						header = "",
						prefix = "",
					},
					signs = {
						text = {
							[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
							[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
							[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
							[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
						},
						numhl = {
							[vim.diagnostic.severity.WARN] = "WarningMsg",
							[vim.diagnostic.severity.ERROR] = "ErrorMsg",
							[vim.diagnostic.severity.INFO] = "DiagnosticInfo",
							[vim.diagnostic.severity.HINT] = "DiagnosticHint",
						},
					},
				},
			}
			return ret
		end,
		config = function(_, opts)
			attacher(function(client, buffer)
				vim.lsp.buf.hover({
					max_height = 14,
					max_width = 25,
					border = "rounded",
				})

				-- Enable inlay hints if supported
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(false, { bufnr = buffer })
				end

				-- Enable codelens if supported
				if client.server_capabilities.codeLensProvider then
					vim.lsp.codelens.refresh()
					vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
						buffer = buffer,
						callback = vim.lsp.codelens.refresh,
					})
				end

				-- Buffer-local keymaps helper
				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = buffer, noremap = true, desc = desc })
				end

				-- Navigation keymaps
				map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
				map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				map("n", "gr", vim.lsp.buf.references, "Go to References")
				map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
				map("n", "gt", vim.lsp.buf.type_definition, "Go to Type Definition")

				-- Workspace management
				map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
				map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
				map("n", "<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "List Workspace Folders")

				-- Actions
				map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
				-- map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
				map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
				map({ "n", "v" }, "<leader>cf", function()
					vim.lsp.buf.format({ async = true })
				end, "Format")

				-- Diagnostics
				map("n", "<leader>q", vim.diagnostic.setloclist, "Set Diagnostic List")

				-- Inlay hints toggle
				if client.server_capabilities.inlayHintProvider then
					map("n", "<leader>ci", function()
						vim.lsp.inlay_hint.disable()
					end, "Inlay Hints off")
					map("n", "<leader>co", function()
						vim.lsp.inlay_hint.enable()
					end, "Inlay Hints on")
				end

				-- Codelens keymaps
				if client.server_capabilities.codeLensProvider then
					map("n", "<leader>cl", vim.lsp.codelens.run, "Run Codelens")
					map("n", "<leader>cL", vim.lsp.codelens.refresh, "Refresh Codelens")
				end
			end)
			require("mason-lspconfig").setup({
				automatic_installation = true,
				automatic_enable = true,
				ensure_installed = {
					"lua_ls",
					"pyright",
					"bashls",
					"tinymist",
				},
				handlers = {
					-- Default handler, runs for each installed server without a custom handler
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,

					-- Lua LSP with special config
					["lua_ls"] = function()
						-- Some very specific init logic (optional)
						require("lspconfig").lua_ls.setup({
							capabilities = capabilities_nosnip,
							settings = {
								Lua = {
									runtime = { version = "Lua 5.1" },
									workspace = {
										checkThirdParty = true,
										library = {
											vim.env.VIMRUNTIME,
											"${3rd}/luv/library",
										},
									},
									hint = { -- Inlay hints
										enable = true,
										arrayIndex = "Enable",
										setType = true,
										paramName = "All",
										paramType = true,
									},
									diagnostics = { globals = { "vim", "it", "describe", "before_each", "after_each" } },
								},
							},
						})
					end,

					-- Pyright with custom settings
					["pyright"] = function()
						require("lspconfig").pyright.setup({
							capabilities = capabilities,
							settings = {
								pyright = {
									disableOrganizeImports = false,
								},
								python = {
									analysis = {
										autoSearchPaths = true,
										useLibraryCodeForTypes = true,
										diagnosticMode = "workspace",
										inlayHints = {
											variableTypes = true,
											functionReturnTypes = true,
										},
										ignore = { "*" },
										typeCheckingMode = "off",
									},
								},
							},
						})
					end,

					-- Ruff LSP server
					["ruff"] = function()
						require("lspconfig").ruff.setup({
							cmd_env = { RUFF_TRACE = "messages" },
							init_option = {
								settings = {
									loglevel = "error",
								},
							},
						})
						-- Disable hover for ruff server
						-- Note: This may need to be handled inside on_attach or LspAttach for updating capabilities
						-- For now, just demonstrating here:
						-- You may also add in LspAttach autocmd:
						-- if client.name == "ruff" then client.server_capabilities.hoverProvider = false end
					end,

					-- Typst LSP server (tinymist)
					tinymist = function()
						require("lspconfig").tinymist.setup({
							root_dir = require("lspconfig.util").root_pattern("main.typ"),
							capabilities = capabilities,
							settings = {
								formatterMode = "typstyle",
								exportPdf = "onType",
								semanticTokens = "disable",
								completion = {
									triggerOnSnippetPlaceholders = false,
								},
							},
						})
					end,
				},
			})
		end,
	},
}
