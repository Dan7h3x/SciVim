local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Base UI
		Normal = { fg = colors.fg, bg = colors.bg },
		NormalFloat = { fg = colors.fg, bg = colors.bg },
		NormalNC = { fg = colors.fg, bg = colors.bg },
		Comment = { fg = colors.color_3 },

		-- Cursor
		Cursor = { fg = colors.bg, bg = colors.fg },
		CursorLine = { bg = colors.bg_alt },
		CursorColumn = { bg = colors.bg_alt },
		ColorColumn = { bg = colors.bg_alt },
		CursorLineNr = { fg = colors.color_5, bold = true },
		LineNr = { fg = colors.color_1 },

		-- Selections
		Visual = { bg = colors.color_2 },
		VisualNOS = { bg = colors.color_2 },

		-- Search
		Search = { fg = colors.bg, bg = colors.color_8 },
		IncSearch = { fg = colors.bg, bg = colors.color_11 },
		CurSearch = { fg = colors.bg, bg = colors.color_11 },
		Substitute = { fg = colors.bg, bg = colors.color_10 },

		-- Windows
		WinSeparator = { fg = colors.color_2 },
		VertSplit = { fg = colors.color_2 },

		-- Statusline
		StatusLine = { fg = colors.fg, bg = colors.bg_alt },
		StatusLineNC = { fg = colors.color_1, bg = colors.bg },

		-- Tabline
		TabLine = { fg = colors.fg_alt, bg = colors.bg_alt },
		TabLineFill = { bg = colors.bg },
		TabLineSel = { fg = colors.fg, bg = colors.color_3, bold = true },

		-- Popup menu
		Pmenu = { fg = colors.fg, bg = colors.bg_alt },
		PmenuSel = { fg = colors.bg, bg = colors.color_5, bold = true },
		PmenuSbar = { bg = colors.bg_alt },
		PmenuThumb = { bg = colors.color_3 },

		-- Folds
		Folded = { fg = colors.color_3, bg = colors.bg_alt },
		FoldColumn = { fg = colors.color_3, bg = colors.bg },

		-- Diffs
		DiffAdd = { fg = colors.color_7, bg = colors.bg_alt },
		DiffChange = { fg = colors.color_8, bg = colors.bg_alt },
		DiffDelete = { fg = colors.color_9, bg = colors.bg_alt },
		DiffText = { fg = colors.color_11, bg = colors.bg_alt, bold = true },

		-- Spelling
		SpellBad = { sp = colors.color_9, undercurl = true },
		SpellCap = { sp = colors.color_8, undercurl = true },
		SpellLocal = { sp = colors.color_6, undercurl = true },
		SpellRare = { sp = colors.color_10, undercurl = true },

		-- Messages
		ErrorMsg = { fg = colors.color_9, bold = true },
		WarningMsg = { fg = colors.color_8, bold = true },
		ModeMsg = { fg = colors.fg_alt, bold = true },
		MoreMsg = { fg = colors.color_5, bold = true },
		Question = { fg = colors.color_6, bold = true },

		-- Misc
		Directory = { fg = colors.color_5, bold = true },
		Title = { fg = colors.color_11, bold = true },
		NonText = { fg = colors.color_3 },
		SpecialKey = { fg = colors.color_2 },
		Whitespace = { fg = colors.color_2 },
		MatchParen = { fg = colors.color_11, bg = colors.color_2, bold = true },
		SignColumn = { fg = colors.fg, bg = colors.bg },
		Conceal = { fg = colors.color_3 },
		WildMenu = { fg = colors.bg, bg = colors.color_5 },

		-- Floating windows
		FloatBorder = { fg = colors.color_3, bg = colors.bg_alt },
		FloatTitle = { fg = colors.color_11, bg = colors.bg_alt, bold = true },

		-- Quickfix
		QuickFixLine = { bg = colors.color_2 },

		-- Basic Colors
		Red = { fg = "#ff6e5e" },
		Orange = { fg = "#FFbd5e" },
		Yellow = { fg = "#f1fF68" },
		Blue = { fg = "#5AA2F7" },
		Cyan = { fg = "#5Af3DE" },
		Green = { fg = "#5EfE6A" },
		Teal = { fg = "#1ABC9C" },
		White = { fg = "#f0fAF5" },
		Black = { fg = "#1A1B26" },
		Magenta = { fg = "#ff53f1" },
		Purple = { fg = "#bd5eff" },
		Pink = { fg = "#ff99c9" },
		Gray = { fg = "#565F89" },
		Brown = { fg = "#B2945B" },
	}
end

return M
