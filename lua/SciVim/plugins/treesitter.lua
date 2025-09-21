return {
	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				{ "<BS>", desc = "Decrement Selection", mode = "x" },
				{ "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },
			},
		},
	},

	-- Treesitter is a new parser generator tool that we can
	-- use in Neovim to power faster and more accurate
	-- syntax highlighting.
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		version = false, -- last release is way too old and doesn't work on Windows
		build = function()
			local _, ts = pcall(require, "nvim-treesitter")
			local function tscall()
				ts.update(nil, { summary = true })
			end
			if not ts.get_installed then
				vim.notify(
					"Run :TSUpdate for fix.",
					vim.log.levels.ERROR,
					{ title = "treesitter executable", source = "treesitter" }
				)
				return
			end
			if vim.fn.executable("tree-sitter") then
				return tscall()
			end
			local mr = require("mason-registry")
			mr.refresh(function()
				local tree = mr.get_package("tree-sitter-cli")
				if not tree:is_installed() then
					vim.notify(
						"Installing `treesitter` with mason.",
						vim.log.levels.INFO,
						{ source = "treesitter", title = "treesitter" }
					)
					tree:install(
						nil,
						vim.schedule_wrap(function(success)
							if success then
								vim.notify(
									"Installed `treesitter` successfully.",
									vim.log.levels.INFO,
									{ source = "treesitter", title = "treesitter" }
								)
							else
								vim.notify(
									"Failed to install `treesitter`.",
									vim.log.levels.ERROR,
									{ source = "treesitter", title = "treesitter" }
								)
							end
						end)
					)
				end
			end)
		end,
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		keys = {
			{ "<c-space>", desc = "Increment Selection" },
			{ "<bs>", desc = "Decrement Selection", mode = "x" },
		},
		opts_extend = { "ensure_installed" },
		---@type TSConfig
		---@diagnostic disable-next-line: missing-fields
		opts = {
			highlight = { enable = true, disable = { "latex", "c" } },
			indent = { enable = true },
			folds = { enable = true },
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"diff",
				"html",
				"javascript",
				"jsdoc",
				"json",
				"lua",
				"luadoc",
				"luap",
				"latex",
				"markdown",
				"markdown_inline",
				"printf",
				"python",
				"query",
				"regex",
				"r",
				"rnoweb",
				"toml",
				"tsx",
				"typescript",
				"typst",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
			auto_install = true,
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			textobjects = {
				move = {
					enable = true,
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
						["]a"] = "@parameter.inner",
					},
					goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
						["[a"] = "@parameter.inner",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
						["[A"] = "@parameter.inner",
					},
				},
			},
		},
		---@param opts TSConfig
		config = function(_, opts)
			local ts = require("nvim-treesitter")
			ts.install(opts.ensure_installed)
			ts.setup(opts)
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		enabled = true,
		keys = function()
			local moves = {
				goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
				goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
				goto_previous_start = {
					["[f"] = "@function.outer",
					["[c"] = "@class.outer",
					["[a"] = "@parameter.inner",
				},
				goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
			}
			local ret = {} ---@type LazyKeysSpec[]
			for method, keymaps in pairs(moves) do
				for key, query in pairs(keymaps) do
					local desc = query:gsub("@", ""):gsub("%..*", "")
					desc = desc:sub(1, 1):upper() .. desc:sub(2)
					desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
					desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
					ret[#ret + 1] = {
						key,
						function()
							-- don't use treesitter if in diff mode and the key is one of the c/C keys
							if vim.wo.diff and key:find("[cC]") then
								return vim.cmd("normal! " .. key)
							end
							require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
						end,
						desc = desc,
						mode = { "n", "x", "o" },
						silent = true,
					}
				end
			end
			return ret
		end,
		config = function()
			-- If treesitter is already loaded, we need to run config again for textobjects
			if require("SciVim.utils").is_loaded("nvim-treesitter") then
				local opts = require("SciVim.utils").opts("nvim-treesitter")
				require("nvim-treesitter").setup({ textobjects = opts.textobjects })
			end
		end,
	},
}
