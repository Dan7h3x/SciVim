local M = {}

local config = {
	enabled = true,
	title = "Nvim",
	toggle_key = "<leader>n",
	position = "top_right",
	width = 30,
	max_height = 50,
	border = "rounded",
	timeout = 3000,
	history_size = 50,
	icons = {
		info = "󰋼 ",
		warn = "󰀪 ",
		error = "󰅙 ",
		success = "󰌵 ",
	},
}
local api = vim.api

-- Notification state
local notification_state = {
	notifications = {},
	history = {},
	control_center = {
		win = nil,
		buf = nil,
		is_open = false,
	},
	floating_notifications = {},
	id_counter = 1,
}

-- Notification levels
M.LEVELS = {
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	SUCCESS = 4,
}

-- Position calculators
local position_calculators = {
	top_right = function(width, height, index)
		local x = vim.o.columns - 2
		local y = 1 + (index * (height + 1))
		return { row = y, col = x }
	end,

	top_left = function(width, height, index)
		local x = 2
		local y = 2 + (index * (height + 1))
		return { row = y, col = x }
	end,

	bottom_right = function(width, height, index)
		local x = vim.o.columns - 2
		local y = vim.o.lines - 5 - (index * (height + 1))
		return { row = y, col = x }
	end,

	bottom_left = function(width, height, index)
		local x = 2
		local y = vim.o.lines - 5 - (index * (height + 1))
		return { row = y, col = x }
	end,
}

-- Create notification object
local function create_notification(title, message, level, opts)
	opts = opts or {}

	local notification = {
		id = notification_state.id_counter,
		title = title or "",
		message = message or "",
		level = level or M.LEVELS.INFO,
		timestamp = os.time(),
		timeout = opts.timeout or config.timeout or 5000,
		persistent = opts.persistent or false,
		actions = opts.actions or {},
		icon = opts.icon,
		source = opts.source or "",
	}

	notification_state.id_counter = notification_state.id_counter + 1
	return notification
end

-- Get level info
local function get_level_info(level)
	local level_map = {
		[M.LEVELS.INFO] = {
			name = "INFO",
			icon = config.icons.info or " ",
			hl = "DiagnosticInfo",
		},
		[M.LEVELS.WARN] = {
			name = "WARN",
			icon = config.icons.warn or " ",
			hl = "DiagnosticWarn",
		},
		[M.LEVELS.ERROR] = {
			name = "ERROR",
			icon = config.icons.error or " ",
			hl = "DiagnosticError",
		},
		[M.LEVELS.SUCCESS] = {
			name = "SUCCESS",
			icon = config.icons.success or " ",
			hl = "DiagnosticHint",
		},
	}

	return level_map[level] or level_map[M.LEVELS.INFO]
end

-- Format notification content with better layout
local function format_notification_content(notification, width)
	local level_info = get_level_info(notification.level)

	local lines = {}
	local content_width = width - 1 -- Account for padding

	if notification.message and notification.message ~= "" then
		local message_lines = vim.split(notification.message, "\n")
		for _, line in ipairs(message_lines) do
			if line == "" then
				table.insert(lines, "")
			else
				-- Wrap long lines at word boundaries when possible
				while #line > content_width do
					local wrap_pos = content_width
					-- Try to break at word boundary
					local last_space = line:sub(1, content_width):match(".*()%s")
					if last_space and last_space > content_width * 0.7 then
						wrap_pos = last_space - 1
					end
					table.insert(lines, line:sub(1, wrap_pos))
					line = line:sub(wrap_pos + 1):gsub("^%s+", "") -- Remove leading spaces
				end
				if #line > 0 then
					table.insert(lines, line)
				end
			end
		end
	end

	-- Actions with better formatting
	if #notification.actions > 0 then
		table.insert(lines, "")
		table.insert(lines, "Actions:")
		for i, action in ipairs(notification.actions) do
			local action_line = string.format(" %d. %s", i, action.label)
			if #action_line > content_width then
				action_line = action_line:sub(1, content_width - 3) .. "..."
			end
			table.insert(lines, action_line)
		end
	end

	return lines, level_info
end

-- Create floating notification window
local function create_floating_notification(notification)
	-- Calculate width as 20% of editor width by default
	local default_width = math.floor(vim.o.columns * 0.2)
	local width = config.width or default_width
	width = math.max(width, 30) -- Minimum width
	width = math.min(width, vim.o.columns - 10) -- Maximum width

	local content, level_info = format_notification_content(notification, width)
	-- Calculate height with max limit and wrapping support
	local max_height = config.max_height or math.floor(vim.o.lines * 0.3)
	local height = math.min(#content, max_height)

	-- Get position
	local position_func = position_calculators[config.position] or position_calculators.top_right
	local active_count = #notification_state.floating_notifications
	local pos = position_func(width, height, active_count)

	-- Create buffer
	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "notifs")
	api.nvim_buf_set_lines(buf, 0, -1, false, content)
	api.nvim_buf_set_option(buf, "modifiable", false)

	-- Enhanced window options with better styling
	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		row = pos.row,
		col = pos.col,
		border = config.border or "rounded",
		style = "minimal",
		focusable = false,
		zindex = 50,
		title = " " .. string.format("%s", level_info.icon) .. notification.title .. " " or config.title,
		title_pos = "center",
	}

	-- Create window
	local win = api.nvim_open_win(buf, false, win_opts)
	api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:" .. string.format("%s", level_info.hl))

	local ns_id = api.nvim_create_namespace("notifs_" .. notification.id)

	for i = 1, #content do
		api.nvim_buf_add_highlight(buf, ns_id, string.format("%s", level_info.hl) or "CursorLineNr", i - 1, 0, -1)
	end
	return win, buf
end

-- Show floating notification
local function show_floating_notification(notification)
	local win, buf = create_floating_notification(notification)

	local floating_notif = {
		id = notification.id,
		win = win,
		buf = buf,
		notification = notification,
	}

	table.insert(notification_state.floating_notifications, floating_notif)

	-- Auto-hide after timeout (unless persistent)
	if not notification.persistent and notification.timeout > 0 then
		vim.defer_fn(function()
			M.hide_notification(notification.id)
		end, notification.timeout)
	end

	return floating_notif
end

-- Reposition floating notifications
local function reposition_floating_notifications()
	local position_func = position_calculators[config.position] or position_calculators.top_right

	for i, floating_notif in ipairs(notification_state.floating_notifications) do
		if floating_notif.win and api.nvim_win_is_valid(floating_notif.win) then
			local width = api.nvim_win_get_config(floating_notif.win).width
			local height = api.nvim_win_get_config(floating_notif.win).height
			local pos = position_func(width, height, i - 1)

			api.nvim_win_set_config(floating_notif.win, {
				relative = "editor",
				row = pos.row,
				col = pos.col,
			})
		end
	end
end

-- Hide notification
function M.hide_notification(notification_id)
	for i, floating_notif in ipairs(notification_state.floating_notifications) do
		if floating_notif.id == notification_id then
			if floating_notif.win and api.nvim_win_is_valid(floating_notif.win) then
				api.nvim_win_close(floating_notif.win, true)
			end
			table.remove(notification_state.floating_notifications, i)
			break
		end
	end

	-- Reposition remaining notifications
	reposition_floating_notifications()
end

-- Add notification to history
local function add_to_history(notification)
	table.insert(notification_state.history, 1, notification)

	if #notification_state.history > config.history_size then
		table.remove(notification_state.history)
	end
end

-- Show notification with auto-refresh trigger
function M.notify(title, message, level, opts)
	level = level or M.LEVELS.INFO
	opts = opts or {}

	local notification = create_notification(title, message, level, opts)

	-- Add to current notifications
	table.insert(notification_state.notifications, notification)

	-- Add to history
	add_to_history(notification)

	-- Show floating notification
	show_floating_notification(notification)

	-- Trigger update event for control center auto-refresh
	api.nvim_exec_autocmds("User", { pattern = "FlNotifUpdate" })

	return notification.id
end

-- Convenience functions
function M.info(title, message, opts)
	return M.notify(title, message, M.LEVELS.INFO, opts)
end

function M.warn(title, message, opts)
	return M.notify(title, message, M.LEVELS.WARN, opts)
end

function M.error(title, message, opts)
	return M.notify(title, message, M.LEVELS.ERROR, opts)
end

function M.success(title, message, opts)
	return M.notify(title, message, M.LEVELS.SUCCESS, opts)
end

-- Clear all notifications
function M.clear_all()
	for _, floating_notif in ipairs(notification_state.floating_notifications) do
		if floating_notif.win and api.nvim_win_is_valid(floating_notif.win) then
			api.nvim_win_close(floating_notif.win, true)
		end
	end

	notification_state.floating_notifications = {}
	notification_state.notifications = {}
end

-- Clear history
function M.clear_history()
	notification_state.history = {}
end

-- Get notification statistics
function M.get_stats()
	local stats = {
		active = #notification_state.notifications,
		history_total = #notification_state.history,
		by_level = {
			info = 0,
			warn = 0,
			error = 0,
			success = 0,
		},
	}

	for _, notif in ipairs(notification_state.history) do
		if notif.level == M.LEVELS.INFO then
			stats.by_level.info = stats.by_level.info + 1
		elseif notif.level == M.LEVELS.WARN then
			stats.by_level.warn = stats.by_level.warn + 1
		elseif notif.level == M.LEVELS.ERROR then
			stats.by_level.error = stats.by_level.error + 1
		elseif notif.level == M.LEVELS.SUCCESS then
			stats.by_level.success = stats.by_level.success + 1
		end
	end

	return stats
end

-- Filter state for control center
local control_center_state = {
	filter_level = nil, -- nil = all, or specific level
	search_term = "",
	show_history = false,
	show_active = true,
}

-- Create notification control center
local function create_control_center()
	-- Calculate dimensions (larger and more elegant)
	local width = math.min(math.floor(vim.o.columns * 0.75), 120)
	local height = math.min(math.floor(vim.o.lines * 0.85), 40)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create buffer
	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "notifs")
	api.nvim_buf_set_option(buf, "modifiable", false)
	api.nvim_buf_set_option(buf, "wrap", false)
	api.nvim_buf_set_option(buf, "cursorline", true)

	-- Enhanced window options with better styling
	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = config.border or "rounded",
		style = "minimal",
		title = " 🔔 Notification Center ",
		title_pos = "center",
	}

	-- Create window
	local win = api.nvim_open_win(buf, true, win_opts)
	api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

	return win, buf
end

-- Filter notifications based on current filter state
local function filter_notifications(notifications)
	local filtered = {}
	for _, notif in ipairs(notifications) do
		local matches = true

		-- Level filter
		if control_center_state.filter_level and notif.level ~= control_center_state.filter_level then
			matches = false
		end

		-- Search filter
		if control_center_state.search_term ~= "" then
			local search_lower = control_center_state.search_term:lower()
			local title_match = notif.title and notif.title:lower():find(search_lower, 1, true)
			local message_match = notif.message and notif.message:lower():find(search_lower, 1, true)
			local source_match = notif.source and notif.source:lower():find(search_lower, 1, true)

			if not (title_match or message_match or source_match) then
				matches = false
			end
		end

		if matches then
			table.insert(filtered, notif)
		end
	end
	return filtered
end

-- Generate enhanced control center content
local function generate_control_center_content()
	local content = {}
	local hls = {}
	local stats = M.get_stats()
	local content_width = notification_state.control_center.win
			and api.nvim_win_get_config(notification_state.control_center.win).width - 4
		or 76

	table.insert(content, "")

	-- Stats bar with better formatting
	local stats_line = string.format(
		"🟢 Active: %d  📊 Total: %d  🔵 Info: %d  🟡 Warn: %d  🔴 Error: %d  🟢 Success: %d",
		stats.active,
		stats.history_total,
		stats.by_level.info,
		stats.by_level.warn,
		stats.by_level.error,
		stats.by_level.success
	)
	table.insert(content, stats_line)

	-- Filter status
	local filter_status = ""
	if control_center_state.filter_level then
		local level_info = get_level_info(control_center_state.filter_level)
		filter_status = filter_status .. string.format("Filter: %s %s  ", level_info.icon, level_info.name)
	end
	if control_center_state.search_term ~= "" then
		filter_status = filter_status .. string.format("Search: '%s'  ", control_center_state.search_term)
	end
	if filter_status ~= "" then
		table.insert(content, "🔍 " .. filter_status)
	end

	table.insert(content, string.rep("═", content_width))
	table.insert(content, "")

	-- Active notifications section
	if control_center_state.show_active then
		local active_filtered = filter_notifications(notification_state.notifications)
		if #active_filtered > 0 then
			table.insert(content, "🔔 Active Notifications (" .. #active_filtered .. ")")
			table.insert(content, string.rep("─", content_width))

			for _, notif in ipairs(active_filtered) do
				local level_info = get_level_info(notif.level)
				local time_str = os.date("%H:%M:%S", notif.timestamp)
				local header = string.format("%s %s", level_info.icon, notif.title or "Untitled")
				if notif.source then
					header = header .. string.format(" (%s)", notif.source)
				end
				header = header .. string.format(" • %s", time_str)

				table.insert(content, header)
				table.insert(hls, {
					line = #content - 1,
					hl_group = level_info.hl,
					start_col = 0,
					end_col = #level_info.icon,
				})
				table.insert(hls, {
					line = #content - 1,
					hl_group = "Special",
					start_col = #header - #time_str,
					end_col = #header,
				})
				if notif.message and notif.message ~= "" then
					local preview = {}
					for line in notif.message:gmatch("[^\r\n]+") do
						table.insert(preview, line)
					end
					if #preview > 0 then
						table.insert(content, "  └─> " .. preview[1])
						table.insert(hls, {
							line = #content - 1,
							hl_group = level_info.hl,
							start_col = 9,
							end_col = -1,
						})
						for i = 2, #preview do
							table.insert(content, "        " .. preview[i])
							table.insert(hls, {
								line = #content - 1,
								hl_group = level_info.hl,
								start_col = 9,
								end_col = -1,
							})
						end
					end
				end
				table.insert(content, "")
			end
		else
			table.insert(content, "🔔 Active Notifications (0)")
			table.insert(content, string.rep("─", content_width))
			table.insert(content, "  🎉 No active notifications - all clear!")
			table.insert(content, "")
		end
	end

	-- History section
	if control_center_state.show_history then
		local history_filtered = filter_notifications(notification_state.history)
		if #history_filtered > 0 then
			table.insert(
				content,
				"📚 Notification History (showing "
					.. math.min(#history_filtered, 15)
					.. "/"
					.. #history_filtered
					.. ")"
			)
			table.insert(content, string.rep("─", content_width))

			for i = 1, math.min(#history_filtered, 15) do
				local notif = history_filtered[i]
				local level_info = get_level_info(notif.level)
				local time_str = os.date("%m/%d %H:%M", notif.timestamp)
				local header = string.format("%s %s", level_info.icon, notif.title or "Untitled")
				if notif.source then
					header = header .. string.format(" (%s)", notif.source)
				end
				header = header .. string.format(" • %s", time_str)

				table.insert(content, header)
				if notif.message and notif.message ~= "" then
					local preview = notif.message:gsub("\n", " ")
					if #preview > content_width - 4 then
						preview = preview:sub(1, content_width - 7) .. "..."
					end
					table.insert(content, "  └─ " .. preview)
				end
				table.insert(content, "")
			end
		else
			table.insert(content, "📚 Notification History (0)")
			table.insert(content, string.rep("─", content_width))
			table.insert(content, "  📦 No notifications in history")
			table.insert(content, "")
		end
	end

	-- Enhanced footer with keyboard shortcuts
	table.insert(content, string.rep("═", content_width))
	table.insert(content, "💡 Quick Actions:")
	table.insert(content, "  [q/ESC] Close  [c] Clear Active  [h] Clear History  [r] Refresh")
	table.insert(content, "  [f] Filter by Level  [/] Search  [a] Toggle Active  [t] Toggle History")

	return content, hls
end

-- Setup enhanced control center keybindings
local function setup_control_center_keybindings(buf)
	-- Close
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"q",
		'<cmd>lua require("SciVim.extras.notifs").close_control_center()<CR>',
		{ noremap = true, silent = true, desc = "Close notification center" }
	)
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"<Esc>",
		'<cmd>lua require("SciVim.extras.notifs").close_control_center()<CR>',
		{ noremap = true, silent = true }
	)

	-- Clear operations
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"c",
		'<cmd>lua require("SciVim.extras.notifs").clear_all()<CR><cmd>lua require("SciVim.extras.notifs").refresh_control_center()<CR>',
		{ noremap = true, silent = true, desc = "Clear active notifications" }
	)
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"h",
		'<cmd>lua require("SciVim.extras.notifs").clear_history()<CR><cmd>lua require("SciVim.extras.notifs").refresh_control_center()<CR>',
		{ noremap = true, silent = true, desc = "Clear notification history" }
	)

	-- Refresh
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"r",
		'<cmd>lua require("SciVim.extras.notifs").refresh_control_center()<CR>',
		{ noremap = true, silent = true, desc = "Refresh view" }
	)

	-- Filter by level
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"f",
		'<cmd>lua require("SciVim.extras.notifs").cycle_filter_level()<CR>',
		{ noremap = true, silent = true, desc = "Filter by notification level" }
	)

	-- Search
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"/",
		'<cmd>lua require("SciVim.extras.notifs").prompt_search()<CR>',
		{ noremap = true, silent = true, desc = "Search notifications" }
	)

	-- Toggle sections
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"a",
		'<cmd>lua require("SciVim.extras.notifs").toggle_active_section()<CR>',
		{ noremap = true, silent = true, desc = "Toggle active notifications section" }
	)
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"t",
		'<cmd>lua require("SciVim.extras.notifs").toggle_history_section()<CR>',
		{ noremap = true, silent = true, desc = "Toggle history section" }
	)

	-- Clear search/filter
	api.nvim_buf_set_keymap(
		buf,
		"n",
		"x",
		'<cmd>lua require("SciVim.extras.notifs").clear_filters()<CR>',
		{ noremap = true, silent = true, desc = "Clear all filters" }
	)
end

-- Open control center
function M.open_control_center()
	if notification_state.control_center.is_open then
		return
	end

	local win, buf = create_control_center()
	local content, hls = generate_control_center_content()

	api.nvim_buf_set_option(buf, "modifiable", true)
	api.nvim_buf_set_lines(buf, 0, -1, false, content)
	api.nvim_buf_set_option(buf, "modifiable", false)

	setup_control_center_keybindings(buf)

	notification_state.control_center.win = win
	notification_state.control_center.buf = buf
	notification_state.control_center.is_open = true
end

-- Close control center
function M.close_control_center()
	if notification_state.control_center.win and api.nvim_win_is_valid(notification_state.control_center.win) then
		api.nvim_win_close(notification_state.control_center.win, true)
	end

	notification_state.control_center.win = nil
	notification_state.control_center.buf = nil
	notification_state.control_center.is_open = false
end

-- Toggle control center
function M.toggle()
	if notification_state.control_center.is_open then
		M.close_control_center()
	else
		M.open_control_center()
		M.refresh_control_center()
	end
end

-- Refresh control center with enhanced highlighting
function M.refresh_control_center()
	if notification_state.control_center.is_open and notification_state.control_center.buf then
		local content, hls = generate_control_center_content()
		local buf = notification_state.control_center.buf

		api.nvim_buf_set_option(buf, "modifiable", true)
		api.nvim_buf_set_lines(buf, 0, -1, false, content)
		api.nvim_buf_set_option(buf, "modifiable", false)

		-- Apply syntax highlighting
		local ns_id = api.nvim_create_namespace("notifs_center")
		api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

		for i, line in ipairs(content) do
			local line_idx = i - 1
			-- Header highlighting
			if line:match("^🔔.*Control Center") then
				api.nvim_buf_add_highlight(buf, ns_id, "Title", line_idx, 0, -1)
			-- Stats line
			elseif line:match("^🟢.*Active:") then
				api.nvim_buf_add_highlight(buf, ns_id, "Normal", line_idx, 0, -1)
			-- Filter status
			elseif line:match("^🔍") then
				api.nvim_buf_add_highlight(buf, ns_id, "Search", line_idx, 0, -1)
			-- Section headers
			elseif line:match("^🔔.*Active") or line:match("^📚.*History") then
				api.nvim_buf_add_highlight(buf, ns_id, "Visual", line_idx, 0, -1)
			-- Help/commands
			elseif line:match("^💡") or line:match("^%s*%[") then
				api.nvim_buf_add_highlight(buf, ns_id, "Comment", line_idx, 0, -1)
			-- Empty state messages
			elseif line:match("🎉") or line:match("📦") then
				api.nvim_buf_add_highlight(buf, ns_id, "Normal", line_idx, 0, -1)
			-- Notification entries with level-specific colors
			elseif line:match("🔵" or config.icons.info) then -- Info
				api.nvim_buf_add_highlight(buf, ns_id, "DiagnosticInfo", line_idx, 0, -1)
			elseif line:match("🟡" or config.icons.warn) then -- Warning
				api.nvim_buf_add_highlight(buf, ns_id, "DiagnosticWarn", line_idx, 0, -1)
			elseif line:match("🔴" or config.icons.error) then -- Error
				api.nvim_buf_add_highlight(buf, ns_id, "DiagnosticError", line_idx, 0, -1)
			elseif line:match("🟢" or config.icons.success) then -- Success
				api.nvim_buf_add_highlight(buf, ns_id, "DiagnosticHint", line_idx, 0, -1)
			end
		end
		for _, hl in ipairs(hls) do
			vim.api.nvim_buf_add_highlight(
				buf,
				-1,
				hl.hl_group,
				hl.line,
				hl.start_col,
				hl.end_col == -1 and -1 or hl.end_col
			)
		end
	end
end

-- Filter level cycling
function M.cycle_filter_level()
	local levels = { nil, M.LEVELS.INFO, M.LEVELS.WARN, M.LEVELS.ERROR, M.LEVELS.SUCCESS }
	local current_idx = 1

	for i, level in ipairs(levels) do
		if control_center_state.filter_level == level then
			current_idx = i
			break
		end
	end

	current_idx = current_idx % #levels + 1
	control_center_state.filter_level = levels[current_idx]

	M.refresh_control_center()
end

-- Search prompt
function M.prompt_search()
	local search_term = vim.fn.input("Search notifications: ", control_center_state.search_term)
	if search_term then
		control_center_state.search_term = search_term
		M.refresh_control_center()
	end
end

-- Toggle sections
function M.toggle_active_section()
	control_center_state.show_active = not control_center_state.show_active
	M.refresh_control_center()
end

function M.toggle_history_section()
	control_center_state.show_history = not control_center_state.show_history
	M.refresh_control_center()
end

-- Clear all filters
function M.clear_filters()
	control_center_state.filter_level = nil
	control_center_state.search_term = ""
	M.refresh_control_center()
end

-- Export notifications (practical feature)
function M.export_notifications(format)
	format = format or "json"
	local export_data = {
		timestamp = os.time(),
		active = notification_state.notifications,
		history = notification_state.history,
		stats = M.get_stats(),
	}

	local filename = string.format("notifications_export_%s.%s", os.date("%Y%m%d_%H%M%S"), format)
	local content = ""

	if format == "json" then
		content = vim.json.encode(export_data)
	elseif format == "csv" then
		content = "timestamp,level,title,message,source\n"
		for _, notif in ipairs(export_data.history) do
			local level_info = get_level_info(notif.level)
			content = content
				.. string.format(
					'"%s","%s","%s","%s","%s"\n',
					os.date("%Y-%m-%d %H:%M:%S", notif.timestamp),
					level_info.name,
					(notif.title or ""):gsub('"', '""'),
					(notif.message or ""):gsub('"', '""'):gsub("\n", " "),
					(notif.source or ""):gsub('"', '""')
				)
		end
	end

	local file = io.open(filename, "w")
	if file then
		file:write(content)
		file:close()
		M.info("Export Complete", "Notifications exported to " .. filename, { timeout = 3000 })
	else
		M.error("Export Failed", "Could not write to " .. filename, { timeout = 3000 })
	end
end

-- Setup function with enhanced features
function M.setup()
	if not config.enabled then
		return
	end

	if config.enabled ~= false then
		---@diagnostic disable-next-line: duplicate-set-field
		vim.notify = function(msg, level, optsv)
			optsv = optsv or {}

			-- Convert vim log levels to our levels
			local our_level = M.LEVELS.INFO
			if level == vim.log.levels.WARN then
				our_level = M.LEVELS.WARN
			elseif level == vim.log.levels.ERROR then
				our_level = M.LEVELS.ERROR
			end

			return M.notify(optsv.title or config.title, msg, our_level, optsv)
		end
	end

	-- Enhanced autocmds
	api.nvim_create_autocmd("VimResized", {
		callback = function()
			reposition_floating_notifications()
			-- Refresh control center if open to adapt to new size
			if notification_state.control_center.is_open then
				M.refresh_control_center()
			end
		end,
	})

	-- Auto-refresh control center when notifications change
	api.nvim_create_autocmd({ "User" }, {
		pattern = "FlNotifUpdate",
		callback = function()
			if notification_state.control_center.is_open then
				M.refresh_control_center()
			end
		end,
	})

	-- Create user commands for easy access
	api.nvim_create_user_command("FlNotif", M.toggle, {
		desc = "Toggle notification control center",
	})

	api.nvim_create_user_command("FlNotifClear", M.clear_all, {
		desc = "Clear all active notifications",
	})

	api.nvim_create_user_command("FlNotifHistory", function()
		M.open_control_center()
		control_center_state.show_active = false
		control_center_state.show_history = true
		M.refresh_control_center()
	end, {
		desc = "Open notification center showing only history",
	})

	api.nvim_create_user_command("FlNotifExport", function(opts)
		local format = opts.args ~= "" and opts.args or "json"
		M.export_notifications(format)
	end, {
		desc = "Export notifications to file",
		nargs = "?",
		complete = function()
			return { "json", "csv" }
		end,
	})
end

return M
