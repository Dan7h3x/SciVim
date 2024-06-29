return {
	{
		"VonHeikemen/lsp-zero.nvim",
		event = "VeryLazy",
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
		cmd = "Mason",
		event = "VeryLazy",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"black",
				"isort",
				"ruff",
				"prettier",
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
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile", "VeryLazy" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp", event = "VeryLazy" },
			{ "williamboman/mason-lspconfig.nvim", event = "VeryLazy" },
			{ "nvimtools/none-ls.nvim", event = "VeryLazy" },
			{
				"folke/neoconf.nvim",
				event = "VeryLazy",
				cmd = "Neoconf",
				config = false,
				dependencies = { "nvim-lspconfig" },
			},
		},
		config = function()
			-- This is where all the LSP shenanigans will live
			local lsp_zero = require("lsp-zero")
			local null_ls = require("null-ls")
			local icons = require("NvimPy.configs.icons")
			lsp_zero.extend_lspconfig()

			null_ls.setup({
				debug = true,
				border = "rounded",
				sources = {
					null_ls.builtins.formatting.prettier.with({
						filetypes = { "vue", "typescript", "html", "javascript", "css", "markdown" },
					}),
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.shfmt,
					-- null_ls.builtins.completion.spell,
				},
			})

			lsp_zero.set_sign_icons({
				error = icons.diagnostics.Error,
				warn = icons.diagnostics.Warn,
				hint = icons.diagnostics.Hint,
				info = icons.diagnostics.Info,
			})

			--- if you want to know more about lsp-zero and mason.nvim
			--- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				local opts = { buffer = bufnr, remap = false }

				-- vim.keymap.set("n", "gd", function()
				--   vim.lsp.buf.definition()
				-- end, opts)
				vim.keymap.set("n", "gD", function()
					vim.lsp.buf.declaration()
				end, opts)
				vim.keymap.set("n", "K", function()
					-- vim.lsp.buf.hover()
					vim.lsp.buf.hover()
				end, opts)
				-- vim.keymap.set("n", "gI", function()
				--   vim.lsp.buf.implementation()
				-- end, opts)
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
					vim.lsp.buf.format()
				end, opts)

				vim.keymap.set({ "n", "i" }, "<A-i>", function()
					vim.lsp.buf.signature_help()
				end, opts)

				vim.keymap.set("n", "<leader>la", function()
					vim.lsp.buf.code_action({
						apply = true,
						context = {
							diagnostics = {},
						},
					})
				end, opts)
				vim.keymap.set("n", "gr", function()
					vim.lsp.buf.references()
				end, opts)
				vim.keymap.set("n", "<leader>lr", function()
					vim.lsp.buf.rename()
				end, opts)

				vim.keymap.set("n", "gd", function()
					require("telescope.builtin").lsp_definitions({ reuse_win = true })
				end, opts)
				vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
				vim.keymap.set("n", "gI", function()
					require("telescope.builtin").lsp_implementations({ reuse_win = true })
				end, opts)
				vim.keymap.set("n", "gy", function()
					require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
				end, opts)

				-- lsp_zero.default_keymaps({ buffer = bufnr })
			end)

			require("mason-lspconfig").setup({
				ensure_installed = {
					"bashls",
					"lua_ls",
					"jsonls",
					"texlab",
					"pyright",
					"typst_lsp",
				},
				handlers = {
					function(server_name)
						local capabilities = require("cmp_nvim_lsp").default_capabilities()
						if server_name ~= "pyright" then
							require("lspconfig")[server_name].setup({ capabilities = capabilities })
						else
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
						end
					end,
					lua_ls = function()
						local opts = lsp_zero.nvim_lua_ls()
						require("lspconfig").lua_ls.setup(opts)
					end,
				},
			})
		end,
	},
	{
		"aznhe21/actions-preview.nvim",
		keys = {
			{ "\\a", "<cmd>lua require('actions-preview').code_actions()<CR>", desc = "CodeActionMenu" },
		},
		lazy = true,
		event = { "LspAttach", "VeryLazy" },
		config = function()
			require("actions-preview").setup({
				telescope = {
					sorting_strategy = "ascending",
					layout_strategy = "vertical",
					layout_config = {
						width = 0.8,
						height = 0.9,
						prompt_position = "top",
						preview_cutoff = 20,
						preview_height = function(_, _, max_lines)
							return max_lines - 15
						end,
					},
				},
			})
		end,
	},
}
