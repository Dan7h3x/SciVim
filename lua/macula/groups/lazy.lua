local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		LazyH1 = { fg = colors.bg, bg = colors.color_11, bold = true },
		LazyH2 = { fg = colors.color_11, bold = true },
		LazyButton = { fg = colors.fg, bg = colors.bg_alt },
		LazyButtonActive = { fg = colors.bg, bg = colors.color_5, bold = true },
		LazyComment = { fg = colors.color_3 },
		LazyCommit = { fg = colors.color_7 },
		LazyCommitIssue = { fg = colors.color_8 },
		LazyCommitScope = { fg = colors.color_6 },
		LazyCommitType = { fg = colors.color_5 },
		LazyDimmed = { fg = colors.bg_alt },
		LazyDir = { fg = colors.fg_alt },
		LazyH3 = { fg = colors.color_8 },
		LazyLocal = { fg = colors.color_10 },
		LazyNoCond = { fg = colors.color_1 },
		LazyNormal = { fg = colors.fg, bg = colors.bg },
		LazyProgressDone = { fg = colors.color_7 },
		LazyProgressTodo = { fg = colors.color_1 },
		LazyProp = { fg = colors.color_3 },
		LazyReasonCmd = { fg = colors.color_8 },
		LazyReasonEvent = { fg = colors.color_6 },
		LazyReasonFt = { fg = colors.color_10 },
		LazyReasonImport = { fg = colors.color_7 },
		LazyReasonKeys = { fg = colors.color_11 },
		LazyReasonPlugin = { fg = colors.color_9 },
		LazyReasonRuntime = { fg = colors.color_12 },
		LazyReasonSource = { fg = colors.color_5 },
		LazyReasonStart = { fg = colors.color_7 },
		LazySpecial = { fg = colors.color_6 },
		LazyTaskError = { fg = colors.color_9 },
		LazyTaskOutput = { fg = colors.fg },
		LazyUrl = { fg = colors.color_4, underline = true },
		LazyValue = { fg = colors.color_10 },
	}
end

return M
