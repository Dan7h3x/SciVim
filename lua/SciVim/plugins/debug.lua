vim.api.nvim_create_augroup("DapGroup", { clear = true })

local function navigate(args)
	local buffer = args.buf

	local wid = nil
	local win_ids = vim.api.nvim_list_wins() -- Get all window IDs
	for _, win_id in ipairs(win_ids) do
		local win_bufnr = vim.api.nvim_win_get_buf(win_id)
		if win_bufnr == buffer then
			wid = win_id
		end
	end

	if wid == nil then
		return
	end

	vim.schedule(function()
		if vim.api.nvim_win_is_valid(wid) then
			vim.api.nvim_set_current_win(wid)
		end
	end)
end

local function create_nav_options(name)
	return {
		group = "DapGroup",
		pattern = string.format("*%s*", name),
		callback = navigate,
	}
end

return {
	{
		"mfussenegger/nvim-dap",
		ft = "python",
		config = function()
			local dap = require("dap")
			dap.set_log_level("DEBUG")

			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<leader>so", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<leader>si", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<leader>sp", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>dh", require("dap.ui.widgets").hover, { desc = "Debug: Hover" })
			vim.keymap.set("n", "<leader>dp", require("dap.ui.widgets").preview, { desc = "Debug: Preview" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>cb", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Conditional Breakpoint" })

			vim.fn.sign_define("DapBreakpoint", { text = "🔴" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "❓" })
			vim.fn.sign_define("DapLogPoint", { text = "📝" })
			vim.fn.sign_define("DapStopped", { text = "⛔" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "💀" })

			----------------
			dap.adapters.python = {
				type = "executable",
				command = "python",
				args = { "-m", "debugpy.adapter" },
			}
			dap.adapters.lua = function(callback, config)
				callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
			end
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch Python File",
					program = "${file}",
					pythonPath = function()
						return vim.fn.exepath("python3")
					end,
				},
				{
					type = "python",
					request = "attach",
					name = "Attach to Process",
					processId = require("dap.utils").pick_process,
				},
			}
			dap.configurations.lua = {
				{
					type = "nlua",
					request = "attach",
					name = "Attach to Neovim",
				},
			}
		end,
	},

	{
		"rcarriga/nvim-dap-ui",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local function layout(name)
				return {
					elements = {
						{ id = name },
					},
					enter = true,
					size = 0.33,
					position = "right",
				}
			end
			local name_to_layout = {
				repl = { layout = layout("repl"), index = 0 },
				stacks = { layout = layout("stacks"), index = 0 },
				scopes = { layout = layout("scopes"), index = 0 },
				console = { layout = layout("console"), index = 0 },
				watches = { layout = layout("watches"), index = 0 },
				breakpoints = { layout = layout("breakpoints"), index = 0 },
			}
			local layouts = {}

			for name, config in pairs(name_to_layout) do
				table.insert(layouts, config.layout)
				name_to_layout[name].index = #layouts
			end

			local function toggle_debug_ui(name)
				dapui.close()
				local layout_config = name_to_layout[name]

				if layout_config == nil then
					error(string.format("bad name: %s", name))
				end

				local uis = vim.api.nvim_list_uis()[1]
				if uis ~= nil then
					layout_config.size = uis.width
				end

				pcall(dapui.toggle, layout_config.index)
			end

			vim.keymap.set("n", "<leader>dr", function()
				toggle_debug_ui("repl")
			end, { desc = "Debug: toggle repl ui" })
			vim.keymap.set("n", "<leader>ds", function()
				toggle_debug_ui("stacks")
			end, { desc = "Debug: toggle stacks ui" })
			vim.keymap.set("n", "<leader>dw", function()
				toggle_debug_ui("watches")
			end, { desc = "Debug: toggle watches ui" })
			vim.keymap.set("n", "<leader>db", function()
				toggle_debug_ui("breakpoints")
			end, { desc = "Debug: toggle breakpoints ui" })
			vim.keymap.set("n", "<leader>dS", function()
				toggle_debug_ui("scopes")
			end, { desc = "Debug: toggle scopes ui" })
			vim.keymap.set("n", "<leader>du", function()
				toggle_debug_ui("console")
			end, { desc = "Debug: toggle console ui" })

			vim.api.nvim_create_autocmd("BufEnter", {
				group = "DapGroup",
				pattern = "*dap-repl*",
				callback = function()
					vim.wo.wrap = true
				end,
			})

			vim.api.nvim_create_autocmd("BufWinEnter", create_nav_options("dap-repl"))
			vim.api.nvim_create_autocmd("BufWinEnter", create_nav_options("DAP Watches"))

			dapui.setup({
				layouts = layouts,
				enter = true,
			})

			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			dap.listeners.after.event_output.dapui_config = function(_, body)
				if body.category == "console" then
					dapui.eval(body.output) -- Sends stdout/stderr to Console
				end
			end
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		ft = "python",
		dependencies = {
			"mason-org/mason.nvim",
			"mfussenegger/nvim-dap",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"debugpy",
				},
				automatic_installation = true,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
					-- delve = function(config)
					-- 	table.insert(config.configurations, 1, {
					-- 		args = function()
					-- 			return vim.split(vim.fn.input("args> "), " ")
					-- 		end,
					-- 		type = "delve",
					-- 		name = "file",
					-- 		request = "launch",
					-- 		program = "${file}",
					-- 		outputMode = "remote",
					-- 	})
					-- 	table.insert(config.configurations, 1, {
					-- 		args = function()
					-- 			return vim.split(vim.fn.input("args> "), " ")
					-- 		end,
					-- 		type = "delve",
					-- 		name = "file args",
					-- 		request = "launch",
					-- 		program = "${file}",
					-- 		outputMode = "remote",
					-- 	})
					-- 	require("mason-nvim-dap").default_setup(config)
					-- end,
				},
			})
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		ft = "python",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enable_commands = true,
				highlight_changed_variables = true,
				highlight_new_as_changed = false,
				show_stop_reason = true,
				commented = false,
				only_first_definition = true,
				all_references = false,
				display_callback = function(variable, buf, stackframe, node, options)
					return variable.name .. " = " .. variable.value
				end,
				virt_text_pos = "eol", -- eol, overlay, or inline
				all_frames = false,
				virt_lines = false,
				virt_text_win_col = nil,
			})
		end,
	},
}
