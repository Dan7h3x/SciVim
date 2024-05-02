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
require("null-ls").setup({
	-- you can reuse a shared lspconfig on_attach callback here
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup("LspFormatting"), buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup("LspFormatting"),
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					-- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
					vim.lsp.buf.formatting_sync()
				end,
			})
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

-- local function fixConfig()
-- 	local path = vim.fn.getcwd() .. "/pyrightconfig.json"
-- 	if not check(path) then
-- 		local temp = [[
--     {
--     "include": ["**/*.py","src"],
--     "exclude": ["**/__pycache__","**/*.pyc","**/*.pyo"],
--     "executionEnvironments" : [{
--     "root":"src"
--     }]
--     }
--     ]]
-- 		local file = io.open(path, "w")
-- 		file:write(temp)
-- 		file:close()
-- 		print("Python Configured")
-- 	end
-- end

-- vim.api.nvim_create_autocmd({ "FileType" }, {
-- 	group = augroup("PythonConfig"),
-- 	pattern = { "python", "*.py" },
-- 	callback = function()
-- 		fixConfig()
-- 	end,
-- })

local function Tokyonight()
	local highlighter = vim.api.nvim_set_hl
	local Theme = require("tokyonight.colors")
	local Colors = require("NvimPy.configs.colors")
	local trans = Theme.default.none

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
	highlighter(0, "CursorLine", { bg = Theme.default.bg })
	highlighter(0, "CmpCursorLine", { bg = Theme.default.bg_dark })
	--[[
-- Simple Cmp Highlights
--]]
	--

	HL("CmpItemKindField", Colors.blue["500"], Theme.default.bg_dark)
	HL("CmpItemKindProperty", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindEvent", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindText", Colors.green["500"], Theme.default.bg_dark)
	HL("CmpItemKindEnum", Colors.green["500"], Theme.default.bg_dark)
	HL("CmpItemKindKeyword", Colors.blue["500"], Theme.default.bg_dark)
	HL("CmpItemKindConstant", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindConstructor", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindRefrence", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindFunction", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindStruct", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindClass", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindModule", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindOperator", Colors.purple["500"], Theme.default.bg_dark)
	HL("CmpItemKindVariable", Colors.blue["400"], Theme.default.bg_dark)
	HL("CmpItemKindFile", Colors.blue["400"], Theme.default.bg_dark)
	HL("CmpItemKindUnit", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindSnippet", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindFolder", Colors.orange["500"], Theme.default.bg_dark)
	HL("CmpItemKindMethod", Colors.yellow["500"], Theme.default.bg_dark)
	HL("CmpItemKindValue", Colors.yellow["500"], Theme.default.bg_dark)
	HL("CmpItemKindEnumMember", Colors.yellow["500"], Theme.default.bg_dark)
	HL("CmpItemKindInterface", Colors.green["500"], Theme.default.bg_dark)
	HL("CmpItemKindColor", Colors.green["500"], Theme.default.bg_dark)
	HL("CmpItemKindTypeParameter", Colors.green["500"], Theme.default.bg_dark)
	HL("CmpItemAbbrMatchFuzzy", Colors.blue["400"], Theme.default.bg_dark)
	HL("CmpItemAbbrMatch", Colors.blue["400"], Theme.default.bg_dark)
	HL("CmpBorder", Theme.default.terminal_black, Theme.night.bg, true)
	HL("CmpBorderDoc", Theme.default.terminal_black, Theme.night.bg, true)
	HL("CmpBorderIconsLT", Colors.blue["400"], Theme.night.bg)
	HL("CmpBorderIconsCT", Colors.orange["500"], Theme.night.bg)
	HL("CmpBorderIconsRT", Colors.green["300"], Theme.night.bg)
	HL("CmpNormal", Colors.purple["500"], Theme.night.bg)
	HL("CmpItemMenu", Colors.blue["400"], Theme.default.bg_dark)

	--[[
-- Telescope
--]]

	HL("TelescopeNormal", Colors.blue["200"], Theme.night.bg)
	HL("TelescopeBorder", Theme.default.bg_dark, trans)
	HL("TelescopePromptNormal", Colors.orange["500"], Theme.night.bg)
	HL("TelescopePromptBorder", Theme.default.bg_dark, Theme.night.bg)
	HL("TelescopePromptTitle", Colors.blue["200"], Theme.night.bg)
	HL("TelescopePreviewTitle", Colors.purple["500"], trans)
	HL("TelescopeResultsTitle", Colors.green["300"], trans)
	HL("TelescopePreviewBorder", Theme.default.terminal_black, trans)
	HL("TelescopeResultsBorder", Theme.default.bg_dark, trans)
	--[[
-- UI
--]]
	HL("CursorLineNr", Colors.blue["200"], trans)
	HL("LineNr", Theme.default.terminal_black, trans)
	HL("WinSeparator", Colors.blue["200"], trans, true)
	HL("VertSplit", Colors.blue["200"], trans)
	HL("StatusLine", Colors.blue["200"], trans)
	HL("StatusLineNC", Colors.blue["200"], trans)
	HL("ColorColumn", Colors.purple["500"], trans)
	HL("NeoTreeWinSeparator", Colors.blue["200"], trans)
	HL("NeoTreeStatusLineNC", trans, trans)
	HL("NeoTreeRootName", Colors.purple["500"], trans)
	HL("NeoTreeIndentMarker", Colors.purple["500"], trans)
	HL("Winbar", Theme.default.fg, trans)
	HL("WinbarNC", Theme.default.fg, trans)
	HL("MiniIndentscopeSymbol", Colors.blue["100"], trans)
	HL("FloatBorder", Colors.purple["500"], Theme.night.bg)
	HL("NvimPyTab", Colors.blue["200"], Colors.black)
	HL("Ghost", Theme.default.terminal_black, trans)

	--[[
-- Git colors
--]]
	--

	HL("GitSignsAdd", Colors.green["500"], trans)
	HL("GitSignsChange", Colors.orange["500"], trans)
	HL("GitSignsDelete", Colors.red["500"], trans)
	HL("GitSignsUntracked", Colors.blue["500"], trans)

	--[[
-- DropBar Highlights
--]]
	HL("DropBarIconKindVariable", Colors.blue["200"], trans)
	HL("DropBarIconKindModule", Colors.blue["200"], trans)
	HL("DropBarIconUISeparator", Colors.purple["500"], trans)
	HL("DropBarIconKindFunction", Colors.blue["200"], trans)
	--[[
-- BufferLine
--]]

	HL("BufferLineCloseButtonSelected", Colors.red["500"], trans)
	HL("BufferLineCloseButtonVisible", Colors.orange["500"], trans)
	HL("BufferLineBufferSelected", Colors.purple["500"])
	HL("BufferLineNumbersSelected", Colors.green["500"])
	HL("BufferLineFill", trans, Theme.default.bg_dark)
	HL("BufferCurrent", Colors.blue["500"], trans)
	HL("BufferLineIndicatorSelected", Colors.blue["200"], trans)
end

local function DeepWhite()
	local highlighter = vim.api.nvim_set_hl
	local Theme = require("deepwhite.colors")
	local Colors = require("NvimPy.configs.colors")
	local trans = "#FFFFFF"

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
	highlighter(0, "CursorLine", { bg = Theme.base2 })
	highlighter(0, "CmpCursorLine", { bg = Theme.base4 })
	--[[
-- Simple Cmp Highlights
--]]
	--

	HL("CmpItemKindField", Colors.blue["500"], Theme.base2)
	HL("CmpItemKindProperty", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindEvent", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindText", Colors.green["500"], Theme.base2)
	HL("CmpItemKindEnum", Colors.green["500"], Theme.base2)
	HL("CmpItemKindKeyword", Colors.blue["500"], Theme.base2)
	HL("CmpItemKindConstant", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindConstructor", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindRefrence", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindFunction", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindStruct", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindClass", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindModule", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindOperator", Colors.purple["500"], Theme.base2)
	HL("CmpItemKindVariable", Colors.blue["400"], Theme.base2)
	HL("CmpItemKindFile", Colors.blue["400"], Theme.base2)
	HL("CmpItemKindUnit", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindSnippet", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindFolder", Colors.orange["500"], Theme.base2)
	HL("CmpItemKindMethod", Colors.yellow["500"], Theme.base2)
	HL("CmpItemKindValue", Colors.yellow["500"], Theme.base2)
	HL("CmpItemKindEnumMember", Colors.yellow["500"], Theme.base2)
	HL("CmpItemKindInterface", Colors.green["500"], Theme.base2)
	HL("CmpItemKindColor", Colors.green["500"], Theme.base2)
	HL("CmpItemKindTypeParameter", Colors.green["500"], Theme.base2)
	HL("CmpItemAbbrMatchFuzzy", Colors.blue["400"], Theme.base2)
	HL("CmpItemAbbrMatch", Colors.blue["400"], Theme.base2)
	HL("CmpBorder", Theme.light_cyan, Theme.base2, true)
	HL("CmpBorderDoc", Theme.light_cyan, Theme.base2, true)
	HL("CmpBorderIconsLT", Colors.blue["400"], Theme.base2)
	HL("CmpBorderIconsCT", Colors.orange["500"], Theme.base2)
	HL("CmpBorderIconsRT", Colors.green["300"], Theme.base2)
	HL("CmpNormal", Colors.purple["500"], Theme.base2)
	HL("CmpItemMenu", Colors.blue["400"], Theme.base2)

	--[[
-- Telescope
--]]

	HL("TelescopeNormal", Colors.blue["200"], Theme.base2)
	HL("TelescopeBorder", Theme.base2, trans)
	HL("TelescopePromptNormal", Colors.orange["500"], Theme.base2)
	HL("TelescopePromptBorder", Theme.base2, Theme.base2)
	HL("TelescopePromptTitle", Colors.blue["200"], Theme.base2)
	HL("TelescopePreviewTitle", Colors.purple["500"], trans)
	HL("TelescopeResultsTitle", Colors.green["300"], trans)
	HL("TelescopePreviewBorder", Theme.base1, trans)
	HL("TelescopeResultsBorder", Theme.base2, trans)
	--[[
-- UI
--]]
	HL("CursorLineNr", Colors.blue["200"], trans)
	HL("LineNr", Theme.default.terminal_black, trans)
	HL("WinSeparator", Colors.blue["200"], trans, true)
	HL("VertSplit", Colors.blue["200"], trans)
	HL("StatusLine", Colors.blue["200"], trans)
	HL("StatusLineNC", Colors.blue["200"], trans)
	HL("ColorColumn", Colors.purple["500"], trans)
	HL("NeoTreeWinSeparator", Colors.blue["200"], trans)
	HL("NeoTreeStatusLineNC", trans, trans)
	HL("NeoTreeRootName", Colors.purple["500"], trans)
	HL("NeoTreeIndentMarker", Colors.purple["500"], trans)
	HL("Winbar", Theme.base1, trans)
	HL("WinbarNC", Theme.base1, trans)
	HL("MiniIndentscopeSymbol", Colors.blue["100"], trans)
	HL("FloatBorder", Colors.purple["500"], Theme.base2)
	HL("NvimPyTab", Colors.blue["200"], Colors.black)
	HL("Ghost", Theme.base1, trans)

	--[[
-- Git colors
--]]
	--

	HL("GitSignsAdd", Colors.green["500"], trans)
	HL("GitSignsChange", Colors.orange["500"], trans)
	HL("GitSignsDelete", Colors.red["500"], trans)
	HL("GitSignsUntracked", Colors.blue["500"], trans)

	--[[
-- DropBar Highlights
--]]
	HL("DropBarIconKindVariable", Colors.blue["200"], trans)
	HL("DropBarIconKindModule", Colors.blue["200"], trans)
	HL("DropBarIconUISeparator", Colors.purple["500"], trans)
	HL("DropBarIconKindFunction", Colors.blue["200"], trans)
	--[[
-- BufferLine
--]]

	HL("BufferLineCloseButtonSelected", Colors.red["500"], trans)
	HL("BufferLineCloseButtonVisible", Colors.orange["500"], trans)
	HL("BufferLineBufferSelected", Colors.purple["500"])
	HL("BufferLineNumbersSelected", Colors.green["500"])
	HL("BufferLineFill", trans, Theme.base2)
	HL("BufferCurrent", Colors.blue["500"], trans)
	HL("BufferLineIndicatorSelected", Colors.blue["200"], trans)
end

vim.api.nvim_create_autocmd({ "ColorScheme", "ColorSchemePre" }, {
	group = augroup("NvimPy_Tokyonight"),
	pattern = "*",
	callback = function()
		local colors = vim.g.colors_name
		if colors == "tokyonight" then
			Tokyonight()
		elseif colors == "deepwhite" then
			DeepWhite()
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