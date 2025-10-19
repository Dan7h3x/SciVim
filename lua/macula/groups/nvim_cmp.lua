local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Completion menu
		CmpItemAbbrDeprecated = { fg = colors.color_1, strikethrough = true },
		CmpItemAbbrMatch = { fg = colors.color_11, bold = true },
		CmpItemAbbrMatchFuzzy = { fg = colors.color_11 },
		CmpItemKindDefault = { fg = colors.fg },
		CmpItemMenu = { fg = colors.color_3, italic = true },

		-- Kind highlights
		CmpItemKindVariable = { fg = colors.fg },
		CmpItemKindInterface = { fg = colors.color_11 },
		CmpItemKindText = { fg = colors.fg_alt },
		CmpItemKindFunction = { fg = colors.color_5 },
		CmpItemKindMethod = { fg = colors.color_5 },
		CmpItemKindKeyword = { fg = colors.color_4 },
		CmpItemKindProperty = { fg = colors.color_12 },
		CmpItemKindUnit = { fg = colors.color_10 },
		CmpItemKindField = { fg = colors.color_12 },
		CmpItemKindClass = { fg = colors.color_11 },
		CmpItemKindModule = { fg = colors.color_11 },
		CmpItemKindConstructor = { fg = colors.color_11 },
		CmpItemKindEnum = { fg = colors.color_11 },
		CmpItemKindEnumMember = { fg = colors.color_10 },
		CmpItemKindEvent = { fg = colors.color_8 },
		CmpItemKindOperator = { fg = colors.color_6 },
		CmpItemKindTypeParameter = { fg = colors.color_11 },
		CmpItemKindStruct = { fg = colors.color_11 },
		CmpItemKindFile = { fg = colors.fg_alt },
		CmpItemKindFolder = { fg = colors.color_5 },
		CmpItemKindConstant = { fg = colors.color_10 },
		CmpItemKindSnippet = { fg = colors.color_7 },
		CmpItemKindValue = { fg = colors.color_10 },
		CmpItemKindColor = { fg = colors.color_6 },
		CmpItemKindReference = { fg = colors.color_6 },
	}
end

return M
