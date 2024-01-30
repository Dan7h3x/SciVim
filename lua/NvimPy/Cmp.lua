local cmp = require("cmp")
local luasnip = require("luasnip")
local Icons = require("NvimPy.Icons")
local neogen = require("neogen")
local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local function borderMenu(hl_name)
	return {
		{ "", "CmpBorderIconsLT" },
		{ "─", hl_name },
		{ "▶", "CmpBorderIconsCT" },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local function borderDoc(hl_name)
	return {
		{ "▼", "CmpBorderIconsCT" },
		{ "─", hl_name },
		{ "", "CmpBorderIconsRT" },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local function Kinder(item)
	if item == "Function" then
		return "Func"
	elseif item == "Text" then
		return item
	elseif item == "Module" then
		return "Modl"
	elseif item == "Snippet" then
		return "Snip"
	elseif item == "Variable" then
		return "Varl"
	elseif item == "Folder" then
		return "Dire"
	elseif item == "Method" then
		return "Mthd"
	elseif item == "Keyword" then
		return "Kywd"
	elseif item == "Constant" then
		return "Cost"
	elseif item == "Property" then
		return "Prop"
	elseif item == "Field" then
		return "Fld "
	else
		return item
	end
end

local winhighlightMenu = {
	border = borderMenu("CmpBorder"),
	scrollbar = false,
	col_offset = 1,
	side_padding = 1,
	winhighlight = "Normal:CmpNormal,CursorLine:CursorLine,Search:CursorLine",
}

local winhighlightDoc = {
	border = borderDoc("CmpBorderDoc"),
	col_offset = 0,
	side_padding = 0,
	scrollbar = false,
	winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
}

cmp.setup({
	completion = {
		completeopt = "menu,menuone,noselect",
	},
	preselect = cmp.PreselectMode.None,
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
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			elseif neogen.jumpable() then
				neogen.jump_next()
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
			elseif neogen.jumpable(true) then
				neogen.jump_prev()
			else
				fallback()
			end
		end, { "i", "s" }),
	},

	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 3000 },
		{ name = "luasnip", priority = 1000 },
		{ name = "buffer", priority = 500 },
		{ name = "path", priority = 250 },
		{
			name = "latex_symbols",
			filetype = { "tex", "latex" },
			option = { cache = true, strategy = 2 }, -- avoids reloading each time
			priority = 500,
		},
	}),

	formatting = {
		fields = { "kind", "abbr", "menu" },
		expandable_indicator = true,
		format = function(entry, item)
			item.kind = string.format(" %s-{%s} ", Icons.kind_icons[item.kind], Kinder(item.kind))
			item.menu = ({
				nvim_lua = "{Lua}",
				nvim_lsp = "{Lsp}",
				luasnip = "{Snip}",
				buffer = "{Buff}",
				path = "{Path}",
				latex_symbols = "{TeX}",
			})[entry.source.name]
			return item
		end,
	},

	view = {
		entries = { name = "custom" },
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
		completion = winhighlightMenu,

		documentation = winhighlightDoc,
	},
})

cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "nvim_lsp_document_symbol" },
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
			separator = " | ",
		},
	},
})
