local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		NeoTreeNormal = { fg = colors.fg, bg = colors.bg },
		NeoTreeNormalNC = { fg = colors.fg, bg = colors.bg },
		NeoTreeRootName = { fg = colors.color_11, bold = true },
		NeoTreeFileName = { fg = colors.fg },
		NeoTreeFileNameOpened = { fg = colors.color_11 },
		NeoTreeDimText = { fg = colors.color_1 },
		NeoTreeFilterTerm = { fg = colors.color_11, bold = true },
		NeoTreeIndentMarker = { fg = colors.color_2 },
		NeoTreeExpander = { fg = colors.color_3 },
		NeoTreeDirectoryIcon = { fg = colors.color_5 },
		NeoTreeDirectoryName = { fg = colors.color_5 },
		NeoTreeSymbolicLinkTarget = { fg = colors.color_6 },
		NeoTreeGitAdded = { fg = colors.color_7 },
		NeoTreeGitConflict = { fg = colors.color_9 },
		NeoTreeGitDeleted = { fg = colors.color_9 },
		NeoTreeGitIgnored = { fg = colors.color_1 },
		NeoTreeGitModified = { fg = colors.color_8 },
		NeoTreeGitUnstaged = { fg = colors.color_8 },
		NeoTreeGitUntracked = { fg = colors.color_7 },
		NeoTreeGitStaged = { fg = colors.color_7 },
		NeoTreeFloatBorder = { fg = colors.color_3, bg = colors.bg_alt },
		NeoTreeFloatTitle = { fg = colors.bg, bg = colors.color_5, bold = true },
		NeoTreeTitleBar = { fg = colors.bg, bg = colors.color_5, bold = true },
		NeoTreeWindowsHidden = { fg = colors.color_1 },
	}
end

return M

