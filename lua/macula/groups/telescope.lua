local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		TelescopeBorder = { fg = colors.color_3, bg = colors.bg_alt },
		TelescopePromptBorder = { fg = colors.color_5, bg = colors.bg_alt },
		TelescopeResultsBorder = { fg = colors.color_3, bg = colors.bg_alt },
		TelescopePreviewBorder = { fg = colors.color_3, bg = colors.bg_alt },

		TelescopePromptNormal = { fg = colors.fg, bg = colors.bg_alt },
		TelescopeResultsNormal = { fg = colors.fg, bg = colors.bg_alt },
		TelescopePreviewNormal = { fg = colors.fg, bg = colors.bg_alt },

		TelescopePromptTitle = { fg = colors.bg, bg = colors.color_5, bold = true },
		TelescopeResultsTitle = { fg = colors.bg, bg = colors.color_6, bold = true },
		TelescopePreviewTitle = { fg = colors.bg, bg = colors.color_7, bold = true },

		TelescopeSelection = { fg = colors.fg, bg = colors.color_2, bold = true },
		TelescopeSelectionCaret = { fg = colors.color_5, bg = colors.color_2, bold = true },
		TelescopeMultiSelection = { fg = colors.color_8, bg = colors.color_2 },

		TelescopeMatching = { fg = colors.color_11, bold = true },

		TelescopePromptPrefix = { fg = colors.color_5, bold = true },
		TelescopePromptCounter = { fg = colors.color_3 },
	}
end

return M
