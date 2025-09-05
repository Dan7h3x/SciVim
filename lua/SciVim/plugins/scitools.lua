return {
	{
		"anufrievroman/vim-angry-reviewer",
		-- dependencies = { 'anufrievroman/vim-tex-kawaii' },
		ft = { "typst", "markdown" },
		keys = { {
			"<localleader>a",
			"<Cmd>AngryReviewer<CR>",
			desc = "AngryReviewer",
		} },
		config = function()
			vim.g.AngryReviewerEnglish = "american"
		end,
	},
}
