return {
	{
		"Dan7h3x/signup.nvim",
		branch = "devel",
		event = "LspAttach", -- or "InsertEnter" if you only want it in insert normal_mode
		opts = {
			-- UI configuration
			ui = {
				border = "rounded", -- Border style: 'single', 'double', 'rounded', 'solid'
				max_width = 80, -- Maximum width of signature window
				max_height = 5, -- Maximum height of signature window
				min_width = 40, -- Minimum width of signature window
				padding = 1, -- Padding inside the window
				spacing = 1, -- Spacing between signature elements
				opacity = 0.9, -- Window opacity (1.0 is fully opaque)
				zindex = 50, -- Z-index of the window
			},

			-- Colors and highlights
			colors = {
				background = nil, -- Background color (nil = default)
				border = nil, -- Border color
				parameter = "#86e1fc", -- Active parameter color
				text = nil, -- Text color
				type = "#c099ff", -- Type signature color
				method = "#4fd6be", -- Method name color
				documentation = "#4fd6be", -- Documentation color
				default_value = "#a8a8a8", -- Default value color
			},
			-- Active parameter highlighting
			active_parameter_colors = {
				fg = "#1a1a1a", -- Active parameter foreground color
				bg = "#86e1fc", -- Active parameter background color
			},

			-- Icons and formatting
			icons = {
				parameter = "󰘍 ", -- Icon for parameters
				method = "󰡱 ", -- Icon for method names
				separator = " → ", -- Separator between elements
			},

			-- Behavior settings
			behavior = {
				auto_trigger = true, -- Auto trigger on typing
				trigger_chars = { "(", "," }, -- Characters that trigger signature
				close_on_done = true, -- Close window when done typing
				dock_mode = false, -- Enable dock mode
				dock_position = "bottom", -- 'top', 'bottom', 'right'
				debounce = 50, -- Debounce time in ms
				prefer_active = true, -- Prefer showing active signature
			},

			-- Performance settings
			performance = {
				cache_size = 10, -- Size of signature cache
				throttle = 30, -- Throttle time in ms
				gc_interval = 60 * 60, -- Garbage collection interval in seconds
			},

			-- Keymaps
			keymaps = {
				toggle = "<C-k>", -- Toggle signature window
				next_signature = "<C-j>", -- Next signature
				prev_signature = "<C-h>", -- Previous signature
				next_parameter = "<C-l>", -- Next parameter
				prev_parameter = "<C-h>", -- Previous parameter
				toggle_dock = "<Leader>sd", -- Toggle dock mode
			},
		},
		config = function(_, opts)
			require("signup").setup(opts)
		end,

		dependencies = {
			-- "nvim-treesitter/nvim-treesitter", -- Optional, for better syntax highlighting
		},
	},
}
