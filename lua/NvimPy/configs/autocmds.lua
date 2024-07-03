local function augroup(name)
	return vim.api.nvim_create_augroup("NvimPy_" .. name, { clear = true })
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

vim.api.nvim_create_autocmd("BufEnter", {
	group = augroup("AutoRoot"),
	callback = function()
		local patterns = { ".git", "package.json", "setup.py" }
		local root = require("NvimPy.utils.init").find_root(0, patterns)
		if root == nil then
			return
		end
		-- vim.fn.chdir(root)
		vim.cmd("tcd " .. root)
	end,
	desc = "Find root and change current directory",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank({ higroup = "NvimPyYank" })
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
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
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
	pattern = { "gitcommit", "markdown", "*.txt", "*.tex", "*.typ" },
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
	pattern = { "*.py" },
	callback = function()
		fixConfig()
	end,
})

local function Night()
	local highlighter = vim.api.nvim_set_hl
	local Theme = require("NvimPy.settings.theme")
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
	HL("NvimPyBBlue", Theme.blue, trans)
	HL("NvimPyOrange", Theme.orange, trans)
	HL("NvimPyYellow", Theme.yellow, trans)
	HL("NvimPyCyan", Theme.cyan, trans)
	HL("NvimPyTeal", Theme.green, trans)
	HL("NvimPyTrans", trans, trans)
	HL("NvimPyYank", Theme.dark, Theme.purple)
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
	HL("CmpItemAbbrMatchFuzzy", Theme.blue, Theme.bg_dark)
	HL("CmpItemAbbrMatch", Theme.blue, Theme.bg_dark)
	HL("CmpBorder", Theme.terminal_black, Theme.bg, true)
	HL("CmpBorderDoc", Theme.terminal_black, Theme.bg, true)
	HL("CmpBorderIconsLT", Theme.blue, Theme.bg)
	HL("CmpBorderIconsCT", Theme.orange, Theme.bg)
	HL("CmpBorderIconsRT", Theme.green, Theme.bg)
	HL("CmpNormal", Theme.purple, Theme.bg)
	HL("CmpItemMenu", Theme.blue, Theme.bg_dark)

	--[[
-- Telescope
--]]

	HL("TelescopeNormal", Theme.blue, Theme.bg)
	HL("TelescopeBorder", Theme.bg_dark, trans)
	HL("TelescopePromptNormal", Theme.orange, Theme.bg)
	HL("TelescopePromptBorder", Theme.bg_dark, Theme.bg)
	HL("TelescopePromptTitle", Theme.blue, Theme.bg)
	HL("TelescopePreviewTitle", Theme.purple, trans)
	HL("TelescopeResultsTitle", Theme.green, trans)
	HL("TelescopePreviewBorder", Theme.terminal_black, trans)
	HL("TelescopeResultsBorder", Theme.bg_dark, trans)
	--[[
-- UI
--]]

	HL("CursorLineNr", Theme.green, trans)
	HL("LineNr", Theme.terminal_black, trans)
	HL("WinSeparator", Theme.blue, trans, true)
	HL("VertSplit", Theme.blue, trans)
	HL("StatusLine", Theme.blue, trans)
	HL("StatusLineNC", Theme.blue, trans)
	HL("ColorColumn", Theme.purple, trans)
	HL("NeoTreeWinSeparator", Theme.blue, trans)
	HL("NeoTreeStatusLineNC", trans, trans)
	HL("NeoTreeRootName", Theme.blue, trans)
	HL("NeoTreeIndentMarker", Theme.dark3, trans)
	HL("Winbar", Theme.fg, trans)
	HL("WinbarNC", Theme.fg, trans)
	HL("MiniIndentscopeSymbol", Theme.blue, trans)
	HL("FloatBorder", Theme.purple, Theme.bg)
	HL("NvimPyTab", Theme.blue, Theme.bg_dark)
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
	HL("DropBarIconKindVariable", Theme.blue, trans)
	HL("DropBarIconKindModule", Theme.blue, trans)
	HL("DropBarIconUISeparator", Theme.purple, trans)
	HL("DropBarIconKindFunction", Theme.blue, trans)

	--[[
  -- BufferLine
  --]]
	HL("BufferLineCloseButtonSelected", Theme.red, trans)
	HL("BufferLineBufferSelected", Theme.blue, trans)
end

local function Day()
	local highlighter = vim.api.nvim_set_hl
	local Theme = require("catppuccin.palettes").get_palette("latte")
	local Colors = require("NvimPy.configs.colors")
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

	HL("NvimPyRed", Colors.red["500"], trans)
	HL("NvimPyPurple", Colors.purple["500"], trans)
	HL("NvimPyGreen", Colors.green["500"], trans)
	HL("NvimPyBlue", Colors.blue["500"], trans)
	HL("NvimPyBBlue", Colors.blue["100"], trans)
	HL("NvimPyOrange", Colors.orange["500"], trans)
	HL("NvimPyYellow", Colors.yellow["500"], trans)
	HL("NvimPyCyan", Colors.blue["400"], trans)
	HL("NvimPyTeal", Colors.green["300"], trans)
	HL("NvimPyTrans", trans, trans)
	HL("NvimPyYank", Colors.green["400"], Colors.grey["400"])
	highlighter(0, "CursorLine", { bg = Colors.grey["200"] })
	highlighter(0, "CmpCursorLine", { bg = Colors.grey["300"] })
	--[[
-- Simple Cmp Highlights
--]]
	--

	HL("CmpItemKindField", Colors.blue["500"], Colors.grey["200"])
	HL("CmpItemKindProperty", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindEvent", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindText", Colors.green["500"], Colors.grey["200"])
	HL("CmpItemKindEnum", Colors.green["500"], Colors.grey["200"])
	HL("CmpItemKindKeyword", Colors.blue["500"], Colors.grey["200"])
	HL("CmpItemKindConstant", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindConstructor", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindRefrence", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindFunction", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindStruct", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindClass", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindModule", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindOperator", Colors.purple["500"], Colors.grey["200"])
	HL("CmpItemKindVariable", Colors.blue["400"], Colors.grey["200"])
	HL("CmpItemKindFile", Colors.blue["400"], Colors.grey["200"])
	HL("CmpItemKindUnit", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindSnippet", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindFolder", Colors.orange["500"], Colors.grey["200"])
	HL("CmpItemKindMethod", Colors.yellow["500"], Colors.grey["200"])
	HL("CmpItemKindValue", Colors.yellow["500"], Colors.grey["200"])
	HL("CmpItemKindEnumMember", Colors.yellow["500"], Colors.grey["200"])
	HL("CmpItemKindInterface", Colors.green["500"], Colors.grey["200"])
	HL("CmpItemKindColor", Colors.green["500"], Colors.grey["200"])
	HL("CmpItemKindTypeParameter", Colors.green["500"], Colors.grey["200"])
	HL("CmpItemAbbrMatchFuzzy", Colors.blue["800"], Colors.grey["200"])
	HL("CmpItemAbbrMatch", Colors.blue["800"], Colors.grey["200"])
	HL("CmpBorder", Colors.blue["500"], trans, true)
	HL("CmpBorderDoc", Colors.blue["500"], trans, true)
	HL("CmpBorderIconsLT", Colors.green["500"], trans)
	HL("CmpBorderIconsCT", Colors.orange["500"], trans)
	HL("CmpBorderIconsRT", Colors.green["300"], trans)
	HL("CmpNormal", Colors.purple["500"], trans)
	HL("CmpItemMenu", Colors.blue["400"], trans)

	--[[
-- Telescope
--]]
end

vim.api.nvim_create_autocmd({ "ColorScheme", "ColorSchemePre" }, {
	group = augroup("NvimPy_Theme"),
	pattern = "*",
	callback = function()
		local colors = vim.g.colors_name
		if colors == "tokyonight-night" then
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
