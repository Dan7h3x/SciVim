local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Noice UI
		NoicePopup = { fg = colors.fg, bg = colors.bg_alt },
		NoicePopupBorder = { fg = colors.color_3, bg = colors.bg_alt },
		NoicePopupmenu = { fg = colors.fg, bg = colors.bg_alt },
		NoicePopupmenuBorder = { fg = colors.color_3, bg = colors.bg_alt },
		NoicePopupmenuSelected = { fg = colors.bg, bg = colors.color_5, bold = true },
		NoicePopupmenuMatch = { fg = colors.color_11, bold = true },
		
		-- Command line
		NoiceCmdline = { fg = colors.fg, bg = colors.bg_alt },
		NoiceCmdlinePopup = { fg = colors.fg, bg = colors.bg_alt },
		NoiceCmdlinePopupBorder = { fg = colors.color_3, bg = colors.bg_alt },
		NoiceCmdlineIcon = { fg = colors.color_5 },
		NoiceCmdlineIconSearch = { fg = colors.color_8 },
		
		-- Confirm dialogs
		NoiceConfirm = { fg = colors.fg, bg = colors.bg_alt },
		NoiceConfirmBorder = { fg = colors.color_3, bg = colors.bg_alt },
		
		-- Cursor
		NoiceCursor = { fg = colors.bg, bg = colors.fg },
		
		-- Format
		NoiceFormatProgressDone = { fg = colors.bg, bg = colors.color_7 },
		NoiceFormatProgressTodo = { fg = colors.fg_alt, bg = colors.bg_alt },
		
		-- LSP
		NoiceLspProgressClient = { fg = colors.color_11 },
		NoiceLspProgressSpinner = { fg = colors.color_5 },
		NoiceLspProgressTitle = { fg = colors.fg_alt },
		
		-- Mini
		NoiceMini = { fg = colors.fg, bg = colors.bg_alt },
		
		-- Scrollbar
		NoiceScrollbar = { fg = colors.color_3, bg = colors.bg_alt },
		NoiceScrollbarThumb = { bg = colors.color_5 },
		
		-- Split
		NoiceSplit = { fg = colors.fg, bg = colors.bg },
		NoiceSplitBorder = { fg = colors.color_3 },
		
		-- Virtual text
		NoiceVirtualText = { fg = colors.color_3 },
	}
end

return M

