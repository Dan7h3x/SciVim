return {

	{ "nvim-telescope/telescope.nvim", lazy = true, dependencies = { "nvim-lua/plenary.nvim" } },
	{
		"benfowler/telescope-luasnip.nvim",
		lazy = true,
		config = function()
			require("telescope").load_extension("luasnip")
		end,
	},
}
