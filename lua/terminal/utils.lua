---@class TerminalUtils
---Utility functions for terminal plugin
local M = {}

---Check if a value is callable (function or table with __call)
---@param obj any Object to check
---@return boolean is_callable
function M.is_callable(obj)
  if type(obj) == 'function' then
    return true
  end
  
  local mt = getmetatable(obj)
  return mt ~= nil and type(mt.__call) == 'function'
end

---Deep merge tables (no garbage creation for nested tables)
---@param base table Base table
---@param overlay table Table to merge on top
---@return table merged
function M.merge_tables(base, overlay)
  local result = {}
  
  -- Copy base
  for k, v in pairs(base) do
    if type(v) == 'table' then
      result[k] = M.merge_tables(v, {})
    else
      result[k] = v
    end
  end
  
  -- Overlay
  for k, v in pairs(overlay) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = M.merge_tables(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

---Get window dimensions for different directions
---@param direction string Direction: 'horizontal', 'vertical', 'float', 'tab'
---@param size number|function Size configuration
---@return number width, number height
function M.calculate_window_size(direction, size)
  -- Handle function-based size
  if M.is_callable(size) then
    size = size()
  end
  
  local width, height
  
  if direction == 'horizontal' then
    width = vim.o.columns
    height = math.floor(size)
  elseif direction == 'vertical' then
    width = math.floor(size)
    height = vim.o.lines
  elseif direction == 'tab' then
    width = vim.o.columns
    height = vim.o.lines
  else -- float
    width = vim.o.columns
    height = vim.o.lines
  end
  
  return width, height
end

---Parse float configuration percentages
---@param value number Value (can be percentage 0-1 or absolute)
---@param total number Total size
---@return number calculated
function M.parse_percentage(value, total)
  if value < 1 then
    return math.floor(total * value)
  end
  return math.floor(value)
end

---Validate terminal options
---@param opts table Options to validate
---@return boolean valid, string|nil error_message
function M.validate_opts(opts)
  local valid_directions = {
    horizontal = true,
    vertical = true,
    float = true,
    tab = true,
  }
  
  if opts.direction and not valid_directions[opts.direction] then
    return false, 'Invalid direction: ' .. opts.direction
  end
  
  if opts.size then
    local size_type = type(opts.size)
    if size_type ~= 'number' and size_type ~= 'function' then
      return false, 'Size must be a number or function'
    end
    
    if size_type == 'number' and opts.size <= 0 then
      return false, 'Size must be positive'
    end
  end
  
  return true, nil
end

---Get terminal icon based on state
---@param is_open boolean Whether terminal is open
---@param is_running boolean Whether process is running
---@return string icon
function M.get_terminal_icon(is_open, is_running)
  if is_open and is_running then
    return '▶'
  elseif is_open then
    return '○'
  elseif is_running then
    return '■'
  else
    return '×'
  end
end

---Format terminal display name
---@param id number Terminal ID
---@param cmd string Command
---@param direction string Direction
---@return string formatted
function M.format_terminal_name(id, cmd, direction)
  -- Truncate command if too long
  local max_len = 30
  local display_cmd = cmd
  if #cmd > max_len then
    display_cmd = cmd:sub(1, max_len - 3) .. '...'
  end
  
  return string.format('[%d] %s (%s)', id, display_cmd, direction)
end

---Check if buffer is a terminal
---@param bufnr number Buffer number
---@return boolean is_terminal
function M.is_terminal_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  
  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
  return buftype == 'terminal'
end

---Get all terminal buffers in current session
---@return number[] buffers
function M.get_all_terminal_buffers()
  local terminals = {}
  local buffers = vim.api.nvim_list_bufs()
  
  for _, bufnr in ipairs(buffers) do
    if M.is_terminal_buffer(bufnr) then
      table.insert(terminals, bufnr)
    end
  end
  
  return terminals
end

---Sanitize command for display
---@param cmd string Command
---@return string sanitized
function M.sanitize_command(cmd)
  -- Remove control characters
  return cmd:gsub('[%c]', '')
end

---Get terminal job ID from buffer
---@param bufnr number Buffer number
---@return number|nil job_id
function M.get_job_id_from_buffer(bufnr)
  if not M.is_terminal_buffer(bufnr) then
    return nil
  end
  
  return vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
end

---Check if job is running
---@param job_id number Job ID
---@return boolean is_running
function M.is_job_running(job_id)
  if not job_id or job_id <= 0 then
    return false
  end
  
  -- Try to get job info
  local ok, _ = pcall(vim.fn.jobwait, { job_id }, 0)
  return ok
end

---Create a debounced function (garbage-free version)
---@param fn function Function to debounce
---@param delay number Delay in milliseconds
---@return function debounced
function M.debounce(fn, delay)
  local timer = vim.loop.new_timer()
  
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(delay, 0, vim.schedule_wrap(function()
      fn(unpack(args))
    end))
  end
end

---Create a throttled function (garbage-free version)
---@param fn function Function to throttle
---@param delay number Delay in milliseconds
---@return function throttled
function M.throttle(fn, delay)
  local timer = vim.loop.new_timer()
  local running = false
  
  return function(...)
    if running then
      return
    end
    
    local args = { ... }
    running = true
    timer:start(delay, 0, vim.schedule_wrap(function()
      running = false
      fn(unpack(args))
    end))
  end
end

---Escape special characters in string for pattern matching
---@param str string String to escape
---@return string escaped
function M.escape_pattern(str)
  return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

---Get shell from environment or default
---@return string shell
function M.get_default_shell()
  return vim.env.SHELL or vim.o.shell or '/bin/sh'
end

---Check if Neovim version meets requirement
---@param required string Required version (e.g., '0.10.0')
---@return boolean meets_requirement
function M.check_version(required)
  return vim.fn.has('nvim-' .. required) == 1
end

---Create autocmd that auto-deletes
---@param event string|string[] Event(s)
---@param opts table Autocmd options
function M.create_autocmd_once(event, opts)
  local original_callback = opts.callback
  local group = opts.group
  local id
  
  opts.callback = function(...)
    if original_callback then
      original_callback(...)
    end
    if id then
      vim.api.nvim_del_autocmd(id)
    end
  end
  
  id = vim.api.nvim_create_autocmd(event, opts)
  return id
end

---Safely call function with error handling
---@param fn function Function to call
---@param ... any Arguments
---@return boolean success, any result_or_error
function M.safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    vim.notify('Terminal error: ' .. tostring(result), vim.log.levels.ERROR)
    return false, result
  end
  return true, result
end

---Get visual selection range
---@return number start_line, number end_line, number start_col, number end_col
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  return start_pos[2], end_pos[2], start_pos[3], end_pos[3]
end

---Clamp value between min and max
---@param value number Value to clamp
---@param min number Minimum value
---@param max number Maximum value
---@return number clamped
function M.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  end
  return value
end

---Round number to nearest integer
---@param value number Value to round
---@return number rounded
function M.round(value)
  return math.floor(value + 0.5)
end

---Check if table is empty
---@param tbl table Table to check
---@return boolean is_empty
function M.is_empty(tbl)
  return next(tbl) == nil
end

---Count table elements (works for non-sequential tables)
---@param tbl table Table to count
---@return number count
function M.table_count(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

return M
