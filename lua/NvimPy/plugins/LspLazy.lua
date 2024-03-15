return {
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		lazy = true,
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
		lazy = true,
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"ruff",
				"isort",
				-- "latexindent",
				-- "write-good",
				"prettier",
			},
		},
		---@param opts MasonSettings | {ensure_installed: string[]}
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

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{ "hrsh7th/cmp-path" }, -- Completion engine for path
			{ "hrsh7th/cmp-buffer" }, -- Completion engine for buffer
			{ "hrsh7th/cmp-cmdline" }, -- Completion engine for CMD
			{ "hrsh7th/cmp-nvim-lsp-document-symbol" },
			{ "kdheepak/cmp-latex-symbols" },
			{ "saadparwaiz1/cmp_luasnip" },
			{
				"L3MON4D3/LuaSnip",
				build = vim.fn.has("win32") ~= 0 and "make install_jsregexp" or nil,
				dependencies = {
					"rafamadriz/friendly-snippets",
				},
				opts = {
					history = true,
					delete_check_events = "TextChanged",
				},
				config = function(_, opts)
					if opts then
						require("luasnip").config.setup(opts)
					end
					vim.tbl_map(function(type)
						require("luasnip.loaders.from_" .. type).lazy_load()
					end, { "vscode", "snipmate" })
					require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/Snippets/" }) -- friendly-snippets - enable standardized comments snippets
					require("luasnip").filetype_extend("typescript", { "tsdoc" })
					require("luasnip").filetype_extend("javascript", { "jsdoc" })
					require("luasnip").filetype_extend("lua", { "luadoc" })
					require("luasnip").filetype_extend("python", { "pydoc" })
					require("luasnip").filetype_extend("rust", { "rustdoc" })
					require("luasnip").filetype_extend("cs", { "csharpdoc" })
					require("luasnip").filetype_extend("java", { "javadoc" })
					require("luasnip").filetype_extend("c", { "cdoc" })
					require("luasnip").filetype_extend("cpp", { "cppdoc" })
					require("luasnip").filetype_extend("php", { "phpdoc" })
					require("luasnip").filetype_extend("kotlin", { "kdoc" })
					require("luasnip").filetype_extend("ruby", { "rdoc" })
					require("luasnip").filetype_extend("sh", { "shelldoc" })
				end,
				keys = {
					{
						"<tab>",
						function()
							return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
						end,
						expr = true,
						silent = true,
						mode = "i",
					},
					{
						"<tab>",
						function()
							require("luasnip").jump(1)
						end,
						mode = "s",
					},
					{
						"<s-tab>",
						function()
							require("luasnip").jump(-1)
						end,
						mode = { "i", "s" },
					},
				},
			}, -- Snippets manager
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local Icons = require("NvimPy.Icons")
			local has_words_before = function()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local function borderMenu(hl_name)
				return {
					{ "", "CmpBorderIconsLT" },
					{ "─", hl_name },
					{ "▼", "CmpBorderIconsCT" },
					{ "│", hl_name },
					{ "╯", hl_name },
					{ "─", hl_name },
					{ "╰", hl_name },
					{ "│", hl_name },
				}
			end

			local function borderDoc(hl_name)
				return {
					{ "▲", "CmpBorderIconsCT" },
					{ "─", hl_name },
					{ "╮", hl_name },
					{ "│", hl_name },
					{ "╯", hl_name },
					{ "─", hl_name },
					{ "╰", hl_name },
					{ "│", hl_name },
				}
			end

			local function Kinder(item)
				if item == "Function" then
					return "Fnc"
				elseif item == "Text" then
					return "Txt"
				elseif item == "Module" then
					return "Mdl"
				elseif item == "Snippet" then
					return "Snp"
				elseif item == "Variable" then
					return "Var"
				elseif item == "Folder" then
					return "Dir"
				elseif item == "Method" then
					return "Mth"
				elseif item == "Keyword" then
					return "Kwd"
				elseif item == "Constant" then
					return "Cst"
				elseif item == "Property" then
					return "Prp"
				elseif item == "Field" then
					return "Fld"
				else
					return item
				end
			end
			local winhighlightMenu = {
				border = borderMenu("CmpBorder"),
				scrollbar = true,
				scrolloff = 6,
				col_offset = -2,
				side_padding = 0,
				winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
			}

			local winhighlightDoc = {
				border = borderDoc("CmpBorderDoc"),
				col_offset = -1,
				side_padding = 0,
				scrollbar = false,
				winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
			}

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,noselect",
				},
				preselect = cmp.PreselectMode.None,
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = {
					["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
					["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
					["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
					["<C-y>"] = cmp.config.disable,
					["<C-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
				},

				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 3000 },
					{ name = "luasnip", priority = 1000 },
					{ name = "buffer", priority = 500 },
					{ name = "path", priority = 250 },
					{
						name = "latex_symbols",
						filetype = { "tex", "latex" },
						option = { cache = true, strategy = 2 }, -- avoids reloading each time
						priority = 500,
					},
				}),

				formatting = {
					fields = { "kind", "abbr", "menu" },
					expandable_indicator = true,
					format = function(entry, item)
						item.kind = string.format("%s-{%s}", Icons.kind_icons[item.kind], Kinder(item.kind))
						item.menu = ({
							nvim_lua = "{Lua}",
							nvim_lsp = "{Lsp}",
							luasnip = "{Snip}",
							buffer = "{Buff}",
							path = "{Path}",
							latex_symbols = "{TeX}",
						})[entry.source.name]
						return item
					end,
				},

				view = {
					entries = { name = "custom" },
					docs = {
						auto_open = true,
					},
					separator = "|",
				},
				duplicates = {
					nvim_lsp = 1,
					luasnip = 1,
					cmp_tabnine = 1,
					buffer = 1,
					path = 1,
				},

				-- experimental = {
				-- 	ghost_text = { hl_group = "FloatBorder" },
				-- },
				window = {
					completion = winhighlightMenu,

					documentation = winhighlightDoc,
				},
			})

			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "nvim_lsp_document_symbol" },
					{ name = "buffer" },
				},
				view = {
					entries = {
						name = "wildmenu",
						separator = "|",
					},
				},
			})
			--
			-- -- `:` cmdline setup.
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{
						name = "cmdline",
						option = {
							ignore_cmds = { "Man", "!" },
						},
					},
				}),

				view = {
					entries = {
						name = "wildmenu",
						separator = " | ",
					},
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason-lspconfig.nvim" },
			{ "nvimtools/none-ls.nvim" },
			{
				"folke/neoconf.nvim",
				cmd = "Neoconf",
				config = false,
				dependencies = { "nvim-lspconfig" },
			},
		},
		config = function()
			-- This is where all the LSP shenanigans will live
			local lsp_zero = require("lsp-zero")
			local null_ls = require("null-ls")
			lsp_zero.extend_lspconfig()
			null_ls.setup({
				debug = true,
				border = "rounded",
				sources = {
					null_ls.builtins.formatting.prettier.with({
						filetypes = { "vue", "typescript", "html", "javascript", "css", "markdown" },
					}),
					-- null_ls.builtins.diagnostics.ruff,
					-- null_ls.builtins.formatting.ruff_format,
					null_ls.builtins.formatting.isort,
					-- null_ls.builtins.formatting.latexindent,
					-- null_ls.builtins.diagnostics.write_good,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.shfmt,
					-- null_ls.builtins.formatting.jq,
				},
			})

			lsp_zero.set_sign_icons({
				error = " ",
				warn = " ",
				hint = " ",
				info = " ",
			})

			--- if you want to know more about lsp-zero and mason.nvim
			--- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				local opts = { buffer = bufnr, remap = false }

				vim.keymap.set("n", "gd", function()
					vim.lsp.buf.definition()
				end, opts)
				vim.keymap.set("n", "gD", function()
					vim.lsp.buf.declaration()
				end, opts)
				vim.keymap.set("n", "K", function()
					-- vim.lsp.buf.hover()
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
					vim.lsp.buf.format({ async = true, timeout_ms = 100 })
				end, opts)

				vim.keymap.set({ "n", "i" }, "<A-i>", function()
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
				-- lsp_zero.default_keymaps({ buffer = bufnr })
			end)

			require("mason-lspconfig").setup({
				ensure_installed = {
					"bashls",
					-- "ruff_lsp",
					"pyright",
					"lua_ls",
					"jsonls",
					"vimls",
					-- "texlab",
					-- "marksman",
					-- "typst_lsp",
				},
				handlers = {
					lsp_zero.default_setup,
					lua_ls = function()
						-- (Optional) Configure lua language server for neovim
						local lua_opts = lsp_zero.nvim_lua_ls()
						require("lspconfig").lua_ls.setup(lua_opts)
					end,
				},
			})
		end,
	},
}
