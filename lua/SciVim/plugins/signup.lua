return {
	{
		dir = "~/.config/nvim/lua/signup/",
		-- "Dan7h3x/signup.nvim",
		-- branch = "main",
		enabled = true,
		event = "LspAttach",
		opts = {
			dock_mode = {
				enabled = false,
				position = "middle",
				height = 4,
				padding = 1,
				width_percentage = 25,
			},
		},
		config = function(_, opts)
			require("signup").setup(opts)
		end,
	},
}
