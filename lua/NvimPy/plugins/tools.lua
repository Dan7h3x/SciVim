return {
	{
		"ethanholz/nvim-lastplace",
		event = "VeryLazy",
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

	{ "hinell/move.nvim", event = "VeryLazy" },
	{
		"cshuaimin/ssr.nvim",
		event = "VeryLazy",
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
				"<leader>sr",
				function()
					require("ssr").open()
				end,
				desc = "Search and Replace",
			},
		},
	},
	{
		"VonHeikemen/searchbox.nvim",
		event = "VeryLazy",
		dependencies = {
			{ "MunifTanjim/nui.nvim" },
		},
		keys = {
			{
				"<a-r>",
				function()
					require("searchbox").match_all({
						title = "Match All",
						clear_matches = false,
						default_value = "I want to search this",
					})
				end,
				desc = "Searchbox",
			},
			{
				"<a-e>",
				"<CMD>SearchBoxReplace confirm=menu<CR>",
				desc = "Searchbox Replace",
			},
		},
	},
	{
		"andrewferrier/wrapping.nvim",
		event = "VeryLazy",
		config = function()
			require("wrapping").setup({
				auto_set_mode_filetype_allowlist = {
					"latex",
					"tex",
					"rst",
					"typst",
					"gitcommit",
					"text",
					"markdown",
				},
				auto_set_mode_heuristically = true,
				notify_on_switch = true,
			})
		end,
	},
	{
		"hedyhli/outline.nvim",
		event = "VeryLazy",
		cmd = { "Outline", "OutlineOpen" },
		keys = { -- Example mapping to toggle outline
			{ "<F10>", "<cmd>Outline<CR>", desc = "Toggle outline" },
		},
		config = function()
			local cfg = require("NvimPy.settings.outline")
			require("outline").setup(cfg)
		end,
	},
	{
		"wthollingsworth/pomodoro.nvim",
		event = "VeryLazy",
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
			{ "<leader>ps", "<CMD>PomodoroStart <CR>", desc = "pomodoro start" },
			{ "<leader>pd", "<CMD> PomodoroStop <CR>", desc = "pomodoro stop" },
			{
				"<leader>po",
				"<CMD> PomodoroStatus <CR>",
				desc = "pomodoro status",
			},
		},
	},
	{ "jbyuki/venn.nvim", event = "VeryLazy", lazy = false },
	{
		"ellisonleao/glow.nvim",
		event = "VeryLazy",
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
	{
		"2kabhishek/termim.nvim",
		event = "VeryLazy",
		cmd = { "Fterm", "FTerm", "Sterm", "STerm", "Vterm", "VTerm" },
	}, -- Commenting tools
	{
		"altermo/ultimate-autopair.nvim",
		lazy = false,
		event = { "VeryLazy", "InsertEnter", "CmdlineEnter" },
		branch = "v0.6", -- recomended as each new version will have breaking changes
		opts = {
			-- Config goes here
		},
	},
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{ "vidocqh/auto-indent.nvim", event = "VeryLazy", opts = {} },

	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		config = function()
			require("neoscroll").setup()
		end,
	},
	{
		"NvChad/nvim-colorizer.lua",
		event = "VeryLazy",
		config = function()
			require("colorizer").setup({
				filetypes = { "*" },
				user_default_options = {
					RGB = true, -- #RGB hex codes
					RRGGBB = true, -- #RRGGBB hex codes
					names = true, -- "Name" codes like Blue or blue
					RRGGBBAA = false, -- #RRGGBBAA hex codes
					AARRGGBB = false, -- 0xAARRGGBB hex codes
					rgb_fn = false, -- CSS rgb() and rgba() functions
					hsl_fn = false, -- CSS hsl() and hsla() functions
					css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
					css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn
					-- Available modes for `mode`: foreground, background,  virtualtext
					mode = "background", -- Set the display mode.
					-- Available methods are false / true / "normal" / "lsp" / "both"
					-- True is same as normal
					tailwind = false, -- Enable tailwind colors
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
	},
}
