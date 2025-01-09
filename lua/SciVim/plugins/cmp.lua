local function borderMenu(hl_name)
	return {
		{ "", "SciVimBlue" },
		{ "─", hl_name },
		{ "▼", "SciVimOrange" },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local function borderDoc(hl_name)
	return {
		{ "▲", "SciVimOrange" },
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
		lazy = true,
		event = { "InsertEnter" },
		-- optional: provides snippets for the snippet source
		dependencies = "rafamadriz/friendly-snippets",

		-- use a release tag to download pre-built binaries
		version = "*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' for mappings similar to built-in completion
			-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
			-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
			-- See the full "keymap" documentation for information on defining your own keymap.
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
				["<C-k>"] = { "show", "show_documentation", "hide_documentation" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<S-up>"] = { "scroll_documentation_up", "fallback" },
				["<S-down>"] = { "scroll_documentation_down", "fallback" },
				cmdline = {
					["<CR>"] = { "accept", "fallback" },
					["<Esc>"] = { "hide", "fallback" },
					["<Tab>"] = { "select_next", "fallback" },
					["<S-Tab>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<Up>"] = { "select_prev", "fallback" },
					["<C-e>"] = { "cancel", "fallback" },
					["<C-y>"] = { "select_and_accept" },
				},
			},

			appearance = {
				-- Sets the fallback highlight groups to nvim-cmp's highlight groups
				-- Useful for when your theme doesn't support blink.cmp
				-- Will be removed in a future release
				use_nvim_cmp_as_default = true,
				-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
				kind_icons = require("SciVim.extras.icons").kind_icons,
			},
			-- signature = { enabled = true },
			completion = {
				-- list = { selection = "manual" },
				-- list = { selection = "preselect" },
				accept = {
					create_undo_point = true,
					auto_brackets = { enabled = true },
				},
				menu = {
					border = borderMenu("Ghost"),
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
						border = borderDoc("Ghost"),
					},
					auto_show = true,
					auto_show_delay_ms = 100,
					treesitter_highlighting = true,
				},
				ghost_text = { enabled = false },
			},
			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "lazydev" },
				providers = {
					lsp = {
						name = "[lsp]",
					},
					snippets = {
						name = "[snips]",
						-- don't show when triggered manually (= length 0), useful
						-- when manually showing completions to see available JSON keys
						min_keyword_length = 2,
						score_offset = -1,
					},
					path = { name = "[path]", opts = { get_cwd = vim.uv.cwd } },
					-- copilot = {
					--   name = "[copilot]",
					--   module = "blink-cmp-copilot",
					--   score_offset = 100,
					--   async = true,
					-- },
					lazydev = {
						name = "[lazy]",
						module = "lazydev.integrations.blink",
						score_offset = 100, -- show at a higher priority than lsp
					},
					markdown = { name = "[md]", module = "render-markdown.integ.blink" },
					-- supermaven = { name = "[super]", kind = "Supermaven", module = "supermaven.cmp", score_offset = 100, async = true },
					-- codecompanion = {
					--   name = "codecompanion",
					--   module = "codecompanion.providers.completion.blink",
					--   enabled = true,
					-- },
					buffer = {
						name = "[buf]",
						-- disable being fallback for LSP, but limit its display via
						-- the other settings
						-- fallbacks = {},
						max_items = 4,
						min_keyword_length = 4,
						score_offset = -3,

						-- show completions from all buffers used within the last x minutes
						opts = {
							get_bufnrs = function()
								local mins = 15
								local allOpenBuffers = vim.fn.getbufinfo({ buflisted = 1, bufloaded = 1 })
								local recentBufs = vim.iter(allOpenBuffers)
									:filter(function(buf)
										local recentlyUsed = os.time() - buf.lastused < (60 * mins)
										local nonSpecial = vim.bo[buf.bufnr].buftype == ""
										return recentlyUsed and nonSpecial
									end)
									:map(function(buf)
										return buf.bufnr
									end)
									:totable()
								return recentBufs
							end,
						},
					},
				},
			},
			-- opts_extend = { "sources.default" }
		},
	},
}
