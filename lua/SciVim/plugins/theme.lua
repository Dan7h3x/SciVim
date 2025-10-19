---@diagnostic disable: missing-fields
--[[
-- Theme related plugins
--]]
--
--

return {
	{
		dir = "~/.config/nvim/lua/aye/",
		lazy = true,
		enabled = false,
		priority = 1000,
		opts = {},
		config = function(_, opts)
			require("aye").load(opts)
		end,
	},
	{
		dir = "~/.config/nvim/lua/macula",
		name = "macula",
		lazy = false,
		keys = {
			{
				"<leader>m",
				"<CMD>MaculaSelect<CR>",
				mode = { "n" },
				desc = "Select Macula Pallete",
			},
		},
		priority = 1000,
		config = function()
			-- Setup Macula
			local macula = require("macula")
			macula.setup({
				-- Choose your favorite palette
				palette = "twilight",

				-- Enable transparent background
				transparent = false,

				-- Enable terminal colors
				terminal_colors = true,

				-- Plugin integrations (toggle as needed)
				integrations = {
					telescope = true,
					nvim_dap_ui = true,
					trouble = true,
					fzf_lua = true,
					nvim_cmp = true,
					blink_cmp = true,
					lualine = true,
					treesitter = true,
					lsp = true,
					gitsigns = true,
					nvim_tree = true,
					neo_tree = true,
					which_key = true,
					indent_blankline = true,
					mini = true,
					dashboard = true,
					lazy = true,
					mason = true,
					aerial = false,
				},
			})
		end,
	},
}
