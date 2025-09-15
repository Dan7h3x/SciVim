return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		lazy = true,
		dependencies = { "echasnovski/mini.icons" },
		init = function()
			local opts = {
				ui_select = function(fzf_opts, items)
					return vim.tbl_deep_extend("force", fzf_opts, {
						prompt = " ",
						winopts = {
							title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " ",
							title_pos = "center",
						},
					}, fzf_opts.kind == "codeaction" and {
						winopts = {
							layout = "vertical",
							-- height is number of items minus 15 lines for the preview, with a max of 80% screen height
							height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 2) + 0.5) + 16,
							width = 0.5,
							preview = {
								layout = "vertical",
								vertical = "down:15,border-top",
							},
						},
					} or {
						winopts = {
							width = 0.5,
							-- height is number of items, with a max of 80% screen height
							height = math.floor(math.min(vim.o.lines * 0.8, #items + 2) + 0.5),
						},
					})
				end,
			}
			require("SciVim.extras.fzf.maps").map()
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "fzf-lua" } })
				require("fzf-lua").register_ui_select(opts.ui_select or nil)
				return vim.ui.select(...)
			end
		end,
		config = function()
			require("SciVim.extras.fzf.setup").setup()
		end,
	},
}
