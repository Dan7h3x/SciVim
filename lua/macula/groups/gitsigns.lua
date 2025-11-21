local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		GitSignsAdd = { fg = colors.color_7 },
		GitSignsChange = { fg = colors.color_8 },
		GitSignsDelete = { fg = colors.color_9 },
		GitSignsAddNr = { fg = colors.color_7 },
		GitSignsChangeNr = { fg = colors.color_8 },
		GitSignsDeleteNr = { fg = colors.color_9 },
		GitSignsAddLn = { fg = colors.color_7, bg = colors.bg_alt },
		GitSignsChangeLn = { fg = colors.color_8, bg = colors.bg_alt },
		GitSignsDeleteLn = { fg = colors.color_9, bg = colors.bg_alt },
		GitSignsCurrentLineBlame = { fg = colors.color_1, italic = true },
	}
end

return M
