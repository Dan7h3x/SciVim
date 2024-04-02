local function augroup(name)
	return vim.api.nvim_create_augroup("NvimPy_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	command = "checktime",
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "",
	command = ":%s/\\s\\+$//e",
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "",
	command = "set fo-=c fo-=r fo-=o",
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
		local root = require("NvimPy.Util").find_root(0, patterns)
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
		vim.highlight.on_yank()
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
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

local function check(path)
	local file = io.open("path", "r")
	if file then
		file:close()
		return true
	end
	return false
end

local function fixConfig()
	local path = vim.fn.getcwd() .. "/pyrightconfig.json"
	if not check(path) then
		local temp = [[
    {
    "include": ["**/*.py","src"],
    "exclude": ["/pycache","**/*.pyc","**/*.pyo"],
    "executionEnvironments" : [{
    "root":"src"
    }]
    }
    ]]
		local file = io.open(path, "w")
		file:write(temp)
		file:close()
		print("Python Configured")
	end
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufWinEnter", "FileType" }, {
	group = augroup("PythonConfig"),
	pattern = { "python", "*.py" },
	callback = function()
		fixConfig()
	end,
})

vim.api.nvim_create_autocmd({ "ColorScheme", "ColorSchemePre" }, {
	group = augroup("NvimPy_Highlights"),
	pattern = "*",
	callback = function()
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

		local red = "#FF0131"
		local purple = "#9417EB"
		local magenta = "#E20D95"
		local green = "#39FF14"
		local blue = "#1D1DFF"
		local bblue = "#59aFf0"
		local orange = "#F6890A"
		local yellow = "#CCFF00"
		local cyan = "#00FEFC"
		local teal = "#43BBB6"
		local black = "#070508"
		local trans = Theme.default.none

		HL("NvimPyRed", red, trans)
		HL("NvimPyPurple", purple, trans)
		HL("NvimPyGreen", green, trans)
		HL("NvimPyBlue", blue, trans)
		HL("NvimPyBBlue", bblue, trans)
		HL("NvimPyOrange", orange, trans)
		HL("NvimPyYellow", yellow, trans)
		HL("NvimPyCyan", cyan, trans)
		HL("NvimPyTeal", teal, trans)
		HL("NvimPyTrans", trans, trans)
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

		HL("TelescopeNormal", cyan, Theme.night.bg)
		HL("TelescopeBorder", Theme.default.bg_dark, trans)
		HL("TelescopePromptNormal", orange, Theme.night.bg)
		HL("TelescopePromptBorder", Theme.default.bg_dark, Theme.night.bg)
		HL("TelescopePromptTitle", cyan, Theme.night.bg)
		HL("TelescopePreviewTitle", purple, trans)
		HL("TelescopeResultsTitle", teal, trans)
		HL("TelescopePreviewBorder", Theme.default.terminal_black, trans)
		HL("TelescopeResultsBorder", Theme.default.bg_dark, trans)
		--[[
-- UI
--]]
		HL("CursorLineNr", cyan, trans)
		HL("LineNr", Theme.default.terminal_black, trans)
		HL("WinSeparator", cyan, trans, true)
		HL("VertSplit", cyan, trans)
		HL("StatusLine", cyan, trans)
		HL("StatusLineNC", cyan, trans)
		HL("ColorColumn", purple, trans)
		HL("NeoTreeWinSeparator", cyan, trans)
		HL("NeoTreeStatusLineNC", trans, trans)
		HL("NeoTreeRootName", purple, trans)
		HL("NeoTreeIndentMarker", purple, trans)
		HL("Winbar", Theme.default.fg, trans)
		HL("WinbarNC", Theme.default.fg, trans)
		HL("MiniIndentscopeSymbol", bblue, trans)
		HL("FloatBorder", purple, Theme.night.bg)
		HL("NvimPyTab", cyan, black)
		HL("Ghost", Theme.default.terminal_black, trans)

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
	end,
})

local stats = require("NvimPy.Typst.stats")
local utils = require("NvimPy.Typst.utils")

vim.api.nvim_create_autocmd({ "BufEnter" }, {
	group = augroup("TypstClean"),
	pattern = { "*.typ" },
	callback = function(args)
		utils.redirect_pdf(args.buf)

		if stats.config.clean_temp_pdf then
			utils.collect_temp_pdf(args.buf)
		end
	end,
})
vim.api.nvim_create_autocmd({ "VimLeave" }, {
	group = augroup("TypstLeave"),
	pattern = { "*.typ" },
	callback = function()
		utils.clean_pdf()
	end,
})
