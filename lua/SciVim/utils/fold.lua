local M = {}

-- Function to set up custom folding
function M.setup_folding()
	-- Set folding options
	vim.o.foldmethod = "expr" -- Use expression-based folding
	vim.o.foldexpr = "nvim_treesitter#foldexpr()" -- Use Treesitter for folding
	vim.o.foldlevelstart = 99 -- Start with all folds open

	-- Define custom icons for folded and unfolded states
	vim.cmd([[
        highlight Folded guibg=#282c34 guifg=#61afef
        set foldtext=M.custom_fold_text()
    ]])
end

-- Function to toggle folding
function M.toggle_fold()
	local fold_level = vim.fn.foldlevel(".")
	if fold_level > 0 then
		vim.cmd("normal! za") -- Toggle fold
	end
end

function M.custom_fold_text()
	local start_line = vim.fn.getline(vim.v.foldstart)
	local end_line = vim.fn.getline(vim.v.foldend)
	local fold_icon = "" -- Custom icon for folded state
	local line_number = vim.v.foldstart
	return line_number .. " " .. fold_icon .. " " .. start_line .. " ... " .. end_line
end

-- Initialize the folding setup
function M.init()
	M.setup_folding()
end

return M
