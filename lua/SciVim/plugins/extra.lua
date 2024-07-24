return {
	{
		"mistricky/codesnap.nvim",
		build = "make",
		lazy = true,
		keys = {
			{ "<leader>Cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
			{ "<leader>Cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
		},
		opts = {
			save_path = "~/Pictures",
			has_breadcrumbs = true,
			bg_theme = "grape",
			has_line_number = true,
			bg_x_padding = 20,
			bg_y_padding = 20,
			watermark = "SciVim",
		},
	},
}
