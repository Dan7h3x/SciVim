local M = {}
local config = require("aye.config")

-- Enhanced dark palette with more soothing colors
local dark = {
  -- Base colors
  bg = "#1a1b26",          -- Slightly blueish dark background
  fg = "#c0caf5",          -- Softer white
  comment = "#565f89",     -- More visible comments
  selection = "#283457",   -- Clearer selection
  cursor_line = "#1f2335", -- Subtle cursor line

  border = "#3b4261",
  line_numbers = "#737aa2",
  float_border = "#3d59a1",
  popup_back = "#1f2335",

  -- Enhanced terminal colors
  terminal = {
    black = "#32344a",
    red = "#f7768e",
    green = "#9ece6a",
    yellow = "#e0af68",
    blue = "#7aa2f7",
    magenta = "#bb9af7",
    cyan = "#7dcfff",
    white = "#c0caf5",
    bright_black = "#6e6a86",
    bright_red = "#eb6f92",
    bright_green = "#3e8fb0",
    bright_yellow = "#f6c177",
    bright_blue = "#9ccfd8",
    bright_magenta = "#c4a7e7",
    bright_cyan = "#ea9a97",
    bright_white = "#e0def4",
  },

  -- Improved syntax colors for better readability
  string = "#9ece6a",    -- Softer green
  number = "#ff9e64",    -- Orange for numbers
  func = "#7aa2f7",      -- Clear blue for functions
  keyword = "#bb9af7",   -- Purple for keywords
  type = "#2ac3de",      -- Cyan for types
  const = "#ff9e64",     -- Orange for constants
  variable = "#c0caf5",  -- Base text color
  parameter = "#e0af68", -- Warm yellow

  -- Enhanced UI colors
  lighter_bg = "#1f2335",
  light_bg = "#24283b",
  dark_fg = "#565f89",
  ui_bg = "#1f2335",
  ui_fg = "#c0caf5",
  ui_active = "#3b4261",
  ui_inactive = "#1f2335",

  -- More visible diagnostic colors
  error = "#f7768e",
  warning = "#e0af68",
  info = "#7aa2f7",
  hint = "#1abc9c",

  -- Git colors with better contrast
  git_add = "#9ece6a",
  git_change = "#e0af68",
  git_delete = "#f7768e",
}

-- Enhanced light palette with better contrast and readability
local light = {
  -- Base colors (slightly darker background for better contrast)
  bg = "#fafae0",      -- Warmer, slightly darker background
  fg = "#3a4238",      -- Darker text for better contrast
  comment = "#83879c", -- More visible comments
  selection = "#c7c7af",
  cursor_line = "#c7c7af",

  -- UI elements
  border = "#c2baa9",
  line_numbers = "#957f6d",
  float_border = "#b3a893",
  popup_back = "#ede8df",
  lighter_bg = "#f0ece3",
  light_bg = "#e5e0d7",
  dark_fg = "#6e665c",
  ui_bg = "#e5e0d7",
  ui_fg = "#3c3836",
  ui_active = "#d5cec5",
  ui_inactive = "#e5e0d7",

  -- Syntax highlighting (warmer tones)
  string = "#587539",    -- Olive green
  number = "#a65d2b",    -- Warm brown
  func = "#175cd5",      -- Deeper blue for better contrast
  keyword = "#8a4af1",   -- Rich purple
  type = "#07707c",      -- Teal
  const = "#df5d2b",     -- Warm orange
  variable = "#3c3836",  -- Base text
  parameter = "#8b6c37", -- Golden brown
  operator = "#996b1d",  -- Amber
  namespace = "#07707c", -- Teal
  decorator = "#8f3f71", -- Purple

  -- Semantic tokens
  attribute = "#2b5cab",
  annotation = "#8b6c37",
  regex = "#8f3f71",

  -- Diagnostics with warmer tones
  error = "#cc241d",
  warning = "#b57614",
  info = "#2b5cab",
  hint = "#427b58",
  error_bg = "#fbe9e7",
  warning_bg = "#fdf6e3",
  info_bg = "#f0f4f8",
  hint_bg = "#f0f7f4",

  -- Git colors
  git_add = "#587539",
  git_change = "#8b6c37",
  git_delete = "#cc241d",

  -- Terminal colors (warm palette)
  terminal = {
    black = "#3c3836",
    red = "#cc241d",
    green = "#587539",
    yellow = "#b57614",
    blue = "#2b5cab",
    magenta = "#8f3f71",
    cyan = "#07707c",
    white = "#e9e5dc",
    bright_black = "#7c7c7c",
    bright_red = "#d64937",
    bright_green = "#6a8a43",
    bright_yellow = "#c68127",
    bright_blue = "#3b6cbd",
    bright_magenta = "#a14a81",
    bright_cyan = "#198592",
    bright_white = "#f0ece3",
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
    ["@lsp.type.class"] = { fg = colors.type, bold = true },
    ["@lsp.type.decorator"] = { fg = colors.decorator, italic = true },
    ["@lsp.type.enum"] = { fg = colors.type },
    ["@lsp.type.enumMember"] = { fg = colors.const },
    ["@lsp.type.function"] = { fg = colors.func },
    ["@lsp.type.interface"] = { fg = colors.type, italic = true },
    ["@lsp.type.macro"] = { fg = colors.const },
    ["@lsp.type.method"] = { fg = colors.func },
    ["@lsp.type.namespace"] = { fg = colors.namespace, bold = true },
    ["@lsp.type.parameter"] = { fg = colors.parameter },
    ["@lsp.type.property"] = { fg = colors.parameter },
    ["@lsp.type.struct"] = { fg = colors.type, bold = true },
    ["@lsp.type.type"] = { fg = colors.type },
    ["@lsp.type.typeParameter"] = { fg = colors.parameter, italic = true },
    ["@lsp.type.variable"] = { fg = colors.variable },

    -- Editor UI
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.popup_back },
    FloatBorder = { fg = colors.float_border, bg = colors.popup_back },
    Cursor = { fg = colors.bg, bg = colors.fg },
    CursorLine = { bg = colors.cursor_line },
    CursorLineNr = { fg = colors.fg, bold = true },
    LineNr = { fg = colors.line_numbers },
    Selection = { bg = colors.selection },
    SignColumn = { bg = colors.bg },
    StatusLine = { fg = colors.fg, bg = colors.ui_active },
    StatusLineNC = { fg = colors.dark_fg, bg = colors.ui_inactive },
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


    -- BufferLine integration
    BufferLineBackground = { fg = colors.dark_fg, bg = colors.ui_bg },
    BufferLineBuffer = { fg = colors.dark_fg, bg = colors.ui_bg },
    BufferLineBufferSelected = { fg = colors.fg, bg = colors.ui_active, bold = true },
    BufferLineBufferVisible = { fg = colors.fg, bg = colors.ui_bg },
    BufferLineCloseButton = { fg = colors.dark_fg, bg = colors.ui_bg },
    BufferLineCloseButtonSelected = { fg = colors.fg, bg = colors.ui_active },
    BufferLineFill = { bg = colors.bg },
    BufferLineIndicatorSelected = { fg = colors.func, bg = colors.ui_active },
    BufferLineModified = { fg = colors.warning, bg = colors.ui_bg },
    BufferLineModifiedSelected = { fg = colors.warning, bg = colors.ui_active },
    BufferLineModifiedVisible = { fg = colors.warning, bg = colors.ui_bg },
    BufferLineTab = { fg = colors.dark_fg, bg = colors.ui_bg },
    BufferLineTabSelected = { fg = colors.fg, bg = colors.ui_active, bold = true },
    BufferLineTabSeparator = { fg = colors.border, bg = colors.ui_bg },
    BufferLineTabSeparatorSelected = { fg = colors.border, bg = colors.ui_active },

    -- Telescope improvements
    TelescopeBorder = { fg = colors.float_border, bg = colors.ui_bg },
    TelescopeNormal = { bg = colors.ui_bg },
    TelescopePreviewBorder = { fg = colors.float_border, bg = colors.ui_bg },
    TelescopePreviewTitle = { fg = colors.func, bold = true },
    TelescopePromptBorder = { fg = colors.float_border, bg = colors.ui_bg },
    TelescopePromptCounter = { fg = colors.dark_fg },
    TelescopePromptPrefix = { fg = colors.const },
    TelescopePromptTitle = { fg = colors.keyword, bold = true },
    TelescopeResultsBorder = { fg = colors.float_border, bg = colors.ui_bg },
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
    BlinkCmpItemAbbr = { fg = colors.fg },
    BlinkCmpItemAbbrDeprecated = { fg = colors.dark_fg, strikethrough = true },
    BlinkCmpItemAbbrMatch = { fg = colors.func, bold = true },
    BlinkCmpItemAbbrMatchFuzzy = { fg = colors.func },
    BlinkCmpItemKind = { fg = colors.type },
    BlinkCmpItemMenu = { fg = colors.comment },
    BlinkCmpItemKindClass = { fg = colors.type },
    BlinkCmpItemKindConstant = { fg = colors.const },
    BlinkCmpItemKindConstructor = { fg = colors.func },
    BlinkCmpItemKindEnum = { fg = colors.type },
    BlinkCmpItemKindEnumMember = { fg = colors.const },
    BlinkCmpItemKindField = { fg = colors.parameter },
    BlinkCmpItemKindFunction = { fg = colors.func },
    BlinkCmpItemKindInterface = { fg = colors.type },
    BlinkCmpItemKindKeyword = { fg = colors.keyword },
    BlinkCmpItemKindMethod = { fg = colors.func },
    BlinkCmpItemKindModule = { fg = colors.namespace },
    BlinkCmpItemKindOperator = { fg = colors.operator },
    BlinkCmpItemKindProperty = { fg = colors.parameter },
    BlinkCmpItemKindReference = { fg = colors.parameter },
    BlinkCmpItemKindSnippet = { fg = colors.string },
    BlinkCmpItemKindStruct = { fg = colors.type },
    BlinkCmpItemKindTypeParameter = { fg = colors.parameter },
    BlinkCmpItemKindUnit = { fg = colors.const },
    BlinkCmpItemKindValue = { fg = colors.const },
    BlinkCmpItemKindVariable = { fg = colors.variable },


    -- Neotree improvements
    NeoTreeNormal = { fg = colors.fg, bg = colors.ui_bg },
    NeoTreeNormalNC = { fg = colors.dark_fg, bg = colors.ui_bg },
    NeoTreeVertSplit = { fg = colors.border },
    NeoTreeWinSeparator = { fg = colors.border },
    NeoTreeEndOfBuffer = { fg = colors.ui_bg, bg = colors.ui_bg },
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
    MiniIndentscopeSymbol = { fg = colors.border },
    MiniIndentscopePrefix = { nocombine = true },
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
    NoiceCmdline = { fg = colors.fg, bg = colors.ui_bg },
    NoiceCmdlineIcon = { fg = colors.const },
    NoiceCmdlineIconSearch = { fg = colors.warning },
    NoiceCmdlinePopup = { bg = colors.popup_back },
    NoiceCmdlinePopupBorder = { fg = colors.float_border },
    NoiceCmdlinePopupTitle = { fg = colors.func, bold = true },
    NoiceConfirm = { bg = colors.popup_back },
    NoiceConfirmBorder = { fg = colors.float_border },
    NoiceCursor = { fg = colors.bg, bg = colors.fg },
    NoiceMini = { fg = colors.fg, bg = colors.ui_bg },
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
    LazyButton = { bg = colors.ui_bg },
    LazyButtonActive = { bg = colors.ui_active, bold = true },
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
    Pmenu = { bg = colors.bg, fg = colors.fg },
    PmenuSbar = { bg = colors.ui_bg },
    PmenuThumb = { bg = colors.ui_active },
    QuickFixLine = { bg = colors.selection },
    ColorColumn = { bg = colors.cursor_line },
    SignColumnSB = { bg = colors.ui_bg },
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
    markdownCode = { fg = colors.string, bg = colors.ui_bg },
    markdownCodeBlock = { fg = colors.string },
    markdownBlockquote = { fg = colors.comment, italic = true },
    markdownLink = { fg = colors.func, underline = true },
    markdownUrl = { fg = colors.string, underline = true },
    markdownLinkText = { fg = colors.func },
    markdownListMarker = { fg = colors.const },

    -- Treesitter Context
    TreesitterContext = { bg = colors.ui_bg },
    TreesitterContextLineNumber = { fg = colors.line_numbers, bg = colors.ui_bg },
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
  -- Toggle between dark and light mode
  if vim.o.background == 'dark' then
    vim.o.background = 'light'
  else
    vim.o.background = 'dark'
  end
  -- Reapply the colorscheme
  M.setup()
end

function M.load()
  -- Set up the user commands
  vim.api.nvim_create_user_command('AyeToggle', function()
    M.toggle()
  end, {})

  -- Create commands for both variants
  vim.api.nvim_create_user_command('Aye', function()
    vim.o.background = 'dark'
    vim.cmd('colorscheme aye')
  end, {})

  vim.api.nvim_create_user_command('AyeLight', function()
    vim.o.background = 'light'
    vim.cmd('colorscheme aye')
  end, {})
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

  -- Set up lualine theme
  M.lualine_theme = {
    normal = {
      a = { fg = colors.bg, bg = colors.func, bold = true },
      b = { fg = colors.fg, bg = colors.ui_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    insert = {
      a = { fg = colors.bg, bg = colors.string, bold = true },
      b = { fg = colors.string, bg = colors.ui_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    visual = {
      a = { fg = colors.bg, bg = colors.warning, bold = true },
      b = { fg = colors.warning, bg = colors.ui_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    replace = {
      a = { fg = colors.bg, bg = colors.error, bold = true },
      b = { fg = colors.error, bg = colors.ui_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    command = {
      a = { fg = colors.bg, bg = colors.const, bold = true },
      b = { fg = colors.const, bg = colors.ui_bg },
      c = { fg = colors.dark_fg, bg = colors.lighter_bg },
    },
    inactive = {
      a = { fg = colors.dark_fg, bg = colors.ui_inactive },
      b = { fg = colors.dark_fg, bg = colors.ui_inactive },
      c = { fg = colors.dark_fg, bg = colors.ui_inactive },
    },
  }
end

return M
