--[[
-- Theme related plugins
--]]
--
--

return {

	{
		dir = "~/.config/nvim/lua/aye/",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function(_, opts)
			require("aye").load(opts)
		end,
	},
}
