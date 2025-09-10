local config = {
	options = {
		icons_enabled = true,
		theme = require("aye").lualine_theme,
		component_separators = { left = "|", right = "|" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			"alpha",
			"dashboard",
			"Chatter",
			"starter",
			"cmp_menu",
			"neo-tree",
			"notifs",
			"mason",
			"Outline",
			"terminal",
			"lazy",
			"lazydo",
			"undotree",
			"Telescope",
			"fzf",
			"dapui*",
			"dapui_scopes",
			"dapui_watches",
			"dapui_console",
			"dapui_breakpoints",
			"dapui_stacks",
			"dap-repl",
			"gitsigns-blame",
			"neaterm",
			"REPL",
			"repl",
			"Iron",
			"Ipython",
			"ipython*",
			"diff",
			"qf",
			"spectre_panel",
			"snacks_dashboard",
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
		lualine_b = { "filename", "branch" },
		lualine_c = {},
		lualine_x = {},
		lualine_y = { "encoding", "fileformat", "filetype", "progress" },
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
local Theme = require("aye").get_colors()
local Icons = require("SciVim.extras.icons")
local Tools = require("SciVim.extras.lualine_tools")
local function ins_left(component)
	table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
	table.insert(config.sections.lualine_x, component)
end

ins_left({
	function()
		return require("dap").status()
	end,
	cond = function()
		return package.loaded["dap"] and require("dap").status() ~= ""
	end,
	icon = { "", color = { fg = Theme.green } },
	color = { fg = Theme.string },
	padding = 1,
})
ins_left({
	Tools.lsp_servers_new,
	icon = { " ", color = { fg = Theme.special } },
	color = { fg = Theme.purple, gui = "bold" },
	padding = 1,
})
ins_left({
	"diagnostics",
	sources = { "nvim_lsp" },
	symbols = {
		error = Icons.diagnostics.Error,
		warn = Icons.diagnostics.Warn,
		info = Icons.diagnostics.Info,
		hint = Icons.diagnostics.Hint,
	},
	diagnostics_color = {
		error = { fg = Theme.error },
		warn = { fg = Theme.warn },
		info = { fg = Theme.info },
		hint = { fg = Theme.hint },
	},
	padding = { left = 1, right = 0 },
})

ins_left({
	"diff",
	symbols = {
		added = Icons.git.LineAdded,
		modified = Icons.git.LineModified,
		removed = Icons.git.LineRemoved,
	},
	source = function()
		local git = vim.b.gitsigns_status_dict
		if git then
			return {
				added = git.added,
				modified = git.changed,
				removed = git.removed,
			}
		end
	end,
})
ins_left({
	"diagnostics-message",
	padding = 1,
})
ins_right({
	function()
		return require("lazydo").get_lualine_stats()
	end,
	cond = function()
		return require("lazydo")._initialized -- Only show if LazyDo is initialized
	end,
})

ins_right({
	require("lazy.status").updates,
	cond = require("lazy.status").has_updates,
	color = { fg = Theme.orange },
	padding = 1,
})

return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
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
