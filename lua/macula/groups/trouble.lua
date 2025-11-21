local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Trouble UI
		TroubleNormal = { fg = colors.fg, bg = colors.bg },
		TroubleNormalNC = { fg = colors.fg, bg = colors.bg },
		TroubleText = { fg = colors.fg },
		TroubleCount = { fg = colors.color_11, bold = true },
		TroubleCode = { fg = colors.color_7 },
		
		-- Location
		TroubleLocation = { fg = colors.color_3 },
		TroubleFile = { fg = colors.color_5 },
		TroubleDirectory = { fg = colors.color_5 },
		TroubleSource = { fg = colors.color_3 },
		
		-- Icons
		TroubleIconArray = { fg = colors.color_10 },
		TroubleIconBoolean = { fg = colors.color_10 },
		TroubleIconClass = { fg = colors.color_11 },
		TroubleIconConstant = { fg = colors.color_10 },
		TroubleIconConstructor = { fg = colors.color_11 },
		TroubleIconEnum = { fg = colors.color_11 },
		TroubleIconEnumMember = { fg = colors.color_10 },
		TroubleIconEvent = { fg = colors.color_8 },
		TroubleIconField = { fg = colors.color_12 },
		TroubleIconFile = { fg = colors.fg_alt },
		TroubleIconFunction = { fg = colors.color_5 },
		TroubleIconInterface = { fg = colors.color_11 },
		TroubleIconKey = { fg = colors.color_6 },
		TroubleIconMethod = { fg = colors.color_5 },
		TroubleIconModule = { fg = colors.color_11 },
		TroubleIconNamespace = { fg = colors.color_11 },
		TroubleIconNull = { fg = colors.color_1 },
		TroubleIconNumber = { fg = colors.color_10 },
		TroubleIconObject = { fg = colors.color_11 },
		TroubleIconOperator = { fg = colors.color_6 },
		TroubleIconPackage = { fg = colors.color_11 },
		TroubleIconProperty = { fg = colors.color_12 },
		TroubleIconString = { fg = colors.color_7 },
		TroubleIconStruct = { fg = colors.color_11 },
		TroubleIconTypeParameter = { fg = colors.color_11 },
		TroubleIconVariable = { fg = colors.fg },
		
		-- Diagnostics
		TroubleError = { fg = colors.color_9 },
		TroubleWarning = { fg = colors.color_8 },
		TroubleInformation = { fg = colors.color_6 },
		TroubleHint = { fg = colors.color_3 },
		
		-- Signs
		TroubleSignError = { fg = colors.color_9 },
		TroubleSignWarning = { fg = colors.color_8 },
		TroubleSignInformation = { fg = colors.color_6 },
		TroubleSignHint = { fg = colors.color_3 },
		TroubleSignOther = { fg = colors.color_11 },
		
		-- Text emphasis
		TroubleTextError = { fg = colors.color_9 },
		TroubleTextWarning = { fg = colors.color_8 },
		TroubleTextInformation = { fg = colors.color_6 },
		TroubleTextHint = { fg = colors.color_3 },
		
		-- Indent
		TroubleIndent = { fg = colors.color_1 },
		TroubleFoldIcon = { fg = colors.color_3 },
	}
end

return M

