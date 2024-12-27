return {
	{
		-- "Dan7h3x/LazyDo",
		-- branch = "dev",
		dir = "~/.config/nvim/lua/lazydo/",
		event = "VeryLazy",
		cmd = {
			"LazyDoToggle",
		},
		keys = {
			{
				"<F2>",
				"<ESC><CMD>LazyDoToggle<CR>",
				desc = "LazyDoToggle panel",
				mode = { "n", "i" },
			},
		},
		opts = {
			layout = {
				width = 0.5,
				metadata_position = "right",
			},
		},
		config = function(_, opts)
			require("lazydo").setup(opts)
		end,
	},
}
