return {
	{
		"VonHeikemen/lsp-zero.nvim",
		enabled = true,
		branch = "v3.x",
		config = false,
		init = function()
			-- Disable automatic setup, we are doing it manually
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},
	{
		"williamboman/mason.nvim",
		lazy = true,
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"prettier",
				"shfmt",
				"isort",
				"ruff",
				"debugpy",
				-- "textlsp",
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
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		enabled = true,
		dependencies = {
			{ "williamboman/mason-lspconfig.nvim", config = function() end },
		},
		config = function()
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				require("cmp_nvim_lsp").default_capabilities()
			)

			local lsp_zero = require("lsp-zero")
			local icons = require("SciVim.extras.icons")

			lsp_zero.on_attach(function(client, bufnr)
				-- Example keybindings for LSP commands
				local opts = { buffer = bufnr, noremap = true, silent = true }
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
				-- vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
				-- vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
				-- vim.keymap.set("n", "<space>wl", function()
				-- print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				-- end, opts)
				vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "<space>cr", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<space>cf", function()
					vim.lsp.buf.format({ async = true })
				end, opts)

				local function diagnostic_prefix(diagnostic)
					if diagnostic.severity == vim.diagnostic.severity.ERROR then
						return icons.diagnostics.Error .. ": "
					elseif diagnostic.severity == vim.diagnostic.severity.WARN then
						return icons.diagnostics.Warn .. ": "
					elseif diagnostic.severity == vim.diagnostic.severity.HINT then
						return icons.diagnostics.Hint .. ": "
					elseif diagnostic.severity == vim.diagnostic.severity.INFO then
						return icons.diagnostics.Info .. ": "
					else
						return ": "
					end
				end

				vim.diagnostic.config({
					underline = true,
					update_in_insert = false,
					virtual_text = {
						spacing = 4,
						source = "if_many",
						prefix = function(diagnostic)
							return diagnostic_prefix(diagnostic)
						end,
					},
					severity_sort = true,
					signs = {
						text = {
							[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
							[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
							[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
							[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
						},
					},
					float = {
						focusable = false,
						border = "rounded",
						source = "if_many",
					},
				})
			end)

			capabilities.textDocument.completion.completionItem.snippetSupport = true
			capabilities.textDocument.completion.completionItem.resolveSupport = {
				properties = {
					"documentation",
					"detail",
					"additionalTextEdits",
				},
			}

			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"bashls",
					"texlab",
					"typst_lsp",
				},
				handlers = {
					function(server)
						require("lspconfig")[server].setup({
							capabilities = capabilities,
						})
					end,
					["lua_ls"] = function()
						local lua_ls_conf = lsp_zero.nvim_lua_ls({ capabilities = capabilities })
						require("lspconfig").lua_ls.setup(lua_ls_conf)
					end,
					-- ["textlsp"] = function()
					-- 	require("lspconfig").textlsp.setup({
					-- 		textLSP = {
					-- 			analysers = {
					-- 				languagetool = {
					-- 					enabled = true,
					-- 					check_text = {
					-- 						on_open = true,
					-- 						on_save = true,
					-- 						on_change = false,
					-- 					},
					-- 				},
					-- 				ollama = {
					-- 					enabled = true,
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = true,
					-- 						on_change = false,
					-- 					},
					-- 					model = "phi3:3.8b-instruct", -- smaller but faster model
					-- 					-- model = "phi3:14b-instruct",  -- more accurate
					-- 					max_token = 50,
					-- 				},
					-- 				gramformer = {
					-- 					-- gramformer dependency needs to be installed manually
					-- 					enabled = false,
					-- 					gpu = false,
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = true,
					-- 						on_change = false,
					-- 					},
					-- 				},
					-- 				hf_checker = {
					-- 					enabled = false,
					-- 					gpu = false,
					-- 					quantize = 32,
					-- 					model = "pszemraj/flan-t5-large-grammar-synthesis",
					-- 					min_length = 40,
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = true,
					-- 						on_change = false,
					-- 					},
					-- 				},
					-- 				hf_instruction_checker = {
					-- 					enabled = false,
					-- 					gpu = false,
					-- 					quantize = 32,
					-- 					model = "grammarly/coedit-large",
					-- 					min_length = 40,
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = true,
					-- 						on_change = false,
					-- 					},
					-- 				},
					-- 				hf_completion = {
					-- 					enabled = false,
					-- 					gpu = false,
					-- 					quantize = 32,
					-- 					model = "bert-base-multilingual-cased",
					-- 					topk = 5,
					-- 				},
					-- 				openai = {
					-- 					enabled = false,
					-- 					api_key = "<MY_API_KEY>",
					-- 					-- url = '<CUSTOM_URL>'  -- optional to use an OpenAI-compatible server
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = false,
					-- 						on_change = false,
					-- 					},
					-- 					model = "gpt-3.5-turbo",
					-- 					max_token = 16,
					-- 				},
					-- 				grammarbot = {
					-- 					enabled = false,
					-- 					api_key = "<MY_API_KEY>",
					-- 					-- longer texts are split, this parameter sets the maximum number of splits per analysis
					-- 					input_max_requests = 1,
					-- 					check_text = {
					-- 						on_open = false,
					-- 						on_save = false,
					-- 						on_change = false,
					-- 					},
					-- 				},
					-- 			},
					-- 			documents = {
					-- 				-- the language of the documents, could be set to `auto` of `auto:<fallback>`
					-- 				-- to detect automatically, default: auto:en
					-- 				language = "auto:en",
					-- 				-- do not autodetect documents with fewer characters
					-- 				min_length_language_detect = 20,
					-- 				org = {
					-- 					org_todo_keywords = {
					-- 						"TODO",
					-- 						"IN_PROGRESS",
					-- 						"DONE",
					-- 					},
					-- 				},
					-- 				txt = {
					-- 					parse = true,
					-- 				},
					-- 			},
					-- 		},
					-- 	})
					-- end,
					["texlab"] = function()
						require("lspconfig").texlab.setup({
							capabilities = capabilities,
							settings = {
								texlab = {
									rootDirectory = { ".latexmkrc", ".texlabroot", "texlabroot", "Tectonic.toml" },
									build = {
										executable = "latexmk",
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
										onOpenAndSave = true,
										onEdit = false,
									},
									diagnosticsDelay = 300,
									latexFormatter = "latexindent",
									latexindent = {
										["local"] = nil, -- local is a reserved keyword
										modifyLineBreaks = false,
									},
									bibtexFormatter = "texlab",
									formatterLineLength = 80,
								},
							},
						})
					end,

					["pyright"] = function()
						require("lspconfig").pyright.setup({
							capabilities = capabilities,
							settings = {
								pyright = {
									disableOrganizeImports = true,
								},
								python = {
									analysis = {
										ignore = { "*" },
										typeCheckingMode = "off",
									},
								},
							},
						})
					end,
					["ruff"] = function()
						require("lspconfig").ruff.setup({
							-- cmd = { "ruff", "server", "--preview" },
							cmd_env = { RUFF_TRACE = "messages" },
							init_option = {
								settings = {
									loglevel = "error",
								},
							},
						})
					end,
				},
			})
		end,
	},
}
