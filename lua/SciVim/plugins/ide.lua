return {
	-- {
	-- 	"MagicDuck/grug-far.nvim",
	-- 	opts = { headerMaxWidth = 30 },
	-- 	cmd = "GrugFar",
	-- 	keys = {
	-- 		{
	-- 			"<leader>sr",
	-- 			function()
	-- 				local grug = require("grug-far")
	-- 				local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
	-- 				grug.open({
	-- 					transient = true,
	-- 					prefills = {
	-- 						filesFilter = ext and ext ~= "" and "*." .. ext or nil,
	-- 					},
	-- 					previewWindow = {
	-- 						max_width = 40,
	-- 					},
	-- 					historyWindow = {
	-- 						max_width = 40,
	-- 					},
	-- 				})
	-- 			end,
	-- 			mode = { "n", "v" },
	-- 			desc = "Search and Replace",
	-- 		},
	-- 	},
	-- },
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter", "CmdlineEnter" },
		branch = "v0.6", -- recomended as each new version will have breaking changes
		opts = {
			profile = "default",
			--what profile to use
			map = true,
			--whether to allow any insert map
			cmap = true, --cmap stands for cmd-line map
			--whether to allow any cmd-line map
			pair_map = true,
			--whether to allow pair insert map
			pair_cmap = true,
			--whether to allow pair cmd-line map
			multiline = true,
			--enable/disable multiline
			bs = { -- *ultimate-autopair-map-backspace-config*
				enable = true,
				map = "<bs>", --string or table
				cmap = "<bs>", --string or table
				overjumps = true,
				--(|foo) > bs > |foo
				space = true, --false, true or 'balance'
				--( |foo ) > bs > (|foo)
				--balance:
				--  Will prioritize balanced spaces
				--  ( |foo  ) > bs > ( |foo )
				indent_ignore = false,
				--(\n\t|\n) > bs > (|)
				single_delete = false,
				-- <!--|--> > bs > <!-|
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
			},
			cr = { -- *ultimate-autopair-map-newline-config*
				enable = true,
				map = "<cr>", --string or table
				autoclose = false,
				--(| > cr > (\n|\n)
				conf = {
					cond = function(fn)
						return not fn.in_lisp()
					end,
				},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
			},
			space = { -- *ultimate-autopair-map-space-config*
				enable = true,
				map = " ", --string or table
				cmap = " ", --string or table
				check_box_ft = { "markdown", "vimwiki", "org" },
				_check_box_ft2 = { "norg" }, --may be removed
				--+ [|] > space > + [ ]
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
			},
			space2 = { -- *ultimate-autopair-map-space2-config*
				enable = false,
				match = [[\k]],
				--what character activate
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
			},
			fastwarp = { -- *ultimate-autopair-map-fastwarp-config*
				enable = true,
				enable_normal = true,
				enable_reverse = true,
				hopout = false,
				--{(|)} > fastwarp > {(}|)
				map = "<A-e>", --string or table
				rmap = "<A-E>", --string or table
				cmap = "<A-e>", --string or table
				rcmap = "<A-E>", --string or table
				multiline = true,
				--(|) > fastwarp > (\n|)
				nocursormove = true,
				--makes the cursor not move (|)foo > fastwarp > (|foo)
				--disables multiline feature
				--only activates if prev char is start pair, otherwise fallback to normal
				do_nothing_if_fail = true,
				--add a module so that if fastwarp fails
				--then an `e` will not be inserted
				no_filter_nodes = { "string", "raw_string", "string_literals", "character_literal" },
				--which nodes to skip for tsnode filtering
				faster = false,
				--only enables jump over pair, goto end/next line
				--useful for the situation of:
				--{|}M.foo('bar') > {M.foo('bar')|}
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
			},
			close = { -- *ultimate-autopair-map-close-config*
				enable = true,
				map = "<A-)>", --string or table
				cmap = "<A-)>", --string or table
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
				do_nothing_if_fail = true,
				--add a module so that if close fails
				--then a `)` will not be inserted
			},
			tabout = { -- *ultimate-autopair-map-tabout-config*
				enable = false,
				map = "<A-tab>", --string or table
				cmap = "<A-tab>", --string or table
				conf = {},
				--contains extension config
				multi = false,
				--use multiple configs (|ultimate-autopair-map-multi-config|)
				hopout = false,
				-- (|) > tabout > ()|
				do_nothing_if_fail = true,
				--add a module so that if close fails
				--then a `\t` will not be inserted
			},
			extensions = { -- *ultimate-autopair-extensions-default-config*
				bigfile = { p = 110 },
				cmdtype = { skip = { "/", "?", "@", "-" }, p = 100 },
				filetype = { p = 90, nft = { "TelescopePrompt" }, tree = true },
				escape = { filter = true, p = 80 },
				utf8 = { p = 70 },
				tsnode = {
					p = 60,
					separate = {
						"comment",
						"string",
						"char",
						"character",
						"raw_string", --fish/bash/sh
						"char_literal",
						"string_literal", --c/cpp
						"string_value", --css
						"str_lit",
						"char_lit", --clojure/commonlisp
						"interpreted_string_literal",
						"raw_string_literal",
						"rune_literal", --go
						"quoted_attribute_value", --html
						"template_string", --javascript
						"LINESTRING",
						"STRINGLITERALSINGLE",
						"CHAR_LITERAL", --zig
						"string_literals",
						"character_literal",
						"line_comment",
						"block_comment",
						"nesting_block_comment", --d #62
					},
				},
				cond = { p = 40, filter = true },
				alpha = { p = 30, filter = false, all = false },
				suround = { p = 20 },
				fly = {
					other_char = { " " },
					nofilter = false,
					p = 10,
					undomapconf = {},
					undomap = nil,
					undocmap = nil,
					only_jump_end_pair = false,
				},
			},
			internal_pairs = { -- *ultimate-autopair-pairs-default-pairs*
				{ "[", "]", fly = true, dosuround = true, newline = true, space = true },
				{ "(", ")", fly = true, dosuround = true, newline = true, space = true },
				{ "{", "}", fly = true, dosuround = true, newline = true, space = true },
				{ '"', '"', suround = true, multiline = false },
				{
					"'",
					"'",
					suround = true,
					cond = function(fn)
						return not fn.in_lisp() or fn.in_string()
					end,
					alpha = true,
					nft = { "tex" },
					multiline = false,
				},
				{
					"`",
					"`",
					cond = function(fn)
						return not fn.in_lisp() or fn.in_string()
					end,
					nft = { "tex" },
					multiline = false,
				},
				{ "``", "''", ft = { "tex" } },
				{ "```", "```", newline = true, ft = { "markdown" } },
				{ "<!--", "-->", ft = { "markdown", "html" }, space = true },
				{ '"""', '"""', newline = true, ft = { "python" } },
				{ "'''", "'''", newline = true, ft = { "python" } },
			},
			config_internal_pairs = { -- *ultimate-autopair-pairs-configure-default-pairs*
				--configure internal pairs
				--example:
				--{'{','}',suround=true},
			},
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
}
