local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Dashboard (dashboard-nvim)
		DashboardShortCut = { fg = colors.color_5, bold = true },
		DashboardHeader = { fg = colors.color_11 },
		DashboardCenter = { fg = colors.color_7 },
		DashboardFooter = { fg = colors.color_3, italic = true },
		DashboardKey = { fg = colors.color_8 },
		DashboardDesc = { fg = colors.fg_alt },
		DashboardIcon = { fg = colors.color_6 },

		-- Alpha (alpha-nvim)
		AlphaShortcut = { fg = colors.color_5, bold = true },
		AlphaHeader = { fg = colors.color_11 },
		AlphaHeaderLabel = { fg = colors.color_11 },
		AlphaFooter = { fg = colors.color_3, italic = true },
		AlphaButtons = { fg = colors.color_7 },
	}
end

return M
