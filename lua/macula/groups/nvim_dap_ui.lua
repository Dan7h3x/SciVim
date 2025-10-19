local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- DAP UI Windows
		DapUIVariable = { fg = colors.fg },
		DapUIScope = { fg = colors.color_11, bold = true },
		DapUIType = { fg = colors.color_11 },
		DapUIValue = { fg = colors.color_10 },
		DapUIModifiedValue = { fg = colors.color_11, bold = true },
		DapUIDecoration = { fg = colors.color_3 },
		DapUIThread = { fg = colors.color_5, bold = true },
		DapUIStoppedThread = { fg = colors.color_11 },
		DapUIFrameName = { fg = colors.fg },
		DapUISource = { fg = colors.color_6 },
		DapUILineNumber = { fg = colors.color_11 },
		DapUIFloatBorder = { fg = colors.color_3, bg = colors.bg_alt },
		DapUIWatchesEmpty = { fg = colors.color_9 },
		DapUIWatchesValue = { fg = colors.color_7 },
		DapUIWatchesError = { fg = colors.color_9 },
		DapUIBreakpointsPath = { fg = colors.color_6 },
		DapUIBreakpointsInfo = { fg = colors.color_7 },
		DapUIBreakpointsCurrentLine = { fg = colors.color_7, bold = true },
		DapUIBreakpointsLine = { fg = colors.color_11 },
		DapUIBreakpointsDisabledLine = { fg = colors.color_1 },
		
		-- DAP UI Controls
		DapUIPlayPause = { fg = colors.color_7 },
		DapUIRestart = { fg = colors.color_8 },
		DapUIStop = { fg = colors.color_9 },
		DapUIUnavailable = { fg = colors.color_1 },
		DapUIStepOver = { fg = colors.color_6 },
		DapUIStepInto = { fg = colors.color_6 },
		DapUIStepBack = { fg = colors.color_6 },
		DapUIStepOut = { fg = colors.color_6 },
		
		-- DAP UI Special
		DapUIWinSelect = { fg = colors.color_11, bold = true },
		DapUIEndofBuffer = { fg = colors.bg },
		DapUINormal = { fg = colors.fg, bg = colors.bg_alt },
		DapUINormalNC = { fg = colors.fg, bg = colors.bg_alt },
		
		-- DAP Core (for breakpoints in code)
		DapBreakpoint = { fg = colors.color_9 },
		DapBreakpointCondition = { fg = colors.color_8 },
		DapLogPoint = { fg = colors.color_6 },
		DapStopped = { fg = colors.color_7 },
	}
end

return M

