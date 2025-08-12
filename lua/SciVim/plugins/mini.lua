return {

	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {
			file = {
				[".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
				["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
			},
			filetype = {
				dotenv = { glyph = "", hl = "MiniIconsYellow" },
			},
		},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},
	{
		"echasnovski/mini.pairs",
		event = "VeryLazy",
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
	},
}
