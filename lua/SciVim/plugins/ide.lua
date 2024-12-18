return {
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
		keys = {
			{
				"<leader>pb",
				function()
					require("dropbar.api").pick()
				end,
				desc = "Dropbar select",
			},
		},
		config = function()
			local ver = vim.version()
			if ver.minor == "10" then
				local cfg = require("SciVim.extras.winbar")
				require("dropbar").setup(cfg)
			end
		end,
	},
	{
		"rcarriga/nvim-notify",
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
		keys = {
			{
				"<leader>un",
				function()
					require("notify").dismiss({ silent = true, pending = true })
				end,
				desc = "Dismiss All Notifications",
			},
		},
		opts = {
			stages = "static",
			timeout = 3000,
			max_height = function()
				return math.floor(vim.o.lines * 0.55)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.55)
			end,
			on_open = function(win)
				vim.api.nvim_win_set_config(win, { zindex = 100 })
			end,
		},
		init = function()
			-- when noice is not enabled, install notify on VeryLazy
			if not require("SciVim.utils").has("notify") then
				require("SciVim.utils").on_very_lazy(function()
					vim.notify = require("notify")
				end)
			end
		end,
	},
}
