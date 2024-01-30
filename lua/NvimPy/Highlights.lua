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
local green = "#39FF14"
local blue = "#4D4DFF"
local bblue = "#89CFF0"
local orange = "#F6890A"
local yellow = "#CCFF00"
local cyan = "#00FEFC"
local teal = "#43BBB6"
local black = "#070508"
local grey = "#212121"
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
highlighter(0, "CursorLine", { bg = black })
--[[
-- Simple Cmp Highlights
--]]
--

HL("CmpItemKindField", black, blue)
HL("CmpItemKindProperty", black, purple)
HL("CmpItemKindEvent", black, purple)
HL("CmpItemKindText", black, green)
HL("CmpItemKindEnum", black, green)
HL("CmpItemKindKeyword", black, blue)
HL("CmpItemKindConstant", black, orange)
HL("CmpItemKindConstructor", black, orange)
HL("CmpItemKindRefrence", black, orange)
HL("CmpItemKindFunction", black, purple)
HL("CmpItemKindStruct", black, purple)
HL("CmpItemKindClass", black, purple)
HL("CmpItemKindModule", black, purple)
HL("CmpItemKindOperator", black, purple)
HL("CmpItemKindVariable", black, cyan)
HL("CmpItemKindFile", black, cyan)
HL("CmpItemKindUnit", black, orange)
HL("CmpItemKindSnippet", black, orange)
HL("CmpItemKindFolder", black, orange)
HL("CmpItemKindMethod", black, yellow)
HL("CmpItemKindValue", black, yellow)
HL("CmpItemKindEnumMember", black, yellow)
HL("CmpItemKindInterface", black, green)
HL("CmpItemKindColor", black, green)
HL("CmpItemKindTypeParameter", black, green)
HL("CmpBorder", purple, grey, true)
HL("CmpBorderDoc", cyan, grey, true)
HL("CmpBorderIconsLT", cyan, grey)
HL("CmpBorderIconsCT", orange, grey)
HL("CmpBorderIconsRT", teal, grey)
HL("CmpNormal", purple, grey)

HL("CmpItemMenu", black, cyan)

--[[
-- Telescope
--]]

HL("TelescopeNormal", blue, Theme.night.bg)
HL("TelescopeBorder", trans, trans)
HL("TelescopePromptNormal", blue, Theme.night.bg)
HL("TelescopePromptBorder", Theme.night.bg, Theme.night.bg)
HL("TelescopePromptTitle", Theme.night.bg, Theme.night.bg)
HL("TelescopePreviewTitle", trans, trans)
HL("TelescopeResultsTitle", trans, trans)
HL("TelescopePreviewBorder", purple, trans)
HL("TelescopeResultsBorder", cyan, trans)
--[[
-- UI
--]]

HL("CursorLineNr", red, black)
HL("LineNr", bblue, black)
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
HL("BufferLineFill", trans, black)
HL("BufferCurrent", blue, trans)
HL("BufferLineIndicatorSelected", purple, trans)
