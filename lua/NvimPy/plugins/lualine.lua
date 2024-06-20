return {
	{
		"nvim-lualine/lualine.nvim",
		event = { "VimEnter", "VeryLazy" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		init = function()
			vim.g.lualine_laststatus = vim.o.laststatus
			if vim.fn.argc(-1) > 0 then
				vim.o.statusline = " "
			else
				vim.o.laststatus = 0
			end
		end,
		config = function()
			local lualine = require("lualine")
			---@diagnostic disable-next-line: unused-function
			local function trunc(trunc_width, trunc_len, hide_width, no_ellipsis)
				return function(str)
					local win_width = vim.fn.winwidth(0)
					if hide_width and win_width < hide_width then
						return ""
					elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
						return str:sub(1, trunc_len) .. (no_ellipsis and "" or "...")
					end
					return str
				end
			end

			vim.o.laststatus = vim.g.lualine_laststatus

      -- Color table for highlights
      -- stylua: ignore
      local colors = require("NvimPy.configs.colors")
			local icons = require("NvimPy.configs.icons")

			local conditions = {
				buffer_not_empty = function()
					return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
				end,
				hide_in_width = function()
					return vim.fn.winwidth(0) > 80
				end,
				check_git_workspace = function()
					local filepath = vim.fn.expand("%:p:h")
					local gitdir = vim.fn.finddir(".git", filepath .. ";")
					return gitdir and #gitdir > 0 and #gitdir < #filepath
				end,
			}

			-- Config
			local config = {
				options = {
					-- Disable sections and component separators
					component_separators = "",

					disabled_filetypes = {
						"alpha",
						"dashboard",
						"starter",
						"neo-tree",
						"Outline",
						"terminal",
						"lazy",
						"undotree",
						"Telescope",
						"dapui*",
						"dapui_scopes",
						"dapui_watches",
						"dapui_console",
						"dapui_breakpoints",
						"dapui_stacks",
						"dap-repl",
						"term",
						"zsh",
						"bash",
						"shell",
						"terminal",
						"toggleterm",
						"termim",
						"REPL",
						"repl",
						"Iron",
						"Ipython",
						"ipython",
						"spectre_panel",
						"Trouble",
						"help",
						"hoversplit",
						"which_key",
					},
					theme = {
						-- We are going to use lualine_c an lualine_x as left and
						-- right section. Both are highlighted by c theme .  So we
						-- are just setting default looks o statusline
						normal = { c = { fg = "None", bg = "None" } },
						inactive = { c = { fg = "None", bg = "None" } },
					},
				},
				sections = {
					-- these are to remove the defaults
					lualine_a = {},
					lualine_b = {},
					lualine_y = {},
					lualine_z = {},
					-- These will be filled later
					lualine_c = {},
					lualine_x = {},
				},
				inactive_sections = {
					-- these are to remove the defaults
					lualine_a = {},
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
			}

			-- Inserts a component in lualine_c at left section
			local function ins_left(component)
				table.insert(config.sections.lualine_c, component)
			end

			-- Inserts a component in lualine_x at right section
			local function ins_right(component)
				table.insert(config.sections.lualine_x, component)
			end

			ins_left({
				function()
					return ""
				end,
				color = function()
					-- auto change color according to neovims mode
					local mode_color = {
						n = colors.red["700"],
						i = colors.green["800"],
						v = colors.blue["500"],
						[""] = colors.blue["900"],
						V = colors.blue["800"],
						c = colors.pink["400"],
						no = colors.red["400"],
						s = colors.orange["400"],
						S = colors.orange["700"],
						[""] = colors.orange["900"],
						ic = colors.yellow["700"],
						R = colors.purple["500"],
						Rv = colors.purple["800"],
						cv = colors.red["300"],
						ce = colors.red["500"],
						r = colors.blue["200"],
						rm = colors.blue["300"],
						["r?"] = colors.blue["400"],
						["!"] = colors.red["200"],
						t = colors.red["300"],
					}
					return { fg = mode_color[vim.fn.mode()], bg = "None" }
				end,
				padding = -1,
			})
			ins_left({
				-- mode component
				function()
					return ""
				end,
				color = function()
					-- auto change color according to neovims mode
					local mode_color = {
						n = colors.red["700"],
						i = colors.green["800"],
						v = colors.blue["500"],
						[""] = colors.blue["900"],
						V = colors.blue["800"],
						c = colors.pink["400"],
						no = colors.red["400"],
						s = colors.orange["400"],
						S = colors.orange["700"],
						[""] = colors.orange["900"],
						ic = colors.yellow["700"],
						R = colors.purple["500"],
						Rv = colors.purple["800"],
						cv = colors.red["300"],
						ce = colors.red["500"],
						r = colors.blue["200"],
						rm = colors.blue["300"],
						["r?"] = colors.blue["400"],
						["!"] = colors.red["200"],
						t = colors.red["300"],
					}
					return { bg = mode_color[vim.fn.mode()], fg = colors.white }
				end,
				padding = { left = -3, right = 1 },
			})

			ins_left({
				"location",
				color = { bg = colors.dark["800"], fg = colors.todo },
				padding = { left = -1, right = -1 },
			})

			ins_left({
				function()
					return ""
				end,
				color = function()
					-- auto change color according to neovims mode
					local mode_color = {
						n = colors.red["700"],
						i = colors.green["800"],
						v = colors.blue["500"],
						[""] = colors.blue["900"],
						V = colors.blue["800"],
						c = colors.pink["400"],
						no = colors.red["400"],
						s = colors.orange["400"],
						S = colors.orange["700"],
						[""] = colors.orange["900"],
						ic = colors.yellow["700"],
						R = colors.purple["500"],
						Rv = colors.purple["800"],
						cv = colors.red["300"],
						ce = colors.red["500"],
						r = colors.blue["200"],
						rm = colors.blue["300"],
						["r?"] = colors.blue["400"],
						["!"] = colors.red["200"],
						t = colors.red["300"],
					}
					return { fg = mode_color[vim.fn.mode()], bg = "None" }
				end,

				padding = -2,
			})

			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.blue["500"], bg = "None" },
				padding = { left = -1, right = -1 },
			})

			ins_left({
				"filename",
				path = 0,
				icon = { "", color = { fg = colors.white } },
				color = { fg = colors.todo, bg = colors.dark["800"] },
				padding = 1,
			})

			ins_left({
				"filetype",
				cond = conditions.buffer_not_empty,
				color = { bg = colors.dark["800"], fg = colors.blue["400"] },
			})
			ins_left({
				-- filesize component
				"filesize",
				cond = conditions.buffer_not_empty,
				padding = -1,
				icon = { "", color = { fg = colors.white } },
				color = { bg = colors.dark["800"], fg = colors.green["500"] },
			})
			ins_left({
				"encoding",
				color = { fg = colors.green["500"], bg = colors.dark["800"] },
			})
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.blue["500"], bg = "None" },
				padding = -1,
			})

			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.green["600"], bg = "None" },
				padding = -2,
			})
			ins_left({
				-- Lsp server name .
				function()
					local bufcl = vim.lsp.get_clients()
					local null_server, null = pcall(require("null-ls"))
					local bufcl_names = {}
					local Utils = require("NvimPy.utils.init")
					for _, cl in pairs(bufcl) do
						if cl.name == "null-ls" then
							if null_server then
								for _, src in ipairs(null.get_source({ filetype = vim.bo.filetype })) do
									table.insert(bufcl_names, src.name)
								end
							end
						else
							table.insert(bufcl_names, cl.name)
						end
					end
					return table.concat(Utils.unique(bufcl_names), ",")
				end,
				icon = { " ", color = { fg = colors.yellow["500"] } },
				color = { fg = colors.todo, bg = colors.dark["800"], gui = "bold" },
				padding = -1,
			})
			ins_left({
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = {
					error = icons.diagnostics.Error,
					warn = icons.diagnostics.Warn,
					info = icons.diagnostics.Info,
				},
				diagnostics_color = {
					color_error = { fg = colors.red["700"] },
					color_warn = { fg = colors.yellow["500"] },
					color_info = { fg = colors.blue["500"] },
				},
				color = { bg = colors.dark["800"] },
				padding = { left = 1, right = 0 },
			})
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.green["600"], bg = "None" },
				padding = { left = 0, right = 0 },
			})

			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				padding = -2,
			})
			ins_right({
				function()
					return require("pomodoro").statusline()
				end,
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				color = { fg = colors.blue["500"], bg = colors.dark["800"], gui = "bold" },
				padding = -1,
			})
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				padding = -2,
			})

			ins_right({
				"branch",
				icon = { "", color = { fg = colors.todo, bg = colors.dark["800"] } },
				color = { fg = colors.todo, bg = colors.dark["800"], gui = "bold" },
			})
			local function diff_source()
				local gitsigns = vim.b.gitsigns_status_dict
				if gitsigns then
					return {
						added = gitsigns.added,
						modified = gitsigns.changed,
						removed = gitsigns.removed,
					}
				end
			end
			ins_right({
				"diff",
				-- Is it me or the symbol for modified us really weird
				symbols = { modified = icons.git.modified, added = icons.git.added, removed = icons.git.removed },
				source = diff_source(),
				diff_color = {
					added = { fg = colors.green["500"], bg = colors.primary["900"] },
					modified = { fg = colors.orange["500"], bg = colors.primary["900"] },
					removed = { fg = colors.red["500"], bg = colors.primary["900"] },
				},
				cond = conditions.hide_in_width,
				color = { bg = colors.dark["800"], fg = colors.purple["500"] },
			})

			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				padding = -2,
				cond = function()
					return vim.b.gitsigns_blame_line ~= nil
				end,
			})

			ins_right({
				function()
					return vim.b.gitsigns_blame_line .. "!"
				end,
				cond = function()
					return vim.b.gitsigns_blame_line ~= nil
				end,
				color = { bg = colors.dark["800"], fg = colors.pink["700"] },
			})
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				padding = 0,
				cond = function()
					return vim.b.gitsigns_blame_line ~= nil
				end,
			})

			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				padding = -2,
			})

			ins_right({
				function()
					return require("dap").status()
				end,
				cond = function()
					return package.loaded["dap"] and require("dap").status() ~= ""
				end,
				icon = { "", color = { fg = colors.green["500"], bg = colors.dark["800"] } },
				color = { bg = colors.dark["800"], fg = colors.green["500"] },
			})

			ins_right({
				require("lazy.status").updates,
				cond = require("lazy.status").has_updates,
				color = { fg = colors.orange["500"], bg = colors.dark["800"] },
			})

			ins_right({
				function()
					return os.date("%R")
				end,
				color = { fg = colors.orange["500"], bg = colors.dark["800"] },
				icon = { "", color = { fg = colors.blue["400"] } },
				padding = -1,
			})
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.dark["800"], bg = "None" },
				padding = -2,
			})
			-- Now don't forget to initialize lualine
			lualine.setup(config)
		end,
	},
}
