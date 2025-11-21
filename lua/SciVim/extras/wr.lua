---@brief [[
--- Writegood integration for Neovim
---
--- This plugin integrates the `writegood` command-line tool into Neovim to check
--- grammar and style issues in your text files. It can display errors as diagnostics
--- or populate the quickfix list, allowing you to jump to and fix issues.
---
--- Usage:
---   :Writegood          - Check grammar in the current buffer
---   :WritegoodClear     - Clear writegood diagnostics
---
--- Keymaps (default):
---   <leader>wg          - Run writegood check
---   <leader>wgc         - Clear diagnostics
---
--- Navigation:
---   When using diagnostics mode, use standard Neovim diagnostic navigation:
---   ]d / [d             - Jump to next/previous diagnostic
---   <leader>lg          - View diagnostics (if using fzf-lua)
---
---   When using quickfix mode:
---   :cnext / :cprev     - Navigate through quickfix entries
---   :copen              - Open quickfix window
---
--- Configuration:
---   require("SciVim.extras.wr").setup({
---     use_diagnostics = true,  -- Use diagnostics (true) or quickfix (false)
---     auto_check = false,      -- Auto check on save
---     filetypes = { "markdown", "text", "gitcommit" },
---     severity = vim.diagnostic.severity.INFO,
---   })
---@brief ]]

local M = {}

local namespace = vim.api.nvim_create_namespace("writegood")

-- Configuration
local config = {
	-- Command to run writegood (can be 'writegood' or 'npx write-good')
	cmd = "writegood",
	-- Additional arguments to pass to writegood
	args = { "--parse", "--yes-eprime" },
	-- File types to enable writegood on
	filetypes = { "markdown", "text", "gitcommit", "tex", "plaintex" },
	-- Auto check on save
	auto_check = true,
	-- Use diagnostics (true) or quickfix list (false)
	use_diagnostics = true,
	-- Severity level for diagnostics (Error, Warn, Info, Hint)
	severity = vim.diagnostic.severity.WARN,
}

-- Check if writegood is available
local function check_writegood_available()
	local cmd = vim.fn.executable(config.cmd)
	if cmd == 0 then
		-- Try npx as fallback
		if vim.fn.executable("npx") == 1 then
			config.cmd = "npx"
			table.insert(config.args, 1, "write-good")
			return true
		end
		return false
	end
	return true
end

-- Parse writegood output into diagnostics/quickfix entries
local function parse_output(output, bufnr)
	local diagnostics = {}
	local qflist = {}

	for _, line in ipairs(output) do
		-- Format: filename:line:column:message
		-- Example: /tmp/test.txt:1:10:"very" is a weasel word and can weaken meaning
		-- The message may or may not have quotes around the word
		local filename, line_num, col_num, message = line:match("^([^:]+):(%d+):(%d+):(.+)")

		if filename and line_num and col_num and message then
			local line_idx = tonumber(line_num) - 1 -- 0-indexed
			local col_idx = tonumber(col_num) - 1 -- 0-indexed

			-- Get the actual line content to find the exact position
			local lines = vim.api.nvim_buf_get_lines(bufnr, line_idx, line_idx + 1, false)
			if #lines > 0 then
				local line_text = lines[1]
				-- Extract the word/phrase from the message (it's usually quoted)
				local word = message:match('^"([^"]+)"')
				if word then
					-- Find the position of the word in the line starting from the reported column
					local search_start = math.max(1, col_idx + 1)
					local start_pos = line_text:find(vim.pesc(word), search_start, true)
					if start_pos then
						col_idx = start_pos - 1
					end
				else
					-- If no quoted word, try to find the first word in the message
					word = message:match("^([^ ]+)")
					if word then
						local search_start = math.max(1, col_idx + 1)
						local start_pos = line_text:find(vim.pesc(word), search_start, true)
						if start_pos then
							col_idx = start_pos - 1
						end
					end
				end
			end

			local diagnostic = {
				lnum = line_idx,
				col = col_idx,
				message = message,
				severity = config.severity,
				source = "writegood",
			}

			table.insert(diagnostics, diagnostic)

			-- Quickfix entry
			table.insert(qflist, {
				bufnr = bufnr,
				lnum = line_idx + 1, -- 1-indexed for quickfix
				col = col_idx + 1, -- 1-indexed for quickfix
				text = message,
			})
		end
	end

	return diagnostics, qflist
end

-- Run writegood on the current buffer
local function run_writegood(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not check_writegood_available() then
		vim.notify(
			"writegood is not available. Please install it with: npm install -g write-good",
			vim.log.levels.ERROR
		)
		return
	end

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filename = vim.api.nvim_buf_get_name(bufnr)

	-- Create a temporary file if buffer is not saved
	local temp_file = nil
	if filename == "" or vim.bo[bufnr].modified then
		temp_file = vim.fn.tempname()
		vim.fn.writefile(lines, temp_file)
		filename = temp_file
	end

	-- Build command
	local cmd_args = vim.list_extend({}, config.args)
	table.insert(cmd_args, filename)

	-- Run writegood
	local job = vim.fn.jobstart({ config.cmd, unpack(cmd_args) }, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data, _)
			-- Filter out empty lines
			local output = vim.tbl_filter(function(line)
				return line ~= ""
			end, data)

			-- Clean up temp file first
			if temp_file and vim.fn.filereadable(temp_file) == 1 then
				vim.fn.delete(temp_file)
			end

			if #output > 0 then
				-- Map temp file references to actual buffer
				local mapped_output = {}
				for _, line in ipairs(output) do
					if temp_file then
						-- Replace temp file path with actual buffer name
						line = line:gsub(vim.pesc(temp_file), vim.api.nvim_buf_get_name(bufnr))
					end
					table.insert(mapped_output, line)
				end

				local diagnostics, qflist = parse_output(mapped_output, bufnr)

				-- Set diagnostics
				if config.use_diagnostics then
					vim.diagnostic.set(namespace, bufnr, diagnostics, {})
					if #diagnostics > 0 then
						vim.notify(string.format("Found %d grammar issue(s)", #diagnostics), vim.log.levels.INFO)
					end
				end

				-- Set quickfix list
				if #qflist > 0 then
					vim.fn.setqflist(qflist, "r")
					if not config.use_diagnostics then
						vim.cmd("copen")
						vim.notify(string.format("Found %d grammar issue(s)", #qflist), vim.log.levels.INFO)
					end
				else
					if config.use_diagnostics then
						vim.diagnostic.set(namespace, bufnr, {}, {})
						vim.notify("No grammar issues found!", vim.log.levels.INFO)
					else
						vim.cmd("cclose")
						vim.notify("No grammar issues found!", vim.log.levels.INFO)
					end
				end
			else
				-- Clear diagnostics if no issues
				if config.use_diagnostics then
					vim.diagnostic.set(namespace, bufnr, {}, {})
				end
				vim.notify("No grammar issues found!", vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data, _)
			local error_msg = table.concat(
				vim.tbl_filter(function(line)
					return line ~= ""
				end, data),
				"\n"
			)
			if error_msg ~= "" and not error_msg:match("not a valid argument") then
				vim.notify("writegood error: " .. error_msg, vim.log.levels.ERROR)
			end
			-- Clean up temp file on error
			if temp_file and vim.fn.filereadable(temp_file) == 1 then
				vim.fn.delete(temp_file)
			end
		end,
		on_exit = function(_, exit_code, _)
			-- Exit code 255 is normal for writegood when issues are found
			-- Exit code 0 means no issues found
			-- Other exit codes might indicate an error, but we handle it in on_stderr
		end,
	})

	if job <= 0 then
		vim.notify("Failed to start writegood job", vim.log.levels.ERROR)
		if temp_file and vim.fn.filereadable(temp_file) == 1 then
			vim.fn.delete(temp_file)
		end
	end
end

-- Clear writegood diagnostics
local function clear_diagnostics(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	vim.diagnostic.set(namespace, bufnr, {}, {})
end

-- Setup function
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", config, opts)

	-- Create user commands
	vim.api.nvim_create_user_command("Writegood", function()
		run_writegood()
	end, { desc = "Check grammar with writegood" })

	vim.api.nvim_create_user_command("WritegoodClear", function()
		clear_diagnostics()
	end, { desc = "Clear writegood diagnostics" })

	-- Auto check on save if enabled
	if config.auto_check then
		local augroup = vim.api.nvim_create_augroup("WritegoodAutoCheck", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = augroup,
			pattern = "*",
			callback = function()
				local ft = vim.bo.filetype
				if vim.tbl_contains(config.filetypes, ft) then
					run_writegood()
				end
			end,
		})
	end

	-- Keymaps (optional, can be customized)
	vim.keymap.set("n", "<leader>lc", function()
		run_writegood()
	end, { desc = "Check grammar with writegood" })

	vim.keymap.set("n", "<leader>lC", function()
		clear_diagnostics()
	end, { desc = "Clear writegood diagnostics" })
end

-- Export functions
M.run = run_writegood
M.clear = clear_diagnostics

return M
