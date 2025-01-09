-- ui.lua
local Utils = require("lazydo.utils")
local Task = require("lazydo.task")
local Actions = require("lazydo.actions")

---@class UI
local UI = {}

-- Add config as a module-level variable
local config = nil

local ns_id = vim.api.nvim_create_namespace("LazyDo")
local buf_name = "LazyDo"

---@class UIState
---@field buf number Buffer handle
---@field win number Window handle
---@field tasks Task[] Current tasks
---@field cursor_task? Task Task under cursor
---@field line_to_task table<number, {task: Task, mapping: table}>
---@field task_to_line table<string, number>
---@field on_task_update function?
local state = {
	buf = nil,
	win = nil,
	tasks = {},
	cursor_task = nil,
	line_to_task = {}, -- Map line numbers to tasks
	task_to_line = {}, -- Map task IDs to line numbers
	on_task_update = nil,
	search_results = {},
	current_search = nil,
	config = nil,
	show_task_info = true,
	view_mode = "list",
	last_view_mode = nil,
	kanban_cursor = { column = 1, row = 1 }, -- Track cursor position in kanban view
}
-- │└─├─ ─╭─╰─
local ICONS = {
	SUBTASK_INDENT = "│  ",
	SUBTASK_LAST = "└──",
	SUBTASK_MIDDLE = "├──",
	SEPARATOR = "━", -- Using a different character for main separators
	NOTE_START = "╭",
	NOTE_END = "╰",
	PROGRESS_START = "╭",
	PROGRESS_END = "╯",
	PROGRESS_FILL = "█",
	PROGRESS_EMPTY = "░",
}

local function ensure_number(value, default)
	if type(value) == "number" then
		return value
	end
	return default or 0
end

local function get_safe_window_width()
	if not state.win then
		return 80 -- Default width
	end
	local ok, width = pcall(vim.api.nvim_win_get_width, state.win)
	return ok and width or 80
end

local function create_task_separator(level, has_subtasks, is_collapsed, width)
	level = level or 0
	width = width or get_safe_window_width()

	local indent = string.rep("  ", level)
	local separator_char = level == 0 and "░"
	local separator_width = math.max(0, width - #indent - 2) -- Ensure non-negative
	local separator = indent
	if has_subtasks then
		separator = separator
			.. (
				is_collapsed and state.config.features.folding.icons.folded
				or state.config.features.folding.icons.unfolded
			)
	else
		separator = separator .. "  "
	end

	separator = separator .. string.rep(separator_char, separator_width)

	if level == 0 then
		-- Add fancy ends for top-level tasks
		separator = indent .. "" .. string.rep(separator_char, separator_width) .. ""
	end

	return separator
end

local function highlight_search_results()
	if not state.search_results or #state.search_results == 0 then
		return
	end

	for _, result in ipairs(state.search_results) do
		local line = state.task_to_line[result.id]
		if line then
			-- Highlight the matched text
			vim.api.nvim_buf_add_highlight(
				state.buf,
				ns_id,
				"LazyDoSearchMatch",
				line - 1,
				result.match_start,
				result.match_end
			)

			-- Add a sign to make it easier to spot
			vim.fn.sign_place(0, "LazyDoSearch", "LazyDoSearchSign", state.buf, { lnum = line, priority = 10 })
		end
	end
end

local function is_valid_window()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function is_valid_buffer()
	return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end
function UI.is_valid()
	return is_valid_window() and is_valid_buffer()
end
---Validate task data structure
---@param task table
---@return boolean
---@return string? error
local function validate_task(task)
	if type(task) ~= "table" then
		return false, "Task must be a table"
	end

	-- Check required fields
	local required_fields = {
		"id",
		"content",
		"status",
		"priority",
		"created_at",
		"updated_at",
	}

	for _, field in ipairs(required_fields) do
		if task[field] == nil then
			return false, string.format("Missing required field: %s", field)
		end
	end

	-- Validate status
	if not vim.tbl_contains({ "pending", "done" }, task.status) then
		return false, "Invalid status value"
	end

	-- Validate priority
	if not vim.tbl_contains({ "low", "medium", "high" }, task.priority) then
		return false, "Invalid priority value"
	end

	-- Validate dates
	if task.due_date and type(task.due_date) ~= "number" then
		return false, "Invalid due_date format"
	end

	-- Validate subtasks recursively
	if task.subtasks then
		if type(task.subtasks) ~= "table" then
			return false, "Subtasks must be a table"
		end
		for _, subtask in ipairs(task.subtasks) do
			local valid, err = validate_task(subtask)
			if not valid then
				return false, "Invalid subtask: " .. err
			end
		end
	end

	-- Validate tags
	if task.tags and type(task.tags) ~= "table" then
		return false, "Tags must be an array"
	end

	-- Validate metadata
	if task.metadata and type(task.metadata) ~= "table" then
		return false, "Metadata must be a table"
	end

	return true
end

local function clear_state()
	state.buf = nil
	state.win = nil
	state.tasks = {}
	state.cursor_task = nil
	state.line_to_task = {}
	state.task_to_line = {}
end

local function validate_config()
	if not state.config then
		return false, "Configuration is missing"
	end

	local required_sections = {
		"theme",
		"icons",
		"features",
		"layout",
	}

	for _, section in ipairs(required_sections) do
		if not state.config[section] then
			return false, string.format("Missing required configuration section: %s", section)
		end
	end

	-- Validate theme colors
	if not state.config.theme.colors then
		return false, "Missing theme colors configuration"
	end

	-- Validate icons
	if not state.config.icons.task_pending or not state.config.icons.task_done then
		return false, "Missing required task status icons"
	end

	return true
end

-- Improve window creation with proper validation
local function create_window()
	-- Validate configuration first
	local valid, err = validate_config()
	if not valid then
		error("Invalid configuration: " .. err)
		return nil
	end

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, buf_name)

	local buf_opts = {
		modifiable = false,
		buftype = "nofile",
		swapfile = false,
		bufhidden = "wipe",
		filetype = "lazydo",
	}

	for opt, val in pairs(buf_opts) do
		vim.api.nvim_buf_set_option(buf, opt, val)
	end

	local size = Utils.get_window_size()

	-- Enhanced window options
	local win_opts = {
		relative = "editor",
		width = size.width,
		height = size.height,
		row = size.row,
		col = size.col,
		style = "minimal",
		border = state.config.theme.border or "rounded",
		title = " LazyDo ",
		title_pos = "center",
		footer = " [a/A]dd task/subtask, [d]elete, [D]ate, [n]ote, [e]dit task, [z] fold, [p]riority, [?]help ",
		footer_pos = "center",
		zindex = 50, -- Ensure window stays on top
	}
	local win = vim.api.nvim_open_win(buf, true, win_opts)

	-- Set window options
	local win_local_opts = {
		wrap = false,
		number = false,
		relativenumber = false,
		cursorline = false,
		signcolumn = "no",
		foldcolumn = "0",
		spell = false,
		list = false,
	}

	for opt, val in pairs(win_local_opts) do
		vim.api.nvim_win_set_option(win, opt, val)
	end

	return buf, win
end

function UI.restore_window_state(state)
	if not state then
		return
	end

	-- Restore cursor position
	if state.cursor then
		pcall(vim.api.nvim_win_set_cursor, state.win, state.cursor)
	end

	-- Restore scroll position
	if state.scroll then
		vim.fn.winrestview(state.scroll)
	end
end

local function render_progress_bar(progress, width)
	local style = state.config.theme.progress_bar.style
	local bar_width = state.config.theme.progress_bar.width or width
	local filled = math.floor(bar_width * progress / 100)
	local empty = bar_width - filled
	progress = progress or 0
	width = width or 10 -- Default reasonable width

	-- 󰪞󰪟󰪠󰪡󰪢󰪣󰪤󰪥
	-- Enhanced progress icons based on percentage
	local progress_icon = progress == 100 and state.config.icons.task_done
		or progress >= 75 and "󰪣"
		or progress >= 50 and "󰪡"
		or progress >= 25 and "󰪟"
		or progress > 0 and "󰪞"
		or "󰪥"

	if style == "modern" then
		return string.format(
			"%s[%s%s] %d%%",
			progress_icon,
			string.rep(state.config.theme.progress_bar.filled, filled),
			string.rep(state.config.theme.progress_bar.empty, empty),
			progress
		)
	elseif style == "minimal" then
		return string.format("%s %d%%", progress_icon, progress)
	else -- classic
		return string.format(
			"%s%s %d%%",
			string.rep(state.config.theme.progress_bar.filled, filled),
			string.rep(state.config.theme.progress_bar.empty, empty),
			progress
		)
	end
end

local function render_note_section(note, indent_level, is_subtask)
	if not note or note == "" then
		return {}, {}
	end

	local indent = string.rep("  ", indent_level)
	local width = get_safe_window_width() - #indent - 4
	local lines = {}
	local regions = {}
	local current_line = 0

	local note_icon = state.config.icons.note or "󰍨"

	-- Different connectors and styling for parent vs child tasks
	local connectors = {
		parent = {
			top_left = "╭",
			top_right = "╮",
			vertical = "│",
			bottom_left = "╰",
			bottom_right = "╯",
			horizontal = "─",
		},
		child = {
			top_left = "├",
			top_right = "╮",
			vertical = "│",
			bottom_left = "└",
			bottom_right = "╯",
			horizontal = "─",
		},
	}

	local style = is_subtask and connectors.child or connectors.parent

	-- Render header with icon and title
	local header =
		string.format("%s%s%s%s %s Note: ", indent, style.top_left, style.horizontal, style.horizontal, note_icon)
	local header_padding = string.rep(style.horizontal, width - vim.fn.strwidth(header) + #indent)
	header = header .. header_padding .. style.top_right

	table.insert(lines, header)

	-- Add header highlights
	table.insert(regions, {
		line = current_line,
		col = #indent,
		length = #indent + 7, -- connector length
		hl_group = "LazyDoNotesBorder",
	})
	table.insert(regions, {
		line = current_line,
		col = #indent + 8,
		length = 6,
		hl_group = "LazyDoNotesIcon",
	})
	-- table.insert(regions, {
	-- 	line = current_line,
	-- 	col = #indent + #note_icon + 4,
	-- 	length = 6, -- "Note" text
	-- 	hl_group = "LazyDoNotesIcon",
	-- })
	table.insert(regions, {
		line = current_line,
		col = #indent + 19,
		length = #header_padding + 9,
		hl_group = "LazyDoNotesBorder",
	})

	current_line = current_line + 1

	-- Render note content with proper padding and borders
	local content_line = string.format("%s%s %s ", indent, style.vertical, note)

	-- Add padding to align with width
	-- local content_padding = width - vim.fn.strwidth(note) - 2
	-- if content_padding > 0 then
	-- 	content_line = content_line:sub(1, -2) .. string.rep(" ", content_padding) .. style.vertical
	-- end

	table.insert(lines, content_line)

	-- Add content highlights
	table.insert(regions, {
		line = current_line,
		col = #indent,
		length = 1,
		hl_group = "LazyDoNotesBorder",
	})
	table.insert(regions, {
		line = current_line,
		col = #indent + 2,
		length = #note + #indent,
		hl_group = "LazyDoNotesBody",
	})
	table.insert(regions, {
		line = current_line,
		col = #content_line - 1,
		length = 1,
		hl_group = "LazyDoNotesBorder",
	})

	current_line = current_line + 1

	-- Render footer
	local footer = string.format(
		"%s%s%s%s",
		indent,
		style.bottom_left,
		string.rep(style.horizontal, width - 1),
		style.bottom_right
	)

	table.insert(lines, footer)

	-- Add footer highlights
	table.insert(regions, {
		line = current_line,
		col = #indent,
		length = #footer - #indent,
		hl_group = "LazyDoNotesBorder",
	})

	return lines, regions
end
local function render_task_info(task, indent_level)
	if not state.show_task_info then
		return "", {}
	end
	local indent = string.rep("  ", indent_level + 1)
	local lines = {}
	local regions = {}

	-- Format timestamps with icons
	local created_icon = state.config.icons.created or "󰃰"
	local updated_icon = state.config.icons.updated or "󰦒"
	local recurring_icon = "󰑖"

	local created_at = os.date("%Y-%m-%d/%H:%M", task.created_at)
	local updated_at = task.updated_at > task.created_at and os.date("%Y-%m-%d/%H:%M", task.updated_at) or nil

	-- Add creation time with proper highlighting
	local created_line = string.format("%s%s Created: %s", indent, created_icon, created_at)
	table.insert(lines, created_line)
	table.insert(regions, {
		line = #lines - 1,
		col = #indent,
		length = #created_line - #indent,
		hl_group = "LazyDoTaskInfo",
	})

	-- Add update time if different
	if updated_at then
		local updated_line = string.format("%s Updated: %s", updated_icon, updated_at)
		table.insert(lines, updated_line)
		table.insert(regions, {
			line = #lines - 1,
			col = #indent,
			length = #updated_line - #indent,
			hl_group = "LazyDoTaskInfo",
		})
	end

	-- Add recurring info if present
	if task.recurring then
		local recurring_line = string.format("%s %s", recurring_icon, task.recurring)
		table.insert(lines, recurring_line)
		table.insert(regions, {
			line = #lines - 1,
			col = #indent,
			length = #recurring_line - #indent,
			hl_group = "LazyDoTaskInfo",
		})
	end
	local single_lines = table.concat(lines, "|")
	return single_lines, regions
end

local function render_tags(task)
	if not state.config.features.tags.enabled or not task.tags or #task.tags == 0 then
		return "", {}
	end

	local tags = {}
	local regions = {}
	local start_col = 0

	for _, tag in ipairs(task.tags) do
		local formatted_tag = state.config.features.tags.prefix .. tag
		table.insert(tags, formatted_tag)

		-- Add highlight for each tag
		table.insert(regions, {
			col = start_col + 1,
			length = #formatted_tag,
			hl_group = "LazyDoTags",
		})
		start_col = start_col + #formatted_tag + 1
	end

	return " " .. table.concat(tags, " "), regions
end

local function render_task_header(task, level, is_last)
	if not task then
		return "", {}
	end

	-- local base_indent = string.rep(" ", ensure_number(level, 0) * ensure_number(state.confitheme.indent.size, 2))
	local base_indent = string.rep(" ", ensure_number(level, 0) * 2)
	local regions = {}
	local current_col = #base_indent

	-- Helper function to add region
	local function add_region(length, hl_group, offset)
		table.insert(regions, {
			col = current_col + (offset or 0),
			length = ensure_number(length, 0) + 1,
			hl_group = hl_group or "Normal",
		})
		current_col = current_col + ensure_number(length, 0) + (offset or 0)
	end

	-- Build header components
	local components = {
		indent = base_indent,
		connector = "",
		status = "",
		priority = "",
		fold = "",
		content = task.content or "",
		tags = "",
		due = "",
		overdue = "",
		recurring = "",
		progress = "",
		info = "",
	}

	-- Add connector for subtasks
	if level > 0 then
		components.connector = is_last and state.config.theme.indent.last_connector
			or state.config.theme.indent.connector
		add_region(#components.connector, "LazyDoConnector")
	end

	-- Add status icon
	local status_icon = task.status == "done" and state.config.icons.task_done or state.config.icons.task_pending
	local status_hl = task.status == "done" and "LazyDoTaskDone"
		or (
			Task.is_overdue(task) and "LazyDoTaskOverdue"
			or (
				task.status == "blocked" and "LazyDoTaskBlocked"
				or (task.status == "in_progress" and "LazyDoTaskInProgress" or "LazyDoTaskPending")
			)
		)

	components.status = " " .. status_icon .. " "
	add_region(#status_icon, status_hl, 1)

	-- Add priority icon
	if state.config.icons.priority and state.config.icons.priority[task.priority] then
		local priority_icon = state.config.icons.priority[task.priority]
		components.priority = priority_icon .. " "
		add_region(#priority_icon, "LazyDoPriority" .. task.priority:sub(1, 1):upper() .. task.priority:sub(2))
	end

	-- Add folding indicator
	if state.config.features.folding.enabled and task.subtasks and #task.subtasks > 0 then
		components.fold = (
			task.collapsed and state.config.features.folding.icons.folded
			or state.config.features.folding.icons.unfolded
		) .. " "
		add_region(#components.fold - 1, "LazyDoFoldIcon", 1)
	end

	-- Add task content
	add_region(#components.content, status_hl, 1)

	-- Add tags
	if state.config.features.tags.enabled and task.tags and #task.tags > 0 then
		local tags_str, tag_regions = render_tags(task)
		if tags_str then
			components.tags = tags_str
			for _, region in ipairs(tag_regions) do
				add_region(region.length, region.hl_group, 1)
			end
		end
	end

	-- Add due date
	if task.due_date then
		local due_text = string.format(" %s %s", state.config.icons.due_date or "", Task.get_due_date_relative(task))
		components.due = due_text

		local days_until_due = math.floor((task.due_date - os.time()) / (24 * 60 * 60))
		local due_hl = days_until_due < 0 and "LazyDoDueDateOverdue"
			or days_until_due <= 2 and "LazyDoDueDateNear"
			or "LazyDoDueDate"

		add_region(#due_text, due_hl, 1)
	end

	-- Add progress bar
	if state.config.theme.progress_bar and state.config.theme.progress_bar.enabled then
		local progress = Task.calculate_progress(task)
		local progress_bar = render_progress_bar(progress, state.config.theme.progress_bar.width)
		if progress_bar then
			local spacer = " | "
			components.progress = spacer .. progress_bar

			local progress_hl = progress == 100 and "LazyDoProgressComplete"
				or progress > 0 and "LazyDoProgressPartial"
				or "LazyDoProgressNone"

			add_region(#progress_bar, progress_hl, #spacer)
		end
	end
	if state.config.features.task_info and state.config.features.task_info.enabled then
		local info_lines = render_task_info(task, 0)
		if info_lines then
			components.info = info_lines
			add_region(#info_lines, "LazyDoTaskInfo", 4)
		end
	end

	-- Construct final header line
	local header_line = table.concat({
		components.indent,
		components.connector,
		components.status,
		components.priority,
		components.fold,
		components.content,
		components.tags,
		components.due,
		components.recurring,
		components.overdue,
		components.progress,
		components.info,
	})

	return header_line, regions
end

local function render_task(task, level, current_line, is_last)
	if not task then
		return {}, {}, {}
	end

	level = ensure_number(level, 0)
	current_line = ensure_number(current_line, 0)

	local lines = {}
	local regions = {}
	local mappings = {}

	-- Render task header
	local header_line, header_regions = render_task_header(task, level, is_last)
	table.insert(lines, header_line)

	-- Add header highlights
	for _, region in ipairs(header_regions) do
		table.insert(regions, {
			line = current_line,
			start = ensure_number(region.col, 0),
			length = ensure_number(region.length, 0),
			hl_group = region.hl_group or "Normal",
		})
	end

	-- Store task mapping
	if task.content then
		mappings[current_line + 1] = {
			task = task,
			mapping = {
				start_line = current_line,
				content_start = #header_line - #task.content,
				content_end = #header_line,
			},
		}
	end

	current_line = current_line + 1

	-- Render metadata if present
	if task.metadata and not vim.tbl_isempty(task.metadata) then
		local metadata_lines, metadata_regions = UI.render_metadata(task, level + 1)
		if metadata_lines and #metadata_lines > 0 then
			-- Add metadata lines
			for _, line in ipairs(metadata_lines) do
				table.insert(lines, line)
			end

			-- Add metadata highlights with proper line offsets
			for _, region in ipairs(metadata_regions) do
				table.insert(regions, {
					line = current_line + region.line,
					start = ensure_number(region.start, 0),
					length = ensure_number(region.length, 0),
					hl_group = region.hl_group,
				})
			end

			current_line = current_line + #metadata_lines
		end
	end

	if task.relations and #task.relations > 0 then
		local relation_lines, relation_regions = UI.render_relations_section(task, level + 1)
		if relation_lines and #relation_lines > 0 then
			-- Add relation lines
			for _, line in ipairs(relation_lines) do
				table.insert(lines, line)
			end

			-- Add relation highlights with proper line offsets
			for _, region in ipairs(relation_regions) do
				table.insert(regions, {
					line = current_line + region.line,
					start = region.start,
					length = region.length,
					hl_group = region.hl_group,
				})
			end

			current_line = current_line + #relation_lines
		end
	end
	-- Render notes if present
	if task.notes then
		local note_lines, note_regions = render_note_section(task.notes, level + 1, level > 0)
		if note_lines and #note_lines > 0 then
			-- Add note lines
			for _, line in ipairs(note_lines) do
				table.insert(lines, line)
			end

			-- Add note highlights with proper line offsets
			for _, region in ipairs(note_regions) do
				table.insert(regions, {
					line = current_line + region.line,
					start = ensure_number(region.col, 0),
					length = ensure_number(region.length, 0),
					hl_group = region.hl_group,
				})
			end

			current_line = current_line + #note_lines
		end
	end

	-- Add spacing for top-level tasks
	if level == 2 then
		table.insert(lines, "")
		current_line = current_line + 1
	end

	-- Render subtasks
	if task.subtasks and #task.subtasks > 0 and not task.collapsed then
		for i, subtask in ipairs(task.subtasks) do
			local sub_lines, sub_regions, sub_mappings =
				render_task(subtask, level + 1, current_line, i == #task.subtasks)

			vim.list_extend(lines, sub_lines)
			vim.list_extend(regions, sub_regions)

			for line_nr, mapping in pairs(sub_mappings) do
				mappings[line_nr] = mapping
			end

			current_line = current_line + #sub_lines
		end
	end

	-- Add separator for top-level tasks
	if level == 0 then
		local separator =
			create_task_separator(level, task.subtasks and #task.subtasks > 0, task.collapsed, get_safe_window_width())
		table.insert(lines, separator)
		table.insert(regions, {
			line = current_line,
			start = 0,
			length = #separator,
			hl_group = "LazyDoTaskBorder",
		})
		current_line = current_line + 1
	end

	return lines, regions, mappings
end

function UI.render_metadata(task, indent)
	if not task.metadata or vim.tbl_isempty(task.metadata) then
		return {}, {}
	end

	local lines = {}
	local regions = {}
	local indent_str = string.rep(" ", indent + 2)

	-- Sort metadata keys for consistent display
	local sorted_keys = vim.tbl_keys(task.metadata)
	table.sort(sorted_keys)

	for _, key in ipairs(sorted_keys) do
		local value = task.metadata[key]
		local line = string.format("%s%s: %s", indent_str, key, tostring(value))
		table.insert(lines, line)

		-- Add highlights for key and value
		table.insert(regions, {
			line = #lines - 1,
			start = #indent_str,
			length = #key,
			hl_group = "LazyDoMetadataKey",
		})
		table.insert(regions, {
			line = #lines - 1,
			start = #indent_str + #key + 2,
			length = #tostring(value),
			hl_group = "LazyDoMetadataValue",
		})
	end

	-- Add separator lines
	if #lines > 0 then
		table.insert(lines, 1, string.rep(" ", indent) .. "┌" .. string.rep("─", 40) .. "┐")
		table.insert(lines, string.rep(" ", indent) .. "└" .. string.rep("─", 40) .. "┘")
	end

	return lines, regions
end

-- Update the metadata deletion keymap
function UI.delete_metadata()
	local task = UI.get_task_under_cursor()
	if not task then
		UI.show_feedback("No task selected", "warn")
		return
	end

	if not task.metadata or vim.tbl_isempty(task.metadata) then
		UI.show_feedback("No metadata to delete", "warn")
		return
	end

	local metadata_keys = vim.tbl_keys(task.metadata)
	table.sort(metadata_keys)

	vim.ui.select(metadata_keys, {
		prompt = "Select metadata to delete:",
		format_item = function(key)
			return string.format("%s: %s", key, tostring(task.metadata[key]))
		end,
	}, function(choice)
		if choice then
			task.metadata[choice] = nil
			if vim.tbl_isempty(task.metadata) then
				task.metadata = nil
			end
			if state.on_task_update then
				state.on_task_update(state.tasks)
			end
			UI.show_feedback("Metadata deleted")
			UI.refresh()
		end
	end)
end

local function ensure_valid_window()
	if not state.win then
		error("Window handle is nil")
		return false
	end
	if not vim.api.nvim_win_is_valid(state.win) then
		error("Invalid window handle")
		return false
	end
	return true
end

function UI.render()
	if not state.buf or not state.win then
		return
	end
	if not ensure_valid_window() then
		return
	end
	local config = state.config

	-- Clear existing highlights and state
	vim.api.nvim_buf_clear_namespace(state.buf, ns_id, 0, -1)
	state.line_to_task = {}
	state.task_to_line = {}

	local lines = {}
	local regions = {}
	local current_line = 0

	-- Get window dimensions
	local width = get_safe_window_width()

	-- Render header section
	local title = state.view_mode == "kanban" and " LazyDo Kanban " or " LazyDo Tasks "
	local centered_title = Utils.Str.center(title, width)
	local header_separator = "╭" .. string.rep("━", width - 2) .. "╮"

	-- Add header components
	table.insert(lines, centered_title)
	table.insert(regions, {
		line = current_line,
		start = math.floor((width - #title) / 2),
		length = #title,
		hl_group = "LazyDoTitle",
	})
	current_line = current_line + 1

	-- Add separator after title
	table.insert(lines, header_separator)
	table.insert(regions, {
		line = current_line,
		start = 0,
		length = #header_separator,
		hl_group = "LazyDoHeaderSeparator",
	})
	current_line = current_line + 1

	-- Add empty line after header
	table.insert(lines, "")
	current_line = current_line + 1

	-- Render content based on view mode
	if state.view_mode == "kanban" then
		local kanban_lines, kanban_regions = UI.render_kanban_view()
		vim.list_extend(lines, kanban_lines)
		vim.list_extend(regions, kanban_regions)
		current_line = current_line + #kanban_lines
	else
		-- Render tasks in list view
		local tasks_to_render = state.filtered_tasks or state.tasks
		for i, task in ipairs(tasks_to_render) do
			if i > 1 and config.layout.spacing > 0 then
				for _ = 1, config.layout.spacing do
					table.insert(lines, "")
					current_line = current_line + 1
				end
			end

			local task_lines, task_regions, task_mappings = render_task(task, 0, current_line, false)
			vim.list_extend(lines, task_lines)
			vim.list_extend(regions, task_regions)

			-- Update task mappings
			for line_nr, mapping in pairs(task_mappings) do
				state.line_to_task[line_nr] = mapping
				state.task_to_line[mapping.task.id] = line_nr
			end

			current_line = current_line + #task_lines
		end
	end

	-- Add footer
	local footer_separator = "╰" .. string.rep("━", width - 2) .. "╯"
	table.insert(lines, footer_separator)
	table.insert(regions, {
		line = #lines - 1,
		start = 0,
		length = #footer_separator,
		hl_group = "LazyDoHeaderSeparator",
	})

	-- Update buffer content
	UI.update_buffer_content(lines, regions)

	-- Apply search highlights if any
	if #(state.search_results or {}) > 0 then
		highlight_search_results()
	end

	-- Restore cursor position if available
	if state.last_cursor then
		pcall(vim.api.nvim_win_set_cursor, state.win, state.last_cursor)
		state.last_cursor = nil
	end
end

local function show_help()
	local help_text = {
		"LazyDo Keybindings",
		"=====================================",
		"",
		"Basic Task Management:",
		"  <CR>       Toggle task status",
		"  a         Add new task",
		"  A         Add subtask",
		"  <leader>a Quick add task",
		"  d         Delete task",
		"  e         Edit task",
		"",
		"Task Properties:",
		"  p         Toggle priority",
		"  n         Set/edit note",
		"  D         Set due date",
		"  t         Add tag",
		"  T         Edit tag",
		"  <leader>t Remove tag",
		"  m         Set metadata",
		"  M         Edit metadata",
		"",
		"Task Organization:",
		"  <leader>x Convert to subtask",
		"  r         Set recurring",
		"  <leader>m Export to markdown",
		"",
		"Views and Navigation:",
		"  <leader>k Toggle Kanban view",
		"  <leader>K Move task in Kanban",
		"  <leader>v Toggle view mode",
		"  z         Toggle fold",
		"",
		"Reminders and Relations:",
		"  <leader>r Add reminder",
		"  <leader>R Manage reminders",
		"  <leader>l Show relations",
		"  <leader>L Add relation",
		"",
		"Sorting and Filtering:",
		"  <leader>sp Sort by priority",
		"  <leader>sd Sort by due date",
		"  <leader>ss Sort by status",
		"  /         Search tasks",
		"",
		"Other:",
		"  ?         Show this help",
		"  q         Close window",
	}

	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(#help_text, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "help")

	-- Set highlights for the help window
	vim.api.nvim_win_set_option(win, "winhl", "Normal:LazyDoHelp")

	-- Add highlights for different sections
	local ns_id = vim.api.nvim_create_namespace("LazyDoHelp")

	-- Highlight headers
	vim.api.nvim_buf_add_highlight(buf, ns_id, "LazyDoHelpHeader", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(buf, ns_id, "LazyDoHelpHeader", 1, 0, -1)

	-- Highlight section titles
	local section_lines = { 3, 8, 15, 21, 26, 32, 38 }
	for _, line in ipairs(section_lines) do
		vim.api.nvim_buf_add_highlight(buf, ns_id, "LazyDoHelpSection", line, 0, -1)
	end

	-- Highlight keybindings
	for i, line in ipairs(help_text) do
		local key_end = line:find("  [^ ]")
		if key_end then
			vim.api.nvim_buf_add_highlight(buf, ns_id, "LazyDoHelpKey", i - 1, 2, key_end)
		end
	end

	-- Close help window with 'q' or '<Esc>'
	local close_keys = { "q", "<Esc>" }
	for _, key in ipairs(close_keys) do
		vim.keymap.set("n", key, function()
			vim.api.nvim_win_close(win, true)
		end, { buffer = buf, nowait = true })
	end
end
function UI.setup(config_opts)
	state.config = config_opts
	state.view_mode = config_opts.views and config_opts.views.default or "list"
end
---Refresh the UI display
function UI.refresh()
	if is_valid_window() and is_valid_buffer() then
		local pos = vim.api.nvim_win_get_cursor(state.win)
		UI.render()
		pcall(vim.api.nvim_win_set_cursor, state.win, pos)
	end
end

-- Wrap action callback to ensure UI refresh
local function wrap_action_callback(fn)
	return function(...)
		local result = fn(...)
		UI.refresh()
		return result
	end
end

-- ui.lua

function UI.setup_keymaps()
	local function map(key, fn, desc)
		vim.api.nvim_buf_set_keymap(state.buf, "n", key, "", {
			callback = wrap_action_callback(fn),
			noremap = true,
			silent = true,
			desc = "LazyDo: " .. desc,
		})
	end

	-- Task Movement
	map("K", function()
		local task = UI.get_task_under_cursor()
		if task then
			Actions.move_task_up(state.tasks, task.id, state.on_task_update)
		end
	end, "Move Task Up")

	map("J", function()
		local task = UI.get_task_under_cursor()
		if task then
			Actions.move_task_down(state.tasks, task.id, state.on_task_update)
		end
	end, "Move Task Down")
	map("H", function()
		if state.view_mode == "kanban" then
			UI.move_kanban_cursor("left")
		end
	end, "Move Left in Kanban")

	map("L", function()
		if state.view_mode == "kanban" then
			UI.move_kanban_cursor("right")
		end
	end, "Move Right in Kanban")

	map("<leader>h", function()
		if state.view_mode == "kanban" then
			UI.move_task_to_column("left")
		end
	end, "Move Task Left")

	map("<leader>l", function()
		if state.view_mode == "kanban" then
			UI.move_task_to_column("right")
		end
	end, "Move Task Right")
	-- Task Status
	map("<CR>", function()
		if state.view_mode == "kanban" then
			if not UI.toggle_task_kanban() then
				-- If not on a toggle box, try to toggle the task under cursor
				local task = UI.get_task_under_cursor()
				if task then
					Actions.toggle_status(state.tasks, task.id, state.on_task_update)
					UI.refresh()
				end
			end
		else
			UI.toggle_task()
		end
	end, "Toggle Task")
	map("i", function()
		UI.toggle_task_info()
	end, "Toggle Task Info")
	-- Task Management
	map("d", function()
		local task = UI.get_task_under_cursor()
		if task then
			Actions.delete_task(state.tasks, task.id, state.on_task_update)
			UI.refresh()
		end
	end, "Delete Task")

	map("e", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.input({
				prompt = "Edit task:",
				default = task.content,
			}, function(new_content)
				if new_content and new_content ~= "" then
					Actions.update_task(state.tasks, task.id, { content = new_content }, state.on_task_update)
					UI.refresh()
				end
			end)
		end
	end, "Edit Task")

	-- Task Properties
	map("p", function()
		local task = UI.get_task_under_cursor()
		if task then
			Actions.cycle_priority(state.tasks, task.id, state.on_task_update)
			UI.refresh()
		end
	end, "Toggle Priority")

	map("n", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.input({
				prompt = "Add note:",
				default = task.notes or "",
			}, function(notes)
				if notes then
					Actions.set_notes(state.tasks, task.id, notes, state.on_task_update)
					UI.refresh()
				end
			end)
		end
	end, "Set Note")

	map("D", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.input({
				prompt = "Set due (YYYY-MM-DD/today/tomorrow/Nd):",
				default = task.due_date and Utils.Date.format(task.due_date) or "",
			}, function(date_str)
				if date_str then
					Actions.set_due_date(state.tasks, task.id, date_str, state.on_task_update)
					UI.refresh()
				end
			end)
		end
	end, "Set Date")

	-- Task Hierarchy
	map("<leader>x", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.select(state.tasks, {
				prompt = "Select parent task:",
				format_item = function(t)
					return t.content
				end,
			}, function(parent)
				if parent and parent.id ~= task.id then
					Actions.convert_to_subtask(state.tasks, task.id, parent.id, state.on_task_update)
					UI.refresh()
				end
			end)
		end
	end, "Convert To SubTask")
	map("<leader>X", function()
		local task = UI.get_task_under_cursor()
		if not task then
			UI.show_feedback("No task selected", "warn")
			return
		end

		-- Find the parent task by traversing all tasks
		local function find_parent_and_remove(tasks, target_id)
			for _, t in ipairs(tasks) do
				if t.subtasks then
					for i, subtask in ipairs(t.subtasks) do
						if subtask.id == target_id then
							-- Found the subtask, remove it from parent
							table.remove(t.subtasks, i)
							return true
						end
					end
					-- Recursively check nested subtasks
					if find_parent_and_remove(t.subtasks, target_id) then
						return true
					end
				end
			end
			return false
		end

		-- Try to find and remove the task from its parent
		if find_parent_and_remove(state.tasks, task.id) then
			-- Add the task to main tasks list
			table.insert(state.tasks, task)

			if state.on_task_update then
				state.on_task_update(state.tasks)
			end
			UI.show_feedback("Converted subtask to main task")
			UI.refresh()
		else
			UI.show_feedback("Task is not a subtask", "warn")
		end
	end, "Convert SubTask to Task")
	map("r", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.select({ "daily", "weekly", "monthly" }, {
				prompt = "Select Recurring:",
			}, function(pattern)
				if pattern then
					Actions.set_reccuring(state.tasks, pattern)
					UI.show_feedback("The Recurring set " .. pattern, "info")
				end
			end)
		end
	end, "Set recurring")

	map("<leader>m", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.input({
				prompt = "Set filename to save tasks in .md:",
				default = vim.fn.expand("%") or "",
			}, function(name)
				if name then
					Actions.export_to_markdown(state.tasks, name)
					UI.show_feedback("The tasks saved in " .. name, "info")
					UI.refresh()
				end
			end)
		end
	end, "Export to markdown")

	map("?", function()
		show_help()
	end, "Help Window")

	-- new feats
	map("<leader>r", function()
		UI.add_reminder()
	end, "Add Reminder")

	map("<leader>R", function()
		local task = UI.get_task_under_cursor()
		if task and task.reminders and #task.reminders > 0 then
			vim.ui.select(task.reminders, {
				prompt = "Select reminder:",
				format_item = function(reminder)
					return string.format("%s (%s)", os.date("%Y-%m-%d %H:%M", reminder.time), reminder.urgency)
				end,
			}, function(selected)
				if selected then
					-- Show reminder options
					vim.ui.select({ "edit", "delete" }, {
						prompt = "Action:",
					}, function(action)
						if action == "delete" then
							vim.tbl_filter(function(r)
								return r.id ~= selected.id
							end, task.reminders)
							UI.refresh()
						elseif action == "edit" then
							UI.add_reminder() -- Re-use add function for editing
						end
					end)
				end
			end)
		end
	end, "Manage Reminders")

	-- Relations
	map("<leader>l", function()
		UI.show_relations()
	end, "Show Relations")

	map("<leader>L", function()
		local task = UI.get_task_under_cursor()
		if task then
			vim.ui.select(state.tasks, {
				prompt = "Select target task:",
				format_item = function(t)
					return t.content
				end,
			}, function(target)
				if target then
					vim.ui.select({ "blocks", "depends_on", "related_to", "duplicates" }, {
						prompt = "Relation type:",
					}, function(rel_type)
						if rel_type then
							Task.add_relation(task, target.id, rel_type)
							UI.refresh()
						end
					end)
				end
			end)
		end
	end, "Add Relation")

	-- Kanban View
	map("<leader>k", function()
		state.view_mode = state.view_mode == "kanban" and "list" or "kanban"
		UI.refresh()
		UI.show_feedback("Switched to " .. state.view_mode .. " view")
	end, "Toggle Kanban View")

	map("<leader>K", function()
		if state.view_mode == "kanban" then
			local task = UI.get_task_under_cursor()
			if task then
				vim.ui.select({ "todo", "in_progress", "blocked", "done" }, {
					prompt = "Move to column:",
				}, function(new_status)
					if new_status then
						task.status = new_status
						if state.on_task_update then
							state.on_task_update(state.tasks)
						end
						UI.refresh()
					end
				end)
			end
		end
	end, "Move Task in Kanban")
	map("<leader>v", function()
		UI.toggle_view()
	end, "Toggle View Mode")

	-- Add task creation keymap
	map("a", function()
		UI.add_task()
	end, "Add Task")
	map("A", function()
		UI.add_subtask()
	end, "Add SubTask")
	map("<leader>a", function()
		vim.ui.input({
			prompt = "Quick task:",
		}, function(content)
			if content and content ~= "" then
				local task = Actions.add_task(state.tasks, content, {
					priority = "medium",
					due_date = nil,
				}, state.on_task_update)
				if task then
					UI.refresh()
					UI.show_feedback("Quick task added")
				end
			end
		end)
	end, "Quick Add Task")
	map("z", function()
		UI.toggle_fold()
	end, "Toggle Fold")

	map("t", function()
		UI.add_tag()
	end, "Add Tag")
	map("T", function()
		UI.edit_tag()
	end, "Edit Tag")
	map("<leader>t", function()
		UI.remove_tag()
	end, "Remove Tag")
	map("m", function()
		UI.set_metadata()
	end, "Set MetaData")
	map("M", function()
		UI.edit_metadata()
	end, "Edit Metadata")

	-- Add task search
	map("/", function()
		vim.ui.input({
			prompt = "Search tasks:",
			default = state.current_search or "",
		}, function(query)
			if not query or query == "" then
				state.search_results = {}
				state.current_search = nil
				UI.refresh()
				return
			end

			state.current_search = query
			state.search_results = {}

			local function search_task(task, parent_indent)
				local content_lower = task.content:lower()
				local query_lower = query:lower()
				local start_idx = content_lower:find(query_lower, 1, true)

				if start_idx then
					table.insert(state.search_results, {
						id = task.id,
						match_start = start_idx + (parent_indent or 0),
						match_end = start_idx + #query + (parent_indent or 0),
						line = state.task_to_line[task.id],
					})
				end

				if task.subtasks then
					for _, subtask in ipairs(task.subtasks) do
						search_task(subtask, (parent_indent or 0) + state.config.theme.indent.size)
					end
				end
			end

			for _, task in ipairs(state.tasks) do
				search_task(task)
			end

			if #state.search_results > 0 then
				UI.show_feedback(string.format("Found %d matches", #state.search_results), "info")
			else
				UI.show_feedback("No matches found", "warn")
			end

			UI.refresh()
		end)
	end, "Search")

	-- Add sort keymaps
	map("<leader>sp", function()
		if #state.tasks == 0 then
			UI.show_feedback("No tasks to sort", "warn")
			return
		end
		Task.sort_by_priority(state.tasks)
		if state.on_task_update then
			state.on_task_update(state.tasks)
		end
		UI.show_feedback("Tasks sorted by priority")
		UI.refresh()
	end, "Sort by Priority")

	map("<leader>sd", function()
		if #state.tasks == 0 then
			UI.show_feedback("No tasks to sort", "warn")
			return
		end
		Task.sort_by_due_date(state.tasks)
		if state.on_task_update then
			state.on_task_update(state.tasks)
		end
		UI.show_feedback("Tasks sorted by due date")
		UI.refresh()
	end, "Sort by Due")

	-- Add new sort by status keymap
	map("<leader>ss", function()
		if #state.tasks == 0 then
			UI.show_feedback("No tasks to sort", "warn")
			return
		end
		Task.sort_by_status(state.tasks)
		if state.on_task_update then
			state.on_task_update(state.tasks)
		end
		UI.show_feedback("Tasks sorted by status")
		UI.refresh()
	end, "Sort by Status")

	-- Add metadata deletion
	map("<leader>md", function()
		local task = UI.get_task_under_cursor()
		if not task then
			UI.show_feedback("No task selected", "warn")
			return
		end

		if not task.metadata or vim.tbl_isempty(task.metadata) then
			UI.show_feedback("No metadata to delete", "warn")
			return
		end

		local metadata_keys = vim.tbl_keys(task.metadata)
		table.sort(metadata_keys)

		vim.ui.select(metadata_keys, {
			prompt = "Select metadata to delete:",
			format_item = function(key)
				return string.format("%s: %s", key, tostring(task.metadata[key]))
			end,
		}, function(choice)
			if choice then
				task.metadata[choice] = nil
				if vim.tbl_isempty(task.metadata) then
					task.metadata = nil
				end
				if state.on_task_update then
					state.on_task_update(state.tasks)
				end
				UI.show_feedback("Metadata deleted")
				UI.refresh()
			end
		end)
	end, "Delete Metadata")
end
---Show feedback to user
---@param message string Message to show
---@param level? "info"|"warn"|"error" Feedback level
function UI.show_feedback(message, level)
	level = level or "info"
	local levels = {
		info = vim.log.levels.INFO,
		warn = vim.log.levels.WARN,
		error = vim.log.levels.ERROR,
	}

	vim.notify(message, levels[level], {
		title = "LazyDo",
		icon = "󱃔 ",
		timeout = 2000,
	})
end

function UI.filter_tasks(filter_fn)
	if not state.tasks then
		return
	end
	local filtered = vim.tbl_filter(filter_fn, state.tasks)
	state.filtered_tasks = filtered
	UI.refresh()
end

function UI.toggle_task_info()
	state.show_task_info = not state.show_task_info
	UI.refresh()
	UI.show_feedback(state.show_task_info and "Task info shown" or "Task info hidden")
end

-- Quick filters
UI.filters = {
	today = function()
		UI.filter_tasks(function(task)
			return Task.is_due_today(task)
		end)
		UI.refresh()
	end,
	overdue = function()
		UI.filter_tasks(function(task)
			return Task.is_overdue(task)
		end)
		UI.refresh()
	end,
	high_priority = function()
		UI.filter_tasks(function(task)
			return task.priority == "high"
		end)
		UI.refresh()
	end,
}

-- Task sorting capabilities
function UI.sort_tasks(sort_fn)
	if not state.tasks then
		return
	end
	table.sort(state.tasks, sort_fn)
	UI.refresh()
end

-- Quick sorts
UI.sorts = {
	by_priority = function()
		local priority_order = { low = 1, medium = 2, high = 3 }
		UI.sort_tasks(function(a, b)
			return priority_order[a.priority] > priority_order[b.priority]
		end)
		UI.refresh()
	end,
	by_due_date = function()
		UI.sort_tasks(function(a, b)
			-- If both tasks have no due date, maintain current order
			if not a.due_date and not b.due_date then
				return false
			end
			-- Tasks without due dates go to the end
			if not a.due_date then
				return false
			end
			if not b.due_date then
				return true
			end
			-- Compare actual dates
			return a.due_date < b.due_date
		end)
		UI.refresh()
	end,
}
-- Task grouping
function UI.group_tasks(group_fn)
	if not state.tasks then
		return
	end
	local groups = {}
	for _, task in ipairs(state.tasks) do
		local group = group_fn(task)
		groups[group] = groups[group] or {}
		table.insert(groups[group], task)
	end
	return groups
end

-- Quick groups
UI.groups = {
	by_status = function()
		return UI.group_tasks(function(task)
			return task.status
		end)
	end,
	by_priority = function()
		return UI.group_tasks(function(task)
			return task.priority
		end)
	end,
}

-- Task export capabilities
function UI.export_tasks(format)
	local exporters = {
		markdown = function(tasks)
			local lines = {}
			local function add_task(task, level)
				local indent = string.rep("  ", level)
				local status = task.status == "done" and "[x]" or "[ ]"
				local line = string.format("%s%s %s", indent, status, task.content)
				table.insert(lines, line)
				if task.subtasks then
					for _, subtask in ipairs(task.subtasks) do
						add_task(subtask, level + 1)
					end
				end
			end
			for _, task in ipairs(tasks) do
				add_task(task, 0)
			end
			return table.concat(lines, "\n")
		end,
		json = function(tasks)
			return vim.fn.json_encode(tasks)
		end,
	}

	local exporter = exporters[format]
	if exporter then
		return exporter(state.tasks)
	end
end
function UI.add_task()
	vim.ui.input({
		prompt = "Task content:",
	}, function(content)
		if not content or content == "" then
			UI.show_feedback("Task content cannot be empty", "warn")
			return
		end

		vim.ui.select({ "low", "medium", "high" }, {
			prompt = "Select priority:",
			format_item = function(item)
				return string.format("%s Priority", item:sub(1, 1):upper() .. item:sub(2))
			end,
		}, function(priority)
			if not priority then
				return
			end

			vim.ui.input({
				prompt = "Due (YYYY-MM-DD/today/tomorrow/Nd, optional):",
			}, function(due_date)
				local timestamp = due_date and due_date ~= "" and Utils.Date.parse(due_date)

				vim.ui.input({
					prompt = "Notes (optional):",
					-- completion = "file",
				}, function(notes)
					local task = Actions.add_task(state.tasks, content, {
						priority = priority,
						due_date = timestamp,
						notes = notes ~= "" and notes or nil,
					}, state.on_task_update)

					if task then
						UI.refresh()
						UI.show_feedback("Task added successfully")
					end
				end)
			end)
		end)
	end)
end

function UI.toggle_task()
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	Actions.toggle_status(state.tasks, task.id, function(tasks)
		if state.on_task_update then
			state.on_task_update(tasks)
		end
		-- Recalculate progress after status change
		local progress = Task.calculate_progress(task)
		UI.show_feedback(string.format("Task marked as %s (%d%% complete)", task.status, progress))
	end)
	UI.refresh()
end

function UI.edit_task()
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	vim.ui.input({
		prompt = "Edit task:",
		default = task.content,
	}, function(new_content)
		if new_content and new_content ~= "" then
			Actions.update_task(state.tasks, task.id, { content = new_content }, state.on_task_update)
		end
	end)
	UI.refresh()
end

function UI.add_note()
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	vim.ui.input({
		prompt = "Add note:",
		default = task.notes or "",
	}, function(notes)
		if notes then
			Actions.set_notes(state.tasks, task.id, notes, state.on_task_update)
		end
	end)
	UI.refresh()
end

function UI.cycle_priority()
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	Actions.cycle_priority(state.tasks, task.id, state.on_task_update)
end

function UI.set_due_date()
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	vim.ui.input({
		prompt = "Set due date (YYYY-MM-DD/today/tomorrow/Nd):",
		default = task.due_date and Utils.Date.format(task.due_date) or "",
	}, function(date_str)
		if date_str then
			Actions.set_due_date(state.tasks, task.id, date_str, state.on_task_update)
		end
	end)
	UI.refresh()
end

function UI.get_task_at_kanban_position(row, col)
	local config = state.config.views.kanban
	local col_width = state.config.column_width == "auto"
			and math.floor(vim.api.nvim_win_get_width(state.win) / #state.config.columns) - 2
		or state.config.column_width

	local column_index = math.floor(col / col_width) + 1
	local column = state.config.columns[column_index]

	if not column then
		return nil
	end

	local tasks_in_column = vim.tbl_filter(function(t)
		return t.status == column.status
	end, state.tasks)

	return tasks_in_column[row - 2] -- Adjust for header row
end

function UI.get_task_under_cursor()
	if not state.win or not state.buf then
		return nil
	end
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line_nr = cursor[1]
	local col_nr = cursor[2]
	if state.view_mode == "kanban" then
		local layout = UI.get_kanban_layout()
		if not layout then
			return nil
		end

		local col_index = math.floor(col_nr / (layout.col_width + 1)) + 1
		local column = state.config.views.kanban.columns[col_index]

		if not column then
			return nil
		end

		local tasks_in_column = vim.tbl_filter(function(t)
			return t.status == column.status
		end, state.tasks)

		-- Account for header row
		local task_index = line_nr - 2
		return tasks_in_column[task_index]
	else
		for task_line, line_info in pairs(state.line_to_task) do
			local task_end_line = task_line
			-- Find end of task section (next task start or end of buffer)
			for i = task_line + 1, vim.api.nvim_buf_line_count(state.buf) do
				local next_line_info = state.line_to_task[i]
				if next_line_info then
					task_end_line = i - 1
					break
				end
				task_end_line = i
			end

			-- Check if cursor is within task range
			if line_nr >= task_line and line_nr <= task_end_line then
				state.cursor_task = line_info.task
				return line_info.task
			end
		end
		return state.line_to_task[line_nr] and state.line_to_task[line_nr].task
	end
end

function UI.update_task(task)
	if not validate_task(task) then
		UI.show_feedback("Cannot update invalid task", "error")
		return
	end

	if state.on_task_update then
		local success, err = pcall(state.on_task_update, task)
		if not success then
			UI.show_feedback("Failed to update task: " .. tostring(err), "error")
			return
		end
	end

	UI.refresh()
end

function UI.update_task_status(task_id, new_status)
	local task = UI.find_task_by_id(task_id)
	if not task then
		UI.show_feedback("Task not found", "error")
		return
	end

	local old_status = task.status
	task.status = new_status
	task.updated_at = os.time()

	-- Calculate progress
	local progress = Task.calculate_progress(task)

	-- Update parent task progress if exists
	if task.parent_id then
		local parent = UI.find_task_by_id(task.parent_id)
		if parent then
			parent.progress = Task.calculate_progress(parent)
		end
	end

	-- Show feedback with progress
	UI.show_feedback(
		string.format("Task status changed from %s to %s (%d%% complete)", old_status, new_status, progress)
	)

	UI.refresh()
end

function UI.update_task_positions()
	state.task_to_line = {}
	if state.view_mode == "kanban" then
		local current_line = 2 -- Account for header
		local layout = UI.get_kanban_layout()

		for col_idx, column in ipairs(state.config.views.kanban.columns) do
			local tasks = vim.tbl_filter(function(t)
				return t.status == column.status
			end, state.tasks)

			for _, task in ipairs(tasks) do
				state.task_to_line[task.id] = {
					line = current_line,
					column = col_idx,
					width = layout.col_width,
				}
				current_line = current_line + 1
			end
		end
	else
		-- Existing list view task position tracking
	end
end

function UI.find_task_by_id(task_id)
	local function search_tasks(tasks)
		for _, task in ipairs(tasks) do
			if task.id == task_id then
				return task
			end
			if task.subtasks then
				local found = search_tasks(task.subtasks)
				if found then
					return found
				end
			end
		end
		return nil
	end

	return search_tasks(state.tasks)
end

-- Add task folding support
function UI.toggle_fold()
	local task = UI.get_task_under_cursor()
	if task and task.subtasks and #task.subtasks > 0 then
		local cursor_pos = vim.api.nvim_win_get_cursor(state.win)
		task.collapsed = not task.collapsed
		UI.refresh()
		vim.api.nvim_win_set_cursor(state.win, cursor_pos)
	end
end
-- Add task tags support
function UI.add_tag()
	local task = UI.get_task_under_cursor()
	if task then
		vim.ui.input({
			prompt = "Add tag:",
		}, function(tag)
			if tag and tag ~= "" then
				Task.add_tag(task, tag)
				if state.on_task_update then
					state.on_task_update(state.tasks)
				end
				UI.refresh()
			end
		end)
	end
end
function UI.edit_tag()
	local task = UI.get_task_under_cursor()
	if not task or not task.tags or #task.tags == 0 then
		UI.show_feedback("No tags to edit", "warn")
		return
	end

	vim.ui.select(task.tags, {
		prompt = "Select tag to edit:",
	}, function(selected_tag)
		if selected_tag then
			vim.ui.input({
				prompt = "Edit tag:",
				default = selected_tag,
			}, function(new_tag)
				if new_tag and new_tag ~= "" then
					Task.remove_tag(task, selected_tag)
					Task.add_tag(task, new_tag)
					if state.on_task_update then
						state.on_task_update(state.tasks)
					end
					UI.refresh()
				end
			end)
		end
	end)
end
function UI.remove_tag()
	local task = UI.get_task_under_cursor()

	if not task or not task.tags or #task.tags == 0 then
		UI.show_feedback("No tags to remove", "warn")
		return
	end

	vim.ui.select(task.tags, {
		prompt = "Select tag to remove:",
		format_item = function(tag)
			return tag
		end,
	}, function(selected_tag)
		if selected_tag then
			Task.remove_tag(task, selected_tag)
		end
		if state.on_task_update then
			state.on_task_update(state.tasks)
		end
		UI.refresh()
	end)
end

function UI.add_subtask()
	local parent_task = UI.get_task_under_cursor()
	if not parent_task then
		UI.show_feedback("No task selected", "warn")
		return
	end

	-- Get content first
	vim.ui.input({
		prompt = "Subtask content:",
		default = "",
	}, function(content)
		if not content or content == "" then
			UI.show_feedback("Subtask content cannot be empty", "warn")
			return
		end

		-- Then get priority
		vim.ui.select({ "low", "medium", "high" }, {
			prompt = "Select priority:",
			format_item = function(item)
				return string.format("%s Priority", item:sub(1, 1):upper() .. item:sub(2))
			end,
			default = "medium",
		}, function(priority)
			if not priority then
				return
			end

			-- Get due date
			vim.ui.input({
				prompt = "Due date (YYYY-MM-DD/today/tomorrow/Nd, optional):",
			}, function(due_date)
				local timestamp = due_date and due_date ~= "" and Utils.Date.parse(due_date)

				-- Finally get notes
				vim.ui.input({
					prompt = "Notes (optional):",
					-- completion = "file",
				}, function(notes)
					-- Create and add the subtask
					local subtask = Task.new(content, {
						priority = priority,
						parent_id = parent_task.id,
						due_date = timestamp,
						notes = notes ~= "" and notes or nil,
					})

					-- Initialize subtasks array if needed
					parent_task.subtasks = parent_task.subtasks or {}
					table.insert(parent_task.subtasks, subtask)

					-- Update state and UI
					if state.on_task_update then
						state.on_task_update(state.tasks)
					end

					-- Show success message and refresh
					UI.show_feedback(string.format("Added subtask to '%s'", parent_task.content))
					UI.refresh()

					-- Ensure parent task is unfolded to show new subtask
					if parent_task.collapsed then
						parent_task.collapsed = false
						UI.refresh()
					end
				end)
			end)
		end)
	end)
end

-- Add task metadata support
function UI.set_metadata()
	local task = UI.get_task_under_cursor()
	if task then
		vim.ui.input({
			prompt = "Metadata key:",
		}, function(key)
			if key and key ~= "" then
				vim.ui.input({
					prompt = "Metadata value:",
				}, function(value)
					if value then
						Task.set_metadata(task, key, value)
						if state.on_task_update then
							state.on_task_update(state.tasks)
						end
						UI.refresh()
					end
				end)
			end
		end)
	end
end
function UI.edit_metadata()
	local task = UI.get_task_under_cursor()
	if not task or not task.metadata or vim.tbl_isempty(task.metadata) then
		UI.show_feedback("No metadata to edit", "warn")
		return
	end

	local metadata_keys = vim.tbl_keys(task.metadata)
	vim.ui.select(metadata_keys, {
		prompt = "Select metadata to edit:",
	}, function(selected_key)
		if selected_key then
			vim.ui.input({
				prompt = "Edit metadata value:",
				default = tostring(task.metadata[selected_key]),
			}, function(new_value)
				if new_value then
					Task.set_metadata(task, selected_key, new_value)
					if state.on_task_update then
						state.on_task_update(state.tasks)
					end
					UI.refresh()
				end
			end)
		end
	end)
end
---Close UI window
function UI.close()
	if is_valid_window() then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	if is_valid_buffer() then
		pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
	end
	clear_state()
end

---Toggle UI visibility
---@param tasks Task[] Current tasks
---@param on_task_update? function Callback for task updates
---@param lazy_config? table Configuration to use if not initialized
function UI.toggle(tasks, on_task_update, lazy_config, last_state)
	if lazy_config then
		UI.setup(lazy_config)
	end

	if not state.config then
		error("UI not properly initialized: missing configuration")
		return
	end

	if is_valid_window() then
		UI.close()
		return
	end

	clear_state()
	state.tasks = type(tasks) == "table" and tasks or {}
	state.on_task_update = on_task_update

	local success, buf_or_err, win_or_err = pcall(create_window)
	if not success then
		error("Failed to create UI: " .. tostring(buf_or_err))
		return
	end

	if not buf_or_err or not win_or_err then
		error("Failed to create window or buffer")
		return
	end

	state.buf = buf_or_err
	state.win = win_or_err

	UI.setup_keymaps()
	UI.refresh()

	if last_state then
		UI.restore_window_state(last_state)
	end

	-- Set up essential autocommands
	if state.buf then
		vim.api.nvim_create_autocmd("WinLeave", {
			buffer = state.buf,
			callback = function()
				if state.win then
					state.last_position = {
						cursor = vim.api.nvim_win_get_cursor(state.win),
						scroll = vim.fn.winsaveview(),
					}
				end
			end,
		})

		vim.api.nvim_create_autocmd("VimResized", {
			buffer = state.buf,
			callback = function()
				if is_valid_window() then
					local size = Utils.get_window_size()
					vim.api.nvim_win_set_config(state.win, {
						width = size.width,
						height = size.height,
						row = size.row,
						col = size.col,
					})
					UI.refresh()
				end
			end,
		})
	end
	if last_state then
		state.view_mode = last_state.view_mode or state.view_mode
		UI.restore_window_state(last_state)
	end
end

function UI.toggle_view()
	state.last_view_mode = state.view_mode
	state.view_mode = state.view_mode == "list" and "kanban" or "list"
	UI.refresh()
	UI.show_feedback("Switched to " .. state.view_mode .. " view")
end
-- Add new UI components for attachments
function UI.show_attachments()
	local task = UI.get_task_under_cursor()
	if not task or not task.attachments then
		return
	end

	local items = {}
	for _, att in ipairs(task.attachments) do
		table.insert(items, string.format("%s (%s)", att.name, Utils.format_size(att.size)))
	end

	vim.ui.select(items, {
		prompt = "Task Attachments:",
		format_item = function(item)
			return item
		end,
	}, function(choice)
		if choice then
			-- Handle attachment selection
			local idx = vim.tbl_contains(items, choice)
			local attachment = task.attachments[idx]
			vim.fn.system(string.format("xdg-open %s", vim.fn.shellescape(attachment.path)))
		end
	end)
end

-- Add new UI components for relations
function UI.show_relations()
	local task = UI.get_task_under_cursor()
	if not task then
		UI.show_feedback("No task selected", "warn")
		return
	end

	if not task.relations or #task.relations == 0 then
		UI.show_feedback("No relations found", "warn")
		return
	end

	local relation_items = {}
	for _, rel in ipairs(task.relations) do
		local target = UI.find_task_by_id(rel.target_id)
		if target then
			local status_icon = target.status == "done" and state.config.icons.task_done
				or state.config.icons.task_pending
			table.insert(relation_items, {
				relation = rel,
				target = target,
				display = string.format(
					"%s %s → [%s] %s",
					state.config.icons.relation,
					rel.type:gsub("_", " "):upper(),
					status_icon,
					target.content
				),
			})
		end
	end

	vim.ui.select(relation_items, {
		prompt = "Task Relations:",
		format_item = function(item)
			return item.display
		end,
	}, function(choice)
		if choice then
			vim.ui.select({
				"Remove Relation",
				"Edit Relation Type",
			}, {
				prompt = "Relation Action:",
			}, function(action)
				if action == "Remove Relation" then
					for i, rel in ipairs(task.relations) do
						if rel.target_id == choice.relation.target_id and rel.type == choice.relation.type then
							table.remove(task.relations, i)
							if state.on_task_update then
								state.on_task_update(state.tasks)
							end
							UI.show_feedback("Relation removed")
							UI.refresh()
							break
						end
					end
				elseif action == "Edit Relation Type" then
					vim.ui.select(Task.get_relation_types(), {
						prompt = "Select new relation type:",
						format_item = function(item)
							return item:gsub("_", " "):upper()
						end,
					}, function(new_type)
						if new_type then
							for _, rel in ipairs(task.relations) do
								if rel.target_id == choice.relation.target_id then
									rel.type = new_type
									if state.on_task_update then
										state.on_task_update(state.tasks)
									end
									UI.show_feedback("Relation type updated")
									UI.refresh()
									break
								end
							end
						end
					end)
				end
			end)
		end
	end)
end

function UI.toggle_kanban_view()
	-- Group tasks by status
	local columns = {
		todo = { title = "Todo", tasks = {} },
		in_progress = { title = "In Progress", tasks = {} },
		blocked = { title = "Blocked", tasks = {} },
		done = { title = "Done", tasks = {} },
	}

	-- Distribute tasks to columns
	for _, task in ipairs(state.tasks) do
		if columns[task.status] then
			table.insert(columns[task.status].tasks, task)
		end
	end

	-- Calculate column width
	local win_width = vim.api.nvim_win_get_width(state.win)
	local col_width = math.floor(win_width / 4) - 2

	-- Render columns
	local lines = {}
	local regions = {}

	-- Add column headers
	local header_line = ""
	for _, col in pairs(columns) do
		local title = Utils.Str.center(col.title, col_width)
		header_line = header_line .. "│" .. title
	end

	table.insert(lines, header_line)

	-- Render tasks in columns
	local max_tasks = 0
	for _, col in pairs(columns) do
		max_tasks = math.max(max_tasks, #col.tasks)
	end

	for i = 1, max_tasks do
		local line = ""
		for _, col in pairs(columns) do
			local task = col.tasks[i]
			local task_text = task and Utils.Str.truncate(task.content, col_width - 2) or string.rep(" ", col_width - 2)
			line = line .. "│ " .. task_text .. string.rep(" ", col_width - #task_text - 2)
		end
		table.insert(lines, line)
	end

	return lines, regions
end

function UI.render_kanban_view()
	local layout = UI.get_kanban_layout()
	local lines = {}
	local regions = {}
	local current_line = 0

	-- Reset state tracking
	state.kanban_cards = {}
	state.line_to_task = {}

	-- Initialize columns with tasks
	local columns = {}
	for _, col in ipairs(state.config.views.kanban.columns) do
		columns[col.status] = vim.tbl_filter(function(t)
			return t.status == col.status
		end, state.tasks)
	end

	-- Render header
	local header_line = "│"
	for _, col in ipairs(state.config.views.kanban.columns) do
		local title = string.format("%s %s", col.icon, col.name)
		if state.config.views.kanban.show_column_stats then
			local count = #columns[col.status]
			title = title .. string.format(" (%d)", count)
		end
		local padded_title = Utils.Str.center(title, layout.col_width)
		header_line = header_line .. padded_title .. "│"

		-- Add header highlight
		table.insert(regions, {
			line = current_line,
			start = #header_line - layout.col_width - 1,
			length = layout.col_width,
			hl_group = "LazyDoKanbanHeader",
		})
	end
	table.insert(lines, header_line)

	-- Add separator
	local separator = "╞" .. string.rep("═", layout.col_width)
	for i = 2, #state.config.views.kanban.columns do
		separator = separator .. "╪" .. string.rep("═", layout.col_width)
	end
	separator = separator .. "╡"
	table.insert(lines, separator)
	current_line = current_line + 2

	-- Find maximum number of tasks
	local max_tasks = 0
	for _, tasks in pairs(columns) do
		max_tasks = math.max(max_tasks, #tasks)
	end

	-- Render tasks row by row
	for row = 1, max_tasks do
		local row_cards = {}
		local max_height = 1

		-- Create cards for this row
		for col_idx, col in ipairs(state.config.views.kanban.columns) do
			local task = columns[col.status][row]
			if task then
				local col_start = (col_idx - 1) * (layout.col_width + 1)
				local card = UI.create_kanban_card(task, layout.col_width, col_start, current_line)
				row_cards[col_idx] = card
				max_height = math.max(max_height, #card.content)
				table.insert(state.kanban_cards, card)

				-- Map lines to tasks for cursor detection
				for line = card.line_start, card.line_end do
					state.line_to_task[line] = {
						task = task,
						card = card,
					}
				end
			end
		end

		-- Render cards in this row
		for i = 1, max_height do
			local line = "│"
			for col_idx, col in ipairs(state.config.views.kanban.columns) do
				local card = row_cards[col_idx]
				local content = card and card.content[i] or string.rep(" ", layout.col_width)
				line = line .. content .. "│"

				-- Add highlights for card content
				if card then
					local col_start = (col_idx - 1) * (layout.col_width + 1) + 1
					UI.add_card_highlights(regions, card, current_line + i - 1, col_start, layout.col_width)
				end
			end
			table.insert(lines, line)
		end

		-- Add spacing between rows
		table.insert(
			lines,
			string.rep("│" .. string.rep(" ", layout.col_width), #state.config.views.kanban.columns) .. "│"
		)
		current_line = current_line + max_height + 1
	end

	return lines, regions
end

function UI.create_kanban_card(task, width, col_start, start_line)
	local card = {
		task = task,
		width = width,
		col_start = col_start,
		content = {},
		line_start = start_line,
	}

	-- Create card content
	local status_icon = task.status == "done" and state.config.icons.task_done or state.config.icons.task_pending
	local priority_icon = state.config.icons.priority[task.priority]
	local toggle_box = "[" .. status_icon .. "]"

	-- Store toggle position for interaction
	card.toggle = {
		width = #toggle_box,
		start = col_start + 2,
		line = start_line + 1, -- Toggle is on the second line
	}

	-- Calculate content width
	local content_width = width - #toggle_box - 6
	local content = Utils.Str.truncate(task.content, content_width)

	-- Build card content
	card.content = {
		string.rep(" ", width), -- Top padding
		" " .. toggle_box .. " " .. priority_icon .. " " .. content .. string.rep(
			" ",
			width - #content - #toggle_box - 5
		),
	}

	-- Add metadata if present
	if task.metadata and not vim.tbl_isempty(task.metadata) then
		local metadata_lines = UI.render_metadata(task, 0)
		if metadata_lines and #metadata_lines > 0 then
			for _, line in ipairs(metadata_lines) do
				table.insert(
					card.content,
					" " .. Utils.Str.truncate(line, width - 2) .. string.rep(" ", width - #line - 2)
				)
			end
		end
	end

	-- Add due date if present
	if task.due_date then
		local due = state.config.icons.due_date .. " " .. Utils.Date.relative(task.due_date)
		local padded_due = Utils.Str.center(Utils.Str.truncate(due, width - 4), width - 2)
		table.insert(card.content, " " .. padded_due)
	end

	-- Add tags if present
	if task.tags and #task.tags > 0 then
		local tags = state.config.features.tags.prefix .. table.concat(task.tags, ", ")
		local padded_tags = Utils.Str.center(Utils.Str.truncate(tags, width - 4), width - 2)
		table.insert(card.content, " " .. padded_tags)
	end

	-- Add relations if present
	if task.relations and #task.relations > 0 then
		local relations_text = UI.format_relations(task)
		if relations_text then
			local padded_relations = Utils.Str.center(Utils.Str.truncate(relations_text, width - 4), width - 2)
			table.insert(card.content, " " .. padded_relations)
		end
	end

	table.insert(card.content, string.rep(" ", width)) -- Bottom padding
	card.line_end = start_line + #card.content - 1

	return card
end

function UI.render_relations_section(task, indent_level)
	if not task.relations or #task.relations == 0 then
		return {}, {}
	end

	local lines = {}
	local regions = {}
	local indent = string.rep("  ", indent_level)
	local base_indent = indent .. "    " -- 4 spaces after base indent
	local box_width = 50 -- Increased width for better visual appeal

	-- Add section header with icon
	local title = " Relations "
	local header = indent .. "┌─" .. title .. string.rep("─", box_width - #title - 2) .. "┐"
	table.insert(lines, header)

	-- Add title highlight
	table.insert(regions, {
		line = #lines - 1,
		start = #indent + 2,
		length = #title,
		hl_group = "LazyDoSectionTitle",
	})

	-- Add border highlight
	table.insert(regions, {
		line = #lines - 1,
		start = #indent,
		length = box_width + 2, -- +2 for left and right borders
		hl_group = "LazyDoNoteBorder",
	})

	-- Group relations by type
	local relations_by_type = {}
	for _, rel in ipairs(task.relations) do
		relations_by_type[rel.type] = relations_by_type[rel.type] or {}
		local target = UI.find_task_by_id(rel.target_id)
		if target then
			table.insert(relations_by_type[rel.type], {
				relation = rel,
				target = target,
			})
		end
	end

	-- Render relations grouped by type
	local types = vim.tbl_keys(relations_by_type)
	table.sort(types)

	for type_idx, type in ipairs(types) do
		-- Add relation type header with icon (safely handle missing icon)
		local type_header = type:gsub("_", " "):upper()
		local relation_icon = (state.config.icons and state.config.icons.relation) or "→"
		local type_line = base_indent .. "│ " .. relation_icon .. " " .. type_header .. ":"
		table.insert(lines, type_line)

		-- Add type highlight
		table.insert(regions, {
			line = #lines - 1,
			start = #base_indent + 4, -- After border and icon
			length = #type_header,
			hl_group = "LazyDoRelationType",
		})

		-- Add relation targets
		for _, rel_info in ipairs(relations_by_type[type]) do
			local status_icon = rel_info.target.status == "done"
					and (state.config.icons and state.config.icons.task_done or "✓")
				or (state.config.icons and state.config.icons.task_pending or "·")
			local target_line = base_indent .. "│   • [" .. status_icon .. "] " .. rel_info.target.content

			table.insert(lines, target_line)

			-- Add target task highlight
			table.insert(regions, {
				line = #lines - 1,
				start = #base_indent + 8, -- After border, bullet, and status
				length = #rel_info.target.content,
				hl_group = "LazyDoRelationTarget",
			})
		end

		-- Add separator between types unless it's the last one
		if type_idx < #types then
			table.insert(lines, base_indent .. "│" .. string.rep("─", box_width - 4))
		end
	end

	-- Add section footer
	table.insert(lines, indent .. "└" .. string.rep("─", box_width) .. "┘")

	-- Add footer border highlight
	table.insert(regions, {
		line = #lines - 1,
		start = #indent,
		length = box_width + 2,
		hl_group = "LazyDoNoteBorder",
	})

	return lines, regions
end

-- New function to format relations as text
function UI.format_relations(task)
	if not task.relations or #task.relations == 0 then
		return nil
	end

	local relation_texts = {}
	for _, rel in ipairs(task.relations) do
		local target = UI.find_task_by_id(rel.target_id)
		if target then
			table.insert(relation_texts, string.format("%s → %s", rel.type, Utils.Str.truncate(target.content, 30)))
		end
	end

	return #relation_texts > 0 and table.concat(relation_texts, " | ") or nil
end

-- Update render_task_header to include relations
function UI.render_task_header(task, level)
	local indent = string.rep("  ", level)
	local status_icon = task.status == "done" and state.config.icons.task_done or state.config.icons.task_pending
	local priority_icon = state.config.icons.priority[task.priority]
	local toggle_box = "[" .. status_icon .. "]"

	-- Format relations text
	local relations_text = ""
	if task.relations and #task.relations > 0 then
		local relation_counts = {}
		for _, rel in ipairs(task.relations) do
			relation_counts[rel.type] = (relation_counts[rel.type] or 0) + 1
		end

		local relation_parts = {}
		for type, count in pairs(relation_counts) do
			table.insert(
				relation_parts,
				string.format(
					"%s:%d",
					type:sub(1, 1):upper(), -- First letter of relation type
					count
				)
			)
		end
		relations_text = " " .. (state.config.icons.relation or "r") .. "(" .. table.concat(relation_parts, ",") .. ")"
	end

	-- Calculate content width considering relations
	local max_width = vim.api.nvim_win_get_width(0) - #indent - #toggle_box - #priority_icon - 5
	local content = Utils.Str.truncate(task.content, max_width - #relations_text)

	-- Combine all parts
	local header = string.format("%s%s %s %s%s", indent, toggle_box, priority_icon, content, relations_text)

	local regions = {
		{ col = #indent, length = #toggle_box, hl_group = "LazyDoTaskToggle" },
		{ col = #indent + #toggle_box + 1, length = #priority_icon, hl_group = "LazyDoTaskPriority" },
		{ col = #indent + #toggle_box + #priority_icon + 2, length = #content, hl_group = "LazyDoTaskContent" },
	}

	-- Add highlight for relations if present
	if #relations_text > 0 then
		table.insert(regions, {
			col = #header - #relations_text,
			length = #relations_text,
			hl_group = "LazyDoTaskRelation",
		})
	end

	return header, regions
end

function UI.add_card_highlights(regions, card, line, col_start, width)
	-- Add base card highlight
	table.insert(regions, {
		line = line,
		start = col_start,
		length = width,
		hl_group = string.format(
			"LazyDoKanbanCard%s%s",
			card.task.priority:upper(),
			card.task.status == "done" and "Done" or ""
		),
	})

	-- Add toggle box highlight
	if line == card.toggle.line then
		table.insert(regions, {
			line = line,
			start = card.toggle.start,
			length = card.toggle.width,
			hl_group = "LazyDoKanbanToggle",
		})
	end

	-- Add metadata highlights
	if card.task.metadata and line > card.toggle.line + 1 then
		table.insert(regions, {
			line = line,
			start = col_start + 2,
			length = width - 4,
			hl_group = "LazyDoKanbanMetadata",
		})
	end
end

function UI.toggle_task_kanban()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line_nr = cursor[1]
	local col_nr = cursor[2]

	local line_info = state.line_to_task[line_nr]
	if line_info then
		local card = line_info.card
		if
			line_nr == card.toggle.line
			and col_nr >= card.toggle.start
			and col_nr < card.toggle.start + card.toggle.width
		then
			Actions.toggle_status(state.tasks, line_info.task.id, function(tasks)
				if state.on_task_update then
					state.on_task_update(tasks)
				end
				UI.show_feedback(
					string.format("Task marked as %s", line_info.task.status == "done" and "pending" or "done")
				)
			end)
			UI.refresh()
			return true
		end
	end
	return false
end

function UI.render_task_card(task, width)
	local status_icon = task.status == "done" and state.config.icons.task_done or state.config.icons.task_pending
	local priority_icon = state.config.icons.priority[task.priority]

	-- Create toggle box with status icon
	local toggle_box = "[" .. status_icon .. "]"

	-- Calculate content width
	local content_width = width - 8 -- Account for borders, padding, and icons
	local content = Utils.Str.truncate(task.content, content_width)

	local card = {
		"╭" .. string.rep("─", width - 2) .. "╮",
		"│ " .. toggle_box .. " " .. priority_icon .. " " .. content .. string.rep(
			" ",
			width - #content - #toggle_box - 5
		) .. "│",
	}

	-- Add due date if present
	if task.due_date then
		local due = state.config.icons.due_date .. " " .. Utils.Date.relative(task.due_date)
		local padded_due = Utils.Str.center(Utils.Str.truncate(due, width - 4), width - 2)
		table.insert(card, "│" .. padded_due .. "│")
	end

	-- Add tags if present
	if task.tags and #task.tags > 0 then
		local tags = state.config.features.tags.prefix .. table.concat(task.tags, ", ")
		local padded_tags = Utils.Str.center(Utils.Str.truncate(tags, width - 4), width - 2)
		table.insert(card, "│" .. padded_tags .. "│")
	end

	table.insert(card, "╰" .. string.rep("─", width - 2) .. "╯")

	return table.concat(card, "\n")
end

function UI.move_kanban_cursor(direction)
	local config = state.config.views.kanban
	if direction == "left" then
		state.kanban_cursor.column = math.max(1, state.kanban_cursor.column - 1)
	elseif direction == "right" then
		state.kanban_cursor.column = math.min(#state.config.columns, state.kanban_cursor.column + 1)
	end
	UI.refresh()
end

function UI.get_kanban_layout()
	local win_width = vim.api.nvim_win_get_width(state.win)
	local config = state.config.views.kanban
	local num_columns = #config.columns

	-- Calculate column width based on configuration
	local col_width = config.column_width == "auto" and math.floor((win_width - num_columns - 1) / num_columns)
		or config.column_width

	-- Ensure minimum column width
	col_width = math.max(col_width, 30)

	return {
		width = win_width,
		col_width = col_width,
		padding = 1,
		separator = "│",
		card_spacing = 1, -- Vertical spacing between cards
	}
end

function UI.move_task_to_column(direction)
	local task = UI.get_task_under_cursor()
	if not task then
		return
	end

	local config = state.config.views.kanban
	local columns = config.columns
	local current_col_idx

	-- Find current column index safely
	for i, col in ipairs(columns) do
		if col.status == task.status then
			current_col_idx = i
			break
		end
	end

	if not current_col_idx then
		return
	end

	-- Calculate new column index
	local new_col_idx = direction == "left" and math.max(1, current_col_idx - 1)
		or math.min(#columns, current_col_idx + 1)

	-- Update task status
	if new_col_idx ~= current_col_idx then
		task.status = columns[new_col_idx].status
		task.updated_at = os.time()

		if state.on_task_update then
			state.on_task_update(state.tasks)
		end

		UI.refresh()
		UI.show_feedback(string.format("Moved task to %s", columns[new_col_idx].name))
	end
end

function UI.render_compact_card(task, width)
	local content = Utils.Str.truncate(task.content, width - 4)
	local priority_icon = state.config.icons.priority[task.priority]
	return string.format(" %s %s ", priority_icon, content)
end

function UI.render_detailed_card(task, width)
	local lines = {}
	local content = Utils.Str.truncate(task.content, width - 4)
	local priority_icon = state.config.icons.priority[task.priority]
	local due_date = task.due_date and Utils.Date.relative(task.due_date) or ""

	table.insert(lines, string.format(" %s %s", priority_icon, content))
	if due_date ~= "" then
		table.insert(lines, string.format(" %s %s", state.config.icons.due_date, due_date))
	end
	if task.tags and #task.tags > 0 then
		table.insert(lines, " " .. table.concat(task.tags, " "))
	end

	return table.concat(lines, "\n")
end
-- Add new UI components for reminders
function UI.add_reminder()
	local task = UI.get_task_under_cursor()
	if not task then
		UI.show_feedback("No task selected", "warn")
		return
	end

	local function parse_time(time_str)
		if time_str:match("^%+") then
			-- Parse relative time (+3d2h format)
			local days, hours = time_str:match("^%+(%d+)d(%d+)h$")
			if days and hours then
				return os.time() + (tonumber(days) * 86400) + (tonumber(hours) * 3600)
			end
			return nil, "Invalid relative time format. Use +NdNh"
		else
			-- Parse absolute time
			local pattern = "(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+)"
			local year, month, day, hour, min = time_str:match(pattern)
			if year then
				local timestamp = os.time({
					year = tonumber(year),
					month = tonumber(month),
					day = tonumber(day),
					hour = tonumber(hour),
					min = tonumber(min),
				})
				if timestamp < os.time() then
					return nil, "Reminder time cannot be in the past"
				end
				return timestamp
			end
			return nil, "Invalid date format. Use YYYY-MM-DD HH:MM"
		end
	end

	local function create_reminder(timestamp, urgency, method)
		local reminder = {
			id = Utils.generate_id(),
			time = timestamp,
			urgency = urgency,
			method = method,
			created_at = os.time(),
		}

		task.reminders = task.reminders or {}
		table.insert(task.reminders, reminder)

		if state.on_task_update then
			state.on_task_update(state.tasks)
		end

		UI.show_feedback(
			string.format("Reminder set for %s (%s urgency)", os.date("%Y-%m-%d %H:%M", timestamp), urgency)
		)
		UI.refresh()
	end

	-- Get reminder time
	vim.ui.input({
		prompt = "Reminder time (YYYY-MM-DD HH:MM or +NdNh):",
		default = os.date("%Y-%m-%d %H:%M"),
		-- completion = "custom,ReminderTimeComplete",
	}, function(time_str)
		if not time_str or time_str == "" then
			return
		end

		local timestamp, err = parse_time(time_str)
		if not timestamp then
			UI.show_feedback(err, "error")
			return
		end

		-- Get urgency level with descriptions
		local urgency_options = {
			{ text = "low - Normal reminder", value = "low" },
			{ text = "medium - Important reminder", value = "medium" },
			{ text = "high - Critical reminder", value = "high" },
			{ text = "urgent - Immediate attention needed", value = "urgent" },
		}

		vim.ui.select(urgency_options, {
			prompt = "Select urgency level:",
			format_item = function(item)
				return item.text
			end,
		}, function(choice)
			if not choice then
				return
			end

			-- Get notification method with descriptions
			local method_options = {
				{ text = "popup - Show in Neovim window", value = "popup" },
				{ text = "notification - System notification", value = "notification" },
				{ text = "both - Both popup and system notification", value = "both" },
			}

			vim.ui.select(method_options, {
				prompt = "Select notification method:",
				format_item = function(item)
					return item.text
				end,
			}, function(method_choice)
				if not method_choice then
					return
				end
				create_reminder(timestamp, choice.value, method_choice.value)
			end)
		end)
	end)
end

function UI.get_highlight_group(base_group, fallback)
	local hl_exists = pcall(vim.api.nvim_get_hl_by_name, base_group, true)
	return hl_exists and base_group or fallback
end

function UI.update_buffer_content(lines, regions)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)

	local flat_lines = {}
	local adjusted_regions = {}
	local line_offset = 0

	for i, line in ipairs(lines) do
		local split_lines = vim.split(line, "\n")
		vim.list_extend(flat_lines, split_lines)

		for _, region in ipairs(regions) do
			if region.line == i - 1 then
				local new_region = vim.deepcopy(region)
				new_region.line = new_region.line + line_offset
				-- Ensure start and length are within line bounds
				new_region.start = math.min(new_region.start, #split_lines[1] or 0)
				new_region.length = math.min(new_region.length, (#split_lines[1] or 0) - new_region.start)
				if new_region.length > 0 then
					table.insert(adjusted_regions, new_region)
				end
			end
		end

		line_offset = line_offset + #split_lines - 1
	end

	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, flat_lines)

	for _, region in ipairs(adjusted_regions) do
		local hl_group = UI.get_highlight_group(region.hl_group, "Normal")
		if region.color then
			local dynamic_hl = region.hl_group .. region.color:gsub("#", "")
			vim.api.nvim_set_hl(0, dynamic_hl, { fg = region.color })
			hl_group = dynamic_hl
		end

		pcall(
			vim.api.nvim_buf_add_highlight,
			state.buf,
			ns_id,
			hl_group,
			region.line,
			region.start,
			region.start + region.length
		)
	end

	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

-- Add helper method for dynamic window updates
function UI.handle_window_resize()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		local size = Utils.get_window_size()
		vim.api.nvim_win_set_config(state.win, {
			width = size.width,
			height = size.height,
			row = size.row,
			col = size.col,
		})
		UI.refresh()
	end
end

-- Add method for view transitions
function UI.transition_view(new_view)
	if new_view ~= state.view_mode then
		state.last_view_mode = state.view_mode
		state.view_mode = new_view
		UI.refresh()
	end
end

-- Add method for task position lookup
function UI.get_task_position(task_id)
	return state.task_to_line[task_id]
end

-- Add method for cursor navigation
function UI.navigate_to_task(task_id)
	local pos = UI.get_task_position(task_id)
	if pos then
		if type(pos) == "table" then
			-- Kanban view position
			vim.api.nvim_win_set_cursor(state.win, { pos.line, pos.column * pos.width })
		else
			-- List view position
			vim.api.nvim_win_set_cursor(state.win, { pos, 0 })
		end
	end
end

function UI.add_relation()
	local source_task = UI.get_task_under_cursor()
	if not source_task then
		UI.show_feedback("No task selected", "warn")
		return
	end

	-- First, select the relation type
	vim.ui.select(Task.get_relation_types(), {
		prompt = "Select relation type:",
		format_item = function(item)
			return string.format("%s", item:gsub("_", " "):gsub("^%l", string.upper))
		end,
	}, function(relation_type)
		if not relation_type then
			return
		end

		-- Then select the target task
		local target_tasks = vim.tbl_filter(function(t)
			return t.id ~= source_task.id
		end, state.tasks)

		vim.ui.select(target_tasks, {
			prompt = "Select target task:",
			format_item = function(task)
				return string.format("%s", task.content)
			end,
		}, function(target_task)
			if target_task then
				local success, err = Task.add_relation(source_task, target_task.id, relation_type)
				if success then
					if state.on_task_update then
						state.on_task_update(state.tasks)
					end
					UI.show_feedback(string.format("Added %s relation", relation_type))
					UI.refresh()
				else
					UI.show_feedback(err or "Failed to add relation", "error")
				end
			end
		end)
	end)
end

return UI
