local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local Icons = require("NvimPy.Icons")
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
vim.g.mapleader = " "

require("lazy").setup({
	--[[
   Plugins
  ]]
	{
		"folke/neodev.nvim",
	},
	"nvim-neo-tree/neo-tree.nvim", -- File Explorer
	"mbbill/undotree", -- Undo Explorer
	"neovim/nvim-lspconfig", -- LSP Client
	"hrsh7th/cmp-nvim-lsp", -- Completion engine for LSP
	"hrsh7th/cmp-path", -- Completion engine for path
	"hrsh7th/cmp-nvim-lua", -- Completion engine for lua
	"hrsh7th/cmp-buffer", -- Completion engine for buffer
	"hrsh7th/cmp-cmdline", -- Completion engine for CMD
	"hrsh7th/cmp-nvim-lsp-signature-help",
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
	"VonHeikemen/lsp-zero.nvim",
	"onsails/lspkind.nvim",
	{
		"williamboman/nvim-lsp-installer",
		config = function()
			require("nvim-lsp-installer").setup({})
		end,
	},
	"folke/lsp-colors.nvim", -- Missing LSP diagnostics groups
	"nvim-treesitter/nvim-treesitter", -- Neovim Treesitter configurations
	{
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup({
				history = 1000,
				enable_persistent_history = false,
				length_limit = 1048576,
				continuous_sync = false,
				db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
				filter = nil,
				preview = true,
				prompt = nil,
				default_register = '"',
				default_register_macros = "q",
				enable_macro_history = true,
				content_spec_column = false,
				disable_keycodes_parsing = false,
				on_select = {
					move_to_front = false,
					close_telescope = true,
				},
				on_paste = {
					set_reg = false,
					move_to_front = false,
					close_telescope = true,
				},
				on_replay = {
					set_reg = false,
					move_to_front = false,
					close_telescope = true,
				},
				on_custom_action = {
					close_telescope = true,
				},
				keys = {
					telescope = {
						i = {
							select = "<cr>",
							paste = "<c-p>",
							paste_behind = "<c-k>",
							replay = "<c-q>", -- replay a macro
							delete = "<c-d>", -- delete an entry
							edit = "<c-e>", -- edit an entry
							custom = {},
						},
						n = {
							select = "<cr>",
							paste = "p",
							--- It is possible to map to more than one key.
							-- paste = { 'p', '<c-p>' },
							paste_behind = "P",
							replay = "q",
							delete = "d",
							edit = "e",
							custom = {},
						},
					},
					fzf = {
						select = "default",
						paste = "ctrl-p",
						paste_behind = "ctrl-k",
						custom = {},
					},
				},
			})
		end,
	}, -- Clipboard manager Neovim
	"kevinhwang91/nvim-hlslens", -- Searching helper

	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }, -- Fuzzy finder awesome
	{
		"NvChad/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	}, -- Color highlighter
	"folke/tokyonight.nvim", -- Great theme

	"goolord/alpha-nvim", -- Dashboard for neovim
	{ "MunifTanjim/nui.nvim" }, -- Better UI neovim
	"frabjous/knap", -- LaTeX builder and previewer
	{ "NvChad/nvterm" }, -- Terminal with configurations
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	}, -- Commenting tools
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter", "CmdlineEnter" },
		branch = "v0.6",
		opts = {
			--Config goes here
		},
	}, -- Pairwise coding helper
	"simrat39/symbols-outline.nvim", -- Symbols of buffer at pane
	"nvim-lualine/lualine.nvim", -- Awesome statusline

	{ "rafamadriz/friendly-snippets" }, -- Common nice snippets
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{
				"<leader>tx",
				"<cmd>TroubleToggle document_diagnostics<cr>",
				desc = "Document Diagnostics (Trouble)",
			},
			{
				"<leader>tX",
				"<cmd>TroubleToggle workspace_diagnostics<cr>",
				desc = "Workspace Diagnostics (Trouble)",
			},
			{ "<leader>tL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
			{ "<leader>tQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
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
      { "]t",        function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      {
        "[t",
        function() require("todo-comments").jump_prev() end,
        desc =
        "Previous todo comment"
      },
      { "<leader>t", "<cmd>TodoTrouble<cr>",                              desc = "Todo (Trouble)" },
      {
        "<leader>T",
        "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",
        desc =
        "Todo/Fix/Fixme (Trouble)"
      },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
    },
	}, -- Todo manager

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
					["<leader>f"] = { name = "+telescope" },
					["<leader>g"] = { name = "+git" },
					["<leader>gh"] = { name = "+hunks" },
					["<leader>q"] = { name = "+quit/session" },
					["<leader>s"] = { name = "+search/iron" },
					["<leader>u"] = { name = "+ui" },
					["<leader>w"] = { name = "+windows" },
					["<leader>x"] = { name = "+diagnostics/quickfix" },
					["<leader>d"] = { name = "+debug" },
					["<leader>da"] = { name = "+adapters" },
				}, wk.register(keymaps)
		end,
	}, -- Leader Key helper
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
	"Fymyte/rasi.vim",
	{ "nvim-tree/nvim-web-devicons" },
	{ "Vigemus/iron.nvim" },
	{
		"danymat/neogen",
		keys = {
			{
				"<leader>cc",
				function()
					require("neogen").generate({})
				end,
				desc = "Neogen Comment",
			},
		},
		opts = { snippet_engine = "luasnip" },
	},
	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = true,
	},
	{
		"ThePrimeagen/refactoring.nvim",
		keys = {
			{
				"<leader>fr",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v",
				noremap = true,
				silent = true,
				expr = false,
			},
		},
		opts = {},
	},
	{
		"andymass/vim-matchup",
		event = "BufReadPost",
		enabled = false,
		init = function()
			vim.o.matchpairs = "(:),{:},[:],<:>"
		end,
		config = function()
			vim.g.matchup_matchparen_deferred = 1
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
		end,
	},
	{ "Bekaboo/dropbar.nvim" },

	{
		"GCBallesteros/NotebookNavigator.nvim",
		keys = {
			{
				"]h",
				function()
					require("notebook-navigator").move_cell("d")
				end,
			},
			{
				"[h",
				function()
					require("notebook-navigator").move_cell("u")
				end,
			},
			{ "<leader>X", "<cmd>lua require('notebook-navigator').run_cell()<cr>" },
			{ "<leader>x", "<cmd>lua require('notebook-navigator').run_and_move()<cr>" },
		},
		dependencies = {
			"echasnovski/mini.comment",
			"anuvyklack/hydra.nvim",
		},
		event = "VeryLazy",
		config = function()
			local nn = require("notebook-navigator")
			nn.setup({ activate_hydra_keys = "<leader>h" })
		end,
	},
	{
		"ada0l/obsidian",
		keys = {
			{
				"<leader>ov",
				function()
					Obsidian.select_vault()
				end,
				desc = "Select Obsidian vault",
			},
			{
				"<leader>oo",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.cd_vault()
					end)
				end,
				desc = "Open Obsidian directory",
			},
			{
				"<leader>ot",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.open_today()
					end)
				end,
				desc = "Open today",
			},
			{
				"<leader>od",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write shift in days: " }, function(input_shift)
							local shift = tonumber(input_shift) * 60 * 60 * 24
							Obsidian.open_today(shift)
						end)
					end)
				end,
				desc = "Open daily node with shift",
			},
			{
				"<leader>on",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write name of new note: " }, function(name)
							Obsidian.new_note(name)
						end)
					end)
				end,
				desc = "New note",
			},
			{
				"<leader>oi",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_template("telescope")
					end)
				end,
				desc = "Insert template",
			},
			{
				"<leader>os",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.search_note("telescope")
					end)
				end,
				desc = "Search note",
			},
			{
				"<leader>ob",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_backlinks("telescope")
					end)
				end,
				desc = "Select backlink",
			},
			{
				"<leader>og",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.go_to()
					end)
				end,
				desc = "Go to file under cursor",
			},
			{
				"<leader>or",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Rename file to" }, function(name)
							Obsidian.rename(name)
						end)
					end)
				end,
				desc = "Rename file with updating links",
			},
			{
				"gf",
				function()
					if Obsidian.found_wikilink_under_cursor() ~= nil then
						return "<cmd>lua Obsidian.get_current_vault(function() Obsidian.go_to() end)<CR>"
					else
						return "gf"
					end
				end,
				noremap = false,
				expr = true,
			},
		},
		opts = function()
			---@param filename string
			---@return string
			local transformator = function(filename)
				if filename ~= nil and filename ~= "" then
					return filename
				end
				return string.format("%d", os.time())
			end
			return {
				vaults = {
					{
						dir = "~/Desktop/Obsidian/Knowledge",
						templates = {
							dir = "templates/",
							date = "%Y-%d-%m",
							time = "%Y-%d-%m",
						},
						note = {
							dir = "",
							transformator = transformator,
						},
					},
					{
						dir = "~/Desktop/Obsidian/SyncObsidian/",
						daily = {
							dir = "01.daily/",
							format = "%Y-%m-%d",
						},
						templates = {
							dir = "templates/",
							date = "%Y-%d-%m",
							time = "%Y-%d-%m",
						},
						note = {
							dir = "notes/",
							transformator = transformator,
						},
					},
				},
			}
		end,
	},
	{ "sekke276/dark_flat.nvim" },
	{
		"s1n7ax/nvim-window-picker",
	},
	{
		"roobert/activate.nvim",
		keys = {
			{
				"<leader>fP",
				'<CMD>lua require("activate").list_plugins()<CR>',
				desc = "Plugins",
			},
		},
	},

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
				pattern = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"terminal",
					"Outline",
					"Ipython",
					"iron",
					"Iron",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},

	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      {
        "<leader>qd",
        function() require("persistence").stop() end,
        desc =
        "Don't Save Current Session"
      },
    },
	},
	{
		"stevearc/dressing.nvim",
		opts = {},
	},
	{
		"ethanholz/nvim-lastplace",
		config = function()
			require("nvim-lastplace").setup({
				lastplace_ignore_buftype = { "terminal", "quickfix", "help", "nofile", "Outline", "Neo-tree" },
				lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "terminal", "neo-tree", "daptui" },
				lastplace_open_folds = true,
			})
		end,
	},
	{ import = "NvimPy.Extra.debug" },
})
