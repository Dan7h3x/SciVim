-- ~/.config/nvim/luasnippets/python.lua

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
-- local l = require("luasnip.extras").lambda
-- local rep = require("luasnip.extras").rep
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty
-- local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
-- local conds = require("luasnip.extras.expand_conditions")
-- local postfix = require("luasnip.extras.postfix").postfix
-- local types = require("luasnip.util.types")
-- local events = require("luasnip.util.events")
--
-- see latex infinite list for the idea. Allows to keep adding arguments via choice nodes.
local function pinit()
	return sn(
		nil,
		c(1, {
			t(""),
			sn(1, {
				t(", "),
				i(1),
				d(2, pinit),
			}),
		})
	)
end

-- splits the string of the comma separated argument list into the arguments
-- and returns the text-/insert- or restore-nodes
local function to_init(args)
	local tab = {}
	local a = args[1][1]
	if #a == 0 then
		table.insert(tab, t({ "", "\tpass" }))
	else
		local cnt = 1
		for e in string.gmatch(a, " ?([^,]*) ?") do
			if #e > 0 then
				table.insert(tab, t({ "", "\tself." }))
				-- use a restore-node to be able to keep the possibly changed attribute name
				-- (otherwise this function would always restore the default, even if the user
				-- changed the name)
				table.insert(tab, r(cnt, tostring(cnt), i(nil, e)))
				table.insert(tab, t(" = "))
				table.insert(tab, t(e))
				cnt = cnt + 1
			end
		end
	end
	return sn(nil, tab)
end

local generate_matchcase_dynamic = function(args, snip)
	if not snip.num_cases then
		snip.num_cases = tonumber(snip.captures[1]) or 1
	end
	local nodes = {}
	local ins_idx = 1
	for j = 1, snip.num_cases do
		vim.list_extend(
			nodes,
			fmta(
				[[
        case <>:
            <>
        ]],
				{ r(ins_idx, "var" .. j, i(1)), r(ins_idx + 1, "next" .. j, i(0)) }
			)
		)
		table.insert(nodes, t({ "", "" }))
		ins_idx = ins_idx + 2
	end
	table.remove(nodes, #nodes) -- removes the extra line break
	return isn(nil, nodes, "\t")
end

return {
	s(
		"pin",
		fmt([[def __init__(self{}):{}]], {
			d(1, pinit),
			d(2, to_init, { 1 }),
		})
	),
	s(
		{ trig = "mc(%d*)", name = "match case", dscr = "match n cases", regTrig = true, hidden = true },
		fmta(
			[[
    match <>:
        <>
        <>
    ]],
			{
				i(1),
				d(2, generate_matchcase_dynamic, {}, {
					user_args = {
						function(snip)
							snip.num_cases = snip.num_cases + 1
						end,
						function(snip)
							snip.num_cases = math.max(snip.num_cases - 1, 1)
						end, -- don't drop below 1 case, probably can be modified but it seems reasonable to me :shrug:
					},
				}),
				c(3, {
					t(""),
					isn(
						nil,
						fmta(
							[[
    case _:
        <>
    ]],
							{ i(1, "pass") }
						),
						"\t"
					),
				}),
			}
		)
	),
}
