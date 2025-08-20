return {
	{
		"rcarriga/nvim-notify",
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
		keys = {
			{
				"<leader>un",
				function()
					require("notify").dismiss({ silent = true, pending = true })
				end,
				desc = "Dismiss All Notifications",
			},
		},
		opts = {
			stages = "static",
			timeout = 3000,
			max_height = function()
				return math.floor(vim.o.lines * 0.55)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.55)
			end,
			on_open = function(win)
				vim.api.nvim_win_set_config(win, { zindex = 100 })
			end,
		},
		init = function()
			-- when noice is not enabled, install notify on VeryLazy
			if not require("SciVim.utils").has("notify") then
				require("SciVim.utils").on_very_lazy(function()
					vim.notify = require("notify")
				end)
			end
		end,
	},
	{
		"cshuaimin/ssr.nvim",
		lazy = true,
		opts = {
			border = "solid",
			min_width = 50,
			min_height = 5,
			max_width = 120,
			max_height = 25,
			adjust_window = true,
			keymaps = {
				close = "q",
				next_match = "n",
				prev_match = "N",
				replace_confirm = "<cr>",
				replace_all = "<leader><cr>",
			},
		},
		keys = {
			{
				"<A-s>",
				function()
					require("ssr").open()
				end,
				desc = "Search and Replace Structural",
			},
		},
	},
	{
		"hedyhli/outline.nvim",
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		keys = { -- Example mapping to toggle outline
			{ "<F10>", "<cmd>Outline<CR>", desc = "Toggle outline" },
		},
		config = function()
			local cfg = require("SciVim.extras.outline")
			require("outline").setup(cfg)
		end,
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
		event = { "BufNewFile", "BufReadPost", "BufWritePre", "VeryLazy" },
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
		lazy = true,
		keys = {
			{ "#", vim.cmd.CccPick, desc = " Color Picker" },
		},
		ft = { "css", "scss", "sh", "zsh", "lua", "python" },
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
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
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
}
