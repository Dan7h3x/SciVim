local M = {}

M.default_opts = {
	style = "dark",
	behavior = "manual",
	integrations = {
		gitsign = true,
	},
}

function M.setup(opts)
	opts = M.default_opts.extend(vim.tbl_deep_extend("force", M.default_opts, opts or {}))
	local theme = require("macula.themes").get_colors(opts.style)
	local groups = require("macula.groups")
	groups.apply(opts.behavior, opts.integrations)
end

return M
