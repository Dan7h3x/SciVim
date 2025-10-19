local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Hop motion plugin
		HopNextKey = { fg = colors.color_9, bold = true },
		HopNextKey1 = { fg = colors.color_11, bold = true },
		HopNextKey2 = { fg = colors.color_6 },
		HopUnmatched = { fg = colors.color_1 },
		HopCursor = { fg = colors.bg, bg = colors.fg },
		HopPreview = { fg = colors.color_8 },
	}
end

return M

