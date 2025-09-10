return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		init = function()
			require("SciVim.extras.fzf.maps").map()
		end,
		config = function()
			require("SciVim.extras.fzf.setup").setup()
		end,
	},
}
