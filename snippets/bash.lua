-- ~/.config/nvim/luasnippets/bash.lua

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
	-- Shebang
	s("shb", {
		t("#!/bin/bash"),
		t(""),
		t(""),
		i(0),
	}),

	-- Basic script template
	s("script", {
		t("#!/bin/bash"),
		t(""),
		t(""),
		t("# "),
		i(1, "Script description"),
		t(""),
		t(""),
		t("set -euo pipefail"),
		t(""),
		t("IFS=$'\\n\\t'"),
		t(""),
		t(""),
		t(""),
		i(0),
	}),

	-- If statement
	s("if", {
		t("if [[ "),
		i(1, "condition"),
		t(" ]]; then"),
		t(""),
		t("    "),
		i(2, 'echo "true"'),
		t(""),
		t("fi"),
		i(0),
	}),

	-- If-else statement
	s("ife", {
		t("if [[ "),
		i(1, "condition"),
		t(" ]]; then"),
		t(""),
		t("    "),
		i(2, 'echo "true"'),
		t(""),
		t("else"),
		t(""),
		t("    "),
		i(3, 'echo "false"'),
		t(""),
		t("fi"),
		i(0),
	}),

	-- For loop
	s("for", {
		t("for "),
		i(1, "item"),
		t(" in "),
		i(2, "list"),
		t("; do"),
		t(""),
		t("    "),
		i(3, 'echo "$item"'),
		t(""),
		t("done"),
		i(0),
	}),

	-- For loop with range
	s("forr", {
		t("for (("),
		i(1, "i"),
		t("="),
		i(2, "0"),
		t("; "),
		i(3, "i"),
		t("<"),
		i(4, "10"),
		t("; "),
		i(5, "i"),
		t("++)); do"),
		t(""),
		t("    "),
		i(6, 'echo "$i"'),
		t(""),
		t("done"),
		i(0),
	}),

	-- While loop
	s("while", {
		t("while [[ "),
		i(1, "condition"),
		t(" ]]; do"),
		t(""),
		t("    "),
		i(2, 'echo "looping"'),
		t(""),
		t("done"),
		i(0),
	}),

	-- Function
	s("func", {
		t(""),
		t(""),
		i(1, "function_name"),
		t("() {"),
		t(""),
		t("    "),
		i(2, "# Function body"),
		t(""),
		t("}"),
		i(0),
	}),

	-- Case statement
	s("case", {
		t("case $"),
		i(1, "var"),
		t(" in"),
		t(""),
		t("    "),
		i(2, "pattern"),
		t(")"),
		t(""),
		t("        "),
		i(3, 'echo "match"'),
		t(""),
		t("        ;;"),
		t(""),
		t("    *)"),
		t(""),
		t("        "),
		i(4, 'echo "default"'),
		t(""),
		t("        ;;"),
		t(""),
		t("esac"),
		i(0),
	}),

	-- Error handling
	s("err", {
		t("if [[ $? -ne 0 ]]; then"),
		t(""),
		t('    echo "Error: '),
		i(1, "description"),
		t('" >&2'),
		t(""),
		t("    exit 1"),
		t(""),
		t("fi"),
		i(0),
	}),

	-- Check if command exists
	s("chkcmd", {
		t("command -v "),
		i(1, "command"),
		t(' >/dev/null 2>&1 || { echo "Error: '),
		i(2, "command"),
		t(' is required but not installed." >&2; exit 1; }'),
		i(0),
	}),

	-- Check if file exists
	s("chkfile", {
		t('if [[ ! -f "$'),
		i(1, "file"),
		t('" ]]; then'),
		t(""),
		t('    echo "Error: File $'),
		i(2, "file"),
		t(' not found!" >&2'),
		t(""),
		t("    exit 1"),
		t(""),
		t("fi"),
		i(0),
	}),

	-- Get script directory
	s("scriptdir", {
		t('SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'),
		i(0),
	}),

	-- Parse arguments
	s("args", {
		t("while [[ $# -gt 0 ]]; do"),
		t(""),
		t("    case $1 in"),
		t(""),
		t("        -"),
		i(1, "h"),
		t("|--help)"),
		t(""),
		t('            echo "Usage: '),
		i(2, "script"),
		t(' [OPTIONS]"'),
		t(""),
		t("            exit 0"),
		t(""),
		t("            ;;"),
		t(""),
		t("        *)"),
		t(""),
		t('            echo "Unknown option $1" >&2'),
		t(""),
		t("            exit 1"),
		t(""),
		t("            ;;"),
		t(""),
		t("    esac"),
		t(""),
		t("    shift"),
		t(""),
		t("done"),
		i(0),
	}),
}
