---@class TerminalUI
---@field manager TerminalManager Reference to terminal manager
---@field _select_buf number|nil Selection buffer number
---@field _select_win number|nil Selection window number
local TerminalUI = {}
TerminalUI.__index = TerminalUI

---Create a new TerminalUI instance
---@param manager TerminalManager Terminal manager instance
---@return TerminalUI
function TerminalUI:new(manager)
  ---@type TerminalUI
  local instance = setmetatable({}, self)
  instance.manager = manager
  instance._select_buf = nil
  instance._select_win = nil
  return instance
end

---Show terminal selector UI
---@param callback function|nil Callback when terminal is selected
function TerminalUI:show_selector(callback)
  local infos = self.manager:get_all_info()
  
  if #infos == 0 then
    vim.notify('No terminals available', vim.log.levels.INFO)
    return
  end
  
  -- Create buffer with terminal list
  local lines = { 'Terminal List:', '' }
  for _, info in ipairs(infos) do
    local status_icon = info.is_open and '●' or '○'
    local running_icon = info.is_running and '▶' or '■'
    local line = string.format(
      '[%d] %s %s %s (%s)',
      info.id,
      status_icon,
      running_icon,
      info.cmd,
      info.direction
    )
    table.insert(lines, line)
  end
  
  table.insert(lines, '')
  table.insert(lines, 'Press <CR> to toggle, d to destroy, q to close')
  
  -- Create floating window
  local width = 80
  local height = #lines + 2
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create buffer
  self._select_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(self._select_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self._select_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(self._select_buf, 'bufhidden', 'wipe')
  
  -- Create window
  self._select_win = vim.api.nvim_open_win(self._select_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(self._select_win, 'cursorline', true)
  vim.api.nvim_win_set_option(self._select_win, 'number', false)
  vim.api.nvim_win_set_option(self._select_win, 'relativenumber', false)
  
  -- Position cursor on first terminal
  vim.api.nvim_win_set_cursor(self._select_win, { 3, 0 })
  
  -- Set up keymaps
  self:_setup_selector_keymaps(callback)
end

---Setup keymaps for selector window
---@param callback function|nil Callback when terminal is selected
function TerminalUI:_setup_selector_keymaps(callback)
  local function close_selector()
    if self._select_win and vim.api.nvim_win_is_valid(self._select_win) then
      vim.api.nvim_win_close(self._select_win, true)
    end
    self._select_win = nil
    self._select_buf = nil
  end
  
  local function get_terminal_id_from_line()
    local line = vim.api.nvim_get_current_line()
    local id = line:match('%[(%d+)%]')
    return id and tonumber(id) or nil
  end
  
  -- Toggle terminal
  vim.keymap.set('n', '<CR>', function()
    local id = get_terminal_id_from_line()
    if id then
      self.manager:toggle_terminal(id)
      close_selector()
      if callback then
        callback(id)
      end
    end
  end, { buffer = self._select_buf, silent = true })
  
  -- Destroy terminal
  vim.keymap.set('n', 'd', function()
    local id = get_terminal_id_from_line()
    if id then
      self.manager:destroy_terminal(id)
      close_selector()
      -- Reopen selector with updated list
      self:show_selector(callback)
    end
  end, { buffer = self._select_buf, silent = true })
  
  -- Close selector
  vim.keymap.set('n', 'q', close_selector, { buffer = self._select_buf, silent = true })
  vim.keymap.set('n', '<Esc>', close_selector, { buffer = self._select_buf, silent = true })
end

---Display terminal information in a floating window
---@param id number Terminal ID
function TerminalUI:show_info(id)
  local info = self.manager:get_info(id)
  if not info then
    vim.notify('Terminal ' .. id .. ' does not exist', vim.log.levels.ERROR)
    return
  end
  
  local lines = {
    'Terminal Information',
    '==================',
    '',
    'ID: ' .. info.id,
    'Command: ' .. info.cmd,
    'Direction: ' .. info.direction,
    'Status: ' .. (info.is_open and 'Open' or 'Closed'),
    'Process: ' .. (info.is_running and 'Running' or 'Stopped'),
    'Buffer: ' .. (info.bufnr or 'N/A'),
    'Window: ' .. (info.winnr or 'N/A'),
  }
  
  if info.exit_code then
    table.insert(lines, 'Exit Code: ' .. info.exit_code)
  end
  
  -- Create floating window
  local width = 50
  local height = #lines + 2
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
  
  -- Close on <Esc> or q
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
end

---Show all terminals in a table format
function TerminalUI:show_all()
  local infos = self.manager:get_all_info()
  
  if #infos == 0 then
    vim.notify('No terminals available', vim.log.levels.INFO)
    return
  end
  
  local lines = {
    'All Terminals',
    '============',
    '',
    string.format('%-4s %-6s %-8s %-30s %-12s', 'ID', 'Open', 'Running', 'Command', 'Direction'),
    string.rep('-', 80),
  }
  
  for _, info in ipairs(infos) do
    local line = string.format(
      '%-4d %-6s %-8s %-30s %-12s',
      info.id,
      info.is_open and 'Yes' or 'No',
      info.is_running and 'Yes' or 'No',
      info.cmd:sub(1, 30),
      info.direction
    )
    table.insert(lines, line)
  end
  
  -- Create floating window
  local width = 85
  local height = math.min(#lines + 2, 25)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
  
  -- Close on <Esc> or q
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
end

return TerminalUI
