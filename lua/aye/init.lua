local M = {}
local config = require("aye.config")

local dark = {
	-- Base colors with improved contrast and depth
	bg = "#1A1B26", -- Deeper blue-black from TokyoNight
	fg = "#C0CAF5", -- Soft lavender-white
	comment = "#565F89", -- Muted indigo from TokyoNight
	selection = "#3D59A1", -- Rich blue selection
	cursor_line = "#292E42", -- Subtle dark shade with blue tint
	transparent = "NONE",
	special = "#f785f5",

	-- UI elements with more vibrant accents
	border = "#3D59A1", -- Richer blue border
	line_numbers = "#3B4261", -- Subdued blue-gray
	cursor_line_num = "#7AA2F7", -- Vibrant blue from TokyoNight
	float_border = "#3D59A1", -- Matching border color
	popup_back = "#2A2B26", -- Slightly lighter background for popups
	lighter_bg = "#262A3F", -- Subtle gradient backgrounds
	light_bg = "#2F3549",
	dark_fg = "#A9B1D6",
	ui_bg = "#1F2335",
	ui_fg = "#C0CAF5",
	ui_active = "#7AA2F7",
	ui_inactive = "#1D1F2B",

	-- Enhanced syntax colors with better distinction - Cyberdream inspired
	attribute = "#9ECE6A", -- Vibrant green
	string = "#9EEAF9", -- Bright cyan from Cyberdream
	number = "#FF9E64", -- Warm orange
	func = "#7AA2F7", -- Clear blue from TokyoNight
	keyword = "#BB9AF7", -- Rich purple
	type = "#2AC3DE", -- Electric blue
	const = "#FF9E64", -- Warm orange
	variable = "#C0CAF5", -- Matches fg
	parameter = "#E0AF68", -- Gold/amber
	operator = "#89DDFF", -- Sky blue
	namespace = "#2AC3DE", -- Electric blue
	decorator = "#BB9AF7", -- Rich purple
	regex = "#F7768E", -- Pink-red

	-- Basic colors
	red = "#ff6e5e",
	orange = "#FFbd5e",
	yellow = "#f1fF68",
	blue = "#5AA2F7",
	cyan = "#5Af3DE",
	green = "#5EfE6A",
	teal = "#1ABC9C",
	white = "#f0fAF5",
	black = "#1A1B26",
	magenta = "#ff5ef1",
	purple = "#bd5eff",
	pink = "#ff99c9",
	gray = "#565F89",
	brown = "#B2945B",

	-- Diagnostics with more distinct backgrounds
	error = "#F7768E", -- Bright pink-red from TokyoNight
	warning = "#E0AF68", -- Gold/amber
	info = "#7AA2F7", -- Clear blue
	hint = "#1ABC9C", -- Teal
	error_bg = "#332332", -- Subtle red background
	warning_bg = "#332C2A", -- Subtle amber background
	info_bg = "#20324E", -- Subtle blue background
	hint_bg = "#233745", -- Subtle teal background

	-- Git colors aligned with syntax
	git_add = "#9ECE6A", -- Vibrant green
	git_change = "#E0AF68", -- Gold/amber
	git_delete = "#F7768E", -- Pink-red

	-- Refined terminal colors
	terminal = {
		black = "#1A1B26",
		red = "#F7768E",
		green = "#9ECE6A",
		yellow = "#E0AF68",
		blue = "#7AA2F7",
		magenta = "#BB9AF7",
		cyan = "#2AC3DE",
		white = "#C0CAF5",
		bright_black = "#565F89",
		bright_red = "#FF7A93",
		bright_green = "#B9F27C",
		bright_yellow = "#FF9E64",
		bright_blue = "#7DCFFF",
		bright_magenta = "#D0A9FF",
		bright_cyan = "#0DB9D7",
		bright_white = "#D5DCF5",
	},
}

local light = {
	bg = "#f9f9e0",
	fg = "#1A1B26",
	comment = "#838781",
	selection = "#D1C2FF",
	cursor_line = "#DFDDD0",
	transparent = "NONE",
	special = "#8a4adf",

	border = "#A8A3B7",
	line_numbers = "#9A998F",
	cursor_line_num = "#3A5CCC",
	float_border = "#A8A3B7",
	popup_back = "#c7c7af",
	lighter_bg = "#F0EEE2",
	light_bg = "#E8E6D9",
	dark_fg = "#6B6B63",
	ui_bg = "#E8E6D9",
	ui_fg = "#4E4E5C",
	ui_active = "#5A7684",
	ui_inactive = "#D4D1C2",

	attribute = "#04a5e5",
	string = "#40a02b",
	number = "#e64553",
	func = "#1e66f5",
	keyword = "#5c5f77",
	type = "#47b2c9",
	const = "#df8e1d",
	variable = "#8839ef",
	parameter = "#ea76cb",
	operator = "#4A6D69",
	namespace = "#4A6D69",
	decorator = "#7B6B94",
	regex = "#B33C3F",

	red = "#d11500",
	orange = "#d17c00",
	yellow = "#c9bb00",
	blue = "#0057d1",
	cyan = "#008c99",
	green = "#008b0c",
	teal = "#3A6E67",
	white = "#F5F3EA",
	black = "#2A2A33",
	magenta = "#d100bf",
	purple = "#a018ff",
	pink = "#f98fc8",
	gray = "#7b8496",
	brown = "#B2945B",

	error = "#B33C3F",
	warning = "#B2945B",
	info = "#5A7684",
	hint = "#218779",
	error_bg = "#F5AAAA",
	warning_bg = "#f5e552",
	info_bg = "#ABB0F2",
	hint_bg = "#ABF0BE",

	git_add = "#3A6E67",
	git_change = "#B2945B",
	git_delete = "#B33C3F",

	terminal = {
		black = "#9ca0b0",
		red = "#d11500",
		green = "#008b0c",
		yellow = "#c9bb00",
		blue = "#0057d1",
		magenta = "#d100bf",
		cyan = "#008c99",
		white = "#1A1B26",
		bright_black = "#8c8fa1",
		bright_red = "#d11500",
		bright_green = "#008b0c",
		bright_yellow = "#c9bb00",
		bright_blue = "#0057d1",
		bright_magenta = "#d100bf",
		bright_cyan = "#008c99",
		bright_white = "#1A1B26",
	},
}
local function load_highlights(colors, opts)
	local h = {
		-- Treesitter syntax
		["@attribute"] = { fg = colors.attribute, italic = true },
		["@attribute.builtin"] = { fg = colors.attribute, italic = true },
		["@boolean"] = { fg = colors.const },
		["@character"] = { fg = colors.string },
		["@comment"] = { fg = colors.comment, italic = opts.styles.comments.italic },
		["@constructor"] = { fg = colors.type, bold = true },
		["@constant"] = { fg = colors.const },
		["@constant.builtin"] = { fg = colors.const, italic = true },
		["@constant.macro"] = { fg = colors.const },
		["@function"] = { fg = colors.func, bold = opts.styles.functions.bold },
		["@function.builtin"] = { fg = colors.func, italic = true },
		["@function.macro"] = { fg = colors.func },
		["@keyword"] = { fg = colors.keyword, italic = opts.styles.keywords.italic },
		["@keyword.operator"] = { fg = colors.operator },
		["@method"] = { fg = colors.func },
		["@namespace"] = { fg = colors.namespace },
		["@number"] = { fg = colors.number },
		["@operator"] = { fg = colors.operator },
		["@parameter"] = { fg = colors.parameter },
		["@property"] = { fg = colors.parameter },
		["@punctuation"] = { fg = colors.fg },
		-- ["@punctuation.bracket"] = { fg = colors.blue },
		["@string"] = { fg = colors.string, italic = opts.styles.strings.italic },
		["@string.documentation"] = { fg = colors.string },
		["@string.regex"] = { fg = colors.regex },
		["@type"] = { fg = colors.type },
		["@variable"] = { fg = colors.variable },
		["@variable.builtin"] = { fg = colors.const, italic = true },
		["@variable.parameter"] = { fg = colors.keyword },
		["@variable.member"] = { fg = colors.variable },
		["@variable.member.key"] = { fg = colors.variable },

		-- Additional Treesitter highlight groups inspired by Tokyo Night
		["@tag"] = { fg = colors.keyword }, -- HTML/JSX/XML tags
		["@tag.attribute"] = { fg = colors.attribute }, -- HTML/JSX/XML attributes
		["@tag.delimiter"] = { fg = colors.operator }, -- HTML/JSX/XML delimiters
		["@text"] = { fg = colors.fg }, -- Plain text content
		["@text.strong"] = { bold = true }, -- Bold text in markdown
		["@text.emphasis"] = { italic = true }, -- Italic text in markdown
		["@text.underline"] = { underline = true }, -- Underlined text
		["@text.title"] = { fg = colors.func, bold = true }, -- Headers/titles
		["@text.literal"] = { fg = colors.string }, -- Code blocks in markdown
		["@text.uri"] = { fg = colors.const, underline = true }, -- URLs
		["@text.todo"] = { fg = colors.bg, bg = colors.info }, -- TODO comments
		["@text.note"] = { fg = colors.bg, bg = colors.hint }, -- NOTE comments
		["@text.warning"] = { fg = colors.bg, bg = colors.warning }, -- WARNING comments
		["@text.danger"] = { fg = colors.bg, bg = colors.error }, -- FIXME/BUG comments
		["@comment.error"] = { fg = colors.error, bold = true }, -- Error comments
		["@diff.plus"] = { fg = colors.git_add }, -- Git diff additions
		["@diff.minus"] = { fg = colors.git_delete }, -- Git diff deletions
		["@diff.delta"] = { fg = colors.git_change }, -- Git diff changes

		-- LSP Semantic tokens
		["@lsp.type.boolean"] = { fg = colors.const },
		["@lsp.type.builtinType"] = { fg = colors.type, italic = true },
		["@lsp.type.comment"] = { fg = colors.comment, italic = opts.styles.comments.italic },
		["@lsp.type.decorator"] = { fg = colors.decorator, italic = true },
		["@lsp.type.deriveHelper"] = { fg = colors.attribute },
		["@lsp.type.escapeSequence"] = { fg = colors.string },
		["@lsp.type.formatSpecifier"] = { fg = colors.string },
		["@lsp.type.generic"] = { fg = colors.type },
		["@lsp.type.keyword"] = { fg = colors.keyword, italic = opts.styles.keywords.italic },
		["@lsp.type.lifetime"] = { fg = colors.const, italic = true },
		["@lsp.type.namespace.rust"] = { fg = colors.namespace },
		["@lsp.type.number"] = { fg = colors.number },
		["@lsp.type.operator"] = { fg = colors.operator },
		["@lsp.type.parameter.rust"] = { fg = colors.parameter },
		["@lsp.type.punctuation"] = { fg = colors.fg },
		["@lsp.type.selfKeyword"] = { fg = colors.keyword, italic = true },
		["@lsp.type.selfTypeKeyword"] = { fg = colors.type, italic = true },
		["@lsp.type.string"] = { fg = colors.string, italic = opts.styles.strings.italic },
		["@lsp.type.typeAlias"] = { fg = colors.type },

		-- Additional LSP semantic token types
		["@lsp.type.class"] = { fg = colors.type },
		["@lsp.type.enum"] = { fg = colors.type },
		["@lsp.type.enumMember"] = { fg = colors.const },
		["@lsp.type.function"] = { fg = colors.func, bold = opts.styles.functions.bold },
		["@lsp.type.interface"] = { fg = colors.type, italic = true },
		["@lsp.type.macro"] = { fg = colors.func },
		["@lsp.type.method"] = { fg = colors.func },
		["@lsp.type.namespace"] = { fg = colors.namespace },
		["@lsp.type.property"] = { fg = colors.parameter },
		["@lsp.type.struct"] = { fg = colors.type },
		["@lsp.type.type"] = { fg = colors.type },
		["@lsp.type.typeParameter"] = { fg = colors.parameter, italic = true },
		["@lsp.type.variable"] = { fg = colors.variable },
		["@lsp.type.event"] = { fg = colors.attribute },
		["@lsp.type.modifier"] = { fg = colors.keyword },

		-- Markups
		["@markup.heading.1.markdown"] = { fg = colors.purple },
		["@markup.heading.2.markdown"] = { fg = colors.pink },
		["@markup.heading.3.markdown"] = { fg = colors.cyan },
		["@markup.heading.4.markdown"] = { fg = colors.teal },
		["@markup.heading.5.markdown"] = { fg = colors.green },
		["@markup.heading.6.markdown"] = { fg = colors.brown },
		["@markup.quote.markdown"] = { fg = colors.decorator },
		-- Basic colors
		Red = { fg = colors.red, bg = colors.bg },
		Orange = { fg = colors.orange, bg = colors.bg },
		yellow = { fg = colors.yellow, bg = colors.bg },
		Blue = { fg = colors.blue, bg = colors.bg },
		Cyan = { fg = colors.cyan, bg = colors.bg },
		Green = { fg = colors.green, bg = colors.bg },
		Teal = { fg = colors.teal, bg = colors.bg },
		White = { fg = colors.white, bg = colors.bg },
		Black = { fg = colors.black, bg = colors.bg },
		Magenta = { fg = colors.magenta, bg = colors.bg },
		Purple = { fg = colors.purple, bg = colors.bg },
		Pink = { fg = colors.pink, bg = colors.bg },
		Gray = { fg = colors.gray, bg = colors.bg },
		Brown = { fg = colors.brown, bg = colors.bg },
		-- Enhanced editor UI highlights
		Normal = { fg = colors.fg, bg = colors.bg },
		NormalFloat = { fg = colors.fg, bg = colors.bg },
		FloatBorder = { fg = colors.float_border, bg = colors.bg },
		Tab = { fg = colors.decorator, bg = colors.bg },
		Title = { fg = colors.special, bold = true },
		WildMenu = { bg = colors.cursor_line, fg = colors.special },

		-- Improved cursor line highlighting for better focus
		Cursor = { fg = colors.bg, bg = colors.fg },
		lCursor = { fg = colors.bg, bg = colors.fg },
		CursorIM = { fg = colors.bg, bg = colors.fg },
		CursorLine = { bg = colors.cursor_line },
		CursorLineNr = { fg = colors.cursor_line_num, bold = true },
		CursorColumn = { bg = colors.lighter_bg },

		-- Softer sign column and line numbers for reduced eye strain
		SignColumn = { bg = colors.transparent },
		LineNr = { fg = colors.line_numbers },

		-- More subtle indent guides
		IndentBlanklineChar = { fg = colors.lighter_bg },
		IndentBlanklineContextChar = { fg = colors.border },

		-- Enhanced fold indicators
		Folded = { fg = colors.special, italic = true },
		FoldColumn = { fg = colors.special, bg = colors.transparent },
		Directory = { fg = colors.cursor_line_num },

		-- Better visual selections
		Visual = { bg = colors.selection },
		VisualNOS = { bg = colors.selection },

		-- Enhanced search highlighting
		Search = { fg = colors.bg, bg = colors.keyword },
		IncSearch = { fg = colors.bg, bg = colors.func },

		-- Clearer matching parentheses
		MatchParen = { fg = colors.special, bg = colors.lighter_bg, bold = true },

		-- More harmonious UI separators
		WinSeparator = { fg = colors.border },
		VertSplit = { fg = colors.border },
		Constant = { fg = colors.const },
		Type = { fg = colors.type },
		Special = { fg = colors.special },
		Comment = { fg = colors.comment },
		-- Better status line contrast
		StatusLine = { fg = colors.fg, bg = colors.ui_bg },
		StatusLineNC = { fg = colors.dark_fg, bg = colors.ui_inactive },

		-- Better DiffChange
		DiffAdd = { bg = colors.git_add, fg = colors.black },
		DiffDelete = { bg = colors.git_delete, fg = colors.black },
		DiffChange = { bg = colors.git_change, fg = colors.black },

		-- Improved diagnostics with subtle backgrounds - for readability
		DiagnosticError = { fg = colors.error },
		DiagnosticWarn = { fg = colors.warning },
		DiagnosticInfo = { fg = colors.info },
		DiagnosticHint = { fg = colors.hint },
		DiagnosticUnderlineError = { undercurl = true, sp = colors.error },
		DiagnosticUnderlineWarn = { undercurl = true, sp = colors.warning },
		DiagnosticUnderlineInfo = { undercurl = true, sp = colors.info },
		DiagnosticUnderlineHint = { undercurl = true, sp = colors.hint },
		DiagnosticVirtualTextError = { fg = colors.error, bg = colors.error_bg },
		DiagnosticVirtualTextWarn = { fg = colors.warning, bg = colors.warning_bg },
		DiagnosticVirtualTextInfo = { fg = colors.info, bg = colors.info_bg },
		DiagnosticVirtualTextHint = { fg = colors.hint, bg = colors.hint_bg },

		-- Enhanced git indicators in gutter
		GitSignsAdd = { fg = colors.git_add, bg = colors.transparent },
		GitSignsChange = { fg = colors.git_change, bg = colors.transparent },
		GitSignsDelete = { fg = colors.git_delete, bg = colors.transparent },

		-- Improved tab and tabline appearance
		TabLine = { fg = colors.dark_fg, bg = colors.ui_inactive },
		TabLineSel = { fg = colors.cursor_line_num, bg = colors.bg, bold = true },
		TabLineFill = { fg = colors.fg, bg = colors.popup_back },

		-- Improved Pmenu (completion menu) for better readability
		Pmenu = { bg = colors.bg },
		PmenuSel = { bg = colors.light_bg, bold = true },
		PmenuSbar = { bg = colors.bg },
		PmenuThumb = { bg = colors.light_bg },
		PmenuMatch = { fg = colors.special },

		-- DropBar

		-- Mini.Icons
		MiniAnimateCursor = { reverse = true, nocombine = true },
		MiniAnimateNormalFloat = { link = "NormalFloat" },

		MiniClueBorder = { link = "FloatBorder" },
		MiniClueDescGroup = { link = "DiagnosticFloatingWarn" },
		MiniClueDescSingle = { link = "NormalFloat" },
		MiniClueNextKey = { fg = colors.attribute },
		MiniClueNextKeyWithPostkeys = { link = "DiagnosticFloatingError" },
		MiniClueSeparator = { link = "DiagnosticFloatingInfo" },
		MiniClueTitle = { link = "FloatTitle" },

		MiniCompletionActiveParameter = { underline = true },

		MiniCursorword = { underline = true },
		MiniCursorwordCurrent = { underline = true },

		MiniDepsChangeAdded = { fg = colors.attribute },
		MiniDepsChangeRemoved = { fg = colors.error },
		MiniDepsHint = { link = "DiagnosticHint" },
		MiniDepsInfo = { link = "DiagnosticInfo" },
		MiniDepsMsgBreaking = { link = "DiagnosticWarn" },
		MiniDepsPlaceholder = { link = "Comment" },
		MiniDepsTitle = { link = "Title" },
		MiniDepsTitleError = { link = "ErrorMsg" },
		MiniDepsTitleSame = { link = "Boolean" },
		MiniDepsTitleUpdate = { link = "String" },

		MiniDiffOverAdd = { bg = colors.namespace },
		MiniDiffOverChange = { bg = colors.type },
		MiniDiffOverContext = { bg = colors.parameter },
		MiniDiffOverDelete = { bg = colors.error },
		MiniDiffSignAdd = { fg = colors.attribute },
		MiniDiffSignChange = { fg = colors.const },
		MiniDiffSignDelete = { fg = colors.error },

		MiniIconsAzure = { fg = colors.keyword, bg = colors.bg },
		MiniIconsBlue = { fg = colors.cursor_line_num },
		MiniIconsCyan = { fg = colors.type },
		MiniIconsGreen = { fg = colors.attribute },
		MiniIconsGrey = { fg = colors.fg },
		MiniIconsOrange = { fg = colors.const },
		MiniIconsPurple = { fg = colors.keyword },
		MiniIconsRed = { fg = colors.error },
		MiniIconsYellow = { fg = colors.warning },

		MiniIndentscopeSymbol = { fg = colors.comment },

		MiniJump = { link = "SpellRare" },

		MiniMapNormal = { link = "NormalFloat" },
		MiniMapSymbolCount = { link = "Special" },

		MiniNotifyBorder = { link = "FloatBorder" },
		MiniNotifyNormal = { link = "NormalFloat" },
		MiniNotifyTitle = { link = "FloatTitle" },

		MiniOperatorsExchangeFrom = { link = "IncSearch" },

		MiniPickBorder = { link = "FloatBorder" },
		MiniPickBorderBusy = { link = "DiagnosticFloatingWarn" },
		MiniPickBorderText = { link = "FloatTitle" },
		MiniPickIconDirectory = { link = "Directory" },
		MiniPickIconFile = { link = "MiniPickNormal" },
		MiniPickHeader = { link = "DiagnosticFloatingHint" },
		MiniPickMatchCurrent = { link = "CursorLine" },
		MiniPickNormal = { link = "NormalFloat" },
		MiniPickPreviewLine = { link = "CursorLine" },
		MiniPickPreviewRegion = { link = "IncSearch" },
		MiniPickPrompt = { link = "DiagnosticFloatingInfo" },

		MiniStarterCurrent = { nocombine = true },
		MiniStarterFooter = { link = "Comment" },
		MiniStarterInactive = { link = "Comment" },
		MiniStarterItem = { link = "Normal" },
		MiniStarterItemBullet = { link = "Delimiter" },
		MiniStarterItemPrefix = { link = "WarningMsg" },
		MiniStarterQuery = { link = "MoreMsg" },

		MiniStatuslineDevinfo = { link = "StatusLine" },
		MiniStatuslineFileinfo = { link = "MiniStatuslineDevinfo" },
		MiniStatuslineFilename = { link = "StatusLineNC" },
		MiniStatuslineInactive = { link = "StatusLineNC" },
		MiniStatuslineModeCommand = { fg = colors.popup_back, bg = colors.parameter, bold = true },
		MiniStatuslineModeInsert = { fg = colors.popup_back, bg = colors.attribute, bold = true },
		MiniStatuslineModeNormal = { fg = colors.popup_back, bg = colors.func, bold = true },
		MiniStatuslineModeOther = { fg = colors.popup_back, bg = colors.type, bold = true },
		MiniStatuslineModeReplace = { fg = colors.popup_back, bg = colors.error, bold = true },
		MiniStatuslineModeVisual = { fg = colors.popup_back, bg = colors.keyword, bold = true },

		MiniSurround = { link = "IncSearch" },

		MiniTablineCurrent = { fg = colors.fg, bg = colors.popup_back, bold = true },
		MiniTablineFill = { link = "TabLineFill" },
		MiniTablineHidden = { fg = colors.comment, bg = colors.bg },
		MiniTablineModifiedCurrent = { fg = colors.popup_back, bg = colors.fg, bold = true },
		MiniTablineModifiedHidden = { fg = colors.light_bg, bg = colors.comment },
		MiniTablineModifiedVisible = { fg = colors.popup_back, bg = colors.fg },
		MiniTablineTabpagesection = { link = "Search" },
		MiniTablineVisible = { fg = colors.fg, bg = colors.light_bg },

		MiniTestEmphasis = { bold = true },
		MiniTestFail = { fg = colors.error, bold = true },
		MiniTestPass = { fg = colors.attribute, bold = true },

		MiniTrailspace = { bg = colors.error },

		-- BufferLineHintDiagnosticVisible = { fg = colors.hint, bg = colors.popup_back },
		-- BufferLineInfoDiagnosticVisible = { fg = colors.info, bg = colors.popup_back },
		-- BufferLineErrorDiagnosticVisible = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineWarningDiagnosticVisible = { fg = colors.warning, bg = colors.popup_back },
		-- BufferLineHint = { fg = colors.hint, bg = colors.popup_back },
		-- BufferLineInfo = { fg = colors.info, bg = colors.popup_back },
		-- BufferLineError = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineWarning = { fg = colors.warning, bg = colors.popup_back },
		-- BufferLineHintDiagnostic = { fg = colors.hint, bg = colors.popup_back },
		-- BufferLineInfoDiagnostic = { fg = colors.info, bg = colors.popup_back },
		-- BufferLineErrorDiagnostic = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineWarningDiagnostic = { fg = colors.warning, bg = colors.popup_back },
		-- BufferLineHintDiagnosticSelected = { fg = colors.hint, bg = colors.bg },
		-- BufferLineInfoDiagnosticSelected = { fg = colors.info, bg = colors.bg },
		-- BufferLineErrorDiagnosticSelected = { fg = colors.error, bg = colors.bg },
		-- BufferLineWarningDiagnosticSelected = { fg = colors.warning, bg = colors.bg },
		-- BufferLineHintVisible = { fg = colors.hint, bg = colors.popup_back },
		-- BufferLineInfoVisible = { fg = colors.info, bg = colors.popup_back },
		-- BufferLineErrorVisible = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineWarningVisible = { fg = colors.warning, bg = colors.popup_back },
		-- BufferLineHintSelected = { fg = colors.hint, bg = colors.bg },
		-- BufferLineInfoSelected = { fg = colors.info, bg = colors.bg },
		-- BufferLineErrorSelected = { fg = colors.error, bg = colors.bg },
		-- BufferLineWarningSelected = { fg = colors.warning, bg = colors.bg },
		-- BufferLineBackground = { bg = colors.popup_back },
		-- BufferLineBuffer = { fg = colors.dark_fg, bg = colors.bg },
		-- BufferLineBufferVisible = { fg = colors.fg, bg = colors.popup_back, bold = true },
		-- BufferLineBufferSelected = { fg = colors.cursor_line_num, bg = colors.bg },
		-- BufferLineDuplicate = { fg = colors.comment, bg = colors.popup_back },
		-- BufferLineDuplicateVisible = { fg = colors.comment, bg = colors.popup_back },
		-- BufferLineDuplicateSelected = { fg = colors.comment, bg = colors.bg },
		-- BufferLineCloseButton = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineCloseButtonVisible = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineCloseButtonSelected = { fg = colors.error, bg = colors.bg },
		-- BufferLineFill = { bg = colors.popup_back },
		-- BufferLineNumbersSelected = { fg = colors.cursor_line_num, bg = colors.bg },
		-- BufferLineNumbersVisible = { fg = colors.line_numbers, bg = colors.popup_back },
		-- BufferLineNumbers = { fg = colors.line_numbers, bg = colors.popup_back },
		-- BufferLineIndicatorVisible = { fg = colors.cursor_line_num, bg = colors.popup_back },
		-- BufferLineIndicatorSelected = { fg = colors.cursor_line_num, bg = colors.bg },
		-- BufferLineModified = { fg = colors.line_numbers, bg = colors.popup_back },
		-- BufferLineModifiedVisible = { fg = colors.dark_fg, bg = colors.popup_back },
		-- BufferLineModifiedSelected = { fg = colors.cursor_line_num, bg = colors.bg },
		-- BufferLineMiniIconsAzureSelected = { fg = colors.cursor_line_num, bg = colors.bg },
		-- BufferLineMiniIconsAzure = { fg = colors.cursor_line_num, bg = colors.popup_back },
		-- BufferLineMiniIconsAzureInactive = { fg = colors.cursor_line_num, bg = colors.popup_back },
		-- BufferLineTab = { fg = colors.dark_fg, bg = colors.popup_back },
		-- BufferLineTabClose = { fg = colors.error, bg = colors.popup_back },
		-- BufferLineTabSelected = { fg = colors.cursor_line_num, bg = colors.bg, bold = true },
		-- BufferLineTabSeparator = { fg = colors.border, bg = colors.popup_back },
		-- BufferLineTabSeparatorSelected = { fg = colors.border, bg = colors.bg },
		--
		-- Telescope improvements
		TelescopeBorder = { fg = colors.float_border, bg = colors.bg },
		TelescopeNormal = { bg = colors.bg },
		TelescopePreviewBorder = { fg = colors.float_border, bg = colors.bg },
		TelescopePreviewTitle = { fg = colors.func, bold = true },
		TelescopePromptBorder = { fg = colors.float_border, bg = colors.bg },
		TelescopePromptCounter = { fg = colors.dark_fg },
		TelescopePromptPrefix = { fg = colors.const },
		TelescopePromptTitle = { fg = colors.keyword, bold = true },
		TelescopeResultsBorder = { fg = colors.float_border, bg = colors.bg },
		TelescopeResultsTitle = { fg = colors.string, bold = true },
		TelescopeSelection = { bg = colors.selection },
		TelescopeSelectionCaret = { fg = colors.func },

		FzfLuaNormal = { bg = colors.bg, fg = colors.fg },
		FzfLuaPreviewNormal = { bg = colors.bg },
		FzfLuaBorder = { fg = colors.float_border, bg = colors.bg },
		FzfLuaTitle = { bg = colors.cursor_line_num, fg = colors.bg },

		FzfLuaFzfMatch = { fg = colors.type },
		FzfLuaFzfQuery = { fg = colors.string },
		FzfLuaFzfPrompt = { fg = colors.fg },
		FzfLuaFzfGutter = { bg = colors.bg },
		FzfLuaFzfPointer = { fg = colors.decorator },
		FzfLuaFzfHeader = { fg = colors.cursor_line_num },
		FzfLuaFzfInfo = { fg = colors.keyword },
		FzfLuaFzfCursorLine = { fg = colors.special, bg = colors.cursor_line },
		FzfLuaFzfNormal = { fg = colors.fg },

		-- nvim-cmp improvements
		CmpItemAbbr = { fg = colors.fg },
		CmpItemAbbrDeprecated = { fg = colors.dark_fg, strikethrough = true },
		CmpItemAbbrMatch = { fg = colors.func, bold = true },
		CmpItemAbbrMatchFuzzy = { fg = colors.func },
		CmpItemKind = { fg = colors.type },
		CmpItemMenu = { fg = colors.comment },
		CmpItemKindClass = { fg = colors.type },
		CmpItemKindConstant = { fg = colors.const },
		CmpItemKindConstructor = { fg = colors.func },
		CmpItemKindEnum = { fg = colors.type },
		CmpItemKindEnumMember = { fg = colors.const },
		CmpItemKindField = { fg = colors.parameter },
		CmpItemKindFunction = { fg = colors.func },
		CmpItemKindInterface = { fg = colors.type },
		CmpItemKindKeyword = { fg = colors.keyword },
		CmpItemKindMethod = { fg = colors.func },
		CmpItemKindModule = { fg = colors.namespace },
		CmpItemKindOperator = { fg = colors.operator },
		CmpItemKindProperty = { fg = colors.parameter },
		CmpItemKindReference = { fg = colors.parameter },
		CmpItemKindSnippet = { fg = colors.string },
		CmpItemKindStruct = { fg = colors.type },
		CmpItemKindTypeParameter = { fg = colors.parameter },
		CmpItemKindUnit = { fg = colors.const },
		CmpItemKindValue = { fg = colors.const },
		CmpItemKindVariable = { fg = colors.variable },

		-- blink-cmp integration
		BlinkCmpLabelDeprecated = { fg = colors.dark_fg, strikethrough = true },
		BlinkCmpLabelMatch = { fg = colors.fg, bold = true },
		BlinkCmpKindText = { fg = colors.type },
		BlinkCmpKindMethod = { fg = colors.func },
		BlinkCmpKindFunction = { fg = colors.func },
		BlinkCmpKindConstructor = { fg = colors.string },
		BlinkCmpKindField = { fg = colors.string },
		BlinkCmpKindVariable = { fg = colors.variable },
		BlinkCmpKindClass = { fg = colors.keyword },
		BlinkCmpKindInterface = { fg = colors.parameter },
		BlinkCmpKindModule = { fg = colors.func },
		BlinkCmpKindProperty = { fg = colors.const },
		BlinkCmpKindUnit = { fg = colors.string },
		BlinkCmpKindValue = { fg = colors.cursor_line_num },
		BlinkCmpKindEnum = { fg = colors.parameter },
		BlinkCmpKindKeyword = { fg = colors.keyword },
		BlinkCmpKindSnippet = { fg = colors.const },
		BlinkCmpKindColor = { fg = colors.error },
		BlinkCmpKindFile = { fg = colors.string },
		BlinkCmpKindReference = { fg = colors.type },
		BlinkCmpKindFolder = { fg = colors.variable },
		BlinkCmpKindEnumMember = { fg = colors.keyword },
		BlinkCmpKindConstant = { fg = colors.const },
		BlinkCmpKindStruct = { fg = colors.string },
		BlinkCmpKindEvent = { fg = colors.func },
		BlinkCmpKindOperator = { fg = colors.type },
		BlinkCmpKindTypeParameter = { fg = colors.error },
		BlinkCmpKindCopilot = { fg = colors.type },
		BlinkCmpMenu = { link = "Pmenu" },
		BlinkCmpMenuBorder = { link = "FloatBorder" },
		BlinkCmpDoc = { link = "Pmenu" },
		BlinkCmpDocBorder = { link = "FloatBorder" },
		-- Neotree improvements
		NeoTreeNormal = { fg = colors.fg, bg = colors.bg },
		NeoTreeNormalNC = { fg = colors.dark_fg, bg = colors.bg },
		NeoTreeVertSplit = { fg = colors.border },
		NeoTreeWinSeparator = { fg = colors.border },
		NeoTreeEndOfBuffer = { fg = colors.bg, bg = colors.bg },
		NeoTreeRootName = { fg = colors.func, bold = true },
		NeoTreeGitAdded = { fg = colors.git_add },
		NeoTreeGitConflict = { fg = colors.error },
		NeoTreeGitDeleted = { fg = colors.git_delete },
		NeoTreeGitIgnored = { fg = colors.dark_fg },
		NeoTreeGitModified = { fg = colors.git_change },
		NeoTreeGitUnstaged = { fg = colors.warning },
		NeoTreeGitUntracked = { fg = colors.git_add, italic = true },
		NeoTreeIndentMarker = { fg = colors.border },
		NeoTreeExpander = { fg = colors.dark_fg },
		NeoTreeFloatBorder = { fg = colors.float_border },
		NeoTreeFloatTitle = { fg = colors.func, bold = true },
		NeoTreeTitleBar = { fg = colors.fg, bg = colors.ui_active },
		NeoTreeDirectoryName = { fg = colors.fg },
		NeoTreeDirectoryIcon = { fg = colors.folder_icon or colors.info },
		NeoTreeFileIcon = { fg = colors.file_icon or colors.dark_fg },
		NeoTreeFileName = { fg = colors.fg },
		NeoTreeFileNameOpened = { fg = colors.func },
		NeoTreeFilterTerm = { fg = colors.string, bold = true },
		NeoTreeModified = { fg = colors.warning },
		NeoTreeMessage = { fg = colors.dark_fg, italic = true },

		-- Notify improvements
		NotifyERRORBorder = { fg = colors.error },
		NotifyWARNBorder = { fg = colors.warning },
		NotifyINFOBorder = { fg = colors.info },
		NotifyDEBUGBorder = { fg = colors.comment },
		NotifyTRACEBorder = { fg = colors.hint },
		NotifyERRORIcon = { fg = colors.error },
		NotifyWARNIcon = { fg = colors.warning },
		NotifyINFOIcon = { fg = colors.info },
		NotifyDEBUGIcon = { fg = colors.comment },
		NotifyTRACEIcon = { fg = colors.hint },
		NotifyERRORTitle = { fg = colors.error, bold = true },
		NotifyWARNTitle = { fg = colors.warning, bold = true },
		NotifyINFOTitle = { fg = colors.info, bold = true },
		NotifyDEBUGTitle = { fg = colors.comment, bold = true },
		NotifyTRACETitle = { fg = colors.hint, bold = true },
		NotifyERRORBody = { fg = colors.fg },
		NotifyWARNBody = { fg = colors.fg },
		NotifyINFOBody = { fg = colors.fg },
		NotifyDEBUGBody = { fg = colors.fg },
		NotifyTRACEBody = { fg = colors.fg },

		-- WhichKey
		WhichKey = { fg = colors.func },
		WhichKeyGroup = { fg = colors.type, bold = true },
		WhichKeyDesc = { fg = colors.fg },
		WhichKeyBorder = { fg = colors.float_border },
		WhichKeyFloat = { bg = colors.popup_back },
		WhichKeyValue = { fg = colors.dark_fg },
		WhichKeySeparator = { fg = colors.border },

		-- Indent Blankline v3
		IblIndent = { fg = colors.border },
		IblScope = { fg = colors.dark_fg, nocombine = true },
		IblWhitespace = { fg = colors.border },

		-- Navic (LSP breadcrumbs)
		NavicIconsArray = { fg = colors.type },
		NavicIconsBoolean = { fg = colors.const },
		NavicIconsClass = { fg = colors.type },
		NavicIconsConstant = { fg = colors.const },
		NavicIconsConstructor = { fg = colors.func },
		NavicIconsEnum = { fg = colors.type },
		NavicIconsEnumMember = { fg = colors.const },
		NavicIconsEvent = { fg = colors.type },
		NavicIconsField = { fg = colors.parameter },
		NavicIconsFile = { fg = colors.fg },
		NavicIconsFunction = { fg = colors.func },
		NavicIconsInterface = { fg = colors.type },
		NavicIconsKey = { fg = colors.keyword },
		NavicIconsMethod = { fg = colors.func },
		NavicIconsModule = { fg = colors.namespace },
		NavicIconsNamespace = { fg = colors.namespace },
		NavicIconsNull = { fg = colors.const },
		NavicIconsNumber = { fg = colors.number },
		NavicIconsObject = { fg = colors.type },
		NavicIconsOperator = { fg = colors.operator },
		NavicIconsPackage = { fg = colors.namespace },
		NavicIconsProperty = { fg = colors.parameter },
		NavicIconsString = { fg = colors.string },
		NavicIconsStruct = { fg = colors.type },
		NavicIconsTypeParameter = { fg = colors.parameter },
		NavicIconsVariable = { fg = colors.variable },
		NavicSeparator = { fg = colors.border },
		NavicText = { fg = colors.fg },

		-- Noice
		NoiceCmdline = { fg = colors.fg, bg = colors.bg },
		NoiceCmdlineIcon = { fg = colors.const },
		NoiceCmdlineIconSearch = { fg = colors.warning },
		NoiceCmdlinePopup = { bg = colors.popup_back },
		NoiceCmdlinePopupBorder = { fg = colors.float_border },
		NoiceCmdlinePopupTitle = { fg = colors.func, bold = true },
		NoiceConfirm = { bg = colors.popup_back },
		NoiceConfirmBorder = { fg = colors.float_border },
		NoiceCursor = { fg = colors.bg, bg = colors.fg },
		NoiceMini = { fg = colors.fg, bg = colors.bg },
		NoicePopup = { bg = colors.popup_back },
		NoicePopupBorder = { fg = colors.float_border },
		NoicePopupmenu = { bg = colors.popup_back },
		NoicePopupmenuBorder = { fg = colors.float_border },
		NoicePopupmenuMatch = { fg = colors.func, bold = true },
		NoicePopupmenuSelected = { bg = colors.selection },

		-- nvim-dap
		DapBreakpoint = { fg = colors.error },
		DapBreakpointCondition = { fg = colors.warning },
		DapBreakpointRejected = { fg = colors.error, italic = true },
		DapLogPoint = { fg = colors.info },
		DapStopped = { fg = colors.warning, bold = true },
		DapUIBreakpoints = { fg = colors.error },
		DapUIBreakpointsCurrentLine = { fg = colors.warning, bold = true },
		DapUIBreakpointsDisabledLine = { fg = colors.dark_fg },
		DapUIBreakpointsInfo = { fg = colors.info },
		DapUIBreakpointsPath = { fg = colors.info },
		DapUIDecoration = { fg = colors.float_border },
		DapUIFloatBorder = { fg = colors.float_border },
		DapUILineNumber = { fg = colors.line_numbers },
		DapUIModifiedValue = { fg = colors.warning, bold = true },
		DapUIScope = { fg = colors.type, bold = true },
		DapUISource = { fg = colors.string },
		DapUIStoppedThread = { fg = colors.warning },
		DapUIType = { fg = colors.type },
		DapUIValue = { fg = colors.fg },
		DapUIVariable = { fg = colors.variable },
		DapUIWatchesEmpty = { fg = colors.dark_fg },
		DapUIWatchesError = { fg = colors.error },
		DapUIWatchesValue = { fg = colors.const },

		-- Lazy
		LazyButton = { bg = colors.bg },
		LazyButtonActive = { fg = colors.keyword, bg = colors.light_bg, bold = true },
		LazyComment = { fg = colors.comment },
		LazyCommit = { fg = colors.const },
		LazyCommitIssue = { fg = colors.number },
		LazyCommitScope = { fg = colors.type },
		LazyCommitType = { fg = colors.keyword },
		LazyDir = { fg = colors.info },
		LazyH1 = { fg = colors.keyword, bold = true },
		LazyH2 = { fg = colors.func, bold = true },
		LazyNoCond = { fg = colors.dark_fg },
		LazyNormal = { bg = colors.bg },
		LazyProgressDone = { fg = colors.git_add },
		LazyProgressTodo = { fg = colors.dark_fg },
		LazyProp = { fg = colors.parameter },
		LazyReasonCmd = { fg = colors.keyword },
		LazyReasonEvent = { fg = colors.const },
		LazyReasonFt = { fg = colors.type },
		LazyReasonImport = { fg = colors.string },
		LazyReasonKeys = { fg = colors.keyword },
		LazyReasonPlugin = { fg = colors.func },
		LazyReasonRuntime = { fg = colors.comment },
		LazyReasonSource = { fg = colors.string },
		LazyReasonStart = { fg = colors.git_add },
		LazySpecial = { fg = colors.keyword },
		LazyTaskError = { fg = colors.error },
		LazyTaskOutput = { fg = colors.fg },
		LazyUrl = { fg = colors.string, underline = true },
		LazyValue = { fg = colors.const },

		-- Additional editor UI elements
		FloatTitle = { fg = colors.func, bold = true },
		FloatFooter = { fg = colors.dark_fg },
		QuickFixLine = { bg = colors.selection },
		ColorColumn = { bg = colors.cursor_line },
		SignColumnSB = { bg = colors.bg },
		Conceal = { fg = colors.dark_fg },
		NonText = { fg = colors.border },
		SpecialKey = { fg = colors.border },
		Substitute = { fg = colors.bg, bg = colors.error },

		-- Markdown
		markdownH1 = { fg = colors.keyword, bold = true },
		markdownH2 = { fg = colors.func, bold = true },
		markdownH3 = { fg = colors.type, bold = true },
		markdownH4 = { fg = colors.const, bold = true },
		markdownH5 = { fg = colors.namespace, bold = true },
		markdownH6 = { fg = colors.parameter, bold = true },
		markdownCode = { fg = colors.string, bg = colors.bg },
		markdownCodeBlock = { fg = colors.string },
		markdownBlockquote = { fg = colors.comment, italic = true },
		markdownLink = { fg = colors.func, underline = true },
		markdownUrl = { fg = colors.string, underline = true },
		markdownLinkText = { fg = colors.func },
		markdownListMarker = { fg = colors.const },

		-- Treesitter Context
		TreesitterContext = { bg = colors.bg },
		TreesitterContextLineNumber = { fg = colors.line_numbers, bg = colors.bg },
		TreesitterContextBottom = { underline = true, sp = colors.border },

		-- Illuminate (word highlighting)
		IlluminatedWordText = { bg = colors.selection },
		IlluminatedWordRead = { bg = colors.selection },
		IlluminatedWordWrite = { bg = colors.selection },

		-- Hop (motion)
		HopNextKey = { fg = colors.error, bold = true },
		HopNextKey1 = { fg = colors.func, bold = true },
		HopNextKey2 = { fg = colors.hint },
		HopUnmatched = { fg = colors.dark_fg },
		HopPreview = { fg = colors.const, bold = true },

		-- LSP Signature
		LspSignatureActiveParameter = { fg = colors.func, bold = true },
		LspSignatureHintHL = { fg = colors.hint, italic = true },
		LspInlayHint = { fg = colors.comment, italic = true },
		LspReferenceText = { bg = colors.selection },
		LspReferenceRead = { bg = colors.selection },
		LspReferenceWrite = { bg = colors.selection, bold = true },

		-- LSP Code Lens
		LspCodeLens = { fg = colors.comment, italic = true },
		LspCodeLensText = { fg = colors.comment, italic = true },
		LspCodeLensRefresh = { fg = colors.info },

		-- LSP Saga enhancements
		LspSagaSignatureHelpBorder = { fg = colors.border },
		LspSagaDefPreviewBorder = { fg = colors.border },
		LspSagaRenameBorder = { fg = colors.border },
		LspSagaHoverBorder = { fg = colors.border },
		LspSagaCodeActionBorder = { fg = colors.border },
		LspSagaFinderSelection = { fg = colors.func },
		LspSagaLspFinderBorder = { fg = colors.border },
		LspSagaAutoPreview = { fg = colors.comment },
		TargetWord = { fg = colors.func, bold = true },

		-- Gitsigns
		GitSignsCurrentLineBlame = { fg = colors.dark_fg, italic = true },
		GitSignsAddInline = { fg = colors.git_add },
		GitSignsChangeInline = { fg = colors.git_change },
		GitSignsDeleteInline = { fg = colors.git_delete },

		-- Neotest
		NeotestAdapterName = { fg = colors.const, bold = true },
		NeotestDir = { fg = colors.info },
		NeotestExpandMarker = { fg = colors.border },
		NeotestFailed = { fg = colors.error },
		NeotestFile = { fg = colors.fg },
		NeotestFocused = { bold = true },
		NeotestIndent = { fg = colors.border },
		NeotestMarked = { fg = colors.warning, bold = true },
		NeotestNamespace = { fg = colors.namespace },
		NeotestPassed = { fg = colors.git_add },
		NeotestRunning = { fg = colors.warning },
		NeotestSkipped = { fg = colors.dark_fg },
		NeotestTarget = { fg = colors.func },
		NeotestTest = { fg = colors.fg },
		NeotestWinSelect = { fg = colors.func, bold = true },

		-- RenderMarkdown
		RenderMarkdownCode = { bg = colors.ui_bg },
		RenderMarkdownCodeInline = { bg = colors.light_bg, fg = colors.cursor_line_num },
		RenderMarkdownBullet = { fg = colors.special },
		RenderMarkdownTableHead = { fg = colors.blue },
		RenderMarkdownTableRow = { fg = colors.border },
		RenderMarkdownSuccess = { fg = colors.green },
		RenderMarkdownInfo = { fg = colors.hint },
		RenderMarkdownHint = { fg = colors.teal },
		RenderMarkdownWarn = { fg = colors.yellow },
		RenderMarkdownError = { fg = colors.red },
		RenderMarkdownH1Bg = { bg = colors.ui_bg, fg = colors.purple },
		RenderMarkdownH2Bg = { bg = colors.ui_bg, fg = colors.pink },
		RenderMarkdownH3Bg = { bg = colors.ui_bg, fg = colors.cyan },
		RenderMarkdownH4Bg = { bg = colors.ui_bg, fg = colors.teal },
		RenderMarkdownH5Bg = { bg = colors.ui_bg, fg = colors.green },
		RenderMarkdownH6Bg = { bg = colors.ui_bg, fg = colors.brown },

		RenderMarkdownQuote1 = { bg = colors.ui_bg, fg = colors.purple },
		RenderMarkdownQuote2 = { bg = colors.ui_bg, fg = colors.pink },
		RenderMarkdownQuote3 = { bg = colors.ui_bg, fg = colors.cyan },
		RenderMarkdownQuote4 = { bg = colors.ui_bg, fg = colors.teal },
		RenderMarkdownQuote5 = { bg = colors.ui_bg, fg = colors.green },
		RenderMarkdownQuote6 = { bg = colors.ui_bg, fg = colors.brown },

		-- Alpha (dashboard)
		AlphaHeader = { fg = colors.const },
		AlphaButtons = { fg = colors.func },
		AlphaShortcut = { fg = colors.keyword },
		AlphaFooter = { fg = colors.comment, italic = true },

		-- Fidget (LSP progress)
		FidgetTask = { fg = colors.dark_fg },
		FidgetTitle = { fg = colors.func, bold = true },

		-- Bqf (quickfix improvements)
		BqfPreviewBorder = { fg = colors.float_border },
		BqfPreviewRange = { bg = colors.selection },
		BqfSign = { fg = colors.func },

		-- Trouble
		TroubleCount = { fg = colors.const },
		TroubleError = { fg = colors.error },
		TroubleNormal = { fg = colors.fg },
		TroubleTextInformation = { fg = colors.info },
		TroubleSignError = { fg = colors.error },
		TroubleLocation = { fg = colors.dark_fg },
		TroubleCode = { fg = colors.comment },
		TroubleTextError = { fg = colors.error },
		TroubleSignWarning = { fg = colors.warning },
		TroubleWarning = { fg = colors.warning },
		TroublePreview = { fg = colors.func },
		TroubleTextWarning = { fg = colors.warning },
		TroubleSignInformation = { fg = colors.info },
		TroubleIndent = { fg = colors.border },
		TroubleSource = { fg = colors.dark_fg },
		TroubleSignHint = { fg = colors.hint },
		TroubleTextHint = { fg = colors.hint },
		TroubleFoldIcon = { fg = colors.comment },
		TroubleHint = { fg = colors.hint },
		TroubleText = { fg = colors.fg },
		TroubleInformation = { fg = colors.info },
		TroubleFile = { fg = colors.info },

		-- Aerial (code outline)
		AerialArrayIcon = { fg = colors.type },
		AerialBooleanIcon = { fg = colors.const },
		AerialClassIcon = { fg = colors.type },
		AerialConstantIcon = { fg = colors.const },
		AerialConstructorIcon = { fg = colors.func },
		AerialEnumIcon = { fg = colors.type },
		AerialEnumMemberIcon = { fg = colors.const },
		AerialEventIcon = { fg = colors.type },
		AerialFieldIcon = { fg = colors.parameter },
		AerialFileIcon = { fg = colors.fg },
		AerialFunctionIcon = { fg = colors.func },
		AerialInterfaceIcon = { fg = colors.type },
		AerialKeyIcon = { fg = colors.keyword },
		AerialMethodIcon = { fg = colors.func },
		AerialModuleIcon = { fg = colors.namespace },
		AerialNamespaceIcon = { fg = colors.namespace },
		AerialNullIcon = { fg = colors.const },
		AerialNumberIcon = { fg = colors.number },
		AerialObjectIcon = { fg = colors.type },
		AerialOperatorIcon = { fg = colors.operator },
		AerialPackageIcon = { fg = colors.namespace },
		AerialPropertyIcon = { fg = colors.parameter },
		AerialStringIcon = { fg = colors.string },
		AerialStructIcon = { fg = colors.type },
		AerialTypeParameterIcon = { fg = colors.parameter },
		AerialVariableIcon = { fg = colors.variable },
		AerialLine = { fg = colors.border },
		AerialLineNC = { fg = colors.dark_fg },
		AerialGuide = { fg = colors.border },
		AerialNormal = { fg = colors.fg },

		-- SuperMaven
		SuperMavenSuggestion = { fg = colors.line_numbers },

		-- Additional language-specific highlights
		-- HTML
		htmlArg = { fg = colors.parameter },
		htmlBold = { bold = true },
		htmlEndTag = { fg = colors.fg },
		htmlH1 = { fg = colors.keyword, bold = true },
		htmlH2 = { fg = colors.func, bold = true },
		htmlH3 = { fg = colors.type, bold = true },
		htmlH4 = { fg = colors.const, bold = true },
		htmlH5 = { fg = colors.namespace, bold = true },
		htmlH6 = { fg = colors.parameter, bold = true },
		htmlItalic = { italic = true },
		htmlLink = { fg = colors.func, underline = true },
		htmlSpecialChar = { fg = colors.const },
		htmlSpecialTagName = { fg = colors.keyword },
		htmlTag = { fg = colors.fg },
		htmlTagN = { fg = colors.keyword },
		htmlTagName = { fg = colors.keyword },
		htmlTitle = { fg = colors.fg },

		-- CSS
		cssAtRule = { fg = colors.keyword },
		cssAttr = { fg = colors.const },
		cssClassName = { fg = colors.type },
		cssColor = { fg = colors.number },
		cssDefinition = { fg = colors.parameter },
		cssIdentifier = { fg = colors.variable },
		cssImportant = { fg = colors.error },
		cssMediaType = { fg = colors.type },
		cssProp = { fg = colors.parameter },
		cssPseudoClass = { fg = colors.func },
		cssPseudoClassId = { fg = colors.func },
		cssTagName = { fg = colors.keyword },
		cssUnitDecorators = { fg = colors.const },
		cssValueLength = { fg = colors.number },
		cssValueNumber = { fg = colors.number },
		cssValueTime = { fg = colors.number },
		cssVendor = { fg = colors.comment },

		-- JavaScript/TypeScript
		typescriptArrayMethod = { fg = colors.func },
		typescriptArrowFunc = { fg = colors.operator },
		typescriptAssign = { fg = colors.operator },
		typescriptBOM = { fg = colors.type },
		typescriptBOMWindowMethod = { fg = colors.func },
		typescriptBinaryOp = { fg = colors.operator },
		typescriptBraces = { fg = colors.fg },
		typescriptCall = { fg = colors.fg },
		typescriptClassHeritage = { fg = colors.type },
		typescriptClassName = { fg = colors.type },
		typescriptDateMethod = { fg = colors.func },
		typescriptDecorator = { fg = colors.decorator },
		typescriptDOMDocMethod = { fg = colors.func },
		typescriptDOMEventTargetMethod = { fg = colors.func },
		typescriptDOMNodeMethod = { fg = colors.func },
		typescriptDOMStorageMethod = { fg = colors.func },
		typescriptEndColons = { fg = colors.fg },
		typescriptExport = { fg = colors.keyword },
		typescriptFuncName = { fg = colors.func },
		typescriptFuncTypeArrow = { fg = colors.operator },
		typescriptGlobal = { fg = colors.type },
		typescriptIdentifier = { fg = colors.variable },
		typescriptInterfaceName = { fg = colors.type },
		typescriptMember = { fg = colors.parameter },
		typescriptMethodAccessor = { fg = colors.keyword },
		typescriptModule = { fg = colors.namespace },
		typescriptObjectMethod = { fg = colors.func },
		typescriptParens = { fg = colors.fg },
		typescriptPredefinedType = { fg = colors.type },
		typescriptTypeAnnotation = { fg = colors.type },
		typescriptTypeBrackets = { fg = colors.fg },
		typescriptTypeReference = { fg = colors.type },
		typescriptVariable = { fg = colors.keyword },

		-- Python
		pythonBuiltin = { fg = colors.func },
		pythonClassVar = { fg = colors.variable },
		pythonDecorator = { fg = colors.decorator },
		pythonDottedName = { fg = colors.namespace },
		pythonException = { fg = colors.error },
		pythonExceptions = { fg = colors.type },
		pythonFunction = { fg = colors.func },
		pythonImport = { fg = colors.keyword },
		pythonInclude = { fg = colors.keyword },
		pythonOperator = { fg = colors.operator },
		pythonRun = { fg = colors.comment },
		pythonStatement = { fg = colors.keyword },

		-- Rust
		rustAssert = { fg = colors.keyword },
		rustAttribute = { fg = colors.attribute },
		rustCharacter = { fg = colors.string },
		rustDerive = { fg = colors.attribute },
		rustDeriveTrait = { fg = colors.type },
		rustEnumVariant = { fg = colors.const },
		rustFuncCall = { fg = colors.func },
		rustFuncName = { fg = colors.func },
		rustIdentifier = { fg = colors.variable },
		rustKeyword = { fg = colors.keyword },
		rustLifetime = { fg = colors.const, italic = true },
		rustMacro = { fg = colors.func },
		rustModPath = { fg = colors.namespace },
		rustModPathSep = { fg = colors.fg },
		rustNamespace = { fg = colors.namespace },
		rustOperator = { fg = colors.operator },
		rustPubScopeCrate = { fg = colors.keyword },
		rustSelf = { fg = colors.keyword },
		rustSigil = { fg = colors.operator },
		rustStorage = { fg = colors.keyword },
		rustStructure = { fg = colors.keyword },
		rustTrait = { fg = colors.type },
		rustType = { fg = colors.type },

		-- Go
		goBuiltins = { fg = colors.func },
		goConditional = { fg = colors.keyword },
		goDeclaration = { fg = colors.keyword },
		goDeclType = { fg = colors.type },
		goDirective = { fg = colors.keyword },
		goFloats = { fg = colors.number },
		goFunction = { fg = colors.func },
		goFunctionCall = { fg = colors.func },
		goImport = { fg = colors.keyword },
		goLabel = { fg = colors.label },
		goMethod = { fg = colors.func },
		goPackage = { fg = colors.namespace },
		goSignedInts = { fg = colors.type },
		goStruct = { fg = colors.type },
		goStructDef = { fg = colors.type },
		goUnsignedInts = { fg = colors.type },

		-- JSON
		jsonBraces = { fg = colors.fg },
		jsonCommentError = { fg = colors.error },
		jsonKeyword = { fg = colors.parameter },
		jsonKeywordMatch = { fg = colors.operator },
		jsonNoQuotesError = { fg = colors.error },
		jsonNumError = { fg = colors.error },
		jsonNumber = { fg = colors.number },
		jsonQuote = { fg = colors.fg },
		jsonString = { fg = colors.string },
		jsonStringSQError = { fg = colors.error },
		jsonTrailingCommaError = { fg = colors.error },

		-- YAML
		yamlAnchor = { fg = colors.parameter },
		yamlBlockCollectionItemStart = { fg = colors.operator },
		yamlBlockMappingKey = { fg = colors.parameter },
		yamlBlockMappingMerge = { fg = colors.operator },
		yamlDocumentStart = { fg = colors.comment },
		yamlFlowCollection = { fg = colors.operator },
		yamlFlowIndicator = { fg = colors.operator },
		yamlFlowMappingKey = { fg = colors.parameter },
		yamlKey = { fg = colors.parameter },
		yamlKeyValueDelimiter = { fg = colors.operator },
		yamlNodeTag = { fg = colors.type },
		yamlPlainScalar = { fg = colors.string },
		yamlTodo = { fg = colors.comment },
	}

	return h
end

function M.setup(opts)
	-- Merge user options with default config
	opts = config.extend(vim.tbl_deep_extend("force", config, opts or {}))

	-- Determine colors based on background
	local colors = vim.o.background == "dark" and dark or light

	-- Set colorscheme name and clear existing highlights
	vim.g.colors_name = vim.o.background == "dark" and "aye" or "aye-light"
	-- vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	-- Load and apply highlights
	local highlights = load_highlights(colors, opts)
	for group, settings in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, settings)
	end

	-- Set terminal colors
	for i, color in pairs(colors.terminal) do
		vim.g["terminal_color_" .. (i == "black" and 0 or i == "red" and 1 or i == "green" and 2 or i == "yellow" and 3 or i == "blue" and 4 or i == "magenta" and 5 or i == "cyan" and 6 or i == "white" and 7 or i == "bright_black" and 8 or i == "bright_red" and 9 or i == "bright_green" and 10 or i == "bright_yellow" and 11 or i == "bright_blue" and 12 or i == "bright_magenta" and 13 or i == "bright_cyan" and 14 or i == "bright_white" and 15)] =
			color
	end

	-- Enhanced lualine theme with better mode distinction
	M.lualine_theme = {
		normal = {
			a = { fg = colors.bg, bg = colors.func, gui = "bold" },
			b = { fg = colors.fg, bg = colors.lighter_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
		insert = {
			a = { fg = colors.bg, bg = colors.string, gui = "bold" },
			b = { fg = colors.string, bg = colors.lighter_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
		visual = {
			a = { fg = colors.bg, bg = colors.keyword, gui = "bold" },
			b = { fg = colors.keyword, bg = colors.lighter_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
		replace = {
			a = { fg = colors.bg, bg = colors.error, gui = "bold" },
			b = { fg = colors.error, bg = colors.lighter_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
		command = {
			a = { fg = colors.bg, bg = colors.const, gui = "bold" },
			b = { fg = colors.const, bg = colors.lighter_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
		inactive = {
			a = { fg = colors.dark_fg, bg = colors.ui_bg },
			b = { fg = colors.dark_fg, bg = colors.ui_bg },
			c = { fg = colors.dark_fg, bg = colors.transparent },
		},
	}

	-- Optional: Set up additional integrations if plugins are detected
	if package.loaded["lualine"] then
		require("lualine").setup({ options = { theme = M.lualine_theme } })
	end

	-- Store current configuration for toggle
	M.current_config = opts
end

function M.toggle()
	-- Store current buffer state to preserve cursor position
	local current_win = vim.api.nvim_get_current_win()
	local current_pos = vim.api.nvim_win_get_cursor(current_win)

	-- Toggle background and apply new theme
	if vim.o.background == "dark" then
		vim.o.background = "light"
		vim.g.colors_name = "aye-light"
		vim.notify("Switched to Aye Light theme", vim.log.levels.INFO, { title = "Aye Theme", source = "Aye" })
	else
		vim.o.background = "dark"
		vim.g.colors_name = "aye"
		vim.notify("Switched to Aye Dark theme", vim.log.levels.INFO, { title = "Aye Theme", source = "Aye" })
	end

	-- Reapply setup with preserved config
	M.setup(M.current_config or config)

	-- Restore cursor position
	pcall(vim.api.nvim_win_set_cursor, current_win, current_pos)

	-- Trigger redraw and syntax refresh
	vim.cmd("redraw!")
	vim.cmd("syntax sync fromstart")
end

function M.load(config)
	-- Create user command with completion
	vim.api.nvim_create_user_command("AyeToggle", function()
		M.toggle()
	end, {
		desc = "Toggle between Aye dark and light themes",
		nargs = 0,
	})

	-- Initial setup with default config
	M.setup(config)
end

function M.get_colors()
	if vim.o.background == "dark" then
		return dark
	else
		return light
	end
end

return M
