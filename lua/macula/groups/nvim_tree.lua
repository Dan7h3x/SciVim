local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		NvimTreeNormal = { fg = colors.fg, bg = colors.bg },
		NvimTreeNormalNC = { fg = colors.fg, bg = colors.bg },
		NvimTreeRootFolder = { fg = colors.color_11, bold = true },
		NvimTreeFolderName = { fg = colors.color_5 },
		NvimTreeFolderIcon = { fg = colors.color_5 },
		NvimTreeEmptyFolderName = { fg = colors.color_3 },
		NvimTreeOpenedFolderName = { fg = colors.color_5, bold = true },
		NvimTreeSymlink = { fg = colors.color_6 },
		NvimTreeExecFile = { fg = colors.color_7, bold = true },
		NvimTreeOpenedFile = { fg = colors.color_11 },
		NvimTreeSpecialFile = { fg = colors.color_8, underline = true },
		NvimTreeImageFile = { fg = colors.color_10 },
		NvimTreeIndentMarker = { fg = colors.color_2 },
		NvimTreeGitDirty = { fg = colors.color_8 },
		NvimTreeGitStaged = { fg = colors.color_7 },
		NvimTreeGitMerge = { fg = colors.color_9 },
		NvimTreeGitRenamed = { fg = colors.color_6 },
		NvimTreeGitNew = { fg = colors.color_7 },
		NvimTreeGitDeleted = { fg = colors.color_9 },
		NvimTreeWindowPicker = { fg = colors.bg, bg = colors.color_11, bold = true },
	}
end

return M

