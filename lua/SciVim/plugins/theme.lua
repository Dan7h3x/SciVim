--[[
-- Theme related plugins
--]]
--
--

return {
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {
			style = "moon",
			transparent = false,
		},
	},
	{
		"yorik1984/newpaper.nvim",
		lazy = true,
		style = "light",
		priority = 1000,
		config = true,
	},
}
