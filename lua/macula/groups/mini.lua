local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- mini.statusline
		MiniStatuslineDevinfo = { fg = colors.fg_alt, bg = colors.bg_alt },
		MiniStatuslineFileinfo = { fg = colors.fg_alt, bg = colors.bg_alt },
		MiniStatuslineFilename = { fg = colors.fg, bg = colors.bg_alt },
		MiniStatuslineInactive = { fg = colors.color_1, bg = colors.bg },
		MiniStatuslineModeCommand = { fg = colors.bg, bg = colors.color_8, bold = true },
		MiniStatuslineModeInsert = { fg = colors.bg, bg = colors.color_7, bold = true },
		MiniStatuslineModeNormal = { fg = colors.bg, bg = colors.color_5, bold = true },
		MiniStatuslineModeOther = { fg = colors.bg, bg = colors.color_6, bold = true },
		MiniStatuslineModeReplace = { fg = colors.bg, bg = colors.color_9, bold = true },
		MiniStatuslineModeVisual = { fg = colors.bg, bg = colors.color_11, bold = true },
		
		-- mini.tabline
		MiniTablineCurrent = { fg = colors.fg, bg = colors.color_3, bold = true },
		MiniTablineFill = { bg = colors.bg },
		MiniTablineHidden = { fg = colors.fg_alt, bg = colors.bg_alt },
		MiniTablineModifiedCurrent = { fg = colors.color_8, bg = colors.color_3, bold = true },
		MiniTablineModifiedHidden = { fg = colors.color_8, bg = colors.bg_alt },
		MiniTablineModifiedVisible = { fg = colors.color_8, bg = colors.bg_alt },
		MiniTablineTabpagesection = { fg = colors.bg, bg = colors.color_5, bold = true },
		MiniTablineVisible = { fg = colors.fg, bg = colors.bg_alt },
		
		-- mini.pick
		MiniPickBorder = { fg = colors.color_3, bg = colors.bg_alt },
		MiniPickBorderBusy = { fg = colors.color_8, bg = colors.bg_alt },
		MiniPickBorderText = { fg = colors.fg_alt, bg = colors.bg_alt },
		MiniPickIconDirectory = { fg = colors.color_5 },
		MiniPickIconFile = { fg = colors.fg },
		MiniPickHeader = { fg = colors.color_11, bold = true },
		MiniPickMatchCurrent = { bg = colors.color_2 },
		MiniPickMatchMarked = { fg = colors.color_8 },
		MiniPickMatchRanges = { fg = colors.color_11, bold = true },
		MiniPickNormal = { fg = colors.fg, bg = colors.bg_alt },
		MiniPickPreviewLine = { bg = colors.color_2 },
		MiniPickPreviewRegion = { bg = colors.color_3 },
		MiniPickPrompt = { fg = colors.color_5, bg = colors.bg_alt, bold = true },
		
		-- mini.files
		MiniFilesBorder = { fg = colors.color_3, bg = colors.bg_alt },
		MiniFilesBorderModified = { fg = colors.color_8, bg = colors.bg_alt },
		MiniFilesCursorLine = { bg = colors.color_2 },
		MiniFilesDirectory = { fg = colors.color_5 },
		MiniFilesFile = { fg = colors.fg },
		MiniFilesNormal = { fg = colors.fg, bg = colors.bg_alt },
		MiniFilesTitle = { fg = colors.bg, bg = colors.color_5, bold = true },
		MiniFilesTitleFocused = { fg = colors.bg, bg = colors.color_11, bold = true },
		
		-- mini.cursorword
		MiniCursorword = { underline = true },
		MiniCursorwordCurrent = { underline = true },
		
		-- mini.indentscope
		MiniIndentscopeSymbol = { fg = colors.color_3 },
		MiniIndentscopePrefix = { nocombine = true },
		
		-- mini.jump
		MiniJump = { fg = colors.bg, bg = colors.color_11, bold = true },
		
		-- mini.starter
		MiniStarterCurrent = { nocombine = true },
		MiniStarterFooter = { fg = colors.color_3, italic = true },
		MiniStarterHeader = { fg = colors.color_11, bold = true },
		MiniStarterInactive = { fg = colors.color_1 },
		MiniStarterItem = { fg = colors.fg },
		MiniStarterItemBullet = { fg = colors.color_3 },
		MiniStarterItemPrefix = { fg = colors.color_8 },
		MiniStarterSection = { fg = colors.color_5, bold = true },
		MiniStarterQuery = { fg = colors.color_7 },
	}
end

return M

