require("nvterm").setup({
	terminals = {
		shell = vim.o.shell,
		list = {},
		type_opts = {
			float = {
				relative = "editor",
				row = 1.0,
				col = 1.0,
				width = 0.5,
				height = 0.5,
				border = "rounded",
			},
			horizontal = { location = "rightbelow", split_ratio = 0.33 },
			vertical = { location = "rightbelow", split_ratio = 0.4 },
		},
	},
	behavior = {
		autoclose_on_quit = {
			enabled = true,
			confirm = true,
		},
		close_on_exit = true,
		auto_insert = true,
	},
})
