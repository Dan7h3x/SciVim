local highlighter = vim.api.nvim_set_hl
local Theme = require("tokyonight.colors")

local function HL(hl, fg, bg, bold)
	if not bg and not bold then
		highlighter(0, hl, { fg = fg, bg = Theme.night.bg, bold = bold })
	elseif not bold then
		highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
	else
		highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
	end
end

--[[
-- My Colors Neon based
--]]
local red = "#FF3131"
local purple = "#9457EB"
local magenta = "#E23DA5"
local green = "#39FF14"
local blue = "#4D4DFF"
local bblue = "#89CFF0"
local orange = "#F6890A"
local yellow = "#CCFF00"
local cyan = "#00FEFC"
local teal = "#43BBB6"
local black = "#070508"
local trans = Theme.default.none

HL("NvimPyRed", red)
HL("NvimPyPurple", purple)
HL("NvimPyGreen", green)
HL("NvimPyBlue", blue)
HL("NvimPyBBlue", bblue)
HL("NvimPyOrange", orange)
HL("NvimPyYellow", yellow)
HL("NvimPyCyan", cyan)
HL("NvimPyTeal", teal)
HL("NvimPyTrans", trans)
highlighter(0, "CursorLine", { bg = Theme.default.bg })
highlighter(0, "CmpCursorLine", { bg = Theme.default.bg_dark })
--[[
-- Simple Cmp Highlights
--]]
--

HL("CmpItemKindField", blue, Theme.default.bg_dark)
HL("CmpItemKindProperty", purple, Theme.default.bg_dark)
HL("CmpItemKindEvent", purple, Theme.default.bg_dark)
HL("CmpItemKindText", green, Theme.default.bg_dark)
HL("CmpItemKindEnum", green, Theme.default.bg_dark)
HL("CmpItemKindKeyword", blue, Theme.default.bg_dark)
HL("CmpItemKindConstant", orange, Theme.default.bg_dark)
HL("CmpItemKindConstructor", orange, Theme.default.bg_dark)
HL("CmpItemKindRefrence", orange, Theme.default.bg_dark)
HL("CmpItemKindFunction", purple, Theme.default.bg_dark)
HL("CmpItemKindStruct", purple, Theme.default.bg_dark)
HL("CmpItemKindClass", purple, Theme.default.bg_dark)
HL("CmpItemKindModule", purple, Theme.default.bg_dark)
HL("CmpItemKindOperator", purple, Theme.default.bg_dark)
HL("CmpItemKindVariable", cyan, Theme.default.bg_dark)
HL("CmpItemKindFile", cyan, Theme.default.bg_dark)
HL("CmpItemKindUnit", orange, Theme.default.bg_dark)
HL("CmpItemKindSnippet", orange, Theme.default.bg_dark)
HL("CmpItemKindFolder", orange, Theme.default.bg_dark)
HL("CmpItemKindMethod", yellow, Theme.default.bg_dark)
HL("CmpItemKindValue", yellow, Theme.default.bg_dark)
HL("CmpItemKindEnumMember", yellow, Theme.default.bg_dark)
HL("CmpItemKindInterface", green, Theme.default.bg_dark)
HL("CmpItemKindColor", green, Theme.default.bg_dark)
HL("CmpItemKindTypeParameter", green, Theme.default.bg_dark)
HL("CmpItemAbbrMatchFuzzy", cyan, Theme.default.bg_dark)
HL("CmpItemAbbrMatch", cyan, Theme.default.bg_dark)
HL("CmpBorder", Theme.default.terminal_black, Theme.night.bg, true)
HL("CmpBorderDoc", Theme.default.terminal_black, Theme.night.bg, true)
HL("CmpBorderIconsLT", cyan, Theme.night.bg)
HL("CmpBorderIconsCT", orange, Theme.night.bg)
HL("CmpBorderIconsRT", teal, Theme.night.bg)
HL("CmpNormal", purple, Theme.night.bg)
HL("CmpItemMenu", cyan, Theme.default.bg_dark)

--[[
-- Telescope
--]]

HL("TelescopeNormal", blue, Theme.night.bg)
HL("TelescopeBorder", Theme.default.bg_dark, trans)
HL("TelescopePromptNormal", blue, Theme.night.bg)
HL("TelescopePromptBorder", Theme.default.bg_dark, Theme.night.bg)
HL("TelescopePromptTitle", cyan, Theme.night.bg)
HL("TelescopePreviewTitle", purple, trans)
HL("TelescopeResultsTitle", teal, trans)
HL("TelescopePreviewBorder", purple, trans)
HL("TelescopeResultsBorder", cyan, trans)
--[[
-- UI
--]]
HL("CursorLineNr", purple, trans)
HL("LineNr", Theme.default.terminal_black, trans)
HL("WinSeparator", purple, trans, true)
HL("NeoTreeWinSeparator", purple, trans)
HL("NeoTreeStatusLineNC", trans, trans)
HL("NeoTreeRootName", purple, trans)
HL("NeoTreeIndentMarker", purple, trans)
HL("Winbar", Theme.default.fg, trans)
HL("WinbarNC", Theme.default.fg, trans)
HL("MiniIndentscopeSymbol", bblue, trans)
HL("FloatBorder", purple, Theme.night.bg)
HL("NvimPyTab", blue, black)

--[[
-- Git colors
--]]
--

HL("GitSignsAdd", green, trans)
HL("GitSignsChange", orange, trans)
HL("GitSignsDelete", red, trans)
HL("GitSignsUntracked", blue, trans)

--[[
-- DropBar Highlights
--]]
HL("DropBarIconKindVariable", cyan, trans)
HL("DropBarIconKindModule", cyan, trans)
HL("DropBarIconUISeparator", purple, trans)
HL("DropBarIconKindFunction", cyan, trans)

--[[
-- BufferLine
--]]

HL("BufferLineCloseButtonSelected", red, trans)
HL("BufferLineCloseButtonVisible", orange, trans)
HL("BufferLineBufferSelected", purple)
HL("BufferLineNumbersSelected", green)
HL("BufferLineFill", trans, Theme.default.bg_dark)
HL("BufferCurrent", blue, trans)
HL("BufferLineIndicatorSelected", cyan, trans)

vim.api.nvim_set_hl(0, "NvimPy18", { fg = "#14067E", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPyPy1", { fg = "#15127B", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy17", { fg = "#171F78", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy16", { fg = "#182B75", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPyPy2", { fg = "#193872", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy15", { fg = "#1A446E", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy14", { fg = "#1C506B", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPyPy3", { fg = "#1D5D68", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy13", { fg = "#1E6965", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy12", { fg = "#1F7562", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPyPy4", { fg = "#21825F", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy11", { fg = "#228E5C", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy10", { fg = "#239B59", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy9", { fg = "#24A755", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy8", { fg = "#26B352", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPyPy5", { fg = "#27C04F", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy7", { fg = "#28CC4C", ctermfg = 41 })
vim.api.nvim_set_hl(0, "NvimPy6", { fg = "#29D343", ctermfg = 41 })
vim.api.nvim_set_hl(0, "NvimPy5", { fg = "#EC9F05", ctermfg = 214 })
vim.api.nvim_set_hl(0, "NvimPy4", { fg = "#F08C04", ctermfg = 208 })
vim.api.nvim_set_hl(0, "NvimPyPy6", { fg = "#F37E03", ctermfg = 208 })
vim.api.nvim_set_hl(0, "NvimPy3", { fg = "#F77002", ctermfg = 202 })
vim.api.nvim_set_hl(0, "NvimPy2", { fg = "#FB5D01", ctermfg = 202 })
vim.api.nvim_set_hl(0, "NvimPy1", { fg = "#FF4E00", ctermfg = 202 })
