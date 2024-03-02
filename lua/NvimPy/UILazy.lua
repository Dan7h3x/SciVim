return {
	{
		"stevearc/dressing.nvim",
		lazy = true,
		init = function()
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
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
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		keys = { -- Example mapping to toggle outline
			{ "<F10>", "<cmd>Outline<CR>", desc = "Toggle outline" },
		},
		config = function()
			local cfg = require("NvimPy.Configs.Symbols")
			require("outline").setup(cfg)
		end,
	},
}
