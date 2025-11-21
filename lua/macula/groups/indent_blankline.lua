local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		IblIndent = { fg = colors.color_1 },
		IblWhitespace = { fg = colors.color_1 },
		IblScope = { fg = colors.color_3 },
		
		-- Rainbow delimiters (often used with indent-blankline)
		RainbowDelimiterRed = { fg = colors.color_9 },
		RainbowDelimiterYellow = { fg = colors.color_8 },
		RainbowDelimiterBlue = { fg = colors.color_5 },
		RainbowDelimiterOrange = { fg = colors.color_10 },
		RainbowDelimiterGreen = { fg = colors.color_7 },
		RainbowDelimiterViolet = { fg = colors.color_11 },
		RainbowDelimiterCyan = { fg = colors.color_6 },
	}
end

return M

