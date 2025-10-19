local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Comments
		Comment = { fg = colors.color_1, italic = true },
		
		-- Constants
		Constant = { fg = colors.color_10 },
		String = { fg = colors.color_7 },
		Character = { fg = colors.color_7 },
		Number = { fg = colors.color_10 },
		Boolean = { fg = colors.color_10 },
		Float = { fg = colors.color_10 },
		
		-- Identifiers
		Identifier = { fg = colors.fg },
		Function = { fg = colors.color_5, bold = true },
		
		-- Statements
		Statement = { fg = colors.color_4 },
		Conditional = { fg = colors.color_4 },
		Repeat = { fg = colors.color_4 },
		Label = { fg = colors.color_4 },
		Operator = { fg = colors.color_6 },
		Keyword = { fg = colors.color_4, bold = true },
		Exception = { fg = colors.color_9 },
		
		-- PreProc
		PreProc = { fg = colors.color_8 },
		Include = { fg = colors.color_8 },
		Define = { fg = colors.color_8 },
		Macro = { fg = colors.color_8 },
		PreCondit = { fg = colors.color_8 },
		
		-- Types
		Type = { fg = colors.color_11 },
		StorageClass = { fg = colors.color_11 },
		Structure = { fg = colors.color_11 },
		Typedef = { fg = colors.color_11 },
		
		-- Special
		Special = { fg = colors.color_6 },
		SpecialChar = { fg = colors.color_6 },
		Tag = { fg = colors.color_5 },
		Delimiter = { fg = colors.fg_alt },
		SpecialComment = { fg = colors.color_3, italic = true },
		Debug = { fg = colors.color_9 },
		
		-- Underlined
		Underlined = { underline = true },
		
		-- Ignore
		Ignore = { fg = colors.color_1 },
		
		-- Error
		Error = { fg = colors.color_9, bold = true },
		
		-- Todo
		Todo = { fg = colors.color_8, bg = colors.bg_alt, bold = true },
		
		-- Markdown
		markdownHeadingDelimiter = { fg = colors.color_5, bold = true },
		markdownH1 = { fg = colors.color_11, bold = true },
		markdownH2 = { fg = colors.color_10, bold = true },
		markdownH3 = { fg = colors.color_8, bold = true },
		markdownH4 = { fg = colors.color_7, bold = true },
		markdownH5 = { fg = colors.color_6 },
		markdownH6 = { fg = colors.color_5 },
		markdownCode = { fg = colors.color_7, bg = colors.bg_alt },
		markdownCodeBlock = { fg = colors.color_7 },
		markdownCodeDelimiter = { fg = colors.color_6 },
		markdownBlockquote = { fg = colors.color_3 },
		markdownListMarker = { fg = colors.color_5 },
		markdownOrderedListMarker = { fg = colors.color_5 },
		markdownRule = { fg = colors.color_2 },
		markdownLinkText = { fg = colors.color_6 },
		markdownUrl = { fg = colors.color_4, underline = true },
	}
end

return M

