return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local lualine = require("lualine")
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

      -- Color table for highlights
      -- stylua: ignore
      local colors = {
        bg      = '#000000',
        fg      = '#82aaff',
        glass   = '#1a1b26',
        yellow  = '#CCFF00',
        cyan    = '#00FEFC',
        green   = '#39FF14',
        orange  = '#F6890A',
        magenta = '#E23DA5',
        blue    = '#4D4DFF',
        red     = '#FF3131',
      }

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

			local function ins_left_Inactive(component)
				table.insert(config.inactive_sections.lualine_c, component)
			end

			-- Inserts a component in lualine_x at right section
			local function ins_right_Inactive(component)
				table.insert(config.inactive_sections.lualine_x, component)
			end

			-- ins_left({
			-- 	function()
			-- 		return ""
			-- 	end,
			-- 	color = function()
			-- 		-- auto change color according to neovims mode
			-- 		local mode_color = {
			-- 			n = colors.red,
			-- 			i = colors.green,
			-- 			v = colors.blue,
			-- 			[""] = colors.blue,
			-- 			V = colors.blue,
			-- 			c = colors.magenta,
			-- 			no = colors.red,
			-- 			s = colors.orange,
			-- 			S = colors.orange,
			-- 			[""] = colors.orange,
			-- 			ic = colors.yellow,
			-- 			R = colors.purple,
			-- 			Rv = colors.purple,
			-- 			cv = colors.red,
			-- 			ce = colors.red,
			-- 			r = colors.cyan,
			-- 			rm = colors.cyan,
			-- 			["r?"] = colors.cyan,
			-- 			["!"] = colors.red,
			-- 			t = colors.red,
			-- 		}
			-- 		return { fg = mode_color[vim.fn.mode()], bg = "None" }
			-- 	end,
			--
			-- 	padding = { left = 0, right = -1 },
			-- })
			ins_left({
				-- mode component
				function()
					return " "
				end,
				color = function()
					-- auto change color according to neovims mode
					local mode_color = {
						n = colors.red,
						i = colors.green,
						v = colors.blue,
						[""] = colors.blue,
						V = colors.blue,
						c = colors.magenta,
						no = colors.red,
						s = colors.orange,
						S = colors.orange,
						[""] = colors.orange,
						ic = colors.yellow,
						R = colors.purple,
						Rv = colors.purple,
						cv = colors.red,
						ce = colors.red,
						r = colors.cyan,
						rm = colors.cyan,
						["r?"] = colors.cyan,
						["!"] = colors.red,
						t = colors.red,
					}
					return { bg = mode_color[vim.fn.mode()], fg = colors.bg, gui = "bold" }
				end,
				padding = { left = 0, right = 0 },
			})

			-- ins_left({
			-- 	function()
			-- 		return ""
			-- 	end,
			-- 	color = function()
			-- 		-- auto change color according to neovims mode
			-- 		local mode_color = {
			-- 			n = colors.red,
			-- 			i = colors.green,
			-- 			v = colors.blue,
			-- 			[""] = colors.blue,
			-- 			V = colors.blue,
			-- 			c = colors.magenta,
			-- 			no = colors.red,
			-- 			s = colors.orange,
			-- 			S = colors.orange,
			-- 			[""] = colors.orange,
			-- 			ic = colors.yellow,
			-- 			R = colors.purple,
			-- 			Rv = colors.purple,
			-- 			cv = colors.red,
			-- 			ce = colors.red,
			-- 			r = colors.cyan,
			-- 			rm = colors.cyan,
			-- 			["r?"] = colors.cyan,
			-- 			["!"] = colors.red,
			-- 			t = colors.red,
			-- 		}
			-- 		return { fg = mode_color[vim.fn.mode()], bg = "None" }
			-- 	end,
			-- 	padding = 0,
			-- })
			-- ins_left({
			--   function()
			--     return "%="
			--   end,
			--   color = { fg = "None", bg = "None" },
			-- })
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})
			ins_left({
				-- filesize component
				"filesize",
				cond = conditions.buffer_not_empty,
				padding = -1,
				color = { bg = colors.bg, fg = colors.green },
			})
			ins_left({
				"filetype",
				cond = conditions.buffer_not_empty,
				color = { bg = colors.bg, fg = colors.blue },
			})
			ins_left({
				"location",
				color = { bg = colors.bg, fg = colors.magenta },
				padding = { left = -1, right = -1 },
			})

			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})

			-- Insert mid section. You can make any number of sections in neovim :)
			-- for lualine it's any number greater then 2
			-- ins_left({
			--   function()
			--     return "%="
			--   end,
			--   color = { fg = "None", bg = "None" },
			-- })
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				padding = -2,
			})
			ins_left({
				function()
					return require("pomodoro").statusline()
				end,
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				color = { fg = colors.cyan, bg = colors.bg, gui = "bold" },
				padding = -1,
			})
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				cond = function()
					local pomstat = require("pomodoro").statusline()
					return not string.find(pomstat, "inactive")
				end,
				padding = -2,
			})

			-- Insert mid section. You can make any number of sections in neovim :)
			-- for lualine it's any number greater then 2
			-- ins_left({
			--   function()
			--     return "%="
			--   end,
			--   color = { fg = "None", bg = "None" },
			-- })
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})
			ins_left({
				-- Lsp server name .
				function()
					local bufcl = vim.lsp.get_clients()
					local null_server, null = pcall(require("null-ls"))
					local bufcl_names = {}
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
					return table.concat(bufcl_names, ",")
				end,
				icon = { " ", color = { fg = colors.green } },
				color = { fg = colors.magenta, bg = colors.bg, gui = "bold" },
				padding = -1,
			})
			ins_left({
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = " ", warn = " ", info = " " },
				diagnostics_color = {
					color_error = { fg = colors.red },
					color_warn = { fg = colors.yellow },
					color_info = { fg = colors.cyan },
				},
				color = { bg = colors.bg },
				padding = { left = 1, right = -1 },
			})
			ins_left({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = { left = 0, right = 0 },
			})

			-- ins_right({
			--   function()
			--     return "%="
			--   end,
			--   color = { fg = "None", bg = "None" },
			-- })
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})
			-- ins_right({
			-- 	function()
			-- 		local res = vim.fn.getcwd()
			-- 		local home = os.getenv("HOME")
			-- 		if home and vim.startswith(res, home) then
			-- 			res = " " .. res:sub(home:len() + 1) .. "/"
			-- 		else
			-- 			res = " "
			-- 		end
			-- 		return res
			-- 	end,
			-- 	icon = { "", color = { fg = colors.orange } },
			-- 	color = { fg = colors.yellow, bg = colors.bg },
			-- 	padding = { left = 0, right = 0 },
			-- 	fmt = trunc(120, 20, 60),
			-- })
			ins_right({
				"filename",
				path = 0,
				icon = { "", color = { fg = colors.orange } },
				color = { fg = colors.purple, bg = colors.bg },
				padding = 0,
			})
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = 0,
			})
			-- InacTives

			ins_left_Inactive({
				function()
					return "-----%="
				end,
				color = { fg = colors.purple, bg = colors.glass, gui = "bold" },
			})

			ins_right_Inactive({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})
			-- ins_right_Inactive({
			-- 	function()
			-- 		local res = vim.fn.getcwd()
			-- 		local home = os.getenv("HOME")
			-- 		if home and vim.startswith(res, home) then
			-- 			res = " " .. res:sub(home:len() + 1) .. "/"
			-- 		else
			-- 			res = " "
			-- 		end
			-- 		return res
			-- 	end,
			-- 	icon = { "", color = { fg = colors.orange } },
			-- 	color = { fg = colors.yellow, bg = colors.bg },
			-- 	padding = { left = 0, right = 0 },
			-- })
			ins_right_Inactive({
				"filename",
				path = 3,
				icon = { "", color = { fg = colors.orange } },
				color = { fg = colors.purple, bg = colors.bg },
				padding = 0,
			})
			ins_right_Inactive({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = 0,
			})
			ins_right_Inactive({
				function()
					return "%=-----"
				end,
				color = { fg = colors.purple, bg = colors.glass, gui = "bold" },
			})

			-- ins_right({
			--   function()
			--     return "%="
			--   end,
			--   color = { fg = "None", bg = "None" },
			-- })

			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})

			ins_right({
				function()
					return require("dap").status()
				end,
				cond = function()
					return package.loaded["dap"] and require("dap").status() ~= ""
				end,
				icon = { " ", color = { fg = colors.green } },
				color = { bg = colors.bg },
			})

			ins_right({
				"branch",
				icon = { " ", color = { fg = colors.purple } },
				color = { fg = colors.purple, bg = colors.bg, gui = "bold" },
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
				symbols = { added = " ", modified = "柳 ", removed = " " },
				source = diff_source(),
				diff_color = {
					added = { fg = colors.green, bg = colors.glass },
					modified = { fg = colors.orange, bg = colors.glass },
					removed = { fg = colors.red, bg = colors.glass },
				},
				cond = conditions.hide_in_width,
				color = { bg = colors.bg, fg = colors.purple },
			})

			ins_right({
				"encoding",
				color = { fg = colors.green, bg = colors.bg },
			})
			ins_right({
				require("lazy.status").updates,
				cond = require("lazy.status").has_updates,
				color = { fg = colors.orange, bg = colors.bg },
				icon = { " ", color = { fg = colors.cyan } },
			})

			ins_right({
				function()
					return os.date("%R")
				end,
				color = { fg = colors.orange, bg = colors.bg },
				icon = { "", color = { fg = colors.blue } },
				padding = -1,
			})
			ins_right({
				function()
					return ""
				end,
				color = { fg = colors.bg, bg = "None" },
				padding = -2,
			})
			-- Now don't forget to initialize lualine
			lualine.setup(config)
		end,
	},
}
