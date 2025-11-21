local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		FzfLuaNormal = { fg = colors.fg, bg = colors.bg },
		FzfLuaBorder = { fg = colors.color_3, bg = colors.bg },
		FzfLuaTitle = { fg = colors.bg, bg = colors.color_5, bold = true },
		FzfLuaPreviewNormal = { fg = colors.fg, bg = colors.bg },
		FzfLuaPreviewBorder = { fg = colors.color_3, bg = colors.bg },
		FzfLuaPreviewTitle = { fg = colors.bg, bg = colors.color_6, bold = true },
		FzfLuaCursor = { fg = colors.bg, bg = colors.fg },
		FzfLuaCursorLine = { bg = colors.color_2 },
		FzfLuaSearch = { fg = colors.color_11, bold = true },
		FzfLuaScrollBorderEmpty = { fg = colors.color_1 },
		FzfLuaScrollBorderFull = { fg = colors.color_3 },
		FzfLuaScrollFloatEmpty = { fg = colors.color_1 },
		FzfLuaScrollFloatFull = { fg = colors.color_3 },
		FzfLuaHeaderBind = { fg = colors.color_8 },
		FzfLuaHeaderText = { fg = colors.color_11 },
		FzfLuaPathColNr = { fg = colors.color_6 },
		FzfLuaPathLineNr = { fg = colors.color_5 },
		FzfLuaBufName = { fg = colors.color_5 },
		FzfLuaBufNr = { fg = colors.color_3 },
		FzfLuaBufFlagCur = { fg = colors.color_8, bold = true },
		FzfLuaBufFlagAlt = { fg = colors.color_6 },
		FzfLuaTabTitle = { fg = colors.color_11, bold = true },
		FzfLuaTabMarker = { fg = colors.color_5 },
		FzfLuaDirPart = { fg = colors.color_13 },
	}
end

return M
