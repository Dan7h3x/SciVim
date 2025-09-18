local function borderMenu(hl_name)
	return {
		{ "", "Special" },
		{ "─", hl_name },
		{ "▲", "Orange" },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local function borderDoc(hl_name)
	return {
		{ "▼", "Orange" },
		{ "─", hl_name },
		{ "╮", hl_name },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end
return {
	{
		"saghen/blink.cmp",
		event = "InsertEnter",
		opts_extend = {
			"sources.completion.enabled_providers",
			"sources.compat",
			"sources.default",
		},
		dependencies = {
			-- { "rafamadriz/friendly-snippets" },
			{
				"saghen/blink.compat",
				optional = true,
				opts = {},
				version = "*",
			},
			{ "garymjr/nvim-snippets", enabled = true },
		},
		version = "*",

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				["<CR>"] = { "select_and_accept", "fallback" },
				["<Esc>"] = { "hide", "fallback" },
				-- ["<C-c>"] = { "cancel", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-e>"] = { "cancel", "show", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-y>"] = { "select_and_accept" },

				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<Tab>"] = {
					function(cmp)
						if not cmp.is_visible() and cmp.snippet_active() then
							return cmp.snippet_forward()
						else
							return cmp.select_next()
						end
					end,
					"snippet_forward",
					"fallback",
				},
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<S-up>"] = { "scroll_documentation_up", "fallback" },
				["<S-down>"] = { "scroll_documentation_down", "fallback" },
			},
			cmdline = {
				enabled = false,
				keymap = { preset = "inherit" },
				completion = { menu = { auto_show = false } },
			},
			appearance = {
				nerd_font_variant = "normal",
				kind_icons = require("SciVim.extras.icons").kind_icons,
			},
			snippets = {
				preset = "default",
			},
			completion = {
				accept = {
					auto_brackets = { enabled = false },
				},
				menu = {
					border = borderMenu("FloatBorder"),
					max_height = 10,
					draw = {
						columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
						treesitter = { "lsp" },
					},
				},
				documentation = {
					window = {
						max_height = 15,
						max_width = 40,
						border = borderDoc("FloatBorder"),
					},
					auto_show = true,
					auto_show_delay_ms = 100,
					treesitter_highlighting = true,
				},
				ghost_text = { enabled = false },
			},
			sources = {
				default = { "lsp", "snippets", "path", "buffer", "lazydev" },
				providers = {
					lsp = {
						name = "[Lsp]",
						module = "blink.cmp.sources.lsp",
						opts = {}, -- Passed to the source directly, varies by source

						enabled = true, -- Whether or not to enable the provider
						async = true, -- Whether we should wait for the provider to return before showing the completions
						timeout_ms = 1000, -- How long to wait for the provider to return before showing completions and treating it as asynchronous
						transform_items = nil, -- Function to transform the items before they're returned
						should_show_items = true, -- Whether or not to show the items
						max_items = nil, -- Maximum number of items to display in the menu
						min_keyword_length = 0, -- Minimum number of characters in the keyword to trigger the provider
						-- If this provider returns 0 items, it will fallback to these providers.
						-- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
						fallbacks = {},
						score_offset = 7, -- Boost/penalize the score of the items
						override = nil, -- Override the source's functions
					},
					path = {
						name = "[Path]",
						module = "blink.cmp.sources.path",
						fallbacks = { "buffer" },
						score_offset = 5,
						opts = {
							trailing_slash = true,
							label_trailing_slash = true,
							get_cwd = function(context)
								return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
							end,
							show_hidden_files_by_default = true,
						},
					},

					snippets = {
						name = "[Snip]",
						module = "blink.cmp.sources.snippets",
						score_offset = 6, -- Boost/penalize the score of the items
						opts = {
							use_show_condition = true,
							show_autosnippets = true,
						},
						-- from the final inserted text
					},
					lazydev = {
						name = "[Lazy]",
						module = "lazydev.integrations.blink",
						score_offset = 10,
					},

					buffer = {
						name = "[Buff]",
						module = "blink.cmp.sources.buffer",
						score_offset = 3,
						opts = {},
					},
				},
			},
		},
		config = function(_, opts)
			local enabled = opts.sources.default
			for _, source in ipairs(opts.sources.compat or {}) do
				opts.sources.providers[source] = vim.tbl_deep_extend(
					"force",
					{ name = source, module = "blink.compat.source" },
					opts.sources.providers[source] or {}
				)
				if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
					table.insert(enabled, source)
				end
			end
			opts.sources.compat = nil
			require("blink.cmp").setup(opts)
		end,
	},
}
