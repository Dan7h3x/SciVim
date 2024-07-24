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

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	group = augroup("SciVimColors"),
	callback = function()
		local highlighter = vim.api.nvim_set_hl
		local Theme = require("SciVim.extras.theme")

		local function HL(hl, fg, bg, bold)
			if not bg and not bold then
				highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
			elseif not bold then
				highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
			else
				highlighter(0, hl, { fg = fg, bg = bg, bold = bold })
			end
		end
		HL("SciVimRed", Theme.red)
		HL("SciVimPurple", Theme.purple)
		HL("SciVimGreen", Theme.green)
		HL("SciVimBlue", Theme.blue)
		HL("SciVimMagenta", Theme.magenta)
		HL("SciVimOrange", Theme.orange)
		HL("SciVimYellow", Theme.yellow)
		HL("SciVimCyan", Theme.cyan)
		HL("SciVimTeal", Theme.green)
		HL("Yanker", Theme.bg, Theme.fg)
		HL("SciVimTab", Theme.cyan, Theme.bg_dark)
		HL("Ghost", Theme.terminal_black)
		HL("WinSeparator", Theme.cyan)

		-- Alpha
		vim.api.nvim_set_hl(0, "SciVim18", { fg = "#14067E", ctermfg = 18 })
		vim.api.nvim_set_hl(0, "SciVimPy1", { fg = "#15127B", ctermfg = 18 })
		vim.api.nvim_set_hl(0, "SciVim17", { fg = "#171F78", ctermfg = 18 })
		vim.api.nvim_set_hl(0, "SciVim16", { fg = "#182B75", ctermfg = 18 })
		vim.api.nvim_set_hl(0, "SciVimPy2", { fg = "#193872", ctermfg = 23 })
		vim.api.nvim_set_hl(0, "SciVim15", { fg = "#1A446E", ctermfg = 23 })
		vim.api.nvim_set_hl(0, "SciVim14", { fg = "#1C506B", ctermfg = 23 })
		vim.api.nvim_set_hl(0, "SciVimPy3", { fg = "#1D5D68", ctermfg = 23 })
		vim.api.nvim_set_hl(0, "SciVim13", { fg = "#1E6965", ctermfg = 23 })
		vim.api.nvim_set_hl(0, "SciVim12", { fg = "#1F7562", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVimPy4", { fg = "#21825F", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVim11", { fg = "#228E5C", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVim10", { fg = "#239B59", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVim9", { fg = "#24A755", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVim8", { fg = "#26B352", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVimPy5", { fg = "#27C04F", ctermfg = 29 })
		vim.api.nvim_set_hl(0, "SciVim7", { fg = "#28CC4C", ctermfg = 41 })
		vim.api.nvim_set_hl(0, "SciVim6", { fg = "#29D343", ctermfg = 41 })
		vim.api.nvim_set_hl(0, "SciVim5", { fg = "#EC9F05", ctermfg = 214 })
		vim.api.nvim_set_hl(0, "SciVim4", { fg = "#F08C04", ctermfg = 208 })
		vim.api.nvim_set_hl(0, "SciVimPy6", { fg = "#F37E03", ctermfg = 208 })
		vim.api.nvim_set_hl(0, "SciVim3", { fg = "#F77002", ctermfg = 202 })
		vim.api.nvim_set_hl(0, "SciVim2", { fg = "#FB5D01", ctermfg = 202 })
		vim.api.nvim_set_hl(0, "SciVim1", { fg = "#FF4E00", ctermfg = 202 })
	end,
})

local function fixConfig()
	local path = vim.fn.getcwd() .. "/pyproject.toml"
	local exist_path = vim.loop.fs_stat(path) ~= nil

	if not exist_path then
		local temp = [[
[tool.pyright]
  include = ["src","**/*.py"]
  exclude = ["**/node_modules",
    "**/__pycache__",
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
select = ["E4", "E7", "E9", "F"]
ignore = []

fixable = ["ALL"]
unfixable = []

dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"

[tool.ruff.format]
quote-style = "double"

indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
docstring-code-format = false
docstring-code-line-length = "dynamic"

    ]]
		local file, err = io.open(path, "w")
		if file then
			file:write(temp)
			file:close()
			print("Python Configured")
		else
			error("Failed to create pyproject.toml: " .. tostring(err))
		end
	end
end

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = augroup("PythonConfig"),
	pattern = { "python" },
	callback = function()
		fixConfig()
	end,
})

-- vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
-- 	pattern = { "tex", "*.tex" },
-- 	callback = function()
-- 		vim.lsp.start({
-- 			name = "textLSP",
-- 			cmd = { "textlsp" },
-- 			settings = {
-- 				textLSP = {
-- 					analysers = {
-- 						languagetool = {
-- 							enabled = true,
-- 							check_text = {
-- 								on_open = true,
-- 								on_save = true,
-- 								on_change = false,
-- 							},
-- 						},
-- 						ollama = {
-- 							enabled = true,
-- 							check_text = {
-- 								on_open = false,
-- 								on_save = true,
-- 								on_change = false,
-- 							},
-- 							model = "phi3:3.8b-instruct", -- smaller but faster model
-- 							-- model = "phi3:14b-instruct",  -- more accurate
-- 							max_token = 50,
-- 						},
-- 						gramformer = {
-- 							-- gramformer dependency needs to be installed manually
-- 							enabled = false,
-- 							gpu = false,
-- 							check_text = {
-- 								on_open = false,
-- 								on_save = true,
-- 								on_change = false,
-- 							},
-- 						},
-- 						hf_checker = {
-- 							enabled = false,
-- 							gpu = false,
-- 							quantize = 32,
-- 							model = "pszemraj/flan-t5-large-grammar-synthesis",
-- 							min_length = 40,
-- 							check_text = {
-- 								on_open = false,
-- 								on_save = true,
-- 								on_change = false,
-- 							},
-- 						},
-- 						hf_instruction_checker = {
-- 							enabled = false,
-- 							gpu = false,
-- 							quantize = 32,
-- 							model = "grammarly/coedit-large",
-- 							min_length = 40,
-- 							check_text = {
-- 								on_open = false,
-- 								on_save = true,
-- 								on_change = false,
-- 							},
-- 						},
-- 						hf_completion = {
-- 							enabled = false,
-- 							gpu = false,
-- 							quantize = 32,
-- 							model = "bert-base-multilingual-cased",
-- 							topk = 5,
-- 						},
-- 						-- openai = {
-- 						-- 	enabled = false,
-- 						-- 	api_key = "<MY_API_KEY>",
-- 						-- 	-- url = '<CUSTOM_URL>'  -- optional to use an OpenAI-compatible server
-- 						-- 	check_text = {
-- 						-- 		on_open = false,
-- 						-- 		on_save = false,
-- 						-- 		on_change = false,
-- 						-- 	},
-- 						-- 	model = "gpt-3.5-turbo",
-- 						-- 	max_token = 16,
-- 						-- },
-- 						-- grammarbot = {
-- 						-- 	enabled = false,
-- 						-- 	api_key = "<MY_API_KEY>",
-- 						-- 	-- longer texts are split, this parameter sets the maximum number of splits per analysis
-- 						-- 	input_max_requests = 1,
-- 						-- 	check_text = {
-- 						-- 		on_open = false,
-- 						-- 		on_save = false,
-- 						-- 		on_change = false,
-- 						-- 	},
-- 						-- },
-- 					},
-- 					documents = {
-- 						-- the language of the documents, could be set to `auto` of `auto:<fallback>`
-- 						-- to detect automatically, default: auto:en
-- 						language = "auto:en",
-- 						-- do not autodetect documents with fewer characters
-- 						min_length_language_detect = 20,
-- 						org = {
-- 							org_todo_keywords = {
-- 								"TODO",
-- 								"IN_PROGRESS",
-- 								"DONE",
-- 							},
-- 						},
-- 						txt = {
-- 							parse = true,
-- 						},
-- 					},
-- 				},
-- 			},
-- 		})
-- 	end,
-- })
