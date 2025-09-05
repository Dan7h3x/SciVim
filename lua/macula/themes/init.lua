local M = {}
local dark = require("macula.themes.dark")
local light = require("macula.themes.light")

function M.get_colors(style)
	if dark and style == "dark" then
		M.theme = dark
	elseif light and style == "light" then
		M.theme = light
	else
		M.theme = {}
	end
end

return M
