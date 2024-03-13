return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		lazy = false,
		opts = {},
		dependencies = {
			"s1n7ax/nvim-window-picker",
			version = "2.*",
			config = function()
				require("window-picker").setup({
					filter_rules = {
						include_current_win = false,
						autoselect_one = true,
						-- filter using buffer options
						bo = {
							-- if the file type is one of following, the window will be ignored
							filetype = { "neo-tree", "neo-tree-popup", "notify" },
							-- if the buffer type is one of following, the window will be ignored
							buftype = { "terminal", "quickfix" },
						},
					},
				})
			end,
		},
		config = function()
			local config = require("NvimPy.Configs.NeoTree")
			require("neo-tree").setup(config)
		end,
	}, -- File Explorer
	{ "mbbill/undotree", lazy = true, event = "VeryLazy" },
	{
		"crusj/bookmarks.nvim",
		branch = "main",
		dependencies = { "nvim-web-devicons" },
		lazy = true,
		event = "VeryLazy",
		config = function()
			require("bookmarks").setup({
				storage_dir = "", -- Default path: vim.fn.stdpath("data").."/bookmarks,  if not the default directory, should be absolute path",
				mappings_enabled = true, -- If the value is false, only valid for global keymaps: toggle、add、delete_on_virt、show_desc
				keymap = {
					toggle = "<space>bt", -- Toggle bookmarks(global keymap)
					add = "<space>ba", -- Add bookmarks(global keymap)
					jump = "<CR>", -- Jump from bookmarks(buf keymap)
					order = "<space>bo", -- Order bookmarks by frequency or updated_time(buf keymap)
					delete_on_virt = "<space>bd", -- Delete bookmark at virt text line(global keymap)
					show_desc = "<space>bs", -- show bookmark desc(global keymap)
					focus_tags = "<c-j>", -- focus tags window
					focus_bookmarks = "<c-k>", -- focus bookmarks window
					toogle_focus = "<S-Tab>", -- toggle window focus (tags-window <-> bookmarks-window)
				},
				width = 0.8, -- Bookmarks window width:  (0, 1]
				height = 0.7, -- Bookmarks window height: (0, 1]
				preview_ratio = 0.45, -- Bookmarks preview window ratio (0, 1]
				tags_ratio = 0.1, -- Bookmarks tags window ratio
				fix_enable = false, -- If true, when saving the current file, if the bookmark line number of the current file changes, try to fix it.

				virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
				sign_icon = "󰃃", -- if it is not empty, show icon in signColumn.
				virt_pattern = { "*.go", "*.lua", "*.tex", "*.sh", "*.py", "*.typ" }, -- Show virt text only on matched pattern
				border_style = "rounded", -- border style: "single", "double", "rounded"
				hl = {
					border = "FloatBorder", -- border highlight
					cursorline = "guibg=Gray guifg=White", -- cursorline highlight
				},
			})
			require("telescope").load_extension("bookmarks")
		end,
	},
}
