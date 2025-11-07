local M = {}

---Get all available palettes
---@return table
function M.get_palettes()
	return require("macula").palettes
end

---Get current palette name
---@return string
function M.get_current_palette()
	return require("macula").config.palette
end

---Switch to a specific palette
---@param palette_name string
function M.switch_palette(palette_name)
	local macula = require("macula")
	local palettes = macula.palettes

	-- Validate palette name
	local valid = false
	for _, p in ipairs(palettes) do
		if p == palette_name then
			valid = true
			break
		end
	end

	if not valid then
		vim.notify(
			"Invalid palette: " .. palette_name .. ". Available: " .. table.concat(palettes, ", "),
			vim.log.levels.ERROR
		)
		return false
	end

	macula.config.palette = palette_name
	vim.cmd("colorscheme macula")
	vim.cmd("redraw!")
	vim.cmd("syntax sync fromstart")
	-- vim.notify("Macula: Switched to '" .. palette_name .. "' palette", vim.log.levels.INFO)
	return true
end

---Cycle to next palette
function M.next_palette()
	local macula = require("macula")
	local palettes = macula.palettes
	local current = macula.config.palette
	local idx = 1

	for i, p in ipairs(palettes) do
		if p == current then
			idx = (i % #palettes) + 1
			break
		end
	end

	M.switch_palette(palettes[idx])
end

---Cycle to previous palette
function M.prev_palette()
	local macula = require("macula")
	local palettes = macula.palettes
	local current = macula.config.palette
	local idx = #palettes

	for i, p in ipairs(palettes) do
		if p == current then
			idx = i - 1
			if idx < 1 then
				idx = #palettes
			end
			break
		end
	end

	M.switch_palette(palettes[idx])
end

---Show palette picker
function M.select_palette()
	local palettes = require("macula").palettes

	vim.ui.select(palettes, {
		prompt = "Select Macula Palette:",
		format_item = function(item)
			local current = require("macula").config.palette
			if item == current then
				return "● " .. item .. " (current)"
			end
			return "  " .. item
		end,
	}, function(choice)
		if choice then
			M.switch_palette(choice)
		end
	end)
end

---Toggle transparent background
function M.toggle_transparent()
	local macula = require("macula")
	macula.config.transparent = not macula.config.transparent
	vim.cmd("colorscheme macula")
	local status = macula.config.transparent and "enabled" or "disabled"
	vim.notify("Macula: Transparent background " .. status, vim.log.levels.INFO)
end

---Get time-based palette recommendation
---@return string
function M.get_time_based_palette()
	local hour = tonumber(os.date("%H"))

	if hour >= 6 and hour < 9 then
		return "warm"
	elseif hour >= 9 and hour < 12 then
		return "light"
	elseif hour >= 12 and hour < 17 then
		return "amber"
	elseif hour >= 17 and hour < 21 then
		return "garden"
	elseif hour >= 21 or hour < 2 then
		return "twilight"
	else
		return "nord"
	end
end

---Apply time-based palette
function M.apply_time_based_palette()
	local palette = M.get_time_based_palette()
	M.switch_palette(palette)
end

---Get color from current palette
---@param color_name string
---@return string|nil
function M.get_color(color_name)
	local colors = require("macula").load_palette()
	return colors[color_name]
end

---Print current palette colors
function M.show_colors()
	local colors = require("macula").load_palette()
	local palette_name = require("macula").config.palette

	print("\n=== Macula Palette: " .. palette_name .. " ===\n")

	-- Show main colors
	print("Main Colors:")
	print("  bg:      " .. colors.bg)
	print("  fg:      " .. colors.fg)
	print("  bg_alt:  " .. colors.bg_alt)
	print("  fg_alt:  " .. colors.fg_alt)

	-- Show color palette
	print("\nColor Palette:")
	for i = 1, 20 do
		local key = "color_" .. i
		if colors[key] then
			print(string.format("  color_%-2d: %s", i, colors[key]))
		end
	end
	print("\n")
end

---Export current palette to a file
---@param filepath string
function M.export_palette(filepath)
	local colors = require("macula").load_palette()
	local palette_name = require("macula").config.palette

	local lines = {
		"-- Macula Palette Export: " .. palette_name,
		"-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"return {",
		'  name = "' .. palette_name .. '",',
		"  colors = {",
	}

	-- Add main colors
	table.insert(lines, '    bg = "' .. colors.bg .. '",')
	table.insert(lines, '    fg = "' .. colors.fg .. '",')
	table.insert(lines, '    bg_alt = "' .. colors.bg_alt .. '",')
	table.insert(lines, '    fg_alt = "' .. colors.fg_alt .. '",')
	table.insert(lines, "")

	-- Add color palette
	for i = 1, 20 do
		local key = "color_" .. i
		if colors[key] then
			table.insert(lines, string.format('    color_%d = "%s",', i, colors[key]))
		end
	end

	table.insert(lines, "  },")
	table.insert(lines, "}")

	-- Write to file
	local file = io.open(filepath, "w")
	if file then
		file:write(table.concat(lines, "\n"))
		file:close()
		vim.notify("Palette exported to: " .. filepath, vim.log.levels.INFO)
		return true
	else
		vim.notify("Failed to export palette to: " .. filepath, vim.log.levels.ERROR)
		return false
	end
end

---Setup user commands
function M.setup_commands()
	-- Switch palette
	vim.api.nvim_create_user_command("MaculaSwitch", function(opts)
		M.switch_palette(opts.args)
	end, {
		nargs = 1,
		complete = function()
			return require("macula").palettes
		end,
		desc = "Switch Macula palette",
	})

	-- Select palette via UI
	vim.api.nvim_create_user_command("MaculaSelect", function()
		M.select_palette()
	end, { desc = "Select Macula palette" })

	-- Next palette
	vim.api.nvim_create_user_command("MaculaNext", function()
		M.next_palette()
	end, { desc = "Next Macula palette" })

	-- Previous palette
	vim.api.nvim_create_user_command("MaculaPrev", function()
		M.prev_palette()
	end, { desc = "Previous Macula palette" })

	-- Toggle transparent
	vim.api.nvim_create_user_command("MaculaTransparent", function()
		M.toggle_transparent()
	end, { desc = "Toggle Macula transparent background" })

	-- Time-based palette
	vim.api.nvim_create_user_command("MaculaTimeBased", function()
		M.apply_time_based_palette()
	end, { desc = "Apply time-based Macula palette" })

	-- Show colors
	vim.api.nvim_create_user_command("MaculaColors", function()
		M.show_colors()
	end, { desc = "Show Macula palette colors" })

	-- Export palette
	vim.api.nvim_create_user_command("MaculaExport", function(opts)
		local filepath = opts.args ~= "" and opts.args or vim.fn.stdpath("config") .. "/macula_palette_export.lua"
		M.export_palette(filepath)
	end, {
		nargs = "?",
		complete = "file",
		desc = "Export current Macula palette",
	})
end

return M
