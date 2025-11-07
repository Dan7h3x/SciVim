---@class Macula
---@field config MaculaConfig
---@field palettes table<string, table>

---@class MaculaConfig
---@field palette string The color palette to use
---@field transparent boolean Enable transparent background
---@field terminal_colors boolean Enable terminal colors
---@field integrations MaculaIntegrations Plugin integrations config

---@class MaculaIntegrations
---@field telescope boolean
---@field fzf_lua boolean
---@field nvim_cmp boolean
---@field blink_cmp boolean
---@field lualine boolean
---@field treesitter boolean
---@field lsp boolean
---@field gitsigns boolean
---@field nvim_tree boolean
---@field neo_tree boolean
---@field which_key boolean
---@field indent_blankline boolean
---@field mini boolean
---@field dashboard boolean
---@field lazy boolean
---@field mason boolean
---@field bufferline boolean
---@field nvim_dap_ui boolean
---@field notify boolean
---@field noice boolean
---@field trouble boolean
---@field hop boolean
---@field aerial boolean

local M = {}

---@type MaculaConfig
M.config = {
	palette = "twilight",
	transparent = false,
	terminal_colors = true,
	integrations = {
		telescope = true,
		fzf_lua = true,
		nvim_cmp = true,
		blink_cmp = true,
		lualine = true,
		treesitter = true,
		lsp = true,
		gitsigns = true,
		nvim_tree = true,
		neo_tree = true,
		which_key = true,
		indent_blankline = true,
		mini = true,
		dashboard = true,
		lazy = true,
		mason = true,
		bufferline = true,
		nvim_dap_ui = true,
		notify = true,
		noice = true,
		trouble = true,
		hop = true,
		aerial = true,
	},
}

-- Available palettes
M.palettes = {
	"garden",
	"warm",
	"amber",
	"forest",
	"sky",
	"meadow",
	"dusk",
	"light",
	"nord",
	"evergreen",
	"ocean",
	"twilight",
	-- Light eye-protective palettes
	"dawn",
	"cream",
	"paper",
	"latte",
	"cloud",
	"mist",
	"silk",
}

---Setup macula with user config
---@param opts MaculaConfig?
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Setup utility commands if requested
	if opts then
		local utils = require("macula.utils")
		utils.setup_commands()
	end
end

---Load the current palette
---@return table
function M.load_palette()
	local palette_name = M.config.palette
	local ok, palette = pcall(require, "macula.palletes." .. palette_name)

	if not ok then
		vim.notify("Macula: Palette '" .. palette_name .. "' not found, falling back to 'garden'", vim.log.levels.WARN)
		palette = require("macula.palletes.twilight")
	end

	return palette.colors
end

---Load highlight groups
---@param colors table
function M.load_highlights(colors)
	local highlights = {}

	-- Always load base highlights
	local base = require("macula.groups.base")
	highlights = vim.tbl_extend("force", highlights, base.get(colors))

	-- Load syntax highlights
	local syntax = require("macula.groups.syntax")
	highlights = vim.tbl_extend("force", highlights, syntax.get(colors))

	-- Load LSP highlights
	if M.config.integrations.lsp then
		local lsp = require("macula.groups.lsp")
		highlights = vim.tbl_extend("force", highlights, lsp.get(colors))
	end

	-- Load Treesitter highlights
	if M.config.integrations.treesitter then
		local treesitter = require("macula.groups.treesitter")
		highlights = vim.tbl_extend("force", highlights, treesitter.get(colors))
	end

	-- Load plugin integrations
	local integrations = {
		"telescope",
		"bufferline",
		"fzf_lua",
		"nvim_cmp",
		"blink_cmp",
		"gitsigns",
		"nvim_tree",
		"neo_tree",
		"which_key",
		"indent_blankline",
		"mini",
		"dashboard",
		"lazy",
		"mason",
		"nvim_dap_ui",
		"notify",
		"noice",
		"trouble",
		"hop",
		"aerial",
	}

	for _, integration in ipairs(integrations) do
		if M.config.integrations[integration] then
			local ok, plugin = pcall(require, "macula.groups." .. integration)
			if ok then
				highlights = vim.tbl_extend("force", highlights, plugin.get(colors))
			end
		end
	end

	return highlights
end

---Apply highlights
---@param highlights table
function M.apply_highlights(highlights)
	for group, settings in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, settings)
	end
end

---Set terminal colors
---@param colors table
function M.set_terminal_colors(colors)
	if not M.config.terminal_colors then
		return
	end

	-- Define terminal colors
	vim.g.terminal_color_0 = colors.bg
	vim.g.terminal_color_1 = colors.color_9 or colors.color_1
	vim.g.terminal_color_2 = colors.color_7 or colors.color_2
	vim.g.terminal_color_3 = colors.color_8 or colors.color_3
	vim.g.terminal_color_4 = colors.color_3 or colors.color_4
	vim.g.terminal_color_5 = colors.color_10 or colors.color_5
	vim.g.terminal_color_6 = colors.color_6
	vim.g.terminal_color_7 = colors.fg_alt
	vim.g.terminal_color_8 = colors.bg_alt
	vim.g.terminal_color_9 = colors.color_15 or colors.color_9
	vim.g.terminal_color_10 = colors.color_11 or colors.color_7
	vim.g.terminal_color_11 = colors.color_14 or colors.color_8
	vim.g.terminal_color_12 = colors.color_5 or colors.color_4
	vim.g.terminal_color_13 = colors.color_17 or colors.color_10
	vim.g.terminal_color_14 = colors.color_12 or colors.color_6
	vim.g.terminal_color_15 = colors.fg
end

---Load the colorscheme
function M.load()
	-- Clear existing highlights
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax clear")
	end

	-- Set colorscheme name
	vim.g.colors_name = "macula"

	-- Load colors
	local colors = M.load_palette()

	-- Handle transparency
	if M.config.transparent then
		colors.bg = "NONE"
		colors.bg_alt = "NONE"
	end

	-- Load and apply highlights
	local highlights = M.load_highlights(colors)
	M.apply_highlights(highlights)

	-- Set terminal colors
	M.set_terminal_colors(colors)
end

return M
