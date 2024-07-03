return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		event = "VeryLazy",
		opts = {},
		dependencies = {
			{ "MunifTanjim/nui.nvim", lazy = true },
			{
				"s1n7ax/nvim-window-picker",
				version = "2.*",
				event = "VeryLazy",
				config = function()
					require("window-picker").setup({
						filter_rules = {
							include_current_win = false,
							autoselect_one = true,
							-- filter using buffer options
							bo = {
								-- if the file type is one of following, the window will be ignored
								filetype = { "neo-tree", "neo-tree-popup", "notify" },
								-- if the buffer type is one of following, the window will be ignored
								buftype = { "terminal", "quickfix" },
							},
						},
					})
				end,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("BufEnter", {
				group = vim.api.nvim_create_augroup("NeOTree_Begin", { clear = true }),
				once = true,
				callback = function()
					if package.loaded["neo-tree"] then
						return
					else
						local stats = vim.uv.fs_stat(vim.fn.argv(0))
						if stats and stats.type == "directory" then
							require("neo-tree")
						end
					end
				end,
			})
		end,
		config = function()
			local config = require("NvimPy.settings.neotree")
			require("neo-tree").setup(config)
		end,
	}, -- File Explorer
	{ "mbbill/undotree", event = "VeryLazy" },
}
