local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "

require("lazy").setup({
	--[[
   Plugins
  ]]
	"nvim-neo-tree/neo-tree.nvim", -- File Explorer
	"mbbill/undotree", -- Undo Explorer
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"folke/neodev.nvim",
			config = function()
				require("neodev").setup({
					library = {
						enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
						-- these settings will be used for your Neovim config directory
						runtime = true, -- runtime path
						types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
						plugins = true, -- installed opt or start plugins in packpath
						-- you can also specify the list of plugins to make available as a workspace library
						-- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
					},
					setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
					-- for your Neovim config directory, the config.library settings will be used as is
					-- for plugin directories (root_dirs having a /lua directory), config.library.plugins will be disabled
					-- for any other directory, config.library.enabled will be set to false
					override = function(root_dir, options) end,
					-- With lspconfig, Neodev will automatically setup your lua-language-server
					-- If you disable this, then you have to set {before_init=require("neodev.lsp").before_init}
					-- in your lsp start options
					lspconfig = true,
					-- much faster, but needs a recent built of lua-language-server
					-- needs lua-language-server >= 3.6.0
					pathStrict = true,
				})
			end,
		},
	}, -- LSP Client
	"hrsh7th/cmp-nvim-lsp", -- Completion engine for LSP
	"hrsh7th/cmp-path", -- Completion engine for path
	"hrsh7th/cmp-nvim-lua", -- Completion engine for lua
	"hrsh7th/cmp-buffer", -- Completion engine for buffer
	"hrsh7th/cmp-cmdline", -- Completion engine for CMD
	"lukas-reineke/cmp-under-comparator",

	{
		"hrsh7th/nvim-cmp",
		dependencies = "kdheepak/cmp-latex-symbols",
	}, -- Completion engine for Neovim with Latex Symbols support
	"saadparwaiz1/cmp_luasnip", -- Completion engine for Snippets
	{
		"L3MON4D3/LuaSnip",
	}, -- Snippets manager
	"nvimtools/none-ls.nvim", -- LSP Injector for Neovim
	"williamboman/mason.nvim", -- LSP and tools manager for Neovim
	"williamboman/mason-lspconfig.nvim", -- Mason compatible with lspconfig
	{
		"VonHeikemen/lsp-zero.nvim",
		lazy = true,
		init = function()
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},
	"onsails/lspkind.nvim",

	"nvim-treesitter/nvim-treesitter", -- Neovim Treesitter configurations
	{
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup({
				history = 1000,
				enable_persistent_history = false,
				length_limit = 1048576,
				continuous_sync = false,
				db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
				filter = nil,
				preview = true,
				prompt = nil,
				default_register = '"',
				default_register_macros = "q",
				enable_macro_history = true,
				content_spec_column = false,
				disable_keycodes_parsing = false,
				on_select = {
					move_to_front = false,
					close_telescope = true,
				},
				on_paste = {
					set_reg = false,
					move_to_front = false,
					close_telescope = true,
				},
				on_replay = {
					set_reg = false,
					move_to_front = false,
					close_telescope = true,
				},
				on_custom_action = {
					close_telescope = true,
				},
				keys = {
					telescope = {
						i = {
							select = "<cr>",
							paste = "<c-p>",
							paste_behind = "<c-k>",
							replay = "<c-q>", -- replay a macro
							delete = "<c-d>", -- delete an entry
							edit = "<c-e>", -- edit an entry
							custom = {},
						},
						n = {
							select = "<cr>",
							paste = "p",
							--- It is possible to map to more than one key.
							-- paste = { 'p', '<c-p>' },
							paste_behind = "P",
							replay = "q",
							delete = "d",
							edit = "e",
							custom = {},
						},
					},
					fzf = {
						select = "default",
						paste = "ctrl-p",
						paste_behind = "ctrl-k",
						custom = {},
					},
				},
			})
		end,
	}, -- Clipboard manager Neovim
	{
		"kevinhwang91/nvim-hlslens",
		config = function()
			require("hlslens").setup()
		end,
	}, -- Searching helper
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }, -- Fuzzy finder awesome
	{
		"NvChad/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup({
				filetypes = { "*" },
				user_default_options = {
					RGB = true, -- #RGB hex codes
					RRGGBB = true, -- #RRGGBB hex codes
					names = true, -- "Name" codes like Blue or blue
					RRGGBBAA = true, -- #RRGGBBAA hex codes
					AARRGGBB = true, -- 0xAARRGGBB hex codes
					rgb_fn = true, -- CSS rgb() and rgba() functions
					hsl_fn = true, -- CSS hsl() and hsla() functions
					css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
					css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
					-- Available modes for `mode`: foreground, background,  virtualtext
					mode = "background", -- Set the display mode.
					-- Available methods are false / true / "normal" / "lsp" / "both"
					-- True is same as normal
					tailwind = true, -- Enable tailwind colors
					-- parsers can contain values used in |user_default_options|
					sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
					virtualtext = "■",
					-- update color values even if buffer is not focused
					-- example use: cmp_menu, cmp_docs
					always_update = false,
				},
				-- all the sub-options of filetypes apply to buftypes
				buftypes = {},
			})
		end,
	}, -- Color highlighter
	"folke/tokyonight.nvim", -- Great theme
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000, -- Ensure it loads first
	},

	"goolord/alpha-nvim", -- Dashboard for neovim
	{ "MunifTanjim/nui.nvim" }, -- Better UI neovim
	"frabjous/knap", -- LaTeX builder and previewer

	{ "akinsho/toggleterm.nvim", version = "*", config = true },
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	}, -- Commenting tools
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter", "CmdlineEnter" },
		branch = "v0.6", --recomended as each new version will have breaking changes
		opts = {
			--Config goes here
		},
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	"simrat39/symbols-outline.nvim", -- Symbols of buffer at pane
	"nvim-lualine/lualine.nvim", -- Awesome statusline

	{ "rafamadriz/friendly-snippets" }, -- Common nice snippets
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{
				"<leader>Tx",
				"<cmd>TroubleToggle document_diagnostics<cr>",
				desc = "Document Diagnostics (Trouble)",
			},
			{
				"<leader>TX",
				"<cmd>TroubleToggle workspace_diagnostics<cr>",
				desc = "Workspace Diagnostics (Trouble)",
			},
			{ "<leader>TL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
			{ "<leader>TQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").previous({ skip_groups = true, jump = true })
					else
						vim.cmd.cprev()
					end
				end,
				desc = "Previous trouble/quickfix item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						vim.cmd.cnext()
					end
				end,
				desc = "Next trouble/quickfix item",
			},
		},
	}, -- LSP diagnostics better way
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile" },
		config = true,
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      {
        "[t",
        function() require("todo-comments").jump_prev() end,
        desc =
        "Previous todo comment"
      },
      { "<leader>Td", "<cmd>TodoTrouble<cr>",                              desc = "Todo (Trouble)" },
      {
        "<leader>t",
        "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",
        desc =
        "Todo/Fix/Fixme (Trouble)"
      },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
    },
	}, -- Todo manager

	{ "akinsho/bufferline.nvim" }, -- Buffer manager
	{
		-- TODO : reconfig this module
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			plugins = { spelling = true },
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			local keymaps =
				{
					mode = { "n", "v" },
					["g"] = { name = "+goto" },
					["gz"] = { name = "+surround" },
					["]"] = { name = "+next" },
					["["] = { name = "+prev" },
					["<leader><tab>"] = { name = "+tabs" },
					["<leader>b"] = { name = "+buffer" },
					["<leader>c"] = { name = "+code" },
					["<leader>f"] = { name = "+telescope" },
					["<leader>g"] = { name = "+git" },
					["<leader>gh"] = { name = "+hunks" },
					["<leader>q"] = { name = "+quit/session" },
					["<leader>s"] = { name = "+search/iron" },
					["<leader>u"] = { name = "+ui" },
					["<leader>w"] = { name = "+windows" },
					["<leader>x"] = { name = "+diagnostics/quickfix" },
					["<leader>d"] = { name = "+debug" },
					["<leader>da"] = { name = "+adapters" },
				}, wk.register(keymaps)
		end,
	}, -- Leader Key helper
	{ "jbyuki/nabla.nvim" }, -- Scientific Note taking LaTeX
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]g", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next git hunk" })

				map("n", "[g", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Previous git hunk" })

				-- Actions
				map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
				map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>gB", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>gl", gs.toggle_current_line_blame, { desc = "Blame current line" })
				map("n", "<leader>gt", gs.toggle_deleted, { desc = "Toggle old versions of hunks" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "inner git hunk" })
			end,
		},
	}, -- Gitsigns helper
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		config = function()
			local cb = require("diffview.config").diffview_callback
			require("diffview").setup({
				view = {
					default = {
						winbar_info = true,
					},
					file_history = {
						winbar_info = true,
					},
				},
				key_bindings = {
					view = { { "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
					file_panel = {
						{ "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
					},
					file_history_panel = {
						{ "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
					},
					option_panel = { { "n", "q", cb("close"), { desc = "Close Diffview" } } },
				},
			})
		end,
	}, -- Git diffs viewer

	{
		"akinsho/git-conflict.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = { disable_diagnostics = true },
	}, -- Git conflict manager
	{ "jbyuki/venn.nvim" },
	{
		"ellisonleao/glow.nvim",
		config = function()
			require("glow").setup({
				border = "rounded",
				style = "dark",
				width = 100,
				height = 120,
				width_ratio = 0.85,
				height_ratio = 0.85,
			})
		end,
		cmd = "Glow",
	},
	{ "nvim-tree/nvim-web-devicons" },
	{ "Vigemus/iron.nvim" },
	{
		"ThePrimeagen/refactoring.nvim",
		keys = {
			{
				"<leader>fr",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v",
				noremap = true,
				silent = true,
				expr = false,
			},
		},
		opts = {},
	},
	{
		"andymass/vim-matchup",
		event = "BufReadPost",
		enabled = true,
		init = function()
			vim.o.matchpairs = "(:),{:},[:],<:>"
		end,
		config = function()
			vim.g.matchup_matchparen_deferred = 1
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
		end,
	},
	{ "Bekaboo/dropbar.nvim" },
	{
		"ada0l/obsidian",
		keys = {
			{
				"<leader>ov",
				function()
					Obsidian.select_vault()
				end,
				desc = "Select Obsidian vault",
			},
			{
				"<leader>oo",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.cd_vault()
					end)
				end,
				desc = "Open Obsidian directory",
			},
			{
				"<leader>ot",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.open_today()
					end)
				end,
				desc = "Open today",
			},
			{
				"<leader>od",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write shift in days: " }, function(input_shift)
							local shift = tonumber(input_shift) * 60 * 60 * 24
							Obsidian.open_today(shift)
						end)
					end)
				end,
				desc = "Open daily node with shift",
			},
			{
				"<leader>on",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write name of new note: " }, function(name)
							Obsidian.new_note(name)
						end)
					end)
				end,
				desc = "New note",
			},
			{
				"<leader>oi",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_template("telescope")
					end)
				end,
				desc = "Insert template",
			},
			{
				"<leader>os",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.search_note("telescope")
					end)
				end,
				desc = "Search note",
			},
			{
				"<leader>ob",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_backlinks("telescope")
					end)
				end,
				desc = "Select backlink",
			},
			{
				"<leader>og",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.go_to()
					end)
				end,
				desc = "Go to file under cursor",
			},
			{
				"<leader>or",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Rename file to" }, function(name)
							Obsidian.rename(name)
						end)
					end)
				end,
				desc = "Rename file with updating links",
			},
			{
				"gf",
				function()
					if Obsidian.found_wikilink_under_cursor() ~= nil then
						return "<cmd>lua Obsidian.get_current_vault(function() Obsidian.go_to() end)<CR>"
					else
						return "gf"
					end
				end,
				noremap = false,
				expr = true,
			},
		},
		opts = function()
			---@param filename string
			---@return string
			local transformator = function(filename)
				if filename ~= nil and filename ~= "" then
					return filename
				end
				return string.format("%d", os.time())
			end
			return {
				vaults = {
					{
						dir = "~/Desktop/Obsidian/Knowledge",
						templates = {
							dir = "templates/",
							date = "%Y-%d-%m",
							time = "%Y-%d-%m",
						},
						note = {
							dir = "",
							transformator = transformator,
						},
					},
					{
						dir = "~/Desktop/Obsidian/SyncObsidian/",
						daily = {
							dir = "01.daily/",
							format = "%Y-%m-%d",
						},
						templates = {
							dir = "templates/",
							date = "%Y-%d-%m",
							time = "%Y-%d-%m",
						},
						note = {
							dir = "notes/",
							transformator = transformator,
						},
					},
				},
			}
		end,
	},
	{
		"echasnovski/mini.indentscope",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			symbol = "",
			options = { try_as_border = false },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"lazy",
					"mason",
					"notify",
					"Terminal",
					"toggleterm",
					"Outline",
					"Ptpython",
					"REPL",
					"ipython",
					"term",
					"Ipython",
					"iron",
					"Iron",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},

	{
		"stevearc/dressing.nvim",
	},
	{
		"ethanholz/nvim-lastplace",
		config = function()
			require("nvim-lastplace").setup({
				lastplace_ignore_buftype = {
					"toggleterm",
					"terminal",
					"quickfix",
					"help",
					"nofile",
					"Outline",
					"Neo-tree",
				},
				lastplace_ignore_filetype = {
					"gitcommit",
					"toggleterm",
					"gitrebase",
					"svn",
					"terminal",
					"neo-tree",
					"daptui",
				},
				lastplace_open_folds = true,
			})
		end,
	},

	{ "hinell/move.nvim" },
	{
		"wthollingsworth/pomodoro.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("pomodoro").setup({
				time_work = 30,
				time_break_short = 3,
				time_break_long = 10,
				timers_to_long_break = 5,
			})
		end,
		keys = {
			{
				"<leader>ps",
				"<CMD>PomodoroStart <CR>",
				desc = "pomodoro start",
			},
			{
				"<leader>pd",
				"<CMD> PomodoroStop <CR>",
				desc = "pomodoro stop",
			},
			{
				"<leader>po",
				"<CMD> PomodoroStatus <CR>",
				desc = "pomodoro status",
			},
		},
	},
	{
		"vidocqh/data-viewer.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"kkharji/sqlite.lua", -- Optional, sqlite support
		},
		config = function()
			require("data-viewer").setup({
				autoDisplayWhenOpenFile = false,
				maxLineEachTable = 100,
				columnColorEnable = true,
				columnColorRoulette = {
					"DataViewerColumn0",
					"DataViewerColumn1",
					"DataViewerColumn2",
				},
				view = {
					width = 0.8, -- Less than 1 means ratio to screen width
					height = 0.8, -- Less than 1 means ratio to screen height
					zindex = 50,
				},
				keymap = {
					next_table = "<C-l>",
					prev_table = "<C-h>",
				},
			})
		end,
		keys = { {
			"<leader>dv",
			"<CMD> DataViewer <CR>",
			desc = "View Data",
		} },
	},
	{
		"lewis6991/hover.nvim",
		config = function()
			require("hover").setup({
				init = function()
					-- Require providers
					require("hover.providers.lsp")
					-- require('hover.providers.gh')
					-- require('hover.providers.gh_user')
					-- require('hover.providers.jira')
					-- require('hover.providers.man')
					-- require('hover.providers.dictionary')
				end,
				preview_opts = {
					border = "single",
				},
				-- Whether the contents of a currently open hover window should be moved
				-- to a :h preview-window when pressing the hover keymap.
				preview_window = false,
				title = true,
			})
		end,
	},

	{
		"roobert/hoversplit.nvim",
		config = function()
			require("hoversplit").setup({
				key_bindings = {
					split = "<leader>hS",
					vsplit = "<leader>hV",
				},
			})
		end,
	},

	{
		"cshuaimin/ssr.nvim",
		-- Calling setup is optional.
		config = function()
			require("ssr").setup({
				border = "rounded",
				min_width = 50,
				min_height = 5,
				max_width = 120,
				max_height = 25,
				adjust_window = true,
				keymaps = {
					close = "q",
					next_match = "n",
					prev_match = "N",
					replace_confirm = "<cr>",
					replace_all = "<leader><cr>",
				},
			})
		end,
		keys = {
			{
				"<leader>sw",
				function()
					require("ssr").open()
				end,
				desc = "Search and Replace",
			},
		},
	},
	{
		"andrewferrier/wrapping.nvim",
		config = function()
			require("wrapping").setup()
		end,
	},
	{ import = "NvimPy.Extra.debug" },
})
