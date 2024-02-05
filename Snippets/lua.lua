local ls = require("luasnip")
local s = ls.s --> Snippet
local i = ls.i --> Insert
local t = ls.t
local d = ls.dynamic_node
local c = ls.choice_node
local f = ls.function_node
local sn = ls.snippet_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local snippets, autosnippets = {}, {}

local group = vim.api.nvim_create_augroup("Lua Snippets", { clear = true })
local file_pattern = "*.lua"

local Snip1 = s("Fuck", {
	t("Fuck it man,"),
	i(1, " +"),
	t(" is domb shit"),
})
table.insert(snippets, Snip1)

local Snip2 = s(
	"funl",
	fmt(
		[[
local {} = function({})
  {}
end
]],
		{
			i(1, "funname"),
			i(2, "arg"),
			i(3, "states"),
		}
	)
)

table.insert(snippets, Snip2)



return snippets, autosnippets
