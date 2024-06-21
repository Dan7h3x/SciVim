return {
	{
		"Bekaboo/dropbar.nvim",
		event = "VeryLazy",
		config = function()
			local ver = vim.version()
			if ver.minor == "10" then
				local cfg = require("NvimPy.settings.winbar")
				require("dropbar").setup(cfg)
			end
		end,
	},
}
