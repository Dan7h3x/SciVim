-- REPL Feature Examples for terminal.nvim
-- This file demonstrates all REPL capabilities

local term = require("terminal")

-- ==============================================================================
-- BASIC REPL USAGE
-- ==============================================================================

-- Setup with REPL enabled
term.setup({
	default_direction = "horizontal",
	default_size = 15,

	-- REPL configuration
	repl = {
		auto_start = true, -- Auto-start REPL when sending code
		auto_close = false, -- Auto-close REPL when buffer closes
		save_history = true, -- Save command history

		-- Custom keymaps (can be overridden)
		keymaps = {
			send_line = "<leader>rl",
			send_selection = "<leader>rs",
			send_paragraph = "<leader>rp",
			send_buffer = "<leader>rb",
			toggle_repl = "<leader>rt",
			clear_repl = "<leader>rc",
			interrupt = "<leader>ri",
			exit = "<leader>rq",
		},
	},
})

-- ==============================================================================
-- STARTING REPLs
-- ==============================================================================

-- Start Python REPL
term.repl_start("python")

-- Start IPython REPL with custom options
term.repl_start("ipython", {
	direction = "vertical",
	size = 80,
})

-- Start Node.js REPL
term.repl_start("node", {
	direction = "float",
	float_opts = {
		width = 0.7,
		height = 0.7,
		border = "rounded",
	},
})

-- Start REPL for current buffer's filetype
-- (automatically detects language from filetype)
term.repl_start()

-- ==============================================================================
-- SUPPORTED LANGUAGES
-- ==============================================================================

-- Python
term.repl_start("python") -- Standard Python REPL
term.repl_start("ipython") -- IPython with magic commands

-- JavaScript/TypeScript
term.repl_start("node") -- Node.js REPL

-- Lua
term.repl_start("lua") -- Lua REPL

-- Ruby
term.repl_start("ruby") -- IRB REPL

-- Julia
term.repl_start("julia") -- Julia REPL

-- R
term.repl_start("r") -- R REPL

-- Shell
term.repl_start("bash") -- Bash shell
term.repl_start("zsh") -- Zsh shell

-- Functional languages
term.repl_start("haskell") -- GHCi
term.repl_start("scheme") -- Guile Scheme
term.repl_start("racket") -- Racket
term.repl_start("clojure") -- Clojure
term.repl_start("ocaml") -- OCaml
term.repl_start("scala") -- Scala

-- Elixir/Erlang
term.repl_start("elixir") -- IEx
term.repl_start("erlang") -- Erlang shell

-- ==============================================================================
-- SENDING CODE TO REPL
-- ==============================================================================

-- Send current line to REPL
term.repl_send_line()

-- Send visual selection to REPL
term.repl_send_selection()

-- Send current paragraph to REPL
-- (blank-line separated block)
term.repl_send_paragraph()

-- Send entire buffer to REPL
term.repl_send_buffer()

-- ==============================================================================
-- REPL CONTROL
-- ==============================================================================

-- Toggle REPL visibility
term.repl_toggle()
term.repl_toggle("python")

-- Clear REPL screen
term.repl_clear()

-- Interrupt running code (Ctrl-C)
term.repl_interrupt()

-- Exit REPL
term.repl_exit()
term.repl_exit("python")

-- ==============================================================================
-- ADVANCED USAGE
-- ==============================================================================

-- Get direct access to REPL instance
local python_repl = term.repl_get("python")
if python_repl then
	-- Send custom code
	python_repl:send("import numpy as np")
	python_repl:send({ "x = [1, 2, 3]", "print(x)" })

	-- Execute file
	python_repl:execute_file("/path/to/script.py")

	-- Execute current buffer
	python_repl:execute_buffer()

	-- Access history
	local prev = python_repl:history_prev()
	local next = python_repl:history_next()

	-- Clear history
	python_repl:history_clear()
end

-- ==============================================================================
-- LANGUAGE-SPECIFIC FEATURES
-- ==============================================================================

-- Python with custom configuration
term.repl_start("python", {
	direction = "vertical",
}, {
	auto_import = true, -- Auto-import numpy, pandas, matplotlib
	startup_commands = {
		"import sys",
		'sys.ps1 = ">>> "',
	},
})

-- IPython with magic commands
term.repl_start("ipython", nil, {
	startup_commands = {
		"%load_ext autoreload",
		"%autoreload 2",
		"%matplotlib inline",
	},
})

-- Node.js with async/await support
term.repl_start("node")
-- The REPL automatically wraps async code in IIFE

-- Haskell with multiline support
term.repl_start("haskell")
-- Use :{ and :} for multiline definitions

-- ==============================================================================
-- KEYMAPS FOR REPL WORKFLOW
-- ==============================================================================

-- These are automatically set up for supported filetypes
-- You can customize them in the setup

vim.keymap.set("n", "<leader>rl", term.repl_send_line, { desc = "Send line to REPL" })

vim.keymap.set("v", "<leader>rs", term.repl_send_selection, { desc = "Send selection to REPL" })

vim.keymap.set("n", "<leader>rp", term.repl_send_paragraph, { desc = "Send paragraph to REPL" })

vim.keymap.set("n", "<leader>rb", term.repl_send_buffer, { desc = "Send buffer to REPL" })

vim.keymap.set("n", "<leader>rt", term.repl_toggle, { desc = "Toggle REPL" })

vim.keymap.set("n", "<leader>rc", term.repl_clear, { desc = "Clear REPL" })

vim.keymap.set("n", "<leader>ri", term.repl_interrupt, { desc = "Interrupt REPL" })

vim.keymap.set("n", "<leader>rq", term.repl_exit, { desc = "Exit REPL" })

-- ==============================================================================
-- WORKFLOW EXAMPLES
-- ==============================================================================

-- Example 1: Python Data Science Workflow
vim.keymap.set("n", "<leader>rds", function()
	-- Start IPython with data science setup
	term.repl_start("ipython", {
		direction = "vertical",
		size = 80,
	}, {
		auto_import = true,
		startup_commands = {
			"import numpy as np",
			"import pandas as pd",
			"import matplotlib.pyplot as plt",
			"import seaborn as sns",
			"%matplotlib inline",
		},
	})
end, { desc = "Start data science REPL" })

-- Example 2: JavaScript Development Workflow
vim.keymap.set("n", "<leader>rjs", function()
	-- Start Node REPL for current project
	local cwd = vim.fn.getcwd()
	term.repl_start("node", {
		direction = "float",
		cwd = cwd,
	})
end, { desc = "Start JavaScript REPL" })

-- Example 3: Send and execute workflow
vim.keymap.set("n", "<leader>re", function()
	-- Send line and move to next
	term.repl_send_line()
	vim.cmd("normal! j")
end, { desc = "Send line and move down" })

-- Example 4: Quick Python evaluation
vim.keymap.set("v", "<leader>rE", function()
	-- Send selection and show in REPL
	term.repl_send_selection()

	-- Focus REPL window
	local repl = term.repl_get("python")
	if repl then
		repl:focus()
	end
end, { desc = "Evaluate selection in Python" })

-- ==============================================================================
-- CUSTOM REPL CONFIGURATION
-- ==============================================================================

-- Create custom REPL with specific behavior
local TerminalRepl = require("terminal.repl")

local custom_python = TerminalRepl:new("python", {
	direction = "horizontal",
	size = 20,
}, {
	prompt_pattern = ">>> ",
	auto_import = true,
	startup_commands = {
		"import sys",
		'sys.path.insert(0, "/my/custom/path")',
	},
	code_wrapper = function(code)
		-- Custom code transformation
		return code
	end,
})

custom_python:open()
custom_python:send('print("Hello from custom REPL")')

-- ==============================================================================
-- REPL WITH CALLBACKS
-- ==============================================================================

-- Monitor REPL output
term.repl_start("python", {
	on_stdout = function(terminal, job_id, data, event)
		for _, line in ipairs(data) do
			if line:match("Error") or line:match("Exception") then
				vim.notify("Error in REPL: " .. line, vim.log.levels.ERROR)
			end
		end
	end,

	on_close = function(terminal, exit_code)
		vim.notify("REPL exited with code: " .. exit_code, vim.log.levels.INFO)
	end,
})

-- ==============================================================================
-- FILETYPE-SPECIFIC AUTOCOMMANDS
-- ==============================================================================

-- Auto-start REPL for Python files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		-- Setup additional keymaps
		vim.keymap.set("n", "<F5>", function()
			term.repl_send_buffer()
		end, { buffer = true, desc = "Run buffer in Python REPL" })

		vim.keymap.set("n", "<F6>", function()
			local line = vim.fn.line(".")
			term.repl_send_line(nil, line)
			vim.cmd("normal! j")
		end, { buffer = true, desc = "Send line and move down" })
	end,
})

-- ==============================================================================
-- TIPS AND TRICKS
-- ==============================================================================

--[[
1. Auto-import common libraries
   - Set auto_import = true for Python/IPython
   - Automatically imports numpy, pandas, matplotlib

2. Bracketed paste mode
   - Automatically enabled for supported REPLs
   - Prevents issues with indented code

3. Multiline input
   - IPython: Use %cpaste and --
   - Haskell: Use :{ and :}
   - Python: Just paste multiline code

4. History navigation
   - Access previous commands with history_prev()
   - History persists across sessions

5. Execute files
   - Use execute_file() to run entire scripts
   - Use execute_buffer() to run current buffer

6. Custom code wrappers
   - Transform code before sending to REPL
   - Useful for adding imports, wrapping in functions, etc.

7. Interrupt long-running code
   - Use repl_interrupt() to send Ctrl-C
   - Different sequences for different REPLs

8. Clear REPL screen
   - Use repl_clear() for a fresh start
   - Language-specific clear commands

9. Multiple REPLs
   - Run different REPLs for different languages simultaneously
   - Each REPL tracks its own history

10. Integration with testing
    - Send test code to REPL for interactive debugging
    - Use callbacks to detect test failures
]]

-- ==============================================================================
-- COMMON PATTERNS
-- ==============================================================================

-- Pattern 1: Test-driven development
vim.keymap.set("n", "<leader>rtt", function()
	-- Send test function and run it
	term.repl_send_paragraph()
	vim.defer_fn(function()
		term.repl_send_line() -- Assuming next line calls the test
	end, 100)
end, { desc = "Send test and run" })

-- Pattern 2: Data exploration
vim.keymap.set("n", "<leader>rde", function()
	-- Send dataframe creation and show info
	local python_repl = term.repl_get("python")
	if python_repl then
		python_repl:send({
			"import pandas as pd",
			'df = pd.read_csv("data.csv")',
			"print(df.info())",
			"print(df.head())",
		})
	end
end, { desc = "Data exploration" })

-- Pattern 3: Live coding presentation
vim.keymap.set("n", "<leader>rlc", function()
	-- Start REPL in float for live coding
	term.repl_start(nil, {
		direction = "float",
		float_opts = {
			width = 0.9,
			height = 0.4,
			row = 0.55,
			col = 0.05,
			border = "rounded",
		},
	})
end, { desc = "Live coding REPL" })
