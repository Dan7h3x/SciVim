---@diagnostic disable: redefined-local
return {
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		version = "^1.0.0",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		extend = { "ensure_installed" },
		opts = {
			ensure_installed = {
				"prettier",
				"shfmt",
				"ruff",
				-- "ty",
				"typstyle",
				"tex-fmt",
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
		"mason-org/mason-lspconfig.nvim",
		version = "^1.0.0",
		event = { "BufNewFile", "BufReadPre", "BufReadPost" },
		dependencies = {
			"mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = function()
			local icons = require("SciVim.extras.icons")

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
			local rename = vim.lsp.handlers["textDocument/rename"]
			vim.lsp.handlers["textDocument/rename"] = function(_, result, ctx)
				rename(_, result, ctx)
				local changes = result.changes or result.documentChanges
				vim.notify(("Renamed %s instance in %s file"):format(
					vim.iter(changes):fold(0, function(a, k, n)
						return a + #((n or k).edits or (n or k))
					end),
					#vim.tbl_keys(changes)
				))
			end
			return ret
		end,
		config = function()
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

			--- LSP Setter
			---@param lsp string
			---@param config table
			local function setlsp(lsp, config)
				vim.lsp.config(lsp, config)
				vim.lsp.enable(lsp)
			end
			local blink_ok, blink = pcall(require, "blink-cmp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				blink_ok and blink.get_lsp_capabilities() or {}
			)

			attacher(function(client, buffer)
				local floating = vim.lsp.util.open_floating_preview
				---@diagnostic disable-next-line: duplicate-set-field
				vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
					opts = vim.tbl_deep_extend("force", {
						border = "rounded",
						close_events = { "CursorMoved", "CursorMovedI" },
						max_width = 80,
						max_height = 18,
						focusable = true,
					}, opts or {})
					return floating(contents, syntax, opts)
				end
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
				map("n", "<leader>ch", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
				end, "Inlay hinter")
				map({ "n", "v" }, "<leader>cf", function()
					vim.lsp.buf.format({ async = true })
				end, "Format")

				-- Diagnostics
				map("n", "<leader>q", vim.diagnostic.setloclist, "Set Diagnostic List")

				-- Codelens keymaps
				if client.server_capabilities.codeLensProvider then
					map("n", "<leader>cl", vim.lsp.codelens.run, "Run Codelens")
					map("n", "<leader>cL", vim.lsp.codelens.refresh, "Refresh Codelens")
				end

				-- For tinymist
				map("n", "<leader>tp", function()
					client:exec_cmd({
						title = "pin",
						command = "tinymist.pinMain",
						arguments = { vim.api.nvim_buf_get_name(0) },
					}, { bufnr = buffer })
				end, "[T]inymist Pin")
				map("n", "<leader>tu", function()
					client:exec_cmd({
						title = "unpin",
						command = "tinymist.pinMain",
						arguments = { vim.v.null },
					}, { bufnr = buffer })
				end, "[T]inymist UnPin")

				-- For texlab
				map("n", "<leader>lf", "<CMD>LspTexlabForward<CR>", "forwardSearch texlab")
			end)
			local mason_ok, mason = pcall(require, "mason-lspconfig")

			if mason_ok then
				mason.setup({
					automatic_installation = true,
					automatic_enable = true,
					ensure_installed = {
						"lua_ls",
						"basedpyright",
						"bashls",
						"texlab",
						"tinymist",
					},
				})
			end

			local bashls = {
				capabilities = capabilities,
				pattern = { "bash", "zsh", "sh" },
				settings = {},
			}
			setlsp("bashls", bashls)

			-- Lua LSP with special config
			local lua_ls = {
				capabilities = capabilities,
				root_markers = {
					"stylua.toml",
					".stylua.toml",
					".styluaignore",
					".luarc.json",
					".luarc",
					"luarc.json",
					".luacheckrc",
					"selene.toml",
					".selene.toml",
					".git",
					"neoconf.json",
					".neoconf.json",
				} or vim.loop.cwd(),
				settings = {
					Lua = {
						runtime = { version = "Lua 5.1" },
						workspace = {
							checkThirdParty = false,
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
						completion = {
							autoRequire = false,
							callSnippet = "Replace",
							displayContext = 5,
							keywordSnippet = "Both",
						},
						codelens = {
							enable = true,
						},
						hover = {
							enumsLimit = 3,
						},

						diagnostics = {
							globals = { "vim", "it", "describe", "before_each", "after_each" },
						},
					},
				},
			}
			setlsp("lua_ls", lua_ls)
			local basedpyright = {
				capabilities = capabilities,
				settings = {
					basedpyright = {
						analysis = {
							autoSearchPaths = true,
							diagnosticMode = "workspace",
							useLibraryCodeForTypes = true,
							autoImportCompletions = false,
							fileEnumerationTimeout = 100,
							autoFormatStrings = true,
							logLevel = "Warning",
						},
						disableOrganizeImports = true,
					},
				},
			}
			setlsp("basedpyright", basedpyright)

			-- local ty = {
			-- 	capabilities = capabilities,
			-- 	root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
			-- 	pattern = { "python" },
			-- 	settings = {
			-- 		ty = {
			-- 			diagnosticMode = "workspace",
			-- 			experimental = {
			-- 				rename = true,
			-- 			},
			-- 		},
			-- 	},
			-- }
			-- setlsp("ty", ty)
			-- local pyrefly = {
			-- 	capabilities = capabilities,
			-- 	command = { "pyrefly", "server" },
			-- 	pattern = { "python" },
			-- }
			-- setlsp("pyrefly", pyrefly)

			local ruff = {
				init_option = {
					settings = {
						loglevel = "error",
					},
				},
			}
			setlsp("ruff", ruff)
			--
			local texlab = {
				capabilities = capabilities,
				settings = {
					texlab = {
						bibtexFormatter = "texlab",
						build = {
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
							executable = "latexmk",
							forwardSearchAfter = false,
							onSave = true,
						},
						chktex = {
							onEdit = false,
							onOpenAndSave = true,
						},
						inlayHints = {
							labelDefinitions = true,
							labelReferences = true,
							maxLength = nil,
						},
						diagnosticsDelay = 200,
						formatterLineLength = 120,
						forwardSearch = {
							executable = "zathura",
							args = { "--synctex-forward", "%l:1:%f", "%p" },
						},
						latexFormatter = "tex-fmt",
						-- latexindent = {
						-- 	modifyLineBreaks = false,
						-- },
					},
				},
			}
			setlsp("texlab", texlab)

			local tinymist = {
				capabilities = capabilities,
				settings = {
					formatterMode = "typstyle",
					exportPdf = "onType",
					semanticTokens = "disable",
					-- completion = {
					-- 	triggerOnSnippetPlaceholders = false,
					-- 	postfixUfcsLeft = false,
					-- },
					lint = {
						enabled = true,
					},
				},
			}
			setlsp("tinymist", tinymist)

			local ltex_plus = {
				capabilities = capabilities,
				settings = {
					ltex = {
						enabled = { "bibtex", "plaintex", "tex", "latex", "typst" },
						language = "en-US",
						diagnosticSeverity = "warning",
						disabledRules = {
							["en-US"] = { "DASH_RULE", "WHITESPACE_RULE", "MORFOLOGIK_RULE_EN_US" },
						},
						enabledRules = {
							["en-US"] = { "MISSING_VERB", "PASSIVE_VOICE", "IT_IS_OBVIOUS", "PLAIN_ENGLISH" },
						},
						completionEnabled = true,
						additionalRules = {
							enablePickyRules = true,
							motherTongue = "fa",
						},
						checkFrequency = "edit",
					},
				},
			}
			setlsp("ltex_plus", ltex_plus)
		end,
	},
}
