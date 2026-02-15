return {
	{
		-- "Dan7h3x/neaterm.nvim",
		-- branch = "stable",
		dir = "~/.config/nvim/lua/neaterm/",
		event = "VeryLazy",
		enabled = true,
		keys = {
			{ "<F2>", "<CMD>NeatermScooter<CR>" },
			{ "<F4>", "<CMD>NeatermYazi<CR>" },
			{ "<F5>", "<CMD>NeatermLazygit<CR>" },
		},
		opts = {
			-- Terminal settings
			shell = vim.o.shell,
			float_width = 0.5,
			float_height = 0.4,
			move_amount = 3,
			resize_amount = 2,
			border = "rounded",

			-- Appearance
			highlights = {
				normal = "Normal",
				border = "FloatBorder",
				title = "Title",
			},

			-- Window management
			min_width = 20,
			min_height = 3,

			-- custom terminals
			terminals = {
				yazi = {
					name = "Yazi",
					cmd = "yazi",
					type = "float",
					float_width = 0.8,
					float_height = 0.8,
					keymaps = {
						quit = "q",
						select = "<CR>",
						preview = "p",
					},
					-- on_exit = function(selected_file)
					-- 	if selected_file then
					-- 		vim.cmd("edit " .. selected_file)
					-- 	end
					-- end,
				},
				lazygit = {
					name = "LazyGit",
					cmd = "lazygit",
					type = "float",
					float_width = 0.9,
					float_height = 0.9,
					keymaps = {
						quit = "q",
						commit = "c",
						push = "P",
					},
				},
				scooter = {
					name = "Scooter",
					cmd = "scooter",
					type = "float",
					float_width = 0.7,
					float_height = 0.9,
					keymaps = {
						quit = "q",
					},
				},
			},

			-- Default keymaps
			use_default_keymaps = true,
			keymaps = {
				toggle = "<A-t>",
				new_vertical = "<A-\\>",
				new_horizontal = "<A-/>",
				new_float = "<C-A-t>",
				close = "<A-d>",
				next = "<C-PageDown>",
				prev = "<C-PageUp>",
				move_up = "<C-A-Up>",
				move_down = "<C-A-Down>",
				move_left = "<C-A-Left>",
				move_right = "<C-A-Right>",
				resize_up = "<C-S-Up>",
				resize_down = "<C-S-Down>",
				resize_left = "<C-S-Left>",
				resize_right = "<C-S-Right>",
				focus_bar = "<C-A-b>",
				repl_toggle = "<leader>rt",
				repl_send_line = "<leader>rl",
				repl_send_selection = "<leader>rs",
				repl_send_buffer = "<leader>rb",
				repl_send_block = "<leader>sb", -- Send current code block
				repl_inspector = "<leader>si", -- Toggle variable inspector

				repl_clear = "<leader>rc",
				repl_history = "<leader>rh",
				repl_variables = "<leader>rv",
				repl_restart = "<leader>rR",
			},

			-- REPL configurations
			repl = {
				float_width = 0.6,
				float_height = 0.4,
				save_history = true,
				history_file = vim.fn.stdpath("data") .. "/neaterm_repl_history.json",
				max_history = 100,
				update_interval = 5000,
				auto_inspect = true, -- Automatically open inspector for new REPLs
				inspect_interval = 1000, -- Update interval in milliseconds
				inspect_position = "right", -- Where to show the inspector (left/right)
				inspect_width = 0.2, -- Width of the inspector window (0-1)
			},

			-- REPL language configurations
			repl_configs = {
				python = {
					name = "Python (IPython)",
					cmd = "ipython --no-autoindent --colors='Linux'",
					type = "vertical",
					startup_cmds = {
						-- "import sys",
						-- "sys.ps1 = 'In []: '",
						-- "sys.ps2 = '   ....: '",
					},
					get_variables_cmd = "whos",
					inspect_variable_cmd = "?",
					exit_cmd = "exit()",
				},
				r = {
					name = "R (Radian)",
					cmd = "radian",
					startup_cmds = {
						-- "options(width = 80)",
						-- "options(prompt = 'R> ')",
					},
					get_variables_cmd = "ls.str()",
					inspect_variable_cmd = "str(",
					exit_cmd = "q(save='no')",
				},
				lua = {
					name = "Lua",
					cmd = "lua5.1",
					exit_cmd = "os.exit()",
				},
				node = {
					name = "Node.js",
					cmd = "node",
					get_variables_cmd = "Object.keys(global)",
					exit_cmd = ".exit",
				},
				sh = {
					name = "Shell",
					cmd = vim.o.shell,
					startup_cmds = {
						"PS1='$ '",
						"TERM=xterm-256color",
					},
					get_variables_cmd = "set",
					inspect_variable_cmd = "echo $",
					exit_cmd = "exit",
				},
			},

			-- Terminal features
			features = {
				auto_insert = true,
				auto_close = true,
				restore_layout = true,
				smart_sizing = true,
				persistent_history = true,
				native_search = true,
				clipboard_sync = true,
				shell_integration = true,
				completion = {
					enable = true,
					trigger_chars = { ".", "_" },
					max_items = 50,
				},
				plot_viewer = {
					enable = true,
					auto_update = true,
					width = 0.4,
					height = 0.4,
					position = "right", -- or "left"
				},
				debug = {
					enable = true,
					signs = {
						breakpoint = "●",
						current_line = "→",
					},
					highlight = {
						breakpoint = "ErrorMsg",
						current_line = "DiffAdd",
					},
				},
				workspace = {
					enable = true,
					auto_save = true,
					save_interval = 300, -- seconds
				},
				package_manager = {
					enable = true,
					auto_update_check = true,
				},
				snippets = {
					enable = true,
					expand_trigger = "<Tab>",
				},
				documentation = {
					enable = true,
					auto_show = true,
					width = 0.4,
					height = 0.4,
					position = "right",
				},
			},
		},
		config = function(_, opts)
			require("neaterm").setup(opts)
		end,
		dependencies = {
			-- "nvim-lua/plenary.nvim",
			-- "ibhagwan/fzf-lua",
		},
	},
	{
		dir = "~/.config/nvim/lua/terminal/",
		enabled = false,
		opts = {
			-- Default terminal direction
			default_direction = "horizontal",

			-- Default size (15 rows for horizontal, 80 columns for vertical)
			default_size = 15,

			-- Close terminal when process exits
			close_on_exit = false,

			-- Auto-scroll to bottom on new output
			auto_scroll = true,

			-- Start in insert mode when opening
			start_in_insert = true,

			-- Default shell
			shell = vim.o.shell,

			-- Remember terminal sizes across toggles
			persist_size = true,

			-- Remember insert/normal mode state
			persist_mode = true,
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
		},
		config = function(_, opts)
			local term = require("terminal")
			term.setup(opts)
			vim.keymap.set("n", "<C-\\>", function()
				term.toggle(1)
			end, { desc = "Toggle terminal" })
			vim.keymap.set("t", "<C-\\>", function()
				term.toggle(1)
			end, { desc = "Toggle terminal" })

			-- Quick terminal types
			vim.keymap.set("n", "<leader>tf", term.float, { desc = "Float terminal" })
			vim.keymap.set("n", "<leader>th", term.horizontal, { desc = "Horizontal terminal" })
			vim.keymap.set("n", "<leader>tv", term.vertical, { desc = "Vertical terminal" })
			vim.keymap.set("n", "<leader>tt", term.tab, { desc = "Tab terminal" })

			-- Terminal navigation (from terminal mode)
			vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
			vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
			vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
			vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })

			-- Exit terminal mode
			vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

			-- Terminal selector
			vim.keymap.set("n", "<leader>ts", term.select, { desc = "Select terminal" })

			-- Send code to terminal
			vim.keymap.set("n", "<leader>sl", function()
				term.send_line(1)
			end, { desc = "Send line to terminal" })

			vim.keymap.set("v", "<leader>ss", function()
				term.send_selection(1)
			end, { desc = "Send selection to terminal" })

			-- Send custom command
			vim.keymap.set("n", "<leader>sc", function()
				local cmd = vim.fn.input("Command: ")
				if cmd ~= "" then
					term.send(1, cmd)
				end
			end, { desc = "Send command to terminal" })

			-- Close all terminals
			vim.keymap.set("n", "<leader>tC", term.close_all, { desc = "Close all terminals" })

			-- Kill all terminals
			vim.keymap.set("n", "<leader>tK", term.kill_all, { desc = "Kill all terminals" })

			vim.keymap.set("n", "<leader>tp", function()
				term.toggle(2, "python3", {
					direction = "vertical",
					size = 80,
					start_in_insert = true,
				})
			end, { desc = "Python REPL" })

			-- Node REPL
			vim.keymap.set("n", "<leader>tn", function()
				term.toggle(3, "node", {
					direction = "float",
					float_opts = {
						width = 0.7,
						height = 0.7,
						border = "rounded",
					},
				})
			end, { desc = "Node REPL" })

			-- Lazygit
			vim.keymap.set("n", "<leader>tg", function()
				term.toggle(4, "lazygit", {
					direction = "float",
					close_on_exit = true,
					float_opts = {
						width = 0.9,
						height = 0.9,
						border = "rounded",
					},
					on_open = function(terminal)
						-- Hide line numbers in lazygit
						vim.wo[terminal:get_winnr()].number = false
						vim.wo[terminal:get_winnr()].relativenumber = false
					end,
				})
			end, { desc = "Lazygit" })

			-- htop
			vim.keymap.set("n", "<leader>tH", function()
				term.run("htop", {
					direction = "tab",
					close_on_exit = true,
				})
			end, { desc = "htop" })
			vim.keymap.set("n", "<leader>tr", function()
				local ft = vim.bo.filetype
				local file = vim.fn.expand("%:p")
				local cmd = nil

				if ft == "python" then
					cmd = "python3 " .. file
				elseif ft == "javascript" or ft == "typescript" then
					cmd = "node " .. file
				elseif ft == "lua" then
					cmd = "lua " .. file
				elseif ft == "sh" or ft == "bash" then
					cmd = "bash " .. file
				elseif ft == "ruby" then
					cmd = "ruby " .. file
				elseif ft == "rust" then
					cmd = "cargo run"
				elseif ft == "go" then
					cmd = "go run " .. file
				end

				if cmd then
					term.run(cmd, {
						direction = "horizontal",
						size = 15,
						close_on_exit = false,
					})
				else
					vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
				end
			end, { desc = "Run current file" })
		end,
	},
}
