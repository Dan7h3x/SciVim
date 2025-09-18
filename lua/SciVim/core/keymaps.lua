local map = vim.keymap.set

map({ "n", "x" }, "j", "v:count == 2 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 2 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 2 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 2 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map({ "n", "x" }, "<Home>", "^", { desc = "Go to first non-blank character", noremap = true })
map("i", "<Home>", "<C-o>^", { desc = "Go to first non-blank character", noremap = true })

map({ "n", "i", "v", "s" }, "<C-s>", "<Cmd>w<CR><esc>", { desc = "Save", noremap = true, silent = true })
map({ "n", "i" }, "<leader>xx", "<Cmd>source $MYVIMRC <CR><esc>", { desc = "Source", noremap = true, silent = true })

map("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Quit", noremap = true, silent = true })
map("n", "<A-a>", "gg<S-v>G", { desc = "Select All", noremap = true, silent = true })

map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "<S-Down>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<S-Up>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<S-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<S-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<S-Down>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<S-Up>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

map("n", "<C-h>", "<C-w>h", { desc = "Focus Left", noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Focus Down", noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Focus Up", noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Focus Right", noremap = true, silent = true })

map("n", "<C-Up>", "<Cmd> resize +2<CR>", { desc = "Inc Height", noremap = true, silent = true })
map("n", "<C-Down>", "<Cmd> resize -2<CR>", { desc = "Dec Height", noremap = true, silent = true })
map("n", "<C-Left>", "<Cmd> vertical resize +2<CR>", { desc = "Inc Width", noremap = true, silent = true })
map("n", "<C-Right>", "<Cmd> vertical resize -2<CR>", { desc = "Dec Width", noremap = true, silent = true })

map("n", "n", "'Nn'[v:searchforward].'zzzv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zzzv'", { expr = true, desc = "Prev Search Result" })

map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keyword help", noremap = true, silent = true })
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "line diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "next diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "prev diagnostic" })
map("n", "]e", diagnostic_goto(true, "error"), { desc = "next error" })
map("n", "[e", diagnostic_goto(false, "error"), { desc = "prev error" })
map("n", "]w", diagnostic_goto(true, "warn"), { desc = "next warning" })
map("n", "[w", diagnostic_goto(false, "warn"), { desc = "prev warning" })

map("n", "<leader>ui", vim.show_pos, { desc = "inspect pos" })
map("n", "<leader>uI", "<cmd>InspectTree<cr>", { desc = "inspect tree" })

map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<leader>wl", "<CMD>wincmd L<CR>", { desc = "To Vertical", remap = true })
map("n", "<leader>wh", "<CMD>wincmd H<CR>", { desc = "To Horizontal", remap = true })

map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

local function get_all_buffer_filetypes()
	local buffer_filetypes = {}

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

		buffer_filetypes[bufnr] = filetype
	end
	return buffer_filetypes
end

map("n", "<leader>Bf", function()
	local files = get_all_buffer_filetypes()
	for bufnr, filetype in pairs(files) do
		vim.notify("Buffer " .. bufnr .. " has ft: " .. filetype)
	end
end, { desc = "Filetype Checker" })

map("n", "<leader>ss", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { desc = "Replace word under cursor" })
map({ "n", "i" }, "<F8>", "<Cmd>OpenPDF<CR>", { silent = true })
map("n", "<leader>X", "<cmd>!chmod +x %<CR>", { desc = "Make executable", silent = true })

map("n", "<leader>sl", "<CMD>.lua<CR>", { desc = "Exec line in lua" })
map("n", "<leader>s;", "<CMD>source %<CR>", { desc = "Exec file in lua" })
map("n", "<M-j>", function()
	if vim.opt.diff:get() then
		vim.cmd([[normal! ]c]])
	else
		vim.cmd([[m .+1<CR>==]])
	end
end)

map("n", "<M-k>", function()
	if vim.opt.diff:get() then
		vim.cmd([[normal! [c]])
	else
		vim.cmd([[m .-2<CR>==]])
	end
end)

map("n", "=ap", "ma=ap'a", { desc = "Indenter" })
map("n", "<leader>cc", function()
	local current_pos = vim.api.nvim_win_get_cursor(0)
	local filetype = vim.api.nvim_get_option_value("filetype", { buf = 0 })

	local base_patterns = {

		"silent! %s/^\\s*\\/\\/.*//g",
		"silent! %s/^\\s*#.*//g",
		"silent! %s/^\\s*;.*//g",
		"silent! %s/^\\s*%%.*//g",

		"silent! %s/\\s\\+\\/\\/.*//g",
		"silent! %s/\\s\\+#.*//g",
		"silent! %s/\\s\\+;.*//g",
		"silent! %s/\\s\\+%%.*//g",

		"silent! %s/\\/\\*.*\\*\\///g",
		"silent! %s/<!\\-\\-.*\\-\\->//g",

		"silent! %s/\\s\\+$//g",
	}

	local language_patterns = {
		lua = {
			"silent! %s/^\\s*--.*//g",
			"silent! %s/--\\[\\[.*\\]\\]//g",
			"silent! %s/--\\[=\\[.*\\]=\\]//g",
			"silent! %s/\\s\\+--.*//g",
		},
		typst = {
			"silent! %s/^\\s*\\/\\/.*//g",
			"silent! %s/^\\s*#.*//g",
			"silent! %s/^\\s*%%.*//g",
			"silent! %s/\\s\\+\\/\\/.*//g",
			"silent! %s/\\s\\+#.*//g",
			"silent! %s/\\s\\+%%.*//g",
		},
		python = {
			"silent! %s/^\\s*#.*//g",
			"silent! %s/\\s\\+#.*//g",
		},
		javascript = {
			"silent! %s/^\\s*\\/\\/.*//g",
			"silent! %s/\\s\\+\\/\\/.*//g",
			"silent! %s/\\/\\*.*\\*\\///g",
		},
		c = {
			"silent! %s/^\\s*\\/\\/.*//g",
			"silent! %s/\\s\\+\\/\\/.*//g",
			"silent! %s/\\/\\*.*\\*\\///g",
		},
		cpp = {
			"silent! %s/^\\s*\\/\\/.*//g",
			"silent! %s/\\s\\+\\/\\/.*//g",
			"silent! %s/\\/\\*.*\\*\\///g",
		},
	}

	local patterns_to_use = base_patterns
	if language_patterns[filetype] then
		for _, pattern in ipairs(language_patterns[filetype]) do
			table.insert(patterns_to_use, pattern)
		end
	end

	for _, cmd in ipairs(patterns_to_use) do
		local success = pcall(function()
			vim.cmd(cmd)
		end)
		if not success then
			vim.notify(
				"Can't remove comments for " .. filetype .. " files!",
				vim.log.levels.WARN,
				{ title = "Comments Remove", source = "SciVim" }
			)
		end
	end

	vim.api.nvim_win_set_cursor(0, current_pos)

	vim.notify(
		"Comments removal completed for " .. filetype .. " files!",
		vim.log.levels.INFO,
		{ title = "Comments Remove", source = "SciVim" }
	)
end, { desc = "Remove Comments" })

require("SciVim.extras.notifs").setup()
map("n", "<leader>n", "<CMD>FlNotif<CR>", { desc = "Notifications" })
