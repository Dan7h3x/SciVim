local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Bufferline backgrounds
		BufferLineFill = { bg = colors.bg },
		BufferLineBackground = { bg = "NONE" },

		-- Buffer (inactive)
		BufferLineBuffer = { fg = colors.fg, italic = true },
		BufferLineBufferVisible = { fg = colors.fg, italic = true },
		BufferLineBufferSelected = { fg = colors.color_6, bold = true, italic = false },

		-- Tab (active buffers)
		BufferLineTab = { fg = colors.fg_alt },
		BufferLineTabSelected = { fg = colors.color_11, bold = true },
		BufferLineTabSeparator = { fg = colors.bg },
		BufferLineTabSeparatorSelected = { fg = colors.bg },

		-- Close button
		BufferLineCloseButton = { fg = colors.color_1, bg = "NONE" },
		BufferLineCloseButtonVisible = { fg = colors.color_3, bg = "NONE" },
		BufferLineCloseButtonSelected = { fg = colors.color_9 },

		-- Modified indicator
		BufferLineModified = { fg = colors.color_7 },
		BufferLineModifiedVisible = { fg = colors.color_7 },
		BufferLineModifiedSelected = { fg = colors.color_7 },

		-- Separators
		-- BufferLineSeparator = { fg = colors.bg },
		-- BufferLineSeparatorVisible = { fg = colors.color_5 },
		-- BufferLineSeparatorSelected = { fg = colors.color_11 },
		--
		-- Indicators
		BufferLineIndicatorSelected = { fg = colors.color_5 },

		-- Pick mode
		BufferLinePick = { fg = colors.color_9, bold = true },
		BufferLinePickVisible = { fg = colors.color_9, bold = true },
		BufferLinePickSelected = { fg = colors.color_9, bold = true },

		-- Diagnostics
		BufferLineDiagnostic = { fg = colors.color_11 },
		BufferLineError = { fg = colors.color_9 },
		BufferLineErrorVisible = { fg = colors.color_9 },
		BufferLineErrorSelected = { fg = colors.color_9, bold = true },
		BufferLineErrorDiagnostic = { fg = colors.color_9 },
		BufferLineErrorDiagnosticVisible = { fg = colors.color_9 },
		BufferLineErrorDiagnosticSelected = { fg = colors.color_9, bold = true },

		BufferLineWarning = { fg = colors.color_8 },
		BufferLineWarningVisible = { fg = colors.color_8 },
		BufferLineWarningSelected = { fg = colors.color_8, bold = true },
		BufferLineWarningDiagnostic = { fg = colors.color_8 },
		BufferLineWarningDiagnosticVisible = { fg = colors.color_8 },
		BufferLineWarningDiagnosticSelected = { fg = colors.color_8, bold = true },

		BufferLineInfo = { fg = colors.color_6 },
		BufferLineInfoVisible = { fg = colors.color_6 },
		BufferLineInfoSelected = { fg = colors.color_6, bold = true },
		BufferLineInfoDiagnostic = { fg = colors.color_6 },
		BufferLineInfoDiagnosticVisible = { fg = colors.color_6 },
		BufferLineInfoDiagnosticSelected = { fg = colors.color_6, bold = true },

		BufferLineHint = { fg = colors.color_3 },
		BufferLineHintVisible = { fg = colors.color_3 },
		BufferLineHintSelected = { fg = colors.color_3, bold = true },
		BufferLineHintDiagnostic = { fg = colors.color_3 },
		BufferLineHintDiagnosticVisible = { fg = colors.color_3 },
		BufferLineHintDiagnosticSelected = { fg = colors.color_3, bold = true },

		-- Duplicate
		BufferLineDuplicate = { fg = colors.color_1, italic = true },
		BufferLineDuplicateVisible = { fg = colors.color_3, italic = true },
		BufferLineDuplicateSelected = { fg = colors.fg_alt, italic = true },

		-- Misc
		BufferLineNumbers = { fg = colors.fg },
		BufferLineNumbersVisible = { fg = colors.fg },
		BufferLineNumbersSelected = { fg = colors.color_11 },
		BufferLineMiniIconsGreen = { fg = colors.fg },
		BufferLineMiniIconsGreenSelected = { fg = colors.color_13 },
		BufferLineMiniIconsGreenVisible = { fg = colors.fg },
		BufferLineMiniIconsAzure = { fg = colors.fg },
		BufferLineMiniIconsAzureInactive = { fg = colors.fg },
		BufferLineMiniIconsAzureVisible = { fg = colors.fg },
		BufferLineMiniIconsAzureSelected = { fg = colors.color_13 },
	}
end

return M
