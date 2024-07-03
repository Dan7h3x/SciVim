return {

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
		"chrisgrieser/nvim-rip-substitute",
		event = "VeryLazy",
		keys = {
			{
				"<leader>fs",
				function()
					require("rip-substitute").sub()
				end,
				mode = { "n", "x" },
				desc = " rip substitute",
			},
		},
	},
	-- {
	-- 	"VonHeikemen/searchbox.nvim",
	-- 	event = "VeryLazy",
	-- 	dependencies = {
	-- 		{ "MunifTanjim/nui.nvim" },
	-- 	},
	-- 	keys = {
	-- 		{
	-- 			"<a-r>",
	-- 			function()
	-- 				require("searchbox").match_all({
	-- 					title = "Match All",
	-- 					clear_matches = false,
	-- 					default_value = "local",
	-- 				})
	-- 			end,
	-- 			desc = "Searchbox",
	-- 		},
	-- 		{
	-- 			"<a-e>",
	-- 			"<CMD>SearchBoxReplace confirm=menu<CR>",
	-- 			desc = "Searchbox Replace",
	-- 		},
	-- 	},
	-- },
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
		lazy = true,
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
	{ -- color previews & color picker
		"uga-rosa/ccc.nvim",
		event = "VeryLazy",
		keys = {
			{ "#", vim.cmd.CccPick, desc = " Color Picker" },
		},
		ft = { "css", "scss", "sh", "zsh", "lua" },
		config = function(spec)
			local ccc = require("ccc")

			ccc.setup({
				win_opts = { border = vim.g.borderStyle },
				highlight_mode = "background",
				highlighter = {
					auto_enable = true,
					filetypes = spec.ft, -- uses lazy.nvim's ft spec
					max_byte = 200 * 1024, -- 200kb
					update_insert = false,
				},
				pickers = {
					ccc.picker.hex_long, -- only long hex to not pick issue numbers like #123
					ccc.picker.css_rgb,
					ccc.picker.css_hsl,
					ccc.picker.css_name,
					ccc.picker.ansi_escape(),
				},
				alpha_show = "hide", -- needed when highlighter.lsp is set to true
				recognize = { output = true }, -- automatically recognize color format under cursor
				inputs = { ccc.input.hsl },
				outputs = {
					ccc.output.css_hsl,
					ccc.output.css_rgb,
					ccc.output.hex,
				},
				mappings = {
					["<Esc>"] = ccc.mapping.quit,
					["q"] = ccc.mapping.quit,
					["L"] = ccc.mapping.increase10,
					["H"] = ccc.mapping.decrease10,
					["o"] = ccc.mapping.cycle_output_mode, -- = change output format
				},
			})
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = { show_start = false, show_end = false },
			exclude = {
				filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
			},
		},
		main = "ibl",
	},
	{
		"rcarriga/nvim-notify",
		keys = {
			{
				"<leader>un",
				function()
					require("notify").dismiss({ silent = true, pending = true })
				end,
				desc = "Dismiss All Notifications",
			},
		},
		opts = {
			stages = "static",
			timeout = 3000,
			max_height = function()
				return math.floor(vim.o.lines * 0.75)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.75)
			end,
			on_open = function(win)
				vim.api.nvim_win_set_config(win, { zindex = 100 })
			end,
		},
		init = function()
			-- when noice is not enabled, install notify on VeryLazy
			if not require("NvimPy.utils.init").has("noice.nvim") then
				require("NvimPy.utils.init").on_very_lazy(function()
					vim.notify = require("notify")
				end)
			end
		end,
	},
}
