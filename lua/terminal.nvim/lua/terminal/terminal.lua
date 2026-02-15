---@class Terminal
---@field bufnr number|nil Buffer number for the terminal
---@field winnr number|nil Window number for the terminal
---@field jobnr number|nil Job ID for the terminal process
---@field cmd string Command to run in terminal
---@field opts TerminalOptions Terminal configuration options
---@field state TerminalState Current state of the terminal
---@field _cached_size table<string, number> Cached window dimensions to avoid garbage
local Terminal = {}
Terminal.__index = Terminal

---@class TerminalOptions
---@field direction string Direction: 'horizontal', 'vertical', 'float', 'tab'
---@field size number|function Size of the terminal (height/width or function returning size)
---@field close_on_exit boolean Close terminal when process exits
---@field auto_scroll boolean Auto-scroll to bottom on output
---@field start_in_insert boolean Start in insert mode when opening
---@field on_open function|nil Callback when terminal opens
---@field on_close function|nil Callback when terminal closes
---@field on_stdout function|nil Callback for stdout data
---@field on_stderr function|nil Callback for stderr data
---@field shell string|nil Shell to use (defaults to &shell)
---@field cwd string|nil Working directory
---@field env table<string, string>|nil Environment variables
---@field clear_env boolean Clear environment before applying env
---@field float_opts table|nil Float window options

---@class TerminalState
---@field is_open boolean Whether terminal window is currently open
---@field is_running boolean Whether terminal process is running
---@field exit_code number|nil Exit code of the process
---@field last_accessed number Timestamp of last access

---Default options for new terminals
---@type TerminalOptions
Terminal.default_opts = {
  direction = 'horizontal',
  size = 15,
  close_on_exit = false,
  auto_scroll = true,
  start_in_insert = true,
  on_open = nil,
  on_close = nil,
  on_stdout = nil,
  on_stderr = nil,
  shell = nil,
  cwd = nil,
  env = nil,
  clear_env = false,
  float_opts = {
    relative = 'editor',
    width = 0.8,
    height = 0.8,
    row = 0.1,
    col = 0.1,
    style = 'minimal',
    border = 'rounded',
  },
}

---Create a new Terminal instance
---@param cmd string|nil Command to run (nil for default shell)
---@param opts TerminalOptions|nil Optional configuration
---@return Terminal
function Terminal:new(cmd, opts)
  ---@type Terminal
  local instance = setmetatable({}, self)
  
  instance.cmd = cmd or vim.o.shell
  instance.opts = vim.tbl_deep_extend('force', self.default_opts, opts or {})
  instance.bufnr = nil
  instance.winnr = nil
  instance.jobnr = nil
  
  -- Initialize state with proper types
  ---@type TerminalState
  instance.state = {
    is_open = false,
    is_running = false,
    exit_code = nil,
    last_accessed = vim.loop.hrtime(),
  }
  
  -- Pre-allocate cached size table to avoid garbage
  instance._cached_size = { width = 0, height = 0 }
  
  return instance
end

---Calculate the size for the terminal window
---Optimized to avoid creating garbage by reusing cached table
---@return number width, number height
function Terminal:_calculate_size()
  local direction = self.opts.direction
  local size = self.opts.size
  
  -- Handle function-based size
  if type(size) == 'function' then
    size = size()
  end
  
  if direction == 'float' then
    local float_opts = self.opts.float_opts
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    
    -- Calculate width (can be percentage or absolute)
    if float_opts.width < 1 then
      self._cached_size.width = math.floor(editor_width * float_opts.width)
    else
      self._cached_size.width = math.floor(float_opts.width)
    end
    
    -- Calculate height (can be percentage or absolute)
    if float_opts.height < 1 then
      self._cached_size.height = math.floor(editor_height * float_opts.height)
    else
      self._cached_size.height = math.floor(float_opts.height)
    end
  elseif direction == 'horizontal' then
    self._cached_size.width = vim.o.columns
    self._cached_size.height = math.floor(size)
  elseif direction == 'vertical' then
    self._cached_size.width = math.floor(size)
    self._cached_size.height = vim.o.lines
  else -- tab
    self._cached_size.width = vim.o.columns
    self._cached_size.height = vim.o.lines
  end
  
  return self._cached_size.width, self._cached_size.height
end

---Create or get the terminal buffer
---Reuses existing buffer to avoid garbage
---@return number bufnr Buffer number
function Terminal:_get_or_create_buffer()
  -- Reuse existing buffer if valid
  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    return self.bufnr
  end
  
  -- Create new buffer
  self.bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options (minimal garbage)
  local buf_opts = {
    { 'buftype', 'terminal' },
    { 'bufhidden', 'hide' },
    { 'buflisted', false },
    { 'swapfile', false },
  }
  
  for _, opt in ipairs(buf_opts) do
    vim.api.nvim_buf_set_option(self.bufnr, opt[1], opt[2])
  end
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(self.bufnr, 'terminal://' .. self.bufnr)
  
  return self.bufnr
end

---Open the terminal window
---@return boolean success Whether window was successfully opened
function Terminal:_open_window()
  if self.state.is_open and self.winnr and vim.api.nvim_win_is_valid(self.winnr) then
    return true
  end
  
  local bufnr = self:_get_or_create_buffer()
  local direction = self.opts.direction
  
  -- Save current window
  local current_win = vim.api.nvim_get_current_win()
  
  if direction == 'float' then
    self:_open_float_window(bufnr)
  elseif direction == 'horizontal' then
    vim.cmd('botright split')
    self.winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.winnr, bufnr)
    local _, height = self:_calculate_size()
    vim.api.nvim_win_set_height(self.winnr, height)
  elseif direction == 'vertical' then
    vim.cmd('botright vsplit')
    self.winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.winnr, bufnr)
    local width, _ = self:_calculate_size()
    vim.api.nvim_win_set_width(self.winnr, width)
  elseif direction == 'tab' then
    vim.cmd('tabnew')
    self.winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.winnr, bufnr)
  end
  
  -- Set window-local options
  self:_set_window_options()
  
  self.state.is_open = true
  self.state.last_accessed = vim.loop.hrtime()
  
  -- Execute on_open callback
  if self.opts.on_open then
    self.opts.on_open(self)
  end
  
  return true
end

---Open floating window
---@param bufnr number Buffer to display
function Terminal:_open_float_window(bufnr)
  local float_opts = self.opts.float_opts
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width, height = self:_calculate_size()
  
  -- Calculate row and col (can be percentage or absolute)
  local row = float_opts.row
  local col = float_opts.col
  
  if row < 1 then
    row = math.floor(editor_height * row)
  end
  
  if col < 1 then
    col = math.floor(editor_width * col)
  end
  
  -- Create window config (reuse table structure)
  local win_config = {
    relative = float_opts.relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = float_opts.style,
    border = float_opts.border,
  }
  
  self.winnr = vim.api.nvim_open_win(bufnr, true, win_config)
end

---Set window-local options for terminal
function Terminal:_set_window_options()
  if not self.winnr or not vim.api.nvim_win_is_valid(self.winnr) then
    return
  end
  
  -- Window options (minimal allocations)
  local win_opts = {
    { 'number', false },
    { 'relativenumber', false },
    { 'signcolumn', 'no' },
    { 'spell', false },
    { 'wrap', false },
  }
  
  for _, opt in ipairs(win_opts) do
    vim.api.nvim_win_set_option(self.winnr, opt[1], opt[2])
  end
end

---Start the terminal process
---@return boolean success Whether process was started
function Terminal:_start_process()
  if self.state.is_running and self.jobnr then
    return true
  end
  
  local bufnr = self.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  
  -- Build job options
  local job_opts = {
    on_exit = function(job_id, exit_code, event_type)
      self:_on_exit(job_id, exit_code, event_type)
    end,
    cwd = self.opts.cwd,
    env = self.opts.env,
    clear_env = self.opts.clear_env,
  }
  
  -- Add stdout/stderr callbacks if provided
  if self.opts.on_stdout then
    job_opts.on_stdout = function(job_id, data, event)
      self.opts.on_stdout(self, job_id, data, event)
    end
  end
  
  if self.opts.on_stderr then
    job_opts.on_stderr = function(job_id, data, event)
      self.opts.on_stderr(self, job_id, data, event)
    end
  end
  
  -- Start terminal job
  vim.api.nvim_buf_call(bufnr, function()
    self.jobnr = vim.fn.termopen(self.cmd, job_opts)
  end)
  
  if self.jobnr > 0 then
    self.state.is_running = true
    self.state.exit_code = nil
    return true
  end
  
  return false
end

---Handle process exit
---@param job_id number Job ID
---@param exit_code number Exit code
---@param event_type string Event type
function Terminal:_on_exit(job_id, exit_code, event_type)
  self.state.is_running = false
  self.state.exit_code = exit_code
  
  -- Execute on_close callback
  if self.opts.on_close then
    self.opts.on_close(self, exit_code)
  end
  
  -- Close window if configured
  if self.opts.close_on_exit then
    self:close()
  end
end

---Open the terminal
---@return Terminal self For method chaining
function Terminal:open()
  -- Open window first
  if not self:_open_window() then
    vim.notify('Failed to open terminal window', vim.log.levels.ERROR)
    return self
  end
  
  -- Start process if not running
  if not self.state.is_running then
    if not self:_start_process() then
      vim.notify('Failed to start terminal process', vim.log.levels.ERROR)
      return self
    end
  end
  
  -- Enter insert mode if configured
  if self.opts.start_in_insert then
    vim.cmd('startinsert')
  end
  
  return self
end

---Close the terminal window (keeps buffer and process)
---@return Terminal self For method chaining
function Terminal:close()
  if self.winnr and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
  end
  
  self.state.is_open = false
  self.winnr = nil
  
  return self
end

---Toggle terminal visibility
---@return Terminal self For method chaining
function Terminal:toggle()
  if self.state.is_open then
    self:close()
  else
    self:open()
  end
  
  return self
end

---Send text to the terminal
---@param text string|string[] Text to send (string or array of lines)
---@return Terminal self For method chaining
function Terminal:send(text)
  if not self.jobnr or not self.state.is_running then
    vim.notify('Terminal is not running', vim.log.levels.WARN)
    return self
  end
  
  -- Convert to table if string
  if type(text) == 'string' then
    text = { text }
  end
  
  -- Send each line
  for _, line in ipairs(text) do
    vim.fn.chansend(self.jobnr, line .. '\n')
  end
  
  -- Auto-scroll if enabled
  if self.opts.auto_scroll and self.winnr and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_call(self.winnr, function()
      vim.cmd('normal! G')
    end)
  end
  
  return self
end

---Clear the terminal screen
---@return Terminal self For method chaining
function Terminal:clear()
  if self.state.is_running then
    self:send('\x0c') -- Ctrl-L to clear
  end
  return self
end

---Kill the terminal process
---@param signal number|nil Signal to send (default: 15/SIGTERM)
---@return Terminal self For method chaining
function Terminal:kill(signal)
  if self.jobnr and self.state.is_running then
    vim.fn.jobstop(self.jobnr)
    self.state.is_running = false
  end
  return self
end

---Destroy the terminal (close window, kill process, delete buffer)
---@return nil
function Terminal:destroy()
  -- Kill process
  self:kill()
  
  -- Close window
  self:close()
  
  -- Delete buffer
  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
  
  -- Clear references for garbage collection
  self.bufnr = nil
  self.winnr = nil
  self.jobnr = nil
end

---Check if terminal is open
---@return boolean is_open
function Terminal:is_open()
  return self.state.is_open and 
         self.winnr ~= nil and 
         vim.api.nvim_win_is_valid(self.winnr)
end

---Check if terminal process is running
---@return boolean is_running
function Terminal:is_running()
  return self.state.is_running
end

---Get terminal buffer number
---@return number|nil bufnr
function Terminal:get_bufnr()
  return self.bufnr
end

---Get terminal window number
---@return number|nil winnr
function Terminal:get_winnr()
  return self.winnr
end

---Focus the terminal window
---@return Terminal self For method chaining
function Terminal:focus()
  if self.winnr and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_set_current_win(self.winnr)
    
    if self.opts.start_in_insert then
      vim.cmd('startinsert')
    end
    
    self.state.last_accessed = vim.loop.hrtime()
  end
  
  return self
end

---Resize the terminal window
---@param size number|nil New size (uses default if nil)
---@return Terminal self For method chaining
function Terminal:resize(size)
  if not self.winnr or not vim.api.nvim_win_is_valid(self.winnr) then
    return self
  end
  
  if size then
    self.opts.size = size
  end
  
  local width, height = self:_calculate_size()
  
  if self.opts.direction == 'horizontal' then
    vim.api.nvim_win_set_height(self.winnr, height)
  elseif self.opts.direction == 'vertical' then
    vim.api.nvim_win_set_width(self.winnr, width)
  elseif self.opts.direction == 'float' then
    local config = vim.api.nvim_win_get_config(self.winnr)
    config.width = width
    config.height = height
    vim.api.nvim_win_set_config(self.winnr, config)
  end
  
  return self
end

return Terminal
