local function borderMenu(hl_name)
	return {
		{ "", "Blue" },
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
return {}
-- return {
-- 	{
-- 		"hrsh7th/nvim-cmp",
-- 		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
-- 		dependencies = {
-- 			"hrsh7th/cmp-nvim-lsp",
-- 			"hrsh7th/cmp-buffer",
-- 			"hrsh7th/cmp-path",
-- 			"hrsh7th/cmp-cmdline",
-- 			"saadparwaiz1/cmp_luasnip",
-- 		},
-- 		config = function()
-- 			local cmp = require("cmp")
-- 			local cmp_sel = { behavior = cmp.SelectBehavior.Insert }
-- 			cmp.setup({
-- 				completion = { completeopt = "menu,menuone,noinsert" },
--
-- 				window = {
-- 					completion = {
-- 						border = borderMenu("FloatBorder"),
-- 						winblend = 0,
-- 					},
-- 					documentation = {
-- 						border = borderDoc("FloatBorder"),
-- 					},
-- 				},
-- 				mapping = cmp.mapping.preset.insert({
-- 					["<C-p>"] = cmp.mapping.select_prev_item(),
-- 					["<C-n>"] = cmp.mapping.select_next_item(),
-- 					["<C-d>"] = cmp.mapping.scroll_docs(-4),
-- 					["<C-f>"] = cmp.mapping.scroll_docs(4),
-- 					["<C-Space>"] = cmp.mapping.complete(),
-- 					["<C-e>"] = cmp.mapping.close(),
--
-- 					["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp_sel }),
-- 					["<Tab>"] = cmp.mapping(function(fallback)
-- 						if cmp.visible() then
-- 							cmp.select_next_item()
-- 						elseif require("luasnip").expand_or_jumpable() then
-- 							require("luasnip").expand_or_jump()
-- 						else
-- 							fallback()
-- 						end
-- 					end, { "i", "s" }),
-- 					["<S-Tab>"] = cmp.mapping(function(fallback)
-- 						if cmp.visible() then
-- 							cmp.select_prev_item()
-- 						elseif require("luasnip").jumpable(-1) then
-- 							require("luasnip").jump(-1)
-- 						else
-- 							fallback()
-- 						end
-- 					end, { "i", "s" }),
-- 				}),
-- 				snippet = {
-- 					expand = function(args)
-- 						require("luasnip").lsp_expand(args.body)
-- 					end,
-- 				},
-- 				sources = cmp.config.sources({
-- 					{ name = "nvim_lsp" },
-- 					{ name = "luasnip" },
-- 					{ name = "buffer" },
-- 					{ name = "nvim_lua" },
-- 					{ name = "path" },
-- 				}),
-- 				formatting = {
-- 					fields = { "kind", "abbr", "menu" },
-- 					format = function(entry, vim_item)
-- 						local icons = require("SciVim.extras.icons").kind_icons
-- 						vim_item.kind = string.format("%s ", icons[vim_item.kind])
-- 						vim_item.menu = ({
-- 							nvim_lsp = "[LSP]",
-- 							nvim_lua = "[Lua]",
-- 							luasnip = "[Sni]",
-- 							buffer = "[Buf]",
-- 							path = "[Pth]",
-- 						})[entry.source.name]
-- 						local widths = {
-- 							abbr = 30,
-- 							menu = 25,
-- 						}
-- 						for key, width in pairs(widths) do
-- 							if vim_item[key] and vim.fn.strdisplaywidth(vim_item[key]) > width then
-- 								vim_item[key] = vim.fn.strcharpart(vim_item[key], 0, width - 1) .. "..."
-- 							end
-- 						end
--
-- 						return vim_item
-- 					end,
-- 				},
-- 			})
-- 		end,
-- 	},
--
-- 	{
-- 		"L3MON4D3/LuaSnip",
-- 		lazy = true,
-- 		dependencies = { "rafamadriz/friendly-snippets" },
-- 		opts = {
-- 			history = true,
-- 			delete_check_events = "TextChanged",
-- 		},
-- 		config = function()
-- 			require("luasnip.loaders.from_vscode").lazy_load()
-- 			require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
-- 		end,
-- 	},
-- }
