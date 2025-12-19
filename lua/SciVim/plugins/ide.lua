return {
	{
		"cshuaimin/ssr.nvim",
		lazy = true,
		keys = {
			{
				"<leader>sr",
				function()
					require("ssr").open()
				end,
				desc = "TS Search/Replace",
				mode = { "n", "x" },
			},
		},
		config = function()
			require("ssr").setup({
				border = "rounded",
				max_height = 25,
				max_width = 100,
				adjust_window = true,
				keymaps = {
					close = "q",
					next_match = "n",
					prev_match = "N",
					replace_confirm = "<cr>",
					replace_all = "<leader><cr>",
				},
			})
		end,
	},
	{
		"kylechui/nvim-surround",
		event = { "BufNewFile", "BufReadPost", "BufWritePre" },
		opts = {
			keymaps = {
				normal = "ys",
				normal_cur = "yss",
				delete = "ds",
				change = "cs",
			},

			aliases = {
				["a"] = ">",
				["b"] = ")",
				["B"] = "}",
				["r"] = "]",
				["q"] = { '"', "'", "`" },
				["s"] = { "}", "]", ")", ">", '"', "'", "`" },
			},
			highlight = {
				duration = 0,
			},
			move_cursor = "begin",
			indent_lines = function(start, stop)
				local b = vim.bo
				-- Only re-indent the selection if a formatter is set up already
				if
					start < stop and (b.equalprg ~= "" or b.indentexpr ~= "" or b.cindent or b.smartindent or b.lisp)
				then
					vim.cmd(string.format("silent normal! %dG=%dG", start, stop))
					require("nvim-surround.cache").set_callback("")
				end
			end,
		},
	},

	{ -- color previews & color picker
		"uga-rosa/ccc.nvim",
		keys = {
			{ "#", vim.cmd.CccPick, desc = " Color Picker" },
		},
		ft = { "css", "scss", "sh", "zsh", "lua", "python", "c", "cpp", "json" },
		config = function(spec)
			local ccc = require("ccc")

			ccc.setup({
				win_opts = { border = vim.g.borderStyle },
				highlight_mode = "background",
				highlighter = {
					auto_enable = true,
					filetypes = spec.ft, -- uses lazy.nvim's ft spec
					max_byte = 200 * 1024, -- 200kb
					update_insert = false,
				},
				pickers = {
					ccc.picker.css_rgb,
					ccc.picker.hex_long, -- only long hex to not pick issue numbers like #123
					ccc.picker.css_hsl,
					ccc.picker.css_name,
					ccc.picker.ansi_escape(),
				},
				alpha_show = "hide", -- needed when highlighter.lsp is set to true
				recognize = { output = true }, -- automatically recognize color format under cursor
				inputs = { ccc.input.hsl },
				outputs = {
					ccc.output.css_hsl,
					ccc.output.css_rgb,
					ccc.output.hex,
				},
				mappings = {
					["<Esc>"] = ccc.mapping.quit,
					["q"] = ccc.mapping.quit,
					["L"] = ccc.mapping.increase10,
					["H"] = ccc.mapping.decrease10,
					["o"] = ccc.mapping.cycle_output_mode, -- = change output format
				},
			})
		end,
	},
	-- {
	-- 	"lukas-reineke/indent-blankline.nvim",
	-- 	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	-- 	opts = {
	-- 		indent = {
	-- 			char = "│",
	-- 			tab_char = "│",
	-- 		},
	-- 		scope = { show_start = false, show_end = false },
	-- 		exclude = {
	-- 			filetypes = {
	-- 				"help",
	-- 				"alpha",
	-- 				"dashboard",
	-- 				"neo-tree",
	-- 				"Trouble",
	-- 				"trouble",
	-- 				"lazy",
	-- 				"mason",
	-- 				"notify",
	-- 				"toggleterm",
	-- 				"lazyterm",
	-- 			},
	-- 		},
	-- 	},
	-- 	main = "ibl",
	-- },
	{ "kevinhwang91/nvim-bqf", ft = "qf" },

	{
		"3rd/image.nvim",
		build = false,
		event = "VeryLazy",
		enabled = function()
			if vim.g.neovide then
				return false
			else
				return true
			end
		end,
		keys = {
			{
				"<M-i>",
				function()
					local image = require("image")
					if image.is_enabled() then
						image.disable()
					else
						image.enable()
					end
				end,
				mode = "n",
				desc = "Toggle Image",
			},
		},
		opts = {
			backend = "kitty",
			processor = "magick_cli", -- or "magick_rock"
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = true,
					only_render_image_at_cursor_mode = "inline", -- or "inline"
					floating_windows = false, -- if true, images will be rendered in floating markdown windows
					filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
				},
				neorg = {
					enabled = true,
					filetypes = { "norg" },
				},
				typst = {
					enabled = true,
					filetypes = { "typst" },
					only_render_image_at_cursor = true,
					only_render_image_at_cursor_mode = "inline", -- or "inline"
				},
				html = {
					enabled = false,
				},
				css = {
					enabled = false,
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			scale_factor = 1.0,
			window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
			window_overlap_clear_ft_ignore = {
				"cmp_menu",
				"cmp_docs",
				"snacks_notif",
				"scrollview",
				"scrollview_sign",
			},
			editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
			tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
		},
		config = function(_, opts)
			require("image").setup(opts)
		end,
	},
	-- {
	-- 	"3rd/diagram.nvim",
	-- 	ft = { "markdown" },
	-- 	enabled = function()
	-- 		if vim.g.neovide then
	-- 			return false
	-- 		else
	-- 			return true
	-- 		end
	-- 	end,
	-- 	opts = { -- you can just pass {}, defaults below
	-- 		events = {
	-- 			render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
	-- 			clear_buffer = { "BufLeave" },
	-- 		},
	-- 		renderer_options = {
	-- 			mermaid = {
	-- 				background = nil, -- nil | "transparent" | "white" | "#hex"
	-- 				theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
	-- 				scale = 1, -- nil | 1 (default) | 2  | 3 | ...
	-- 				width = nil, -- nil | 800 | 400 | ...
	-- 				height = nil, -- nil | 600 | 300 | ...
	-- 				cli_args = nil, -- nil | { "--no-sandbox" } | { "-p", "/path/to/puppeteer" } | ...
	-- 			},
	-- 			plantuml = {
	-- 				charset = nil,
	-- 				cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
	-- 			},
	-- 			d2 = {
	-- 				theme_id = nil,
	-- 				dark_theme_id = nil,
	-- 				scale = nil,
	-- 				layout = nil,
	-- 				sketch = nil,
	-- 				cli_args = nil, -- nil | { "--pad", "0" } | ...
	-- 			},
	-- 			gnuplot = {
	-- 				size = "800,600", -- nil | "800,600" | ...
	-- 				font = nil, -- nil | "Arial,12" | ...
	-- 				theme = "light", -- nil | "light" | "dark" | custom theme string
	-- 				cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
	-- 			},
	-- 		},
	-- 	},
	-- },
}
