return {

	{ "nvim-telescope/telescope.nvim", event = "VeryLazy", dependencies = { "nvim-lua/plenary.nvim" } },
	{
		"benfowler/telescope-luasnip.nvim",
		event = "VeryLazy",
		config = function()
			require("telescope").load_extension("luasnip")
		end,
	},
}
