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
			{
				"L3MON4D3/LuaSnip",
				dependencies = {
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
							require("luasnip.loaders.from_lua").lazy_load({
								paths = vim.fn.stdpath("config") .. "/snippets",
							})
						end,
					},
				},
				version = "v2.*",
				build = "make install_jsregexp",
				opts = { history = true },
				delete_check_events = "TextChanged",
			},
			-- { "garymjr/nvim-snippets", enabled = true },
		},
		version = "*",

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				["<CR>"] = { "accept", "fallback" },
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
						if not require("blink-cmp").is_visible() and cmp.snippet_active() then
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
				preset = "luasnip",
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
						score_offset = 5, -- Boost/penalize the score of the items
						override = nil, -- Override the source's functions
					},
					path = {
						name = "[Path]",
						module = "blink.cmp.sources.path",
						fallbacks = { "buffer" },
						score_offset = 3,
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
					},
					lazydev = {
						name = "[Lazy]",
						module = "lazydev.integrations.blink",
						score_offset = 32,
					},

					buffer = {
						name = "[Buff]",
						module = "blink.cmp.sources.buffer",
						score_offset = -3,
						opts = {
							get_bufnrs = function()
								return vim.iter(vim.api.nvim_list_wins())
									:map(function(win)
										return vim.api.nvim_win_get_buf(win)
									end)
									:filter(function(buf)
										return vim.bo[buf].buftype ~= "nofile"
									end)
									:totable()
							end,
							-- buffers when searching with `/` or `?`
							get_search_bufnrs = function()
								return { vim.api.nvim_get_current_buf() }
							end,
							-- Maximum total number of characters (across all selected buffers) for which buffer completion runs synchronously. Above this, asynchronous processing is used.
							max_sync_buffer_size = 20000,
							-- Maximum total number of characters (across all selected buffers) for which buffer completion runs asynchronously. Above this, buffer completions are skipped to avoid performance issues.
							max_async_buffer_size = 200000,
							-- Maximum text size across all buffers (default: 500KB)
							max_total_buffer_size = 500000,
							-- Order in which buffers are retained for completion, up to the max total size limit (see above)
							retention_order = { "focused", "visible", "recency", "largest" },
							-- Cache words for each buffer which increases memory usage but drastically reduces cpu usage. Memory usage depends on the size of the buffers from `get_bufnrs`. For 100k items, it will use ~20MBs of memory. Invalidated and refreshed whenever the buffer content is modified.
							use_cache = true,
							-- Whether to enable buffer source in substitute (:s) and global (:g) commands.
							-- Note: Enabling this option will temporarily disable Neovim's 'inccommand' feature
							-- while editing Ex commands, due to a known redraw issue (see neovim/neovim#9783).
							-- This means you will lose live substitution previews when using :s, :smagic, or :snomagic
							-- while buffer completions are active.
							enable_in_ex_commands = false,
						},
					},
				},
			},
		},
	},
}
