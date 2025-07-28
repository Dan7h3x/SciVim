-- ~/.config/nvim/luasnippets/python.lua

local ls = require("luasnip")
local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
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
--
return {
	-- Main function for scripts
	s("main", {
		t("def main():"),
		t(""),
		t("    "),
		i(1, "pass"),
		t(""),
		t(""),
		t(""),
		t('if __name__ == "__main__":'),
		t(""),
		t("    main()"),
		i(0),
	}),

	-- If statement
	s("if", {
		t("if "),
		i(1, "condition"),
		t(":"),
		t(""),
		t("    "),
		i(2, "pass"),
		i(0),
	}),

	-- If-else statement
	s("ife", {
		t("if "),
		i(1, "condition"),
		t(":"),
		t(""),
		t("    "),
		i(2, "pass"),
		t(""),
		t("else:"),
		t(""),
		t("    "),
		i(3, "pass"),
		i(0),
	}),

	-- If-elif-else statement
	s("ifee", {
		t("if "),
		i(1, "condition"),
		t(":"),
		t(""),
		t("    "),
		i(2, "pass"),
		t(""),
		t("elif "),
		i(3, "condition"),
		t(":"),
		t(""),
		t("    "),
		i(4, "pass"),
		t(""),
		t("else:"),
		t(""),
		t("    "),
		i(5, "pass"),
		i(0),
	}),

	-- For loop
	s("for", {
		t("for "),
		i(1, "item"),
		t(" in "),
		i(2, "iterable"),
		t(":"),
		t(""),
		t("    "),
		i(3, "pass"),
		i(0),
	}),

	-- For loop with range
	s("forr", {
		t("for "),
		i(1, "i"),
		t(" in range("),
		i(2, "n"),
		t("):"),
		t(""),
		t("    "),
		i(3, "pass"),
		i(0),
	}),

	-- While loop
	s("while", {
		t("while "),
		i(1, "condition"),
		t(":"),
		t(""),
		t("    "),
		i(2, "pass"),
		i(0),
	}),

	-- Function definition
	s("def", {
		t("def "),
		i(1, "function_name"),
		t("("),
		i(2, "params"),
		t("):"),
		t(""),
		t('    """'),
		i(3, "Docstring"),
		t('"""'),
		t(""),
		t("    "),
		i(4, "pass"),
		i(0),
	}),

	-- Class definition
	s("class", {
		t("class "),
		i(1, "ClassName"),
		t("("),
		i(2, "object"),
		t("):"),
		t(""),
		t('    """'),
		i(3, "Docstring"),
		t('"""'),
		t(""),
		t("    "),
		i(4, "pass"),
		i(0),
	}),

	-- Try-except
	s("try", {
		t("try:"),
		t(""),
		t("    "),
		i(1, "pass"),
		t(""),
		t("except "),
		i(2, "Exception"),
		t(" as "),
		i(3, "e"),
		t(":"),
		t(""),
		t("    "),
		i(4, "pass"),
		i(0),
	}),

	-- Try-except-finally
	s("tryf", {
		t("try:"),
		t(""),
		t("    "),
		i(1, "pass"),
		t(""),
		t("except "),
		i(2, "Exception"),
		t(" as "),
		i(3, "e"),
		t(":"),
		t(""),
		t("    "),
		i(4, "pass"),
		t(""),
		t("finally:"),
		t(""),
		t("    "),
		i(5, "pass"),
		i(0),
	}),

	-- With statement
	s("with", {
		t("with "),
		i(1, "expression"),
		t(" as "),
		i(2, "target"),
		t(":"),
		t(""),
		t("    "),
		i(3, "pass"),
		i(0),
	}),

	-- Import statements
	s("imp", {
		t("import "),
		i(1, "module"),
		i(0),
	}),

	s("from", {
		t("from "),
		i(1, "module"),
		t(" import "),
		i(2, "name"),
		i(0),
	}),

	-- List comprehension
	s("lc", {
		t("["),
		i(1, "expression"),
		t(" for "),
		i(2, "item"),
		t(" in "),
		i(3, "iterable"),
		t("]"),
		i(0),
	}),

	-- Dictionary comprehension
	s("dc", {
		t("{"),
		i(1, "key"),
		t(": "),
		i(2, "value"),
		t(" for "),
		i(3, "item"),
		t(" in "),
		i(4, "iterable"),
		t("}"),
		i(0),
	}),

	-- Lambda function
	s("lambda", {
		t("lambda "),
		i(1, "x"),
		t(": "),
		i(2, "x"),
		i(0),
	}),

	-- Print statement
	s("pr", {
		t("print("),
		i(1, "text"),
		t(")"),
		i(0),
	}),

	-- Assert statement
	s("ass", {
		t("assert "),
		i(1, "condition"),
		t(", "),
		i(2, '"Assertion failed"'),
		i(0),
	}),

	-- Property decorator
	s("prop", {
		t("@property"),
		t(""),
		t("def "),
		i(1, "name"),
		t("(self):"),
		t(""),
		t("    return self._"),
		i(2, "name"),
		t(""),
		t(""),
		t("@"),
		i(3, "name"),
		t(".setter"),
		t(""),
		t("def "),
		i(4, "name"),
		t("(self, value):"),
		t(""),
		t("    self._"),
		i(5, "name"),
		t(" = value"),
		i(0),
	}),
}
