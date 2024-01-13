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

HL("NvimPyRed", red)
HL("NvimPyPurple", purple)
HL("NvimPyGreen", green)
HL("NvimPyBlue", blue)
HL("NvimPyBBlue", bblue)
HL("NvimPyOrange", orange)
HL("NvimPyYellow", yellow)
HL("NvimPyCyan", cyan)
HL("NvimPyTeal", teal)

--[[
-- Simple Cmp Highlights
--]]
--
HL("CmpBorder", purple)
HL("CmpBorderIconsLT", blue)
HL("CmpBorderIconsCT", orange)
HL("CmpBorderIconsRT", teal)
HL("CmpItemAbbrDeprecated", Theme.default.fg_gutter, Theme.default.none)
HL("CmpItemAbbrMatch", blue, Theme.default.none)
HL("CmpItemAbbrMatchFuzzy", teal, Theme.default.none)
HL("CmpItemMenu", purple)
HL("CmpItemKindField", Theme.night.bg, blue)
HL("CmpItemKindProperty", Theme.night.bg, purple)
HL("CmpItemKindEvent", Theme.night.bg, purple)
HL("CmpItemKindText", Theme.night.bg, green)
HL("CmpItemKindEnum", Theme.night.bg, green)
HL("CmpItemKindKeyword", Theme.night.bg, blue)
HL("CmpItemKindConstant", Theme.night.bg, orange)
HL("CmpItemKindConstructor", Theme.night.bg, orange)
HL("CmpItemKindRefrence", Theme.night.bg, orange)
HL("CmpItemKindFunction", Theme.night.bg, purple)
HL("CmpItemKindStruct", Theme.night.bg, purple)
HL("CmpItemKindClass", Theme.night.bg, purple)
HL("CmpItemKindModule", Theme.night.bg, purple)
HL("CmpItemKindOperator", Theme.night.bg, purple)
HL("CmpItemKindVariable", Theme.night.bg, cyan)
HL("CmpItemKindFile", Theme.night.bg, cyan)
HL("CmpItemKindUnit", Theme.night.bg, orange)
HL("CmpItemKindSnippet", Theme.night.bg, orange)
HL("CmpItemKindFolder", Theme.night.bg, orange)
HL("CmpItemKindMethod", Theme.night.bg, yellow)
HL("CmpItemKindValue", Theme.night.bg, yellow)
HL("CmpItemKindEnumMember", Theme.night.bg, yellow)
HL("CmpItemKindInterface", Theme.night.bg, green)
HL("CmpItemKindColor", Theme.night.bg, green)
HL("CmpItemKindTypeParameter", Theme.night.bg, green)

--[[
-- Telescope
--]]

HL("TelescopeNormal", Theme.default.fg_dark, Theme.default.bg_dark)
HL("TelescopeBorder", Theme.default.none, Theme.default.none)
HL("TelescopePromptNormal", blue, Theme.default.bg_dark)
HL("TelescopePromptBorder", Theme.default.bg_dark, Theme.default.bg_dark)
HL("TelescopePromptTitle", Theme.default.bg_dark, Theme.default.bg_dark)
HL("TelescopePreviewTitle", Theme.default.none, Theme.default.none)
HL("TelescopeResultsTitle", Theme.default.none, Theme.default.none)

--[[
-- UI
--]]

HL("CursorLineNr", red, Theme.default.bg_highlight)
HL("LineNr", bblue, Theme.default.none)
HL("WinSeparator", purple, Theme.default.none, true)
HL("NeoTreeWinSeparator", purple, Theme.default.none)
HL("NeoTreeRootName", purple, Theme.default.none)
HL("Winbar", Theme.default.fg, Theme.default.none)
HL("WinbarNC", Theme.default.fg, Theme.default.none)
HL("MiniIndentscopeSymbol", bblue, Theme.default.none)
HL("FloatBorder", purple, Theme.night.bg)

--[[
-- Git colors
--]]
--

HL("GitSignsAdd", green, Theme.default.none)
HL("GitSignsChange", orange, Theme.default.none)
HL("GitSignsDelete", red, Theme.default.none)
HL("GitSignsUntracked", blue, Theme.default.none)

--[[
-- DropBar Highlights
--]]
HL("DropBarIconKindVariable", cyan, Theme.default.none)
HL("DropBarIconKindModule", cyan, Theme.default.none)
HL("DropBarIconUISeparator", purple, Theme.default.none)
HL("DropBarIconKindFunction", cyan, Theme.default.none)

--[[
-- BufferLine
--]]

HL("BufferLineCloseButtonSelected", red, Theme.default.none)
HL("BufferLineTabSelected", purple, Theme.default.none)
