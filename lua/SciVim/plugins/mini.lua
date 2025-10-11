return {

	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {
			file = {
				[".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
				["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
			},
			filetype = {
				dotenv = { glyph = "", hl = "MiniIconsYellow" },
			},
		},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},
	{
		"echasnovski/mini.pairs",
		event = "InsertEnter",
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
	},
	{
		"echasnovski/mini.ai",
		event = "InsertEnter",
		opts = function()
			local _, ai = pcall(require, "mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({ -- code block
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
					d = { "%f[%d]%d+" }, -- digits
					e = { -- Word with case
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
						},
						"^().*()$",
					},
					g = require("SciVim.utils").ai_buffer, -- buffer
					u = ai.gen_spec.function_call(), -- u for "Usage"
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
				},
			}
		end,
		config = function(_, opts)
			require("mini.ai").setup(opts)
			-- require("SciVim.utils").on_load("which-key.nvim", function()
			-- 	vim.schedule(function()
			-- 		require("SciVim.utils").ai_whichkey(opts)
			-- 	end)
			-- end)
		end,
	},
	{
		"echasnovski/mini.clue",
		event = "VeryLazy",
		config = function()
			local _, miniclue = pcall(require, "mini.clue")
			miniclue.setup({
				window = { delay = 500, config = { width = 40 } },
				clues = {
					miniclue.gen_clues.builtin_completion(),
					miniclue.gen_clues.square_brackets(),
					miniclue.gen_clues.g(),
					miniclue.gen_clues.marks(),
					miniclue.gen_clues.registers(),
					miniclue.gen_clues.windows(),
					miniclue.gen_clues.z(),
					{ mode = "n", keys = "<leader>g", desc = "+Git" },
					{ mode = "n", keys = "<leader>l", desc = "+Lsp" },
					{ mode = "n", keys = "<leader>d", desc = "+Dap" },
					{ mode = "n", keys = "<leader>f", desc = "+Fzf" },
					{ mode = "n", keys = "<leader>h", desc = "+Gitsigns" },
					{ mode = "n", keys = "<leader>t", desc = "+MiniTest" },
				},
				triggers = {
					-- Leader triggers
					{ mode = "n", keys = "<Leader>" },
					{ mode = "x", keys = "<Leader>" },
					-- Movement keys
					{ mode = "n", keys = "]" },
					{ mode = "n", keys = "[" },
					-- Built-in completion
					{ mode = "i", keys = "<C-x>" },
					-- `g` key
					{ mode = "n", keys = "g" },
					{ mode = "x", keys = "g" },
					-- Marks
					{ mode = "n", keys = "'" },
					{ mode = "n", keys = "`" },
					{ mode = "x", keys = "'" },
					{ mode = "x", keys = "`" },
					-- Registers
					{ mode = "n", keys = '"' },
					{ mode = "x", keys = '"' },
					{ mode = "i", keys = "<C-r>" },
					{ mode = "c", keys = "<C-r>" },
					-- Window commands
					{ mode = "n", keys = "<C-w>" },
					-- `z` key
					{ mode = "n", keys = "z" },
					{ mode = "x", keys = "z" },
				},
			})
		end,
	},
}
