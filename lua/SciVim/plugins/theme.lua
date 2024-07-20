--[[
-- Theme related plugins
--]]
--
return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "moon",
		},
		config = function()
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
}
