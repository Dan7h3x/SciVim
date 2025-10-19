local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Blink completion menu
		BlinkCmpMenu = { fg = colors.fg, bg = colors.bg },
		BlinkCmpMenuBorder = { fg = colors.color_3, bg = colors.bg },
		BlinkCmpMenuSelection = { bg = colors.color_2, bold = true },

		BlinkCmpDoc = { fg = colors.fg, bg = colors.bg_alt },
		BlinkCmpDocBorder = { fg = colors.color_3, bg = colors.bg_alt },
		BlinkCmpDocSeparator = { fg = colors.color_2, bg = colors.bg_alt },

		BlinkCmpSignatureHelp = { fg = colors.fg, bg = colors.bg_alt },
		BlinkCmpSignatureHelpBorder = { fg = colors.color_3, bg = colors.bg_alt },
		BlinkCmpSignatureHelpActiveParameter = { fg = colors.color_11, bold = true },

		-- Item kinds
		BlinkCmpKind = { fg = colors.fg },
		BlinkCmpKindVariable = { fg = colors.fg },
		BlinkCmpKindInterface = { fg = colors.color_11 },
		BlinkCmpKindText = { fg = colors.fg_alt },
		BlinkCmpKindFunction = { fg = colors.color_5 },
		BlinkCmpKindMethod = { fg = colors.color_5 },
		BlinkCmpKindKeyword = { fg = colors.color_4 },
		BlinkCmpKindProperty = { fg = colors.color_12 },
		BlinkCmpKindUnit = { fg = colors.color_10 },
		BlinkCmpKindField = { fg = colors.color_12 },
		BlinkCmpKindClass = { fg = colors.color_11 },
		BlinkCmpKindModule = { fg = colors.color_11 },
		BlinkCmpKindConstructor = { fg = colors.color_11 },
		BlinkCmpKindEnum = { fg = colors.color_11 },
		BlinkCmpKindEnumMember = { fg = colors.color_10 },
		BlinkCmpKindEvent = { fg = colors.color_8 },
		BlinkCmpKindOperator = { fg = colors.color_6 },
		BlinkCmpKindTypeParameter = { fg = colors.color_11 },
		BlinkCmpKindStruct = { fg = colors.color_11 },
		BlinkCmpKindFile = { fg = colors.fg_alt },
		BlinkCmpKindFolder = { fg = colors.color_5 },
		BlinkCmpKindConstant = { fg = colors.color_10 },
		BlinkCmpKindSnippet = { fg = colors.color_7 },
		BlinkCmpKindValue = { fg = colors.color_10 },
		BlinkCmpKindColor = { fg = colors.color_6 },
		BlinkCmpKindReference = { fg = colors.color_6 },

		-- Label highlights
		BlinkCmpLabel = { fg = colors.fg },
		BlinkCmpLabelDeprecated = { fg = colors.color_1, strikethrough = true },
		BlinkCmpLabelMatch = { fg = colors.color_11, bold = true },
		BlinkCmpLabelDetail = { fg = colors.color_3, italic = true },
		BlinkCmpLabelDescription = { fg = colors.color_3 },
	}
end

return M
