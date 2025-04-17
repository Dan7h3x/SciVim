local M = {}
local config = require("aye.config")



local dark = {
  -- Base colors
  bg = "#1e1e2f",          -- Slightly lighter for better contrast
  fg = "#dcdfe4",          -- Softer foreground color
  comment = "#a0a0a0",     -- Softer comment color
  selection = "#3a3a4d",   -- More muted selection color
  cursor_line = "#2a2a3a", -- Softer cursor line
  transparent = "NONE",

  -- UI elements
  border = "#4b4b5b",          -- Softer border color
  line_numbers = "#7a7a8a",    -- Softer line numbers
  cursor_line_num = "#9ab4f8", -- Softer cursor line number
  float_border = "#4b4b5b",
  popup_back = "#1c1c2f",      -- Softer popup background
  lighter_bg = "#2a2a3a",
  light_bg = "#3a3a4d",
  dark_fg = "#a0a0a0",
  ui_bg = "#2a2a3a",
  ui_fg = "#dcdfe4",
  ui_active = "#9ab4f8",
  ui_inactive = "#2a2a3a",

  -- Syntax
  attribute = "#98c379",
  string = "#9ee7d8",
  number = "#f8b886",
  func = "#8ab4f8",
  keyword = "#c4a7e7",
  type = "#7dcfff",
  const = "#f8b886",
  variable = "#12f8f0",
  parameter = "#ffd394",
  operator = "#89ddff",
  namespace = "#7dcfff",
  decorator = "#c4a7e7",

  -- Diagnostics
  error = "#ff6f6f",   -- Softer error color
  warning = "#ffb86c", -- Softer warning color
  info = "#8ab4f8",
  hint = "#9ee7d8",
  error_bg = "#3c2829",
  warning_bg = "#3c2e24",
  info_bg = "#24344d",
  hint_bg = "#233942",

  -- Git colors
  git_add = "#9ee7d8",
  git_change = "#f8b886",
  git_delete = "#ff6f6f",

  -- Terminal colors
  terminal = {
    black = "#1e1e2f",
    red = "#ff6f6f",
    green = "#9ee7d8",
    yellow = "#ffd394",
    blue = "#8ab4f8",
    magenta = "#c4a7e7",
    cyan = "#89ddff",
    white = "#dcdfe4",
    bright_black = "#7f8c98",
    bright_red = "#ff8787",
    bright_green = "#b4f8d8",
    bright_yellow = "#ffe0b4",
    bright_blue = "#a7ceff",
    bright_magenta = "#d8beff",
    bright_cyan = "#a7ecff",
    bright_white = "#f0f4f8",
  },
}


local light = {
  -- Base colors
  bg = "#f7f7f7",      -- Softer background
  fg = "#2c2c2c",      -- Darkened slightly for better contrast
  comment = "#6b7280", -- Softer comment color
  selection = "#e2e8f0",
  cursor_line = "#f1f5f9",
  transparent = "NONE",

  -- UI elements
  border = "#6b7280",
  line_numbers = "#6b7280",
  cursor_line_num = "#2563eb",
  float_border = "#6b7280",
  popup_back = "#f0eae0",
  lighter_bg = "#faf7f5",
  light_bg = "#f8f4f2",
  dark_fg = "#6b7280",
  ui_bg = "#f8f4f2",
  ui_fg = "#2c2c2c",
  ui_active = "#a7ceff",
  ui_inactive = "#f8fafc",

  -- Syntax
  string = "#0f766e",
  number = "#c2410c",
  func = "#2563eb",
  keyword = "#7c3aed",
  type = "#0284c7",
  const = "#c2410c",
  variable = "#2c2c2c", -- Darkened slightly for better contrast
  parameter = "#b45309",
  operator = "#0284c7",
  namespace = "#0284c7",
  decorator = "#7c3aed",

  -- Diagnostics
  error = "#dc2626",   -- Softer error color
  warning = "#d97706", -- Softer warning color
  info = "#2563eb",
  hint = "#0f766e",
  error_bg = "#fef2f2",
  warning_bg = "#fff7ed",
  info_bg = "#f0f7ff",
  hint_bg = "#f0fdfa",

  -- Git colors
  git_add = "#0f766e",
  git_change = "#d97706",
  git_delete = "#dc2626",

  -- Terminal colors
  terminal = {
    black = "#2c2c2c",
    red = "#dc2626",
    green = "#0f766e",
    yellow = "#b45309",
    blue = "#2563eb",
    magenta = "#7c3aed",
    cyan = "#0284c7",
    white = "#6b7280",
    bright_black = "#6b7280",
    bright_red = "#ef4444",
    bright_green = "#10b981",
    bright_yellow = "#d97706",
    bright_blue = "#3b82f6",
    bright_magenta = "#8b5cf6",
    bright_cyan = "#06b6d4",
    bright_white = "#1e293b",
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
    ["@string"] = { fg = colors.string, italic = opts.styles.strings.italic },
    ["@string.regex"] = { fg = colors.regex },
    ["@type"] = { fg = colors.type },
    ["@variable"] = { fg = colors.variable },
    ["@variable.builtin"] = { fg = colors.const, italic = true },

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
    ["@lsp.type.unresolvedReference"] = { fg = colors.error, undercurl = true },

    -- Editor UI
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.cursor_line_num, bg = colors.popup_back },
    FloatBorder = { fg = colors.float_border, bg = colors.bg },
    Cursor = { bg = colors.fg },
    CursorLine = { bg = colors.cursor_line },
    CursorLineNr = { fg = colors.cursor_line_num, bold = true },
    LineNr = { fg = colors.line_numbers },
    Selection = { bg = colors.selection },
    SignColumn = { bg = colors.bg },
    StatusLine = { fg = colors.fg, bg = colors.transparent },
    StatusLineNC = { fg = colors.dark_fg, bg = colors.transparent },
    VertSplit = { fg = colors.border },

    -- Diagnostics
    DiagnosticError = { fg = colors.error },
    DiagnosticWarn = { fg = colors.warning },
    DiagnosticInfo = { fg = colors.info },
    DiagnosticHint = { fg = colors.hint },
    DiagnosticVirtualTextError = { fg = colors.error, bg = colors.error_bg },
    DiagnosticVirtualTextWarn = { fg = colors.warning, bg = colors.warning_bg },
    DiagnosticVirtualTextInfo = { fg = colors.info, bg = colors.info_bg },
    DiagnosticVirtualTextHint = { fg = colors.hint, bg = colors.hint_bg },

    -- Git signs
    GitSignsAdd = { fg = colors.git_add },
    GitSignsChange = { fg = colors.git_change },
    GitSignsDelete = { fg = colors.git_delete },

    -- Mini.Icons
    MiniIndentscopeSymbol = { fg = colors.border },
    MiniJump = { bg = colors.selection },
    MiniJump2dSpot = { fg = colors.error, bold = true },
    MiniStarterCurrent = { nocombine = true },
    MiniStarterFooter = { fg = colors.const, italic = true },
    MiniStarterHeader = { fg = colors.keyword, bold = true },
    MiniStarterItem = { fg = colors.fg },
    MiniStarterItemBullet = { fg = colors.border },
    MiniStarterItemPrefix = { fg = colors.warning },
    MiniStarterSection = { fg = colors.type },
    MiniStarterQuery = { fg = colors.func },

    -- BufferLine integration
    BufferLineHintDiagnosticVisible = { fg = colors.hint, bg = colors.popup_back },
    BufferLineInfoDiagnosticVisible = { fg = colors.info, bg = colors.popup_back },
    BufferLineErrorDiagnosticVisible = { fg = colors.error, bg = colors.popup_back },
    BufferLineWarningDiagnosticVisible = { fg = colors.warning, bg = colors.popup_back },
    BufferLineHint = { fg = colors.hint, bg = colors.popup_back },
    BufferLineInfo = { fg = colors.info, bg = colors.popup_back },
    BufferLineError = { fg = colors.error, bg = colors.popup_back },
    BufferLineWarning = { fg = colors.warning, bg = colors.popup_back },
    BufferLineHintDiagnostic = { fg = colors.hint, bg = colors.popup_back },
    BufferLineInfoDiagnostic = { fg = colors.info, bg = colors.popup_back },
    BufferLineErrorDiagnostic = { fg = colors.error, bg = colors.popup_back },
    BufferLineWarningDiagnostic = { fg = colors.warning, bg = colors.popup_back },
    BufferLineHintDiagnosticSelected = { fg = colors.hint, bg = colors.bg },
    BufferLineInfoDiagnosticSelected = { fg = colors.info, bg = colors.bg },
    BufferLineErrorDiagnosticSelected = { fg = colors.error, bg = colors.bg },
    BufferLineWarningDiagnosticSelected = { fg = colors.warning, bg = colors.bg },
    BufferLineHintVisible = { fg = colors.hint, bg = colors.popup_back },
    BufferLineInfoVisible = { fg = colors.info, bg = colors.popup_back },
    BufferLineErrorVisible = { fg = colors.error, bg = colors.popup_back },
    BufferLineWarningVisible = { fg = colors.warning, bg = colors.popup_back },
    BufferLineHintSelected = { fg = colors.hint, bg = colors.bg },
    BufferLineInfoSelected = { fg = colors.info, bg = colors.bg },
    BufferLineErrorSelected = { fg = colors.error, bg = colors.bg },
    BufferLineWarningSelected = { fg = colors.warning, bg = colors.bg },
    BufferLineBackground = { bg = colors.popup_back },
    BufferLineBuffer = { fg = colors.dark_fg, bg = colors.bg },
    BufferLineBufferVisible = { fg = colors.fg, bg = colors.popup_back, bold = true },
    BufferLineBufferSelected = { fg = colors.cursor_line_num, bg = colors.bg },
    BufferLineDuplicate = { fg = colors.comment, bg = colors.popup_back },
    BufferLineDuplicateVisible = { fg = colors.comment, bg = colors.popup_back },
    BufferLineDuplicateSelected = { fg = colors.comment, bg = colors.bg },
    BufferLineCloseButton = { fg = colors.error, bg = colors.popup_back },
    BufferLineCloseButtonVisible = { fg = colors.error, bg = colors.popup_back },
    BufferLineCloseButtonSelected = { fg = colors.error, bg = colors.bg },
    BufferLineFill = { bg = colors.popup_back },
    BufferLineNumbersSelected = { fg = colors.cursor_line_num, bg = colors.bg },
    BufferLineNumbersVisible = { fg = colors.line_numbers, bg = colors.popup_back },
    BufferLineNumbers = { fg = colors.line_numbers, bg = colors.popup_back },
    BufferLineIndicatorVisible = { fg = colors.cursor_line_num, bg = colors.popup_back },
    BufferLineIndicatorSelected = { fg = colors.cursor_line_num, bg = colors.bg },
    BufferLineModified = { fg = colors.line_numbers, bg = colors.popup_back },
    BufferLineModifiedVisible = { fg = colors.dark_fg, bg = colors.popup_back },
    BufferLineModifiedSelected = { fg = colors.cursor_line_num, bg = colors.bg },
    BufferLineMiniIconsAzureSelected = { fg = colors.cursor_line_num, bg = colors.bg },
    BufferLineMiniIconsAzure = { fg = colors.cursor_line_num, bg = colors.popup_back },
    BufferLineMiniIconsAzureInactive = { fg = colors.cursor_line_num, bg = colors.popup_back },
    BufferLineTab = { fg = colors.dark_fg, bg = colors.popup_back },
    BufferLineTabClose = { fg = colors.error, bg = colors.popup_back },
    BufferLineTabSelected = { fg = colors.cursor_line_num, bg = colors.bg, bold = true },
    BufferLineTabSeparator = { fg = colors.border, bg = colors.popup_back },
    BufferLineTabSeparatorSelected = { fg = colors.border, bg = colors.bg },

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

    -- Mini.nvim improvements
    MiniCompletionActiveParameter = { underline = true },
    MiniCursorword = { underline = true },
    MiniCursorwordCurrent = { underline = true },

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

    -- Dropbar
    DropBarIconCurrent = { fg = colors.func, bold = true },
    DropBarIconKind = { fg = colors.type },
    DropBarIconPath = { fg = colors.info },
    DropBarIconUi = { fg = colors.ui_fg },
    DropBarMenuHoverEntry = { bg = colors.selection },
    DropBarMenuHoverIcon = { fg = colors.func },
    DropBarMenuHoverSymbol = { fg = colors.func },
    DropBarMenuNormalEntry = { fg = colors.fg, bg = colors.popup_back },
    DropBarMenuNormalIcon = { fg = colors.type },
    DropBarMenuNormalSymbol = { fg = colors.type },
    DropBarPreview = { bg = colors.selection },
    DropBarCurrentContext = { fg = colors.func, bold = true },

    -- Dropbar symbols
    DropBarIconArrayCurrent = { fg = colors.type, bold = true },
    DropBarIconBooleanCurrent = { fg = colors.const, bold = true },
    DropBarIconClassCurrent = { fg = colors.type, bold = true },
    DropBarIconConstantCurrent = { fg = colors.const, bold = true },
    DropBarIconConstructorCurrent = { fg = colors.func, bold = true },
    DropBarIconEnumCurrent = { fg = colors.type, bold = true },
    DropBarIconEnumMemberCurrent = { fg = colors.const, bold = true },
    DropBarIconEventCurrent = { fg = colors.type, bold = true },
    DropBarIconFieldCurrent = { fg = colors.parameter, bold = true },
    DropBarIconFileCurrent = { fg = colors.fg, bold = true },
    DropBarIconFunctionCurrent = { fg = colors.func, bold = true },
    DropBarIconInterfaceCurrent = { fg = colors.type, bold = true },
    DropBarIconKeyCurrent = { fg = colors.keyword, bold = true },
    DropBarIconMethodCurrent = { fg = colors.func, bold = true },
    DropBarIconModuleCurrent = { fg = colors.namespace, bold = true },
    DropBarIconNamespaceCurrent = { fg = colors.namespace, bold = true },
    DropBarIconNullCurrent = { fg = colors.const, bold = true },
    DropBarIconNumberCurrent = { fg = colors.number, bold = true },
    DropBarIconObjectCurrent = { fg = colors.type, bold = true },
    DropBarIconOperatorCurrent = { fg = colors.operator, bold = true },
    DropBarIconPackageCurrent = { fg = colors.namespace, bold = true },
    DropBarIconPropertyCurrent = { fg = colors.parameter, bold = true },
    DropBarIconStringCurrent = { fg = colors.string, bold = true },
    DropBarIconStructCurrent = { fg = colors.type, bold = true },
    DropBarIconTypeParameterCurrent = { fg = colors.parameter, bold = true },
    DropBarIconVariableCurrent = { fg = colors.variable, bold = true },

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
    LazyButtonActive = { bg = colors.keyword, bold = true },
    LazyComment = { fg = colors.comment },
    LazyCommit = { fg = colors.const },
    LazyCommitIssue = { fg = colors.number },
    LazyCommitScope = { fg = colors.type },
    LazyCommitType = { fg = colors.keyword },
    LazyDir = { fg = colors.info },
    LazyH1 = { fg = colors.keyword, bold = true },
    LazyH2 = { fg = colors.func, bold = true },
    LazyNoCond = { fg = colors.dark_fg },
    LazyNormal = { bg = colors.popup_back },
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
    LazySpecial = { fg = colors.const },
    LazyTaskError = { fg = colors.error },
    LazyTaskOutput = { fg = colors.fg },
    LazyUrl = { fg = colors.string, underline = true },
    LazyValue = { fg = colors.const },

    -- Additional editor UI elements
    WinSeparator = { fg = colors.border },
    FloatTitle = { fg = colors.func, bold = true },
    FloatFooter = { fg = colors.dark_fg },
    Pmenu = { bg = colors.bg, fg = colors.cursor_line },
    PmenuSbar = { bg = colors.bg },
    PmenuThumb = { bg = colors.popup_back },
    PmenuSel = { bg = colors.light_bg },
    QuickFixLine = { bg = colors.selection },
    ColorColumn = { bg = colors.cursor_line },
    SignColumnSB = { bg = colors.bg },
    Conceal = { fg = colors.dark_fg },
    NonText = { fg = colors.border },
    SpecialKey = { fg = colors.border },
    MatchParen = { fg = colors.func, bold = true },
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

function M.toggle()
  if vim.o.background == 'dark' then
    vim.o.background = 'light'
    vim.cmd('colorscheme aye-light')
    vim.notify('Switched to Aye Light theme', vim.log.levels.INFO)
  else
    vim.o.background = 'dark'
    vim.cmd('colorscheme aye')
    vim.notify('Switched to Aye Dark theme', vim.log.levels.INFO)
  end
  M.setup(config)
end

function M.load()
  -- Set up the user commands with descriptions
  vim.api.nvim_create_user_command('AyeToggle', function()
    M.toggle()
  end, {
    desc = "Toggle between Aye dark and light themes"
  })
end

function M.setup(opts)
  opts = config.extend(vim.tbl_deep_extend("force", config, opts or {}))
  local colors = vim.o.background == 'dark' and dark or light

  if vim.o.background == 'dark' then
    vim.g.colors_name = 'aye'
  else
    vim.g.colors_name = 'aye-light'
  end

  local highlights = load_highlights(colors, opts)

  -- Apply highlights while preserving existing ones
  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end

  -- Set up lualine theme with gradient-like colors
  M.lualine_theme = {
    normal = {
      a = { fg = colors.bg, bg = colors.func, bold = true, gui = "bold" },
      b = { fg = colors.fg, bg = colors.lighter_bg },
      c = { fg = colors.dark_fg, bg = colors.light_bg },
    },
    insert = {
      a = { fg = colors.bg, bg = colors.string, bold = true, gui = "bold" },
      b = { fg = colors.string, bg = colors.light_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    visual = {
      a = { fg = colors.bg, bg = colors.keyword, bold = true, gui = "bold" },
      b = { fg = colors.keyword, bg = colors.light_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    replace = {
      a = { fg = colors.bg, bg = colors.error, bold = true, gui = "bold" },
      b = { fg = colors.error, bg = colors.light_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    command = {
      a = { fg = colors.bg, bg = colors.const, bold = true, gui = "bold" },
      b = { fg = colors.const, bg = colors.light_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    inactive = {
      a = { fg = colors.dark_fg, bg = colors.transparent },
      b = { fg = colors.dark_fg, bg = colors.transparent },
      c = { fg = colors.dark_fg, bg = colors.transparent },
    },
  }
end

return M
