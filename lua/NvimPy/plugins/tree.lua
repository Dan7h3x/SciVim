return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		event = "VeryLazy",
		opts = {},
		dependencies = {
			{ "MunifTanjim/nui.nvim", lazy = true },
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
