return {
	{
		"Dan7h3x/signup.nvim",
		branch = "main",
		opts = {
			silent = true,
			icons = {
				parameter = "",
				method = "󰡱",
				documentation = "󱪙",
				type = "󰌗",
				default = "󰁔",
			},
			colors = {
				parameter = "#86e1fc",
				method = "#c099ff",
				documentation = "#4fd6be",
				default_value = "#a80888",
				type = "#f6c177",
			},
			active_parameter = true, -- enable/disable active_parameter highlighting
			active_parameter_colors = {
				bg = "#86e1fc",
				fg = "#1a1a1a",
			},
			border = "rounded",
			dock_border = "rounded",
			winblend = 10,
			auto_close = true,
			trigger_chars = { "(", ",", ")" },
			max_height = 10,
			max_width = 40,
			floating_window_above_cur_line = true,
			debounce_time = 50,
			dock_toggle_key = "<Leader>sd",
			dock_mode = {
				enabled = false,
				position = "bottom", -- "bottom", "top", or "middle"
				height = 4, -- If > 1: fixed height in lines, if <= 1: percentage of window height (e.g., 0.3 = 30%)
				padding = 1, -- Padding from window edges
				side = "right", -- "right", "left", or "center"
				width_percentage = 40, -- Percentage of editor width (10-90%)
			},
		},
		config = function(_, opts)
			require("signup").setup(opts)
		end,
	},
}
