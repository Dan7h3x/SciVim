local M = {}

local here = debug.getinfo(1, "S").source:sub(2)
here = vim.fn.fnamemodify(here, ":h")

function M.mod(modname)
	if package.loaded[modname] then
		return package.loaded[modname]
	end
	local ret = loadfile(here .. "/" .. modname:gsub("%.", "/") .. ".lua")()
	package.loaded[modname] = ret
	return ret
end

function M.apply(behavior, integrations)
	local groups = {
		base = true,
	}
	if behavior == "manual" then
		for plug, group in pairs(integrations) do
		end
	end
end

return M
