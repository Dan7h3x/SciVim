local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- LSP References
		LspReferenceText = { bg = colors.color_2 },
		LspReferenceRead = { bg = colors.color_2 },
		LspReferenceWrite = { bg = colors.color_2, underline = true },

		-- LSP Signature
		LspSignatureActiveParameter = { fg = colors.color_11, bold = true },

		-- LSP Semantic Tokens
		["@lsp.type.class"] = { fg = colors.color_11 },
		["@lsp.type.decorator"] = { fg = colors.color_8 },
		["@lsp.type.enum"] = { fg = colors.color_11 },
		["@lsp.type.enumMember"] = { fg = colors.color_10 },
		["@lsp.type.function"] = { fg = colors.color_5 },
		["@lsp.type.interface"] = { fg = colors.color_11 },
		["@lsp.type.macro"] = { fg = colors.color_8 },
		["@lsp.type.method"] = { fg = colors.color_5 },
		["@lsp.type.namespace"] = { fg = colors.color_11 },
		["@lsp.type.parameter"] = { fg = colors.color_13 },
		["@lsp.type.property"] = { fg = colors.color_12 },
		["@lsp.type.struct"] = { fg = colors.color_11 },
		["@lsp.type.type"] = { fg = colors.color_11 },
		["@lsp.type.typeParameter"] = { fg = colors.color_11 },
		["@lsp.type.variable"] = { fg = colors.fg },

		-- Diagnostics
		DiagnosticError = { fg = colors.color_9 },
		DiagnosticWarn = { fg = colors.color_8 },
		DiagnosticInfo = { fg = colors.color_6 },
		DiagnosticHint = { fg = colors.color_3 },
		DiagnosticOk = { fg = colors.color_7 },

		-- Diagnostic Virtual Text
		DiagnosticVirtualTextError = { fg = colors.color_9, italic = true },
		DiagnosticVirtualTextWarn = { fg = colors.color_8, italic = true },
		DiagnosticVirtualTextInfo = { fg = colors.color_6, italic = true },
		DiagnosticVirtualTextHint = { fg = colors.color_3, italic = true },

		-- Diagnostic Underline
		DiagnosticUnderlineError = { sp = colors.color_9, undercurl = true },
		DiagnosticUnderlineWarn = { sp = colors.color_8, undercurl = true },
		DiagnosticUnderlineInfo = { sp = colors.color_6, undercurl = true },
		DiagnosticUnderlineHint = { sp = colors.color_3, undercurl = true },

		-- Diagnostic Signs
		DiagnosticSignError = { fg = colors.color_9 },
		DiagnosticSignWarn = { fg = colors.color_8 },
		DiagnosticSignInfo = { fg = colors.color_6 },
		DiagnosticSignHint = { fg = colors.color_3 },

		-- Diagnostic Floating
		DiagnosticFloatingError = { fg = colors.color_9 },
		DiagnosticFloatingWarn = { fg = colors.color_8 },
		DiagnosticFloatingInfo = { fg = colors.color_6 },
		DiagnosticFloatingHint = { fg = colors.color_3 },

		-- Misc
		DiagnosticUnnecessary = { fg = colors.color_3 },
	}
end

return M
