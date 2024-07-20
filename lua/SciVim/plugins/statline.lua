local config = {
	options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			"alpha",
			"dashboard",
			"starter",
			"cmp_menu",
			"neo-tree",
			"Outline",
			"terminal",
			"lazy",
			"undotree",
			"Telescope",
			"dapui*",
			"dapui_scopes",
			"dapui_watches",
			"dapui_console",
			"dapui_breakpoints",
			"dapui_stacks",
			"dap-repl",
			"term",
			"zsh*",
			"bash",
			"shell",
			"terminal",
			"toggleterm",
			"termim",
			"REPL",
			"repl",
			"Iron",
			"Ipython",
			"ipython*",
			"diff",
			"qf",
			"spectre_panel",
			"Trouble",
			"help",
			"hoversplit",
			"which_key",
		},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = vim.o.laststatus == 3,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
}
local Theme = require("SciVim.extras.theme")
local Icons = require("SciVim.extras.icons")
local function ins_left(component)
	table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
	table.insert(config.sections.lualine_x, component)
end

ins_left({
	function()
		return require("pomodoro").statusline()
	end,
	cond = function()
		local pomstat = require("pomodoro").statusline()
		return not string.find(pomstat, "inactive")
	end,
	color = { fg = Theme.blue, gui = "bold" },
	padding = 1,
})
ins_left({
	function()
		return require("dap").status()
	end,
	cond = function()
		return package.loaded["dap"] and require("dap").status() ~= ""
	end,
	icon = { "", color = { fg = Theme.teal } },
	color = { fg = Theme.teal },
	padding = 1,
})
ins_left({
	function()
		local msg = "Off "
		local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
		local clients = vim.lsp.get_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				return client.name
			end
		end
		return msg
	end,
	icon = { " ", color = { fg = Theme.cyan } },
	color = { fg = Theme.magenta, gui = "bold" },
	padding = -1,
})
ins_left({
	"diagnostics",
	sources = { "nvim_diagnostic" },
	symbols = {
		error = Icons.diagnostics.Error,
		warn = Icons.diagnostics.Warn,
		info = Icons.diagnostics.Info,
	},
	diagnostics_color = {
		color_error = { fg = Theme.red },
		color_warn = { fg = Theme.yellow },
		color_info = { fg = Theme.blue },
	},
	padding = { left = 1, right = 0 },
})

ins_right({
	require("lazy.status").updates,
	cond = require("lazy.status").has_updates,
	color = { fg = Theme.orange },
	padding = 1,
})

ins_right({
	function()
		return os.date("%R:%S")
	end,
	color = { fg = Theme.blue },
	icon = { "", color = { fg = Theme.magenta } },
	padding = 1,
})

return {
	{
		"nvim-lualine/lualine.nvim",
		-- event = "VeryLazy",
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
		init = function()
			vim.g.lualine_laststatus = vim.o.laststatus
			if vim.fn.argc(-1) > 0 then
				vim.o.statusline = " "
			else
				vim.o.laststatus = 0
			end
		end,
		config = function()
			vim.o.laststatus = vim.g.lualine_laststatus
			require("lualine").setup(config)
		end,
	},
}
