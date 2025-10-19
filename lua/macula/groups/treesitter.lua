local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Treesitter
		["@variable"] = { fg = colors.fg },
		["@variable.builtin"] = { fg = colors.color_9, italic = true },
		["@variable.parameter"] = { fg = colors.color_13 },
		["@variable.member"] = { fg = colors.color_12 },

		["@constant"] = { fg = colors.color_10 },
		["@constant.builtin"] = { fg = colors.color_10, bold = true },
		["@constant.macro"] = { fg = colors.color_8 },

		["@module"] = { fg = colors.color_11 },
		["@label"] = { fg = colors.color_4 },

		-- Functions
		["@function"] = { fg = colors.color_5, bold = true },
		["@function.builtin"] = { fg = colors.color_5, italic = true },
		["@function.macro"] = { fg = colors.color_8 },
		["@function.method"] = { fg = colors.color_5 },
		["@constructor"] = { fg = colors.color_11 },

		-- Keywords
		["@keyword"] = { fg = colors.color_4, bold = true },
		["@keyword.function"] = { fg = colors.color_4 },
		["@keyword.operator"] = { fg = colors.color_6 },
		["@keyword.return"] = { fg = colors.color_4, bold = true },
		["@keyword.conditional"] = { fg = colors.color_4 },
		["@keyword.repeat"] = { fg = colors.color_4 },
		["@keyword.import"] = { fg = colors.color_8 },
		["@keyword.exception"] = { fg = colors.color_9 },

		-- Operators
		["@operator"] = { fg = colors.color_6 },

		-- Punctuation
		["@punctuation.delimiter"] = { fg = colors.fg_alt },
		["@punctuation.bracket"] = { fg = colors.fg_alt },
		["@punctuation.special"] = { fg = colors.color_6 },

		-- Strings
		["@string"] = { fg = colors.color_7 },
		["@string.regex"] = { fg = colors.color_6 },
		["@string.escape"] = { fg = colors.color_6 },
		["@character"] = { fg = colors.color_7 },

		-- Types
		["@type"] = { fg = colors.color_11 },
		["@type.builtin"] = { fg = colors.color_11, italic = true },
		["@type.definition"] = { fg = colors.color_11 },
		["@type.qualifier"] = { fg = colors.color_4 },

		["@property"] = { fg = colors.color_12 },
		["@attribute"] = { fg = colors.color_8 },

		-- Numbers
		["@number"] = { fg = colors.color_10 },
		["@number.float"] = { fg = colors.color_10 },
		["@boolean"] = { fg = colors.color_10 },

		-- Comments
		["@comment"] = { fg = colors.color_3, italic = true },
		["@comment.documentation"] = { fg = colors.color_4 },
		["@comment.error"] = { fg = colors.color_9 },
		["@comment.warning"] = { fg = colors.color_8 },
		["@comment.todo"] = { fg = colors.color_8, bold = true },
		["@comment.note"] = { fg = colors.color_6 },

		-- Tags (HTML, XML)
		["@tag"] = { fg = colors.color_5 },
		["@tag.attribute"] = { fg = colors.color_12 },
		["@tag.delimiter"] = { fg = colors.fg_alt },

		-- Markup
		["@markup.strong"] = { bold = true },
		["@markup.italic"] = { italic = true },
		["@markup.underline"] = { underline = true },
		["@markup.strike"] = { strikethrough = true },
		["@markup.heading"] = { fg = colors.color_11, bold = true },
		["@markup.link"] = { fg = colors.color_6 },
		["@markup.link.url"] = { fg = colors.color_4, underline = true },
		["@markup.raw"] = { fg = colors.color_7 },
		["@markup.list"] = { fg = colors.color_5 },
		["@markup.quote"] = { fg = colors.color_3, italic = true },

		-- Diffs
		["@diff.plus"] = { fg = colors.color_7 },
		["@diff.minus"] = { fg = colors.color_9 },
		["@diff.delta"] = { fg = colors.color_8 },
	}
end

return M
