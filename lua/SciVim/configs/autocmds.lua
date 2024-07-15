--[[
-- AutoCmds for SciVim
--]]

local function augroup(name)
  return vim.api.nvim_create_augroup("SciVim_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup("help_window_right"),
  pattern = { "*.txt" },
  callback = function()
    if vim.o.filetype == "help" then
      vim.cmd.wincmd("L")
    end
  end,
  desc = "Help page at right",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "Yanker" })
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})
-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_location then
      return
    end
    vim.b[buf].last_location = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "bookmarks",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "dbout",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})




local function Night()
  local highlighter = vim.api.nvim_set_hl
  local Theme = require("SciVim.extras.theme")
  local trans = "NONE"

  local function HL(hl, fg, bg, bold)
    if not bg and not bold then
      highlighter(0, hl, { fg = fg, bg = Theme.bg, bold = bold })
    elseif not bold then
      highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
    else
      highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
    end
  end

  HL("NvimPyRed", Theme.red, trans)
  HL("NvimPyPurple", Theme.purple, trans)
  HL("NvimPyGreen", Theme.green, trans)
  HL("NvimPyBlue", Theme.blue, trans)
  HL("NvimPyBBlue", Theme.cyan, trans)
  HL("NvimPyOrange", Theme.orange, trans)
  HL("NvimPyYellow", Theme.yellow, trans)
  HL("NvimPyCyan", Theme.cyan, trans)
  HL("NvimPyTeal", Theme.green, trans)
  HL("NvimPyTrans", trans, trans)
  HL("Yanker", Theme.bg, Theme.fg)
  highlighter(0, "CursorLine", { bg = Theme.bg_highlight })
  highlighter(0, "CmpCursorLine", { bg = Theme.bg_highlight })
  --[[
-- Simple Cmp Highlights
--]]
  --


  HL("CmpItemKindField", Theme.blue, Theme.bg_dark)
  HL("CmpItemKindProperty", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindEvent", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindText", Theme.green, Theme.bg_dark)
  HL("CmpItemKindEnum", Theme.green, Theme.bg_dark)
  HL("CmpItemKindKeyword", Theme.blue, Theme.bg_dark)
  HL("CmpItemKindConstant", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindConstructor", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindRefrence", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindFunction", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindStruct", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindClass", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindModule", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindOperator", Theme.purple, Theme.bg_dark)
  HL("CmpItemKindVariable", Theme.blue, Theme.bg_dark)
  HL("CmpItemKindFile", Theme.blue, Theme.bg_dark)
  HL("CmpItemKindUnit", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindSnippet", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindFolder", Theme.orange, Theme.bg_dark)
  HL("CmpItemKindMethod", Theme.yellow, Theme.bg_dark)
  HL("CmpItemKindValue", Theme.yellow, Theme.bg_dark)
  HL("CmpItemKindEnumMember", Theme.yellow, Theme.bg_dark)
  HL("CmpItemKindInterface", Theme.green, Theme.bg_dark)
  HL("CmpItemKindColor", Theme.green, Theme.bg_dark)
  HL("CmpItemKindTypeParameter", Theme.green, Theme.bg_dark)
  HL("CmpItemAbbrMatchFuzzy", Theme.cyan, Theme.bg_dark)
  HL("CmpItemAbbrMatch", Theme.cyan, Theme.bg_dark)
  HL("CmpBorder", Theme.bg_highlight, trans, true)
  HL("CmpBorderDoc", Theme.bg_highlight, trans, true)
  HL("CmpBorderIconsLT", Theme.blue, trans)
  HL("CmpBorderIconsCT", Theme.orange, trans)
  HL("CmpBorderIconsRT", Theme.green, trans)
  HL("CmpNormal", Theme.white, trans)
  HL("CmpItemMenu", Theme.yellow, Theme.bg_dark)

  --[[
-- Telescope
--]]
  HL("TelescopeNormal", Theme.blue, trans)
  HL("TelescopeBorder", Theme.bg_dark, trans)
  HL("TelescopePromptNormal", Theme.orange, trans)
  HL("TelescopePromptBorder", Theme.bg_dark, trans)
  HL("TelescopePromptTitle", Theme.blue, trans)
  HL("TelescopePreviewTitle", Theme.purple, trans)
  HL("TelescopeResultsTitle", Theme.green, trans)
  HL("TelescopePreviewBorder", Theme.terminal_black, trans)
  HL("TelescopeResultsBorder", Theme.bg_dark, trans)
  --[[
-- UI
--]]

  HL("CursorLineNr", Theme.cyan, trans)
  HL("LineNr", Theme.terminal_black, trans)
  HL("WinSeparator", Theme.cyan, trans, true)
  HL("VertSplit", Theme.blue, trans)
  HL("StatusLine", Theme.blue, trans)
  HL("StatusLineNC", Theme.blue, trans)
  HL("ColorColumn", Theme.purple, trans)
  HL("NeoTreeWinSeparator", Theme.cyan, trans)
  HL("NeoTreeStatusLineNC", trans, trans)
  HL("NeoTreeRootName", Theme.blue, trans)
  HL("NeoTreeIndentMarker", Theme.dark3, trans)
  HL("Winbar", Theme.fg_dark, trans)
  HL("WinbarNC", Theme.fg_dark, trans)
  HL("MiniIndentscopeSymbol", Theme.blue, trans)
  HL("FloatBorder", Theme.magenta, trans)
  HL("NvimPyTab", Theme.cyan, Theme.bg_dark)
  HL("Ghost", Theme.terminal_black, trans)

  --[[
-- Git colors
--]]
  --

  HL("GitSignsAdd", Theme.green, trans)
  HL("GitSignsChange", Theme.orange, trans)
  HL("GitSignsDelete", Theme.red, trans)
  HL("GitSignsUntracked", Theme.blue, trans)

  --[[
-- DropBar Highlights
--]]
  HL("DropBarIconKindVariable", Theme.orange, trans)
  HL("DropBarIconKindModule", Theme.orange, trans)
  HL("DropBarIconUISeparator", Theme.cyan, trans)
  HL("DropBarIconKindFunction", Theme.orange, trans)

  --[[
  -- BufferLine
  --]]
  HL("BufferLineCloseButtonSelected", Theme.red, trans)

  --[[
  -- WhickKey
  --]]
end

local function Day()
  local highlighter = vim.api.nvim_set_hl
  local Theme = require("catppuccin.palettes").get_palette("latte")
  local Colors = require("SciVim.extras.theme")
  local trans = "NONE"

  local function HL(hl, fg, bg, bold)
    if not bg and not bold then
      highlighter(0, hl, { fg = fg, bg = Theme.base2, bold = bold })
    elseif not bold then
      highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
    else
      highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
    end
  end

  HL("NvimPyRed", Colors.red, trans)
  HL("NvimPyPurple", Colors.purple, trans)
  HL("NvimPyGreen", Colors.green, trans)
  HL("NvimPyBlue", Colors.blue, trans)
  HL("NvimPyBBlue", Colors.blue, trans)
  HL("NvimPyOrange", Colors.orange, trans)
  HL("NvimPyYellow", Colors.yellow, trans)
  HL("NvimPyCyan", Colors.blue, trans)
  HL("NvimPyTeal", Colors.green, trans)
  HL("NvimPyTrans", trans, trans)
  HL("NvimPyYank", Colors.dark, Colors.dark)
  highlighter(0, "CursorLine", { bg = Colors.grey })
  highlighter(0, "CmpCursorLine", { bg = Colors.grey })
  --[[
-- Simple Cmp Highlights
--]]
  --

  HL("CmpItemKindField", Colors.blue, Colors.grey)
  HL("CmpItemKindProperty", Colors.purple, Colors.grey)
  HL("CmpItemKindEvent", Colors.purple, Colors.grey)
  HL("CmpItemKindText", Colors.green, Colors.grey)
  HL("CmpItemKindEnum", Colors.green, Colors.grey)
  HL("CmpItemKindKeyword", Colors.blue, Colors.grey)
  HL("CmpItemKindConstant", Colors.orange, Colors.grey)
  HL("CmpItemKindConstructor", Colors.orange, Colors.grey)
  HL("CmpItemKindRefrence", Colors.orange, Colors.grey)
  HL("CmpItemKindFunction", Colors.purple, Colors.grey)
  HL("CmpItemKindStruct", Colors.purple, Colors.grey)
  HL("CmpItemKindClass", Colors.purple, Colors.grey)
  HL("CmpItemKindModule", Colors.purple, Colors.grey)
  HL("CmpItemKindOperator", Colors.purple, Colors.grey)
  HL("CmpItemKindVariable", Colors.blue, Colors.grey)
  HL("CmpItemKindFile", Colors.blue, Colors.grey)
  HL("CmpItemKindUnit", Colors.orange, Colors.grey)
  HL("CmpItemKindSnippet", Colors.orange, Colors.grey)
  HL("CmpItemKindFolder", Colors.orange, Colors.grey)
  HL("CmpItemKindMethod", Colors.yellow, Colors.grey)
  HL("CmpItemKindValue", Colors.yellow, Colors.grey)
  HL("CmpItemKindEnumMember", Colors.yellow, Colors.grey)
  HL("CmpItemKindInterface", Colors.green, Colors.grey)
  HL("CmpItemKindColor", Colors.green, Colors.grey)
  HL("CmpItemKindTypeParameter", Colors.green, Colors.grey)
  HL("CmpItemAbbrMatchFuzzy", Colors.dark, Colors.grey)
  HL("CmpItemAbbrMatch", Colors.dark, Colors.grey)
  HL("CmpBorder", Colors.blue, trans, true)
  HL("CmpBorderDoc", Colors.blue, trans, true)
  HL("CmpBorderIconsLT", Colors.green, trans)
  HL("CmpBorderIconsCT", Colors.orange, trans)
  HL("CmpBorderIconsRT", Colors.green, trans)
  HL("CmpNormal", Colors.purple, trans)
  HL("CmpItemMenu", Colors.blue, trans)

  --[[
-- Telescope
--]]

  HL("BufferLineCloseButtonSelected", Theme.red, trans)
  HL("BufferLineBufferSelected", Theme.cyan, trans)
end

vim.api.nvim_create_autocmd({ "ColorScheme", "ColorSchemePre" }, {
  group = augroup("SciVim_Theme"),
  pattern = "*",
  callback = function()
    local colors = vim.g.colors_name
    if colors and string.find(colors, "tokyonight") then
      Night()
    elseif colors == "catppuccin-latte" then
      Day()
    end

    -- Alpha
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
  end,
})




local function check(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function fixConfig()
  local path = vim.fn.getcwd() .. "/pyproject.toml"
  if not check(path) then
    local temp = [[
[tool.pyright]
  include = ["src","**/*.py"]
  exclude = ["**/node_modules",
    "**/__pycache__",
    "src/experimental",
    "src/typestubs"
]
ignore = ["src/oldstuff"]
defineConstant = { DEBUG = true }
stubPath = "src/stubs"

reportMissingImports = true
reportMissingTypeStubs = false

pythonPlatform = "Linux"



[tool.ruff]
# Exclude a variety of commonly ignored directories.
exclude = [
    ".bzr",
    ".direnv",
    ".eggs",
    ".git",
    ".git-rewrite",
    ".hg",
    ".ipynb_checkpoints",
    ".mypy_cache",
    ".nox",
    ".pants.d",
    ".pyenv",
    ".pytest_cache",
    ".pytype",
    ".ruff_cache",
    ".svn",
    ".tox",
    ".venv",
    ".vscode",
    "__pypackages__",
    "_build",
    "buck-out",
    "build",
    "dist",
    "node_modules",
    "site-packages",
    "venv",
]

# Same as Black.
line-length = 88
indent-width = 4

# Assume Python 3.8

[tool.ruff.lint]
# Enable Pyflakes (`F`) and a subset of the pycodestyle (`E`)  codes by default.
# Unlike Flake8, Ruff doesn't enable pycodestyle warnings (`W`) or
# McCabe complexity (`C901`) by default.
select = ["E4", "E7", "E9", "F"]
ignore = []

# Allow fix for all enabled rules (when `--fix`) is provided.
fixable = ["ALL"]
unfixable = []

# Allow unused variables when underscore-prefixed.
dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"

[tool.ruff.format]
# Like Black, use double quotes for strings.
quote-style = "double"

# Like Black, indent with spaces, rather than tabs.
indent-style = "space"

# Like Black, respect magic trailing commas.
skip-magic-trailing-comma = false

# Like Black, automatically detect the appropriate line ending.
line-ending = "auto"

# Enable auto-formatting of code examples in docstrings. Markdown,
# reStructuredText code/literal blocks and doctests are all supported.
#
# This is currently disabled by default, but it is planned for this
# to be opt-out in the future.
docstring-code-format = false

# Set the line length limit used when formatting code snippets in
# docstrings.
#
# This only has an effect when the `docstring-code-format` setting is
# enabled.
docstring-code-line-length = "dynamic"

    ]]
    local file = io.open(path, "w")
    file:write(temp)
    file:close()
    print("Python Configured")
  end
end

vim.api.nvim_create_autocmd({ "FileType", "BufNewFile", "BufWinEnter" }, {
  group = augroup("PythonConfig"),
  pattern = { "*.py", "python" },
  callback = function()
    fixConfig()
  end,
})
