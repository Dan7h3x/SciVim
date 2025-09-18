--[[
-- AutoCmds for SciVim
--]]
local function augroup(name)
	return vim.api.nvim_create_augroup("SciVim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("opening"),
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("treesitter_folding"),
	desc = "Enable Treesitter folding",
	callback = function(args)
		local bufnr = args.buf

		-- Enable Treesitter folding when not in huge files and when Treesitter
		-- is working.
		if vim.bo[bufnr].filetype ~= "bigfile" and pcall(vim.treesitter.start, bufnr) then
			vim.api.nvim_buf_call(bufnr, function()
				vim.wo[0][0].foldmethod = "expr"
				vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.cmd.normal("zx")
			end)
		else
			-- Else just fallback to using indentation.
			vim.wo[0][0].foldmethod = "indent"
		end
	end,
})
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
	pattern = { "*.txt", "*.md" },
	callback = function()
		if vim.o.filetype == "help" or vim.o.filetype == "man" then
			vim.cmd.wincmd("L")
		end
	end,
	desc = "Help/Man page at right",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
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
		"dap-float",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "tex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
		vim.opt_local.colorcolumn = "0"
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
		vim.api.nvim_set_hl(0, "SciVim6", { fg = "#47D326", ctermfg = 41 })
		vim.api.nvim_set_hl(0, "SciVim5", { fg = "#ECCF05", ctermfg = 214 })
		vim.api.nvim_set_hl(0, "SciVim4", { fg = "#F0AC04", ctermfg = 208 })
		vim.api.nvim_set_hl(0, "SciVimPy6", { fg = "#F39E03", ctermfg = 208 })
		vim.api.nvim_set_hl(0, "SciVim3", { fg = "#F77909", ctermfg = 202 })
		vim.api.nvim_set_hl(0, "SciVim2", { fg = "#FB5D01", ctermfg = 202 })
		vim.api.nvim_set_hl(0, "SciVim1", { fg = "#FF4E00", ctermfg = 202 })
	end,
})

-- Additional autocmd for Python-specific settings
vim.api.nvim_create_autocmd({ "FileType", "BufReadPost", "BufNewFile" }, {
	pattern = { "python", "*.py" },
	callback = function()
		-- Python-specific buffer settings
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.expandtab = true
		vim.opt_local.autoindent = true
		vim.opt_local.smartindent = true
		vim.cmd("silent! retab")
	end,
})

local openPDF = augroup("openPDF")
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = {
		"*.pdf",
	},
	callback = function()
		vim.fn.jobstart({ "zathura", vim.fn.expand("%:p") }, { detach = true })
	end,
	group = openPDF,
})
-- vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
-- 	pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp" },
-- 	callback = function()
-- 		local filepath = vim.fn.expand("%:p")
-- 		local escaped_path = string.gsub(filepath, "'", "'\"'\"'")
--
-- 		-- Check if file exists
-- 		if vim.fn.filereadable(filepath) == 0 then
-- 			vim.notify("File not found: " .. filepath, vim.log.levels.WARN)
-- 			return
-- 		end
--
-- 		local cmd = ""
-- 		local platform = vim.loop.os_uname().sysname
--
-- 		-- Cross-platform image viewer detection
-- 		if platform == "Linux" or platform == "Darwin" then
-- 			if platform == "Linux" then
-- 				-- Try different Linux image viewers
-- 				cmd = string.format(
-- 					"([ -x \"$(command -v viewnior)\" ] && viewnior '%s') || "
-- 						.. "([ -x \"$(command -v eog)\" ] && eog '%s') || "
-- 						.. "([ -x \"$(command -v xdg-open)\" ] && xdg-open '%s') &",
-- 					escaped_path,
-- 					escaped_path,
-- 					escaped_path
-- 				)
-- 			else
-- 				-- macOS
-- 				cmd = string.format("open '%s' &", escaped_path)
-- 			end
-- 		elseif platform:match("Windows") then
-- 			-- Windows
-- 			cmd = string.format('start "" "%s"', filepath)
-- 		else
-- 			vim.notify("Unsupported platform: " .. platform, vim.log.levels.ERROR)
-- 			return
-- 		end
--
-- 		local success, _, code = os.execute(cmd)
-- 		if not success and code ~= 0 and platform ~= "Windows" then
-- 			vim.notify("Failed to open image viewer", vim.log.levels.ERROR)
-- 		end
--
-- 		-- Close the buffer immediately
-- 		vim.schedule(function()
-- 			vim.cmd("bwipeout!")
-- 		end)
-- 	end,
-- })
vim.api.nvim_create_user_command("OpenPDF", function()
	local filepath = vim.api.nvim_buf_get_name(0)
	if not filepath:match("%.typ$") and not filepath:match("%.tex$") then
		vim.notify("Can't open pdf related to .typ or .tex file", vim.log.levels.WARN)
		return
	end
	if filepath:match("%.typ$") or filepath:match("%.tex$") then
		if filepath:match("%.typ$") then
			os.execute("zathura " .. vim.fn.shellescape(filepath:gsub("%.typ$", ".pdf")) .. " &>/dev/null &")
		else
			os.execute("zathura " .. vim.fn.shellescape(filepath:gsub("%.tex$", ".pdf")) .. " &>/dev/null &")
		end
	end
end, { force = true })

vim.api.nvim_create_user_command("Todos", function()
	require("fzf-lua").grep({ search = [[TODO:|todo!\(.*\)|FIXME|FIX]], no_esc = true })
end, { desc = "Grep TODOs", nargs = 0 })
