---[[
--> The notification manager
---]]

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
    info = "󰋼",
    warn = "󰀪",
    error = "󰅙",
    success = "󰌵",
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

-- Setup highlight groups
local function setup_highlights()
  -- Notification window highlights
  api.nvim_set_hl(0, "Notif", { link = "Normal" })
  api.nvim_set_hl(0, "NotifBorder", { link = "FloatBorder" })
  api.nvim_set_hl(0, "NotifTitle", { link = "Title" })
  api.nvim_set_hl(0, "NotifInfo", { link = "DiagnosticInfo" })
  api.nvim_set_hl(0, "NotifWarn", { link = "DiagnosticWarn" })
  api.nvim_set_hl(0, "NotifError", { link = "DiagnosticError" })
  api.nvim_set_hl(0, "NotifSuccess", { link = "DiagnosticHint" })
  api.nvim_set_hl(0, "NotifTime", { link = "Constant" })
  api.nvim_set_hl(0, "NotifActions", { link = "Type" })
end

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
      hl = "NotifInfo",
    },
    [M.LEVELS.WARN] = {
      name = "WARN",
      icon = config.icons.warn or " ",
      hl = "NotifWarn",
    },
    [M.LEVELS.ERROR] = {
      name = "ERROR",
      icon = config.icons.error or " ",
      hl = "NotifError",
    },
    [M.LEVELS.SUCCESS] = {
      name = "SUCCESS",
      icon = config.icons.success or " ",
      hl = "NotifSuccess",
    },
  }

  return level_map[level] or level_map[M.LEVELS.INFO]
end

-- Format notification content with better layout
local function format_notification_content(notification, width)
  local level_info = get_level_info(notification.level)

  local lines = {}
  local content_width = width - 1 -- Account for padding

  -- Message content with proper wrapping
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
  -- Separator
  -- table.insert(lines, string.rep("─", content_width + 1))
  -- Source and timestamp line

  -- Actions with better formatting
  if #notification.actions > 0 then
    table.insert(lines, "Actions:")
    for i, action in ipairs(notification.actions) do
      local action_line = string.format("  %d. %s", i, action.label)
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
  width = math.max(width, 30)                 -- Minimum width
  width = math.min(width, vim.o.columns - 10) -- Maximum width

  local content, level_info = format_notification_content(notification, width)
  local icon = notification.icon or level_info.icon

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
  api.nvim_buf_set_option(buf, "filetype", "markdown")
  api.nvim_buf_set_lines(buf, 0, -1, false, content)
  api.nvim_buf_set_option(buf, "modifiable", false)
  local title = icon .. " " .. notification.title
  local time_str = os.date("%H:%M", notification.timestamp)
  local meta_line = ""
  if notification.source and notification.source ~= "" then
    meta_line = "From: " .. notification.source .. " at " .. time_str
  else
    meta_line = "󰥔 " .. time_str
  end

  -- Enhanced window options with better styling
  local win_opts = {
    relative = "editor",
    anchor = "NE",
    width = width,
    height = height,
    row = pos.row - 1,
    col = pos.col,
    border = config.border or "rounded",
    style = "minimal",
    focusable = false,
    title = { { title, level_info.hl } } or "notification",
    title_pos = "center",
    footer = { { meta_line, level_info.hl } } or " ",
    footer_pos = "right",
    zindex = 50,
  }

  -- Create window
  local win = api.nvim_open_win(buf, false, win_opts)
  api.nvim_win_set_option(win, "winhl", "Normal:Notif,FloatBorder:NotifBorder")

  -- Apply enhanced highlighting
  local ns_id = api.nvim_create_namespace("notifs_" .. notification.id)

  -- Highlight header with icon and title
  api.nvim_buf_add_highlight(buf, ns_id, level_info.hl, 0, 0, -1)

  -- Highlight meta line (source and time)

  -- Highlight separator

  -- Highlight message content with level color
  local start_idx = 1
  local actions_started = false
  for i = start_idx, #content - 1 do
    local line = content[i + 1] or ""
    if line:match("^Actions:") then
      actions_started = true
      api.nvim_buf_add_highlight(buf, ns_id, "NotifActions", i, 0, -1)
    elseif actions_started or line:match("^%s*%d+%.") then
      api.nvim_buf_add_highlight(buf, ns_id, "NotifActions", i, 0, -1)
    else
      api.nvim_buf_add_highlight(buf, ns_id, level_info.hl, i, 0, -1)
    end
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
  api.nvim_exec_autocmds("User", { pattern = "NotifUpdate" })

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

  setup_highlights()

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







  api.nvim_create_user_command("NotifClear", M.clear_all, {
    desc = "Clear all active notifications",
  })


  api.nvim_create_user_command("NotifExport", function(opts)
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
