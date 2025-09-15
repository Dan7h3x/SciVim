return {
	{
		"MagicDuck/grug-far.nvim",
		opts = { headerMaxWidth = 80 },
		cmd = "GrugFar",
		keys = {
			{
				"<leader>sr",
				function()
					local grug = require("grug-far")
					local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
					grug.open({
						transient = true,
						prefills = {
							filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						},
					})
				end,
				mode = { "n", "v" },
				desc = "Search and Replace",
			},
		},
	},
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter", "CmdlineEnter" },
		branch = "v0.6", -- recomended as each new version will have breaking changes
		opts = {
			-- Config goes here
		},
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
	{
		"jbyuki/venn.nvim",
		ft = { "markdown", "text" },
		config = function()
			function _G.Toggle_venn()
				local venn_enabled = vim.inspect(vim.b.venn_enabled)
				if venn_enabled == "nil" then
					vim.b.venn_enabled = true
					vim.cmd([[setlocal ve=all]])
					-- draw a line on HJKL keystokes
					vim.api.nvim_buf_set_keymap(0, "n", "J", "<C-v>j:VBox<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "K", "<C-v>k:VBox<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "L", "<C-v>l:VBox<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "H", "<C-v>h:VBox<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "<C-j>", "<C-v>j:VBoxD<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "<C-k>", "<C-v>k:VBoxD<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "<C-l>", "<C-v>l:VBoxD<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "n", "<C-h>", "<C-v>h:VBoxD<CR>", { noremap = true })
					-- draw a box by pressing "f" with visual selection
					vim.api.nvim_buf_set_keymap(0, "v", "f", ":VBoxO<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "v", "d", ":VBoxDO<CR>", { noremap = true })
					vim.api.nvim_buf_set_keymap(0, "v", "h", ":VBoxHO<CR>", { noremap = true })
				else
					vim.cmd([[setlocal ve=]])
					vim.cmd([[mapclear <buffer>]])
					vim.b.venn_enabled = nil
				end
			end

			-- toggle keymappings for venn using <leader>v
			vim.api.nvim_set_keymap("n", "<leader>v", "<Cmd>lua Toggle_venn()<CR>", { noremap = true })
		end,
	},

	{ -- color previews & color picker
		"uga-rosa/ccc.nvim",
		lazy = true,
		keys = {
			{ "#", vim.cmd.CccPick, desc = " Color Picker" },
		},
		ft = { "css", "scss", "sh", "zsh", "lua", "python", "c", "cpp" },
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
					ccc.picker.hex_long, -- only long hex to not pick issue numbers like #123
					ccc.picker.css_rgb,
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
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = { show_start = false, show_end = false },
			exclude = {
				filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
			},
		},
		main = "ibl",
	},
	{ "kevinhwang91/nvim-bqf", ft = "qf" },

	{
		"3rd/image.nvim",
		build = false,
		event = "VeryLazy",
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
					only_render_image_at_cursor_mode = "popup", -- or "inline"
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
}
