local cmp = require("cmp")
local comparator = require("cmp.config.compare")
local luasnip = require("luasnip")
local win = require("cmp.config.window")
local Icons = require("NvimPy.Icons")
local check_backspace = function()
	local col = vim.fn.col(".") - 1
	return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end
local winhighlight = {
	border = "rounded",
	scrollbar = false,
	winhighlight = "Normal:FloatBorder,FloatBorder:FloatBorder,CursorLine:CursorLine,Search:None",
}
cmp.setup({
	completion = {
		completeopt = "menu,menuone,insert",
	},

	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = {
		["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
		["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-y>"] = cmp.config.disable,
		["<C-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
		["<CR>"] = cmp.mapping.confirm({ select = false }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			elseif has_words_before() then
				cmp.complete()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	},

	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 1000 },
		{ name = "luasnip", priority = 750 },
		{ name = "buffer", priority = 500 },
		{ name = "path", priority = 250 },
		{
			name = "latex_symbols",
			filetype = { "tex", "latex" },
			option = { cache = true, strategy = 2 }, -- avoids reloading each time
			priority = 50,
		},
	}),

	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, item)
			item.kind = string.format("|%s (%s)|", Icons.kind_icons[item.kind], item.kind)
			item.menu = ({
				nvim_lua = "(Lua)",
				nvim_lsp = "(Lsp)",
				luasnip = "(Snip)",
				buffer = "(Buff)",
				latex_symbols = "(TeX)",
			})[entry.source.name]

			return item
		end,
	},

	view = {
		entries = { name = "custom", selection_order = "near_cursor" },
		docs = {
			auto_open = true,
		},
		separator = "|",
	},
	duplicates = {
		nvim_lsp = 1,
		luasnip = 1,
		cmp_tabnine = 1,
		buffer = 1,
		path = 1,
	},

	-- experimental = {
	-- 	ghost_text = { hl_group = "FloatBorder" },
	-- },
	window = {
		completion = win.bordered(winhighlight),

		documentation = win.bordered(winhighlight),
	},
	sorting = {
		comparators = {
			comparator.offset,
			comparator.exact,
			comparator.score,
			comparator.recently_used,
			require("cmp-under-comparator").under,
			comparator.kind,
			-- comparator.sort_text,
			comparator.length,
			comparator.order,
		},
	},
})

cmp.setup.cmdline("/", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
	view = {
		entries = {
			name = "wildmenu",
			separator = "|",
		},
	},
})

-- `:` cmdline setup.
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{
			name = "cmdline",
			option = {
				ignore_cmds = { "Man", "!" },
			},
		},
	}),

	view = {
		entries = {
			name = "wildmenu",
			separator = "|",
		},
	},
})
