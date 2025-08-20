return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons", "elanmed/fzf-lua-frecency.nvim" },
		init = function()
			require("SciVim.extras.fzf.maps").map()
		end,
		config = function()
			require("SciVim.extras.fzf.setup").setup()
			require("fzf-lua-frecency").setup()
			require("SciVim.extras.words")
		end,
	},
}
