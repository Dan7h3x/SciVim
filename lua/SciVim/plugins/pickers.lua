return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		init = function()
			require("SciVim.extras.fzf.maps").map()
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "fzf-lua" } })
				require("fzf-lua").register_ui_select(opts.ui_select or nil)
				return vim.ui.select(...)
			end
		end,
		config = function()
			require("SciVim.extras.fzf.setup").setup()
		end,
	},
}
