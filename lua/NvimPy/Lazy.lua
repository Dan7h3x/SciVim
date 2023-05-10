local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	--[[
   Plugins
  ]]
	"nvim-neo-tree/neo-tree.nvim", -- File Explorer
	"mbbill/undotree", -- Undo Explorer
	"folke/neodev.nvim", -- Docs and Completion Helper
	"neovim/nvim-lspconfig", -- LSP Client
	"hrsh7th/cmp-nvim-lsp", -- Completion engine for LSP
	"hrsh7th/cmp-path", -- Completion engine for path
	"hrsh7th/cmp-nvim-lua", -- Completion engine for lua
	"hrsh7th/cmp-buffer", -- Completion engine for buffer
	"hrsh7th/cmp-cmdline", -- Completion engine for CMD
	{
		"hrsh7th/nvim-cmp",
		dependencies = "kdheepak/cmp-latex-symbols",
	}, -- Completion engine for Neovim with Latex Symbols support
	"saadparwaiz1/cmp_luasnip", -- Completion engine for Snippets
	{
		"L3MON4D3/LuaSnip",
	}, -- Snippets manager
	"jose-elias-alvarez/null-ls.nvim", -- LSP Injector for Neovim
	"williamboman/mason.nvim", -- LSP and tools manager for Neovim
	"williamboman/mason-lspconfig.nvim", -- Mason compatible with lspconfig
	"folke/lsp-colors.nvim", -- Missing LSP diagnostics groups
	"nvim-treesitter/nvim-treesitter", -- Neovim Treesitter configurations
	"kylechui/nvim-surround", -- Manage surrounding delimiter pairs
	"AckslD/nvim-neoclip.lua", -- Clipboard manager Neovim
	"kevinhwang91/nvim-hlslens", -- Searching helper
	{
		"folke/twilight.nvim",
		config = function()
			require("twilight").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	}, -- Focus on partial of code
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }, -- Fuzzy finder awesome
	"NvChad/nvim-colorizer.lua", -- Color highlighter
	"folke/tokyonight.nvim", -- Great theme
	{
		"utilyre/barbecue.nvim",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons", -- optional dependency
		},
		opts = {
			-- configurations go here
		},
	}, -- Winbar like VScode
	"RRethy/vim-illuminate", -- Under cursor highlighter
	"goolord/alpha-nvim", -- Dashboard for neovim
	{
		"folke/noice.nvim",
		config = function()
			require("noice").setup({
				-- add any options here
			})
		end,
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},
	}, -- Modern UI for Neovim

	"frabjous/knap", -- LaTeX builder and previewer
	{ "NvChad/nvterm" }, -- Terminal with configurations
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	}, -- Commenting tools
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	}, -- Pairwise coding helper
	"mrjones2014/nvim-ts-rainbow", -- Rainbow delimiters
	"simrat39/symbols-outline.nvim", -- Symbols of buffer at pane
	"lukas-reineke/indent-blankline.nvim", -- Indent manager
	"s1n7ax/nvim-window-picker", -- Window manager
	{ "bluz71/vim-nightfly-colors", name = "nightfly", lazy = true, priority = 1000 }, -- Main theme
	"ellisonleao/gruvbox.nvim", -- Alternative theme

	"nvim-lualine/lualine.nvim", -- Awesome statusline

	{ "rafamadriz/friendly-snippets" }, -- Common nice snippets
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{ "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
			{ "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").previous({ skip_groups = true, jump = true })
					else
						vim.cmd.cprev()
					end
				end,
				desc = "Previous trouble/quickfix item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						vim.cmd.cnext()
					end
				end,
				desc = "Next trouble/quickfix item",
			},
		},
	}, -- LSP diagnostics better way
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile" },
		config = true,
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>",                              desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",      desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>",                            desc = "Todo" },
    },
	}, -- Todo manager

	{
		"echasnovski/mini.indentscope",
		version = false, -- wait till new 0.7.0 release to put it back on semver
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			-- symbol = "▏",
			symbol = "│",
			options = { try_as_border = true },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
		config = function(_, opts)
			require("mini.indentscope").setup(opts)
		end,
	}, -- Indent coloring visualizer

	{
		"echasnovski/mini.nvim",
		version = "*",
		config = function()
			require("mini.surround").setup({
				mappings = {
					add = "gsa",
					del = "gsd",
					find = "gsf",
					find_left = "gsq",
					find_right = "gse",
					replace = "gsr",
					update_n_lines = "gsu",
					suffix_last = "q",
					suffix_next = "e",
				},
				n_lines = 15,
				respect_selection_type = false,
				search_method = "cover",
				silent = false,
			})
		end,
	}, -- Mini plugins
	{
		"ethanholz/nvim-lastplace",
		event = "BufRead",
		config = function()
			require("nvim-lastplace").setup({
				lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
				lastplace_ignore_filetype = {
					"gitcommit",
					"gitrebase",
					"svn",
					"hgcommit",
				},
				lastplace_open_folds = true,
			})
		end,
	}, -- LastPlace helper
	{ "akinsho/bufferline.nvim" }, -- Buffer manager
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			plugins = { spelling = true },
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			local keymaps =
				{
					mode = { "n", "v" },
					["g"] = { name = "+goto" },
					["gz"] = { name = "+surround" },
					["]"] = { name = "+next" },
					["["] = { name = "+prev" },
					["<leader><tab>"] = { name = "+tabs" },
					["<leader>b"] = { name = "+buffer" },
					["<leader>c"] = { name = "+code" },
					["<leader>f"] = { name = "+file/find" },
					["<leader>g"] = { name = "+git" },
					["<leader>gh"] = { name = "+hunks" },
					["<leader>q"] = { name = "+quit/session" },
					["<leader>s"] = { name = "+search" },
					["<leader>u"] = { name = "+ui" },
					["<leader>w"] = { name = "+windows" },
					["<leader>x"] = { name = "+diagnostics/quickfix" },
				}, wk.register(keymaps)
		end,
	}, -- Leader Key helper
	{
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup()
		end,
	}, -- LSP events widget
	{
		"iurimateus/luasnip-latex-snippets.nvim",
		-- replace "lervag/vimtex" with "nvim-treesitter/nvim-treesitter" if you're
		-- using treesitter.
		dependencies = { "L3MON4D3/LuaSnip", "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("luasnip-latex-snippets").setup({ use_treesitter = true })
			-- or setup({ use_treesitter = true })
		end,
		-- treesitter is required for markdown
		ft = { "tex", "markdown" },
	}, -- Snippets for LaTeX
	"jbyuki/nabla.nvim", -- Scientific Note taking LaTeX

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
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
			local cb = require("diffview.config").diffview_callback
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
	{ "nvim-pack/nvim-spectre" }, -- Search and Replace
})
