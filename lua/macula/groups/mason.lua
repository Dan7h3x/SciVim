local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Mason UI
		MasonNormal = { fg = colors.fg, bg = colors.bg_alt },
		MasonHeader = { fg = colors.bg, bg = colors.color_5, bold = true },
		MasonHeaderSecondary = { fg = colors.bg, bg = colors.color_11, bold = true },
		MasonHighlight = { fg = colors.color_11 },
		MasonHighlightBlock = { fg = colors.bg, bg = colors.color_11 },
		MasonHighlightBlockBold = { fg = colors.bg, bg = colors.color_11, bold = true },
		MasonHighlightSecondary = { fg = colors.color_5 },
		MasonHighlightBlockSecondary = { fg = colors.bg, bg = colors.color_5 },
		MasonHighlightBlockBoldSecondary = { fg = colors.bg, bg = colors.color_5, bold = true },

		-- Links and references
		MasonLink = { fg = colors.color_6, underline = true },
		MasonMuted = { fg = colors.color_1 },
		MasonMutedBlock = { fg = colors.color_1, bg = colors.bg_alt },
		MasonMutedBlockBold = { fg = colors.color_1, bg = colors.bg_alt, bold = true },

		-- Status indicators
		MasonError = { fg = colors.color_9 },
		MasonWarning = { fg = colors.color_8 },
		MasonHeading = { fg = colors.color_11, bold = true },
	}
end

return M
