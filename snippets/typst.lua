-- ~/.config/nvim/luasnippets/typst.lua

local ls = require("luasnip")
local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
local c = ls.choice_node
-- local d = ls.dynamic_node
-- local r = ls.restore_node
-- local l = require("luasnip.extras").lambda
-- local rep = require("luasnip.extras").rep
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty
-- local dl = require("luasnip.extras").dynamic_lambda
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local conds = require("luasnip.extras.expand_conditions")
-- local postfix = require("luasnip.extras.postfix").postfix
-- local types = require("luasnip.util.types")
-- local events = require("luasnip.util.events")

-- Helper function for newlines
-- local function line(...)
-- 	local args = { ... }
-- 	local result = {}
-- 	for i, arg in ipairs(args) do
-- 		table.insert(result, arg)
-- 		if i < #args then
-- 			table.insert(result, t(""))
-- 		end
-- 	end
-- 	return result
-- end

return {
	-- Document structure
	s("doc", {
		t("#set page(width: "),
		c(1, { t("auto"), t("8.5in"), t("21cm") }),
		t(", height: "),
		c(2, { t("auto"), t("11in"), t("29.7cm") }),
		t(")"),
		t(""),
		t(""),
		t('#set text(lang: "'),
		c(3, { t("en"), t("de"), t("fr"), t("es") }),
		t('")'),
		t(""),
		t(""),
		i(0),
	}),

	-- Misc
	s("it", {
		t("_"),
		i(1, "Text"),
		t("_"),
		i(0),
	}),
	s("bo", {
		t("*"),
		i(1, "Text"),
		t("*"),
		i(0),
	}),
	s("itbo", {
		t("_*"),
		i(1, "Text"),
		t("*_"),
		i(0),
	}),

	s("sum", {
		t("sum_("),
		i(1, "i=0"),
		t(")^("),
		i(2, "N"),
		t(") "),
		i(0),
	}),
	s("prd", {
		t("product_("),
		i(1, "i=0"),
		t(")^("),
		i(2, "N"),
		t(") "),
		i(0),
	}),
	s("*", {
		t("^("),
		i(1, "-"),
		t(")"),
		i(0),
	}),
	s("_", {
		t("_("),
		i(1, "-"),
		t(")"),
		i(0),
	}),
	s("ind", {
		t(" "),
		i(1, "i"),
		t(" = "),
		i(2, "1"),
		t(",dots,"),
		i(3, "N"),
		t(" "),
		i(0),
	}),
	s("indx", {
		t(" "),
		i(1, "i"),
		t(" =( "),
		i(2, "1"),
		t(",dots,"),
		i(3, "N"),
		t(")"),
		i(0),
	}),
	-- Section headings
	s("sec", {
		t("# "),
		i(1, "Section Title"),
		t(" "),
		i(0),
	}),

	s("ssec", {
		t("## "),
		i(1, "Subsection Title"),
		t(" "),
		i(0),
	}),

	s("sssec", {
		t("### "),
		i(1, "Sub-subsection Title"),
		t(" "),
		i(0),
	}),

	-- Math expressions
	s("eq", {
		t("$"),
		i(1, "E = mc^2"),
		t("$"),
		i(0),
	}),

	s("eqb", {
		t("$ "),
		t(""),
		i(1, "E = mc^2"),
		t(" $"),
		i(0),
	}),

	-- Lists
	s("item", {
		t("- "),
		i(1, "Item content"),
		i(0),
	}),

	s("enum", {
		t("+ "),
		i(1, "First item"),
		i(0),
	}),

	-- References and citations
	s("ref", {
		t("@"),
		i(1, "label"),
		i(0),
	}),

	s("cite", {
		t("#cite("),
		i(1, "key"),
		t(")"),
		i(0),
	}),

	-- Figures and images
	s("fig", {
		t("#figure("),
		t('  image("'),
		i(1, "path/to/image.png"),
		t('"),'),
		t("  caption: ["),
		i(2, "Figure caption"),
		t("]"),
		t(")"),
		i(0),
	}),

	-- Tables
	s("table", {
		t("#table("),
		t("  columns: "),
		i(1, "3"),
		t(","),
		t("  [],"),
		t("  "),
		i(2, "// Table content"),
		t(")"),
		i(0),
	}),

	-- Functions and definitions
	s("let", {
		t("#let "),
		i(1, "variable"),
		t(" = "),
		i(2, "value"),
		i(0),
	}),

	s("func", {
		t("#let "),
		i(1, "function"),
		t("("),
		i(2, "params"),
		t(") = {"),
		t("  "),
		i(3, "// function body"),
		t("}"),
		i(0),
	}),

	-- Show rules
	s("show", {
		t("#show "),
		i(1, "selector"),
		t(": "),
		i(2, "transformation"),
		i(0),
	}),

	-- Import statements
	s("imp", {
		t('#import "'),
		i(1, "module.typ"),
		t('": '),
		i(2, "*"),
		i(0),
	}),

	s("impas", {
		t('#import "'),
		i(1, "module.typ"),
		t('" as '),
		i(2, "alias"),
		i(0),
	}),

	-- Conditional content
	s("if", {
		t("#if "),
		i(1, "condition"),
		t(" {"),
		t("  "),
		i(2, "// content"),
		t("}"),
		i(0),
	}),

	s("ifelse", {
		t("#if "),
		i(1, "condition"),
		t(" {"),
		t("  "),
		i(2, "// content if true"),
		t("} else {"),
		t("  "),
		i(3, "// content if false"),
		t("}"),
		i(0),
	}),

	-- Loops
	s("for", {
		t("#for "),
		i(1, "item"),
		t(" in "),
		i(2, "collection"),
		t(" {"),
		t("  "),
		i(3, "// content"),
		t("}"),
		i(0),
	}),

	-- Strong and emphasis
	s("strong", {
		t("*"),
		i(1, "strong text"),
		t("*"),
		i(0),
	}),

	s("emph", {
		t("_"),
		i(1, "emphasized text"),
		t("_"),
		i(0),
	}),

	-- Code blocks
	s("code", {
		t("```"),
		i(1, "language"),
		t(""),
		i(2, "code content"),
		t("```"),
		i(0),
	}),

	-- Comments
	s("comment", {
		t("// "),
		i(1, "comment text"),
		i(0),
	}),

	-- Page breaks
	s("pageb", {
		t("#pagebreak()"),
		i(0),
	}),

	-- Columns
	s("cols", {
		t("#columns("),
		i(1, "2"),
		t(")[ "),
		i(2, "content"),
		t(" ]"),
		i(0),
	}),
}
