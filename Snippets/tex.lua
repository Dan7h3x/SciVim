local ls = require("luasnip")
-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.expand_conditions")
local ai = require("luasnip.nodes.absolute_indexer")
local rec_ls = function()
	return sn(nil, {
		c(1, {
			-- important!! Having the sn(...) as the first choice will cause infinite recursion.
			t({ "" }),
			-- The same dynamicNode as in the snippet (also note: self reference).
			sn(nil, { t({ "", "\t\\item " }), i(1), d(2, rec_ls, {}) }),
		}),
	})
end

ls.add_snippets("tex", {
	s("ls", {
		t({ "\\begin{itemize}", "\t\\item " }),
		i(1),
		d(2, rec_ls, {}),
		t({ "", "\\end{itemize}" }),
		i(0),
	}),
})

local table_node = function(args)
	local tabs = {}
	local count
	table = args[1][1]:gsub("%s", ""):gsub("|", "")
	count = table:len()
	for j = 1, count do
		local iNode
		iNode = i(j)
		tabs[2 * j - 1] = iNode
		if j ~= count then
			tabs[2 * j] = t(" & ")
		end
	end
	return sn(nil, tabs)
end
local rec_table = function()
	return sn(nil, {
		c(1, {
			t({ "" }),
			sn(nil, { t({ "\\\\", "" }), d(1, table_node, { ai[1] }), d(2, rec_table, { ai[1] }) }),
		}),
	})
end

ls.add_snippets("tex", {
	s("table", {
		t("\\begin{tabular}{"),
		i(1, "0"),
		t({ "}", "" }),
		d(2, table_node, { 1 }, {}),
		d(3, rec_table, { 1 }),
		t({ "", "\\end{tabular}" }),
	}),
})

ls.add_snippets("tex", {
	s("pdflatex", {
		t({ "% !TEX TS-program = pdflatex" }),
	}),
})
ls.add_snippets("tex", {
	s("enc8", {
		t({ "% !TEX encoding = UTF-8 Unicode" }),
	}),
})
ls.add_snippets("tex", {
	s("root", {
		t({ "% !TEX root = " }),
		i(0, "dir"),
	}),
})
ls.add_snippets("tex", {
	s("spllchk", {
		t({ "% !TEX speellcheck = en-US" }),
	}),
})

ls.add_snippets("tex", {
	s("$", {
		t("$ "),
		i(0),
		t(" $"),
	}),
})
