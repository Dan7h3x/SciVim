return {
	{
		"2kabhishek/termim.nvim",
		cmd = { "Fterm", "FTerm", "Sterm", "STerm", "Vterm", "VTerm" },
	},
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		lazy = true,
		opts = {
			enable_autocmd = false,
		},
	},
	-- Commenting tools
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter", "CmdlineEnter" },
		branch = "v0.6", --recomended as each new version will have breaking changes
		opts = {
			--Config goes here
		},
	},
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = " " },
				untracked = { text = " " },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]g", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next git hunk" })

				map("n", "[g", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Previous git hunk" })

				-- Actions
				map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
				map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>gB", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>gl", gs.toggle_current_line_blame, { desc = "Blame current line" })
				map("n", "<leader>gt", gs.toggle_deleted, { desc = "Toggle old versions of hunks" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "inner git hunk" })
			end,
		},
	}, -- Gitsigns helper
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		config = function()
			local cb = require("diffview.config").DiffviewClose
			require("diffview").setup({
				view = {
					default = {
						winbar_info = true,
					},
					file_history = {
						winbar_info = true,
					},
				},
				key_bindings = {
					view = { { "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
					file_panel = {
						{ "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
					},
					file_history_panel = {
						{ "n", "q", "<Cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
					},
					option_panel = { { "n", "q", cb("close"), { desc = "Close Diffview" } } },
				},
			})
		end,
	}, -- Git diffs viewer

	{
		"akinsho/git-conflict.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = { disable_diagnostics = true },
	}, -- Git conflict manager
	{ "jbyuki/venn.nvim" },
	{
		"ellisonleao/glow.nvim",
		config = function()
			require("glow").setup({
				border = "rounded",
				style = "dark",
				width = 100,
				height = 120,
				width_ratio = 0.85,
				height_ratio = 0.85,
			})
		end,
		cmd = "Glow",
	},
	{ "nvim-tree/nvim-web-devicons" },
	{
		"andymass/vim-matchup",
		event = "BufReadPost",
		enabled = true,
		init = function()
			vim.o.matchpairs = "(:),{:},[:],<:>"
		end,
		config = function()
			vim.g.matchup_matchparen_deferred = 1
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
		end,
	},
	{
		"Bekaboo/dropbar.nvim",
		config = function()
			local ver = vim.version()
			if ver.minor == "10" then
				local cfg = require("NvimPy.Configs.Winbar")
				require("dropbar").setup(cfg)
			end
		end,
	},
}
