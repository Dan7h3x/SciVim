local function augroup(name)
	return vim.api.nvim_create_augroup("NvimPy_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	command = "checktime",
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
	pattern = { "*" },
	callback = function()
		utils.clean_pdf()
	end,
})
