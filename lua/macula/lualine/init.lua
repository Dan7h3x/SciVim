local M = {}

---Generate lualine theme from colors
---@param colors table
---@return table
function M.generate_theme(colors)
	local theme = {
		normal = {
			a = { fg = colors.bg, bg = colors.color_5, gui = "bold" },
			b = { fg = colors.fg, bg = colors.bg_alt },
			c = { fg = colors.fg_alt, bg = colors.bg },
		},
		insert = {
			a = { fg = colors.bg, bg = colors.color_7, gui = "bold" },
			b = { fg = colors.fg, bg = colors.bg_alt },
			c = { fg = colors.fg_alt, bg = colors.bg },
		},
		visual = {
			a = { fg = colors.bg, bg = colors.color_11, gui = "bold" },
			b = { fg = colors.fg, bg = colors.bg_alt },
			c = { fg = colors.fg_alt, bg = colors.bg },
		},
		replace = {
			a = { fg = colors.bg, bg = colors.color_9, gui = "bold" },
			b = { fg = colors.fg, bg = colors.bg_alt },
			c = { fg = colors.fg_alt, bg = colors.bg },
		},
		command = {
			a = { fg = colors.bg, bg = colors.color_8, gui = "bold" },
			b = { fg = colors.fg, bg = colors.bg_alt },
			c = { fg = colors.fg_alt, bg = colors.bg },
		},
		inactive = {
			a = { fg = colors.color_1, bg = colors.bg },
			b = { fg = colors.color_1, bg = colors.bg },
			c = { fg = colors.color_1, bg = colors.bg },
		},
	}
	
	return theme
end

---Get lualine theme for current palette
---@return table
function M.get_theme()
	local macula = require("macula")
	local colors = macula.load_palette()
	return M.generate_theme(colors)
end

return M

