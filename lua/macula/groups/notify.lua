local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- nvim-notify backgrounds
		NotifyBackground = { bg = colors.bg_alt },

		-- Error level
		NotifyERRORBorder = { fg = colors.color_9, bg = colors.bg_alt },
		NotifyERRORIcon = { fg = colors.color_9 },
		NotifyERRORTitle = { fg = colors.color_9, bold = true },
		NotifyERRORBody = { fg = colors.fg, bg = colors.bg_alt },

		-- Warning level
		NotifyWARNBorder = { fg = colors.color_8, bg = colors.bg_alt },
		NotifyWARNIcon = { fg = colors.color_8 },
		NotifyWARNTitle = { fg = colors.color_8, bold = true },
		NotifyWARNBody = { fg = colors.fg, bg = colors.bg_alt },

		-- Info level
		NotifyINFOBorder = { fg = colors.color_6, bg = colors.bg_alt },
		NotifyINFOIcon = { fg = colors.color_6 },
		NotifyINFOTitle = { fg = colors.color_6, bold = true },
		NotifyINFOBody = { fg = colors.fg, bg = colors.bg_alt },

		-- Debug level
		NotifyDEBUGBorder = { fg = colors.color_3, bg = colors.bg_alt },
		NotifyDEBUGIcon = { fg = colors.color_3 },
		NotifyDEBUGTitle = { fg = colors.color_3, bold = true },
		NotifyDEBUGBody = { fg = colors.fg, bg = colors.bg_alt },

		-- Trace level
		NotifyTRACEBorder = { fg = colors.color_11, bg = colors.bg_alt },
		NotifyTRACEIcon = { fg = colors.color_11 },
		NotifyTRACETitle = { fg = colors.color_11, bold = true },
		NotifyTRACEBody = { fg = colors.fg, bg = colors.bg_alt },

		-- Log levels
		NotifyLogTime = { fg = colors.color_3 },
		NotifyLogTitle = { fg = colors.color_11, bold = true },
	}
end

return M
