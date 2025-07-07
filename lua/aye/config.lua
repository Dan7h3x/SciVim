local M = {}

M.defaults = {
	-- Style configurations
	styles = {
		comments = { italic = true },
		keywords = { italic = false, bold = true },
		functions = { bold = false },
		variables = {},
		strings = { italic = false },
		types = { italic = false, bold = true },
	},
	-- Plugin specific configurations
	plugins = {
		cmp = true,
		treesitter = true,
		indentline = true,
		telescope = true,
		fzf_lua = true,
		gitsigns = true,
		indent_blankline = true,
		nvim_tree = true,
		neotree = true,
		lualine = false,
		bufferline = true,
		alpha = true,
		which_key = true,
		notify = true,
		dap = true,
		navic = true,
		noice = true,
		mini = true,
	},
}

function M.extend(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
