local M = {}

-- Function to set up custom folding with VS Code-like appearance
function M.setup_folding()
	-- Set folding options

	-- Auto commands for better folding behavior
	local folding_group = vim.api.nvim_create_augroup("CustomFolding", { clear = true })

	-- Save and restore fold state
	vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
		group = folding_group,
		pattern = "*",
		command = "silent! mkview",
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		group = folding_group,
		pattern = "*",
		command = "silent! loadview",
	})
end

-- VS Code-style fold text with better formatting
function M.custom_fold_text()
	local start_line = vim.fn.getline(vim.v.foldstart)
	local end_line_num = vim.v.foldend
	local start_line_num = vim.v.foldstart
	local lines_count = end_line_num - start_line_num + 1

	-- Clean up the start line (remove leading whitespace for display)
	local cleaned_start = start_line:gsub("^%s*", "")

	-- VS Code-style icons and formatting
	local fold_icon = "" -- Collapsed folder icon
	local line_count_text = string.format("(%d lines folded)", lines_count)

	-- Get window width for proper alignment
	local win_width = vim.fn.winwidth(0)
	local line_num_width = vim.o.number and vim.o.numberwidth or 0
	local fold_col_width = vim.o.foldcolumn
	local available_width = win_width - line_num_width - fold_col_width - 10

	-- Truncate if necessary
	local display_text = cleaned_start
	if #display_text > available_width - #line_count_text - 10 then
		display_text = display_text:sub(1, available_width - #line_count_text - 13) .. "..."
	end

	-- Create the fold text with VS Code-style formatting
	local fold_text = string.format("%s %s %s", fold_icon, display_text, line_count_text)

	return fold_text
end

-- Enhanced fold toggle with better logic
function M.toggle_fold()
	local line = vim.fn.line(".")
	local fold_level = vim.fn.foldlevel(line)

	if fold_level > 0 then
		local fold_closed = vim.fn.foldclosed(line)
		if fold_closed == -1 then
			-- Fold is open, close it
			vim.cmd("normal! zc")
		else
			-- Fold is closed, open it
			vim.cmd("normal! zo")
		end
	else
		-- No fold at current line, try to find and create one
		vim.cmd("normal! zf")
	end
end

-- Smart fold navigation
function M.next_fold()
	vim.cmd("normal! zj")
end

function M.prev_fold()
	vim.cmd("normal! zk")
end

-- Fold all at specific level
function M.fold_level(level)
	vim.cmd("normal! zM") -- Close all folds first
	if level > 0 then
		vim.o.foldlevel = level
	end
end

-- Open/close all folds
function M.open_all_folds()
	vim.cmd("normal! zR")
end

function M.close_all_folds()
	vim.cmd("normal! zM")
end

-- Set up key mappings for VS Code-like experience
function M.setup_keymaps()
	local opts = { noremap = true, silent = true }

	-- Toggle fold at cursor
	vim.keymap.set("n", "<Tab>", M.toggle_fold, opts)

	-- Navigate between folds
	vim.keymap.set("n", "]z", M.next_fold, opts)
	vim.keymap.set("n", "[z", M.prev_fold, opts)

	-- Fold level controls (like VS Code's Ctrl+K Ctrl+1, etc.)
	vim.keymap.set("n", "<leader>z1", function()
		M.fold_level(1)
	end, opts)
	vim.keymap.set("n", "<leader>z2", function()
		M.fold_level(2)
	end, opts)
	vim.keymap.set("n", "<leader>z3", function()
		M.fold_level(3)
	end, opts)
	vim.keymap.set("n", "<leader>z4", function()
		M.fold_level(4)
	end, opts)

	-- Open/close all
	vim.keymap.set("n", "<leader>za", M.open_all_folds, opts)
	vim.keymap.set("n", "<leader>zc", M.close_all_folds, opts)
end

-- Initialize everything
function M.init()
	M.setup_folding()
	M.setup_keymaps()
end

-- Setup function for lazy loading
function M.setup(opts)
	opts = opts or {}

	-- Allow customization of icons and colors
	if opts.fold_icon then
		M.fold_icon = opts.fold_icon
	end

	if opts.colors then
		for highlight, color in pairs(opts.colors) do
			vim.cmd(string.format("highlight %s %s", highlight, color))
		end
	end

	M.init()
end

return M
