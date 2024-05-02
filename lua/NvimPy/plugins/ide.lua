return {
    {
		"Bekaboo/dropbar.nvim",
		lazy = false,
		config = function()
			local ver = vim.version()
			if ver.minor == "10" then
				local cfg = require("NvimPy.settings.winbar")
				require("dropbar").setup(cfg)
			end
		end,
	},
}