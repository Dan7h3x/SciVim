-- ~/.config/nvim/luasnippets/lua.lua

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
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
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local events = require("luasnip.util.events")

return {
	-- Module pattern
	s("mod", {
		t("local M = {}"),
		t(""),
		t(""),
		t("-- "),
		i(1, "Module description"),
		t(""),
		t(""),
		t(""),
		i(2, "-- Module content"),
		t(""),
		t(""),
		t(""),
		t("return M"),
		i(0),
	}),

	-- Function
	s("func", {
		t("local function "),
		i(1, "name"),
		t("("),
		i(2, "params"),
		t(")"),
		t(""),
		t("    "),
		i(3, "-- Function body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- Method
	s("meth", {
		t("function M."),
		i(1, "name"),
		t("("),
		i(2, "params"),
		t(")"),
		t(""),
		t("    "),
		i(3, "-- Method body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- If statement
	s("if", {
		t("if "),
		i(1, "condition"),
		t(" then"),
		t(""),
		t("    "),
		i(2, "-- Body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- If-else statement
	s("ife", {
		t("if "),
		i(1, "condition"),
		t(" then"),
		t(""),
		t("    "),
		i(2, "-- If body"),
		t(""),
		t("else"),
		t(""),
		t("    "),
		i(3, "-- Else body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- If-elseif-else statement
	s("ifee", {
		t("if "),
		i(1, "condition"),
		t(" then"),
		t(""),
		t("    "),
		i(2, "-- If body"),
		t(""),
		t("elseif "),
		i(3, "condition"),
		t(" then"),
		t(""),
		t("    "),
		i(4, "-- ElseIf body"),
		t(""),
		t("else"),
		t(""),
		t("    "),
		i(5, "-- Else body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- For loop (numeric)
	s("for", {
		t("for "),
		i(1, "i"),
		t(" = "),
		i(2, "1"),
		t(", "),
		i(3, "10"),
		t(" do"),
		t(""),
		t("    "),
		i(4, "print(i)"),
		t(""),
		t("end"),
		i(0),
	}),

	-- For loop (generic)
	s("fori", {
		t("for "),
		i(1, "key"),
		t(", "),
		i(2, "value"),
		t(" in ipairs("),
		i(3, "table"),
		t(") do"),
		t(""),
		t("    "),
		i(4, "print(key, value)"),
		t(""),
		t("end"),
		i(0),
	}),

	-- For loop (pairs)
	s("forp", {
		t("for "),
		i(1, "key"),
		t(", "),
		i(2, "value"),
		t(" in pairs("),
		i(3, "table"),
		t(") do"),
		t(""),
		t("    "),
		i(4, "print(key, value)"),
		t(""),
		t("end"),
		i(0),
	}),

	-- While loop
	s("while", {
		t("while "),
		i(1, "condition"),
		t(" do"),
		t(""),
		t("    "),
		i(2, "-- Loop body"),
		t(""),
		t("end"),
		i(0),
	}),

	-- Repeat-until loop
	s("repeat", {
		t("repeat"),
		t(""),
		t("    "),
		i(1, "-- Loop body"),
		t(""),
		t("until "),
		i(2, "condition"),
		i(0),
	}),

	-- Table
	s("tbl", {
		t("local "),
		i(1, "name"),
		t(" = {"),
		t(""),
		t("    "),
		i(2, "-- Table content"),
		t(""),
		t("}"),
		i(0),
	}),

	-- Require statement
	s("req", {
		t("local "),
		i(1, "module"),
		t(' = require("'),
		i(2, "module"),
		t('")'),
		i(0),
	}),

	-- Print statement
	s("pr", {
		t("print("),
		i(1, '"Hello, World!"'),
		t(")"),
		i(0),
	}),

	-- Error handling
	s("pcall", {
		t("local success, result = pcall(function()"),
		t(""),
		t("    "),
		i(1, "-- Protected code"),
		t(""),
		t("end)"),
		t(""),
		t(""),
		t(""),
		t("if not success then"),
		t(""),
		t('    print("Error:", result)'),
		t(""),
		t("end"),
		i(0),
	}),

	-- Class-like structure (metatable)
	s("class", {
		t("local "),
		i(1, "Class"),
		t(" = {}"),
		t(""),
		t(""),
		t("function "),
		i(2, "Class"),
		t(":new(o)"),
		t(""),
		t("    o = o or {}"),
		t(""),
		t("    setmetatable(o, self)"),
		t(""),
		t("    self.__index = self"),
		t(""),
		t("    return o"),
		t(""),
		t("end"),
		t(""),
		t(""),
		t(""),
		t("function "),
		i(3, "Class"),
		t(":"),
		i(4, "method"),
		t("()"),
		t(""),
		t("    "),
		i(5, "-- Method implementation"),
		t(""),
		t("end"),
		t(""),
		t(""),
		t(""),
		t("return "),
		i(6, "Class"),
		i(0),
	}),

	-- Vim plugin setup
	s("plugin", {
		t("local M = {}"),
		t(""),
		t(""),
		t("function M.setup(opts)"),
		t(""),
		t("    opts = opts or {}"),
		t(""),
		t("    "),
		i(1, "-- Setup code"),
		t(""),
		t("end"),
		t(""),
		t(""),
		t(""),
		t("return M"),
		i(0),
	}),
}
