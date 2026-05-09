-- golden-ratio.lua
-- Automatic resizing of Neovim windows to the golden ratio
-- MIT License - Same terms as original

local M = {}

-- Default configuration
local config = {
	golden_ratio_value = 1.618,
	exclude_filetypes = {},
	exclude_buffer_names = {},
	exclude_buffer_regexp = {},
	recenter = false,
	adjust_factor = 1.0,
	wide_adjust_factor = 0.8,
	auto_scale = false,
	max_width = nil,
	minimal_width_change = 1,
	minimal_height_change = 1,
	extra_commands = {
		-- Default navigation commands that trigger resize
		"<C-w>h",
		"<C-w>j",
		"<C-w>k",
		"<C-w>l",
		"<C-w><Left>",
		"<C-w><Down>",
		"<C-w><Up>",
		"<C-w><Right>",
	},
	-- Debounce delay in milliseconds
	debounce_delay = 50,
	-- Enable debug logging
	debug = false,
}

-- State
local enabled = false
local running = false
local augroup_id = nil

-- Logger for debugging
local function log(...)
	if config.debug then
		print("[golden-ratio] ", ...)
	end
end

-- Calculate scale factor based on frame width
local function get_scale_factor()
	if config.auto_scale then
		local frame_width = vim.o.columns
		local scale = 1.0 - ((frame_width - 100.0) / 1000.0 * 1.8)
		return math.max(0.4, math.min(1.2, scale)) -- Clamp between 0.4 and 1.2
	else
		return config.adjust_factor
	end
end

-- Calculate target dimensions using golden ratio
local function get_golden_dimensions()
	local frame_height = vim.o.lines
	local frame_width = vim.o.columns

	local target_height = math.floor(frame_height / config.golden_ratio_value)
	local target_width = math.floor((frame_width / config.golden_ratio_value) * get_scale_factor())

	-- Apply max width constraint
	if config.max_width and config.max_width > 0 and target_width > config.max_width then
		target_width = config.max_width
	end

	return { height = target_height, width = target_width }
end

-- Check if current buffer should be excluded
local function is_excluded_buffer()
	local bufname = vim.api.nvim_buf_get_name(0)
	local filetype = vim.bo.filetype

	-- Check by filetype
	for _, excluded in ipairs(config.exclude_filetypes) do
		if filetype == excluded then
			log("Excluded by filetype: " .. filetype)
			return true
		end
	end

	-- Check by buffer name
	for _, excluded in ipairs(config.exclude_buffer_names) do
		if bufname == excluded then
			log("Excluded by buffer name: " .. bufname)
			return true
		end
	end

	-- Check by regexp
	for _, pattern in ipairs(config.exclude_buffer_regexp) do
		if bufname:match(pattern) then
			log("Excluded by regexp: " .. pattern .. " matched " .. bufname)
			return true
		end
	end

	-- Exclude special buffers
	local buftype = vim.bo.buftype
	if buftype == "nofile" or buftype == "prompt" or buftype == "help" or buftype == "terminal" then
		log("Excluded by buftype: " .. buftype)
		return true
	end

	return false
end

-- Check if we should perform resizing
local function should_resize()
	if running then
		return false
	end

	-- Don't resize if only one window
	local window_count = #vim.api.nvim_tabpage_list_wins(0)
	if window_count == 1 then
		return false
	end

	if is_excluded_buffer() then
		return false
	end

	return true
end

-- Resize the current window to golden ratio
local function resize_window()
	if not enabled or not should_resize() then
		return
	end

	running = true

	local target = get_golden_dimensions()
	local current_height = vim.api.nvim_win_get_height(0)
	local current_width = vim.api.nvim_win_get_width(0)

	local height_diff = target.height - current_height
	local width_diff = target.width - current_width

	log(
		string.format(
			"Current: %dx%d, Target: %dx%d, Diff: %dx%d",
			current_width,
			current_height,
			target.width,
			target.height,
			width_diff,
			height_diff
		)
	)

	-- Resize height if change is significant
	if math.abs(height_diff) >= config.minimal_height_change then
		local new_height = math.max(1, current_height + height_diff)
		vim.api.nvim_win_set_height(0, new_height)
		log("Set height to: " .. new_height)
	end

	-- Resize width if change is significant
	if math.abs(width_diff) >= config.minimal_width_change then
		local new_width = math.max(1, current_width + width_diff)
		vim.api.nvim_win_set_width(0, new_width)
		log("Set width to: " .. new_width)
	end

	-- Recenter if enabled
	if config.recenter then
		vim.cmd("normal! zz")
		-- Scroll horizontally to center
		local win_width = vim.api.nvim_win_get_width(0)
		local cursor_col = vim.fn.col(".")
		local scroll_amount = math.floor((win_width / 2) - cursor_col)
		if scroll_amount ~= 0 then
			vim.cmd("normal! " .. math.abs(scroll_amount) .. (scroll_amount > 0 and "zl" or "zh"))
		end
	end

	running = false
end

-- Balance all windows first, then apply golden ratio to current
local function balance_then_golden()
	if not enabled or running then
		return
	end

	if not should_resize() then
		return
	end

	running = true

	-- Save current window
	local current_win = vim.api.nvim_get_current_win()

	-- Balance windows equally (almost - Vim's `wincmd =` alternative)
	-- We need to calculate equal distribution manually for better control
	local windows = vim.api.nvim_tabpage_list_wins(0)
	local win_count = #windows

	if win_count > 1 then
		local total_width = vim.o.columns
		local total_height = vim.o.lines

		-- For now, use Vim's built-in equalization as it's good enough
		vim.cmd("wincmd =")
	end

	-- Restore focus and apply golden ratio
	vim.api.nvim_set_current_win(current_win)
	resize_window()

	running = false
end

-- Debounced version of balance_then_golden
local debounced_resize
do
	local timer = nil
	debounced_resize = function()
		if timer then
			timer:stop()
			timer:close()
		end
		timer = vim.loop.new_timer()
		timer:start(
			config.debounce_delay,
			0,
			vim.schedule_wrap(function()
				balance_then_golden()
				timer:stop()
				timer:close()
				timer = nil
			end)
		)
	end
end

-- Event handlers
local function on_win_enter()
	debounced_resize()
end

local function on_win_resized()
	debounced_resize()
end

local function on_buf_enter()
	debounced_resize()
end

-- Setup autocommands
local function setup_autocommands()
	if augroup_id then
		return
	end

	augroup_id = vim.api.nvim_create_augroup("GoldenRatio", { clear = true })

	vim.api.nvim_create_autocmd({ "WinEnter", "WinNew" }, {
		group = augroup_id,
		callback = on_win_enter,
		desc = "Golden ratio resize on window enter",
	})

	vim.api.nvim_create_autocmd("WinResized", {
		group = augroup_id,
		callback = on_win_resized,
		desc = "Golden ratio resize on window resize",
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup_id,
		callback = on_buf_enter,
		desc = "Golden ratio resize on buffer enter",
	})

	-- Add autocmds for extra commands
	for _, cmd in ipairs(config.extra_commands) do
		vim.api.nvim_create_autocmd("User", {
			group = augroup_id,
			pattern = cmd,
			callback = on_win_enter,
			desc = "Golden ratio resize after " .. cmd,
		})
	end

	-- Also trigger on VimResized (terminal/frame resize)
	vim.api.nvim_create_autocmd("VimResized", {
		group = augroup_id,
		callback = on_win_resized,
		desc = "Golden ratio resize on Vim resize",
	})

	log("Autocommands setup complete")
end

-- Cleanup autocommands
local function cleanup_autocommands()
	if augroup_id then
		pcall(vim.api.nvim_del_augroup_by_id, augroup_id)
		augroup_id = nil
		log("Autocommands cleaned up")
	end
end

-- Public API functions

-- Enable golden ratio mode
function M.enable()
	if enabled then
		log("Already enabled")
		return
	end

	enabled = true
	setup_autocommands()
	balance_then_golden()
	log("Golden ratio enabled")
end

-- Disable golden ratio mode
function M.disable()
	if not enabled then
		return
	end

	enabled = false
	cleanup_autocommands()
	log("Golden ratio disabled")
end

-- Toggle golden ratio mode
function M.toggle()
	if enabled then
		M.disable()
	else
		M.enable()
	end
end

-- Force resize now
function M.resize_now()
	balance_then_golden()
end

-- Toggle widescreen mode
function M.toggle_widescreen()
	if config.adjust_factor == 1.0 then
		config.adjust_factor = config.wide_adjust_factor
	else
		config.adjust_factor = 1.0
	end
	log("Adjust factor set to: " .. config.adjust_factor)
	balance_then_golden()
end

-- Set adjust factor
function M.set_adjust_factor(factor)
	config.adjust_factor = tonumber(factor) or 1.0
	log("Adjust factor set to: " .. config.adjust_factor)
	balance_then_golden()
end

-- Update configuration
function M.setup(user_config)
	config = vim.tbl_deep_extend("force", config, user_config or {})
	log("Configuration updated")

	-- Re-apply if enabled
	if enabled then
		M.disable()
		M.enable()
	end
end

-- Get current status
function M.is_enabled()
	return enabled
end

-- Get current configuration
function M.get_config()
	return config
end

-- Statusline component
function M.statusline()
	return enabled and "⚫" or ""
end

-- Initialize with default config
function M.init()
	M.enable()
end

return M
