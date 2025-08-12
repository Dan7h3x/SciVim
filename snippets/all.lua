local ls = require("luasnip")
local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
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
local function box(opts)
	local function box_width()
		return opts.box_width or vim.opt.textwidth:get()
	end

	local function padding(cs, input_text)
		local spaces = box_width() - (2 * #cs)
		spaces = spaces - #input_text
		return spaces / 2
	end

	local comment_string = function()
		return require("luasnip.util.util").buffer_comment_chars()[1]
	end

	return {
		f(function()
			local cs = comment_string()
			return string.rep(string.sub(cs, 1, 1), box_width())
		end, { 1 }),
		t({ "", "" }),
		f(function(args)
			local cs = comment_string()
			return cs .. string.rep(" ", math.floor(padding(cs, args[1][1])))
		end, { 1 }),
		i(1, "placeholder"),
		f(function(args)
			local cs = comment_string()
			return string.rep(" ", math.ceil(padding(cs, args[1][1]))) .. cs
		end, { 1 }),
		t({ "", "" }),
		f(function()
			local cs = comment_string()
			return string.rep(string.sub(cs, 1, 1), box_width())
		end, { 1 }),
	}
end
return {
	s({ trig = "cbox" }, box({ box_width = 16 })),
	s({ trig = "cbbox" }, box({})),
}
