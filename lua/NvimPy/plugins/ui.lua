return {
	{ -- Better input/selection fields
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		init = function()
			-- lazy load triggers
			vim.ui.select = function(...) ---@diagnostic disable-line: duplicate-set-field
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			vim.ui.input = function(...) ---@diagnostic disable-line: duplicate-set-field
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
		keys = {
			{ "<Tab>", "j", ft = "DressingSelect" },
			{ "<S-Tab>", "k", ft = "DressingSelect" },
		},
		opts = {
			input = {
				trim_prompt = true,
				border = vim.g.borderStyle,
				relative = "editor",
				prefer_width = 45,
				min_width = 0.4,
				max_width = 0.8,
				mappings = { n = { ["q"] = "Close" } },
			},
			select = {
				backend = { "telescope", "builtin" },
				trim_prompt = true,
				builtin = {
					mappings = { ["q"] = "Close" },
					show_numbers = false,
					border = vim.g.borderStyle,
					relative = "editor",
					max_width = 80,
					min_width = 20,
					max_height = 12,
					min_height = 3,
				},
				telescope = {
					layout_config = {
						horizontal = { width = { 0.7, max = 75 }, height = 0.6 },
					},
				},
				get_config = function(opts)
					local useBuiltin = { "just-recipes", "codeaction", "rule_selection" }
					if vim.tbl_contains(useBuiltin, opts.kind) then
						return { backend = { "builtin" }, builtin = { relative = "cursor" } }
					end
				end,
			},
		},
	},
}
