return {
	{
		"Dan7h3x/LazyDo",
		branch = "dev",
		event = "VeryLazy",
		cmd = {
			"LazyDoToggle",
			"LazyDoAdd",
			"LazyDoSearch",
			"LazyDoFilter",
			"LazyDoSort",
		},
		keys = {
			{
				"<F2>",
				"<ESC><CMD>LazyDoToggle<CR>",
				desc = "LazyDoToggle panel",
				mode = { "n", "i" },
			},
		},
		config = function()
			require("lazydo").setup({
				theme = {
					border = "rounded",
					colors = {
						header = { fg = "#7aa2f7", bold = true },
						title = { fg = "#7dcfff", bold = true },
						task = {
							pending = { fg = "#a9b1d6" },
							done = { fg = "#565f89", italic = true },
							overdue = { fg = "#f7768e", bold = true },
						},
						priority = {
							high = "#f7768e",
							medium = "#e0af68",
							low = "#9ece6a",
						},
						notes = { fg = "#565f89", italic = true },
						due_date = { fg = "#bb9af7" },
						progress = {
							bar = {
								filled = { fg = "#7aa2f7" },
								empty = { fg = "#3b4261" },
								text = { fg = "#c0caf5" },
							},
							complete = { fg = "#9ece6a" },
							partial = { fg = "#e0af68" },
							none = { fg = "#f7768e" },
						},
						separator = { fg = "#3b4261" },
						help = { fg = "#c0caf5" },
					},
					progress_bar = {
						width = 15,
						filled = "█",
						empty = "░",
						style = "classic", -- can be "classic", "modern", or "minimal"
					},
					indent = {
						size = 4,
						marker = "│",
						connector = "├─",
						last_connector = "└─",
					},
				},
				keymaps = {
					toggle_status = "<CR>",
					delete_task = "d",
					edit_task = "e",
					add_note = "n",
					cycle_priority = "p",
					set_due_date = "D",
					add_subtask = "s",
					close = "q",
					help = "?",
					move_up = "K",
					move_down = "J",
					toggle_details = "<Tab>",
					quick_add = "a",
				},
				icons = {
					task_pending = "◯",
					task_done = "✓",
					priority = {
						low = "○",
						medium = "◐",
						high = "●",
					},
					note = "📝",
					due_date = "📅",
					progress = {
						none = "○",
						partial = "◐",
						complete = "●",
					},
				},
				date_format = "%Y-%m-%d",
				storage_path = "~/.config/nvim/", -- Uses default if not specified
			})
		end,
		dependencies = {
			"nvim-lua/plenary.nvim", -- Optional: for improved date handling
			"rcarriga/nvim-notify", -- Optional: for better notifications
		},
	},
}
