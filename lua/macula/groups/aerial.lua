local M = {}

---@param colors table
---@return table
function M.get(colors)
	return {
		-- Aerial outline plugin
		AerialNormal = { fg = colors.fg, bg = colors.bg },
		AerialNormalNC = { fg = colors.fg, bg = colors.bg },
		AerialLine = { bg = colors.color_2 },
		AerialLineNC = { bg = colors.color_2 },
		AerialGuide = { fg = colors.color_2 },
		
		-- Symbol types
		AerialClass = { fg = colors.color_11 },
		AerialClassIcon = { fg = colors.color_11 },
		AerialConstructor = { fg = colors.color_11 },
		AerialConstructorIcon = { fg = colors.color_11 },
		AerialEnum = { fg = colors.color_11 },
		AerialEnumIcon = { fg = colors.color_11 },
		AerialEnumMember = { fg = colors.color_10 },
		AerialEnumMemberIcon = { fg = colors.color_10 },
		AerialEvent = { fg = colors.color_8 },
		AerialEventIcon = { fg = colors.color_8 },
		AerialField = { fg = colors.color_12 },
		AerialFieldIcon = { fg = colors.color_12 },
		AerialFile = { fg = colors.fg_alt },
		AerialFileIcon = { fg = colors.fg_alt },
		AerialFunction = { fg = colors.color_5 },
		AerialFunctionIcon = { fg = colors.color_5 },
		AerialInterface = { fg = colors.color_11 },
		AerialInterfaceIcon = { fg = colors.color_11 },
		AerialMethod = { fg = colors.color_5 },
		AerialMethodIcon = { fg = colors.color_5 },
		AerialModule = { fg = colors.color_11 },
		AerialModuleIcon = { fg = colors.color_11 },
		AerialNamespace = { fg = colors.color_11 },
		AerialNamespaceIcon = { fg = colors.color_11 },
		AerialObject = { fg = colors.color_11 },
		AerialObjectIcon = { fg = colors.color_11 },
		AerialOperator = { fg = colors.color_6 },
		AerialOperatorIcon = { fg = colors.color_6 },
		AerialPackage = { fg = colors.color_11 },
		AerialPackageIcon = { fg = colors.color_11 },
		AerialProperty = { fg = colors.color_12 },
		AerialPropertyIcon = { fg = colors.color_12 },
		AerialStruct = { fg = colors.color_11 },
		AerialStructIcon = { fg = colors.color_11 },
		AerialTypeParameter = { fg = colors.color_11 },
		AerialTypeParameterIcon = { fg = colors.color_11 },
		AerialVariable = { fg = colors.fg },
		AerialVariableIcon = { fg = colors.fg },
	}
end

return M

