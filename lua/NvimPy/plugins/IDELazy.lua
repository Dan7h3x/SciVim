return {
	{
		"2kabhishek/termim.nvim",
		event = "VeryLazy",
		cmd = { "Fterm", "FTerm", "Sterm", "STerm", "Vterm", "VTerm" },
	},
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		event = "VeryLazy",
		opts = {
			enable_autocmd = false,
		},
	},
	-- Commenting tools
	{
		"altermo/ultimate-autopair.nvim",
		lazy = false,
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
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "┃" },
				untracked = { text = "" },
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
				map({ "n", "v" }, "<leader>gg", "<Cmd>Gitsigns<CR>", { desc = "Gitsigns" })
				map({ "n", "v" }, "<leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
				map({ "n", "v" }, "<leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
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
				map({ "o", "x" }, "ih", "<Cmd><C-U>Gitsigns select_hunk<CR>", { desc = "inner git hunk" })
			end,
		},
	}, -- Gitsigns helper

	{
		"akinsho/git-conflict.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = { disable_diagnostics = true },
	}, -- Git conflict manager

	{
		"SuperBo/fugit2.nvim",
		opts = {},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			"nvim-lua/plenary.nvim",
			{
				"chrisgrieser/nvim-tinygit", -- optional: for Github PR view
				dependencies = { "stevearc/dressing.nvim" },
			},
			"sindrets/diffview.nvim", -- optional: for Diffview
		},
		cmd = { "Fugit2", "Fugit2Graph" },
		keys = {
			{ "<leader>Gf", mode = "n", "<cmd>Fugit2<cr>" },
			{ "<leader>Gg", mode = "n", "<cmd>Fugit2Graph<cr>" },
			{ "<leader>Gd", mode = "n", "<cmd>Fugit2Diff<cr>" },
		},
	},
	{ "jbyuki/venn.nvim", lazy = false },
	{
		"ellisonleao/glow.nvim",
		event = "VeryLazy",
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
		lazy = false,
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
		lazy = false,
		config = function()
			local ver = vim.version()
			if ver.minor == "10" then
				local cfg = require("NvimPy.Configs.Winbar")
				require("dropbar").setup(cfg)
			end
		end,
	},

	{ -- snippet management
		"chrisgrieser/nvim-scissors",
		event = "VeryLazy",
		dependencies = "nvim-telescope/telescope.nvim",
		keys = {
			{
				"<leader>nn",
				function()
					require("scissors").editSnippet()
				end,
				desc = " Edit snippet",
			},
			{
				"<leader>na",
				function()
					require("scissors").addNewSnippet()
				end,
				mode = { "n", "x" },
				desc = " Add new snippet",
			},
		},
		opts = {
			snippetDir = vim.fn.expand("$HOME") .. "/.config/nvim/Snippets",
		},
	},
	{
		"vidocqh/auto-indent.nvim",
		opts = {},
	},

	-- {
	-- 	"Exafunction/codeium.nvim",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"hrsh7th/nvim-cmp",
	-- 	},
	-- 	config = function()
	-- 		require("codeium").setup({})
	-- 	end,
	-- },
}
