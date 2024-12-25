return {
	{
		"Dan7h3x/LazyDo",
		branch = "dev",
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
		opts = {},
		config = function(_, opts)
			require("lazydo").setup(opts)
		end,
	},
}
