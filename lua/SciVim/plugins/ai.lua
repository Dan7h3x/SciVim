return {
	{
		"Dan7h3x/chatter.nvim",
		branch = "devel",
		lazy = true,
		dependencies = {
			"ibhagwan/fzf-lua",
			lazy = true,
		},
		keys = { {
			"<leader>cc",
			"<Cmd>ChatterStart<CR>",
			desc = "Chatter Start",
		} },
		config = function()
			require("chatter").setup({})
		end,
	},
}
