return {
	"Dan7h3x/signup.nvim",
	branch = "devel",
	event = "LspAttach", -- or "InsertEnter" if you only want it in insert normal_mode
	opts = {
		silent = false,
		number = false,
		icons = {
			parameter = "",
			method = "󰡱",
			documentation = "󱪙",
		},
		colors = {
			parameter = "#86e1fc",
			method = "#c099ff",
			documentation = "#4fd6be",
			default_value = "#a80888",
		},
		active_parameter_colors = {
			bg = "#86e1fc",
			fg = "#1a1a1a",
		},
		border = "solid",
		dock_border = "rounded",
		winblend = 10,
		auto_close = true,
		trigger_chars = { "(", "," },
		max_height = 10,
		max_width = 40,
		floating_window_above_cur_line = true,
		preview_parameters = true,
		debounce_time = 30,
		dock_toggle_key = "<Leader>sd",
		toggle_key = "<C-k>",
		dock_mode = {
			enabled = false,
			position = "right",
			height = 5,
			width = 10,
			padding = 4,
			auto_adjust = true,
		},
		render_style = {
			separator = true,
			compact = true,
			align_icons = true,
		},
	},
	config = function(_, opts)
		require("SciVim.signup").setup(opts)
	end,

	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- Optional, for better syntax highlighting
	},
}
