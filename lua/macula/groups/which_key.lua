local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		WhichKey = { fg = colors.color_5, bold = true },
		WhichKeyGroup = { fg = colors.color_11 },
		WhichKeyDesc = { fg = colors.fg_alt },
		WhichKeySeparator = { fg = colors.color_3 },
		WhichKeyFloat = { bg = colors.bg_alt },
		WhichKeyBorder = { fg = colors.color_3, bg = colors.bg_alt },
		WhichKeyValue = { fg = colors.color_7 },
	}
end

return M

