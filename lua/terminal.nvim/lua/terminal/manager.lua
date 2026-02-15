---@class TerminalManager
---@field terminals table<number, Terminal> Map of terminal ID to Terminal instance
---@field _next_id number Next available terminal ID
---@field _active_id number|nil Currently active terminal ID
---@field config ManagerConfig Global configuration
local TerminalManager = {}
TerminalManager.__index = TerminalManager

---@class ManagerConfig
---@field default_direction string Default direction for new terminals
---@field default_size number Default size for new terminals
---@field close_on_exit boolean Default close_on_exit behavior
---@field auto_scroll boolean Default auto_scroll behavior
---@field start_in_insert boolean Default start_in_insert behavior
---@field shell string Default shell
---@field persist_size boolean Remember terminal sizes across toggles
---@field persist_mode boolean Remember insert/normal mode state

---Default manager configuration
---@type ManagerConfig
TerminalManager.default_config = {
  default_direction = 'horizontal',
  default_size = 15,
  close_on_exit = false,
  auto_scroll = true,
  start_in_insert = true,
  shell = vim.o.shell,
  persist_size = true,
  persist_mode = true,
}

---Create a new TerminalManager instance
---This is a singleton, use TerminalManager:get_instance() instead
---@param config ManagerConfig|nil Optional configuration
---@return TerminalManager
function TerminalManager:new(config)
  ---@type TerminalManager
  local instance = setmetatable({}, self)
  
  instance.terminals = {}
  instance._next_id = 1
  instance._active_id = nil
  instance.config = vim.tbl_deep_extend('force', self.default_config, config or {})
  
  return instance
end

---Singleton instance
---@type TerminalManager|nil
TerminalManager._instance = nil

---Get the singleton TerminalManager instance
---@param config ManagerConfig|nil Configuration (only used on first call)
---@return TerminalManager
function TerminalManager:get_instance(config)
  if not TerminalManager._instance then
    TerminalManager._instance = TerminalManager:new(config)
  end
  return TerminalManager._instance
end

---Create a new terminal and return its ID
---@param cmd string|nil Command to run
---@param opts TerminalOptions|nil Terminal options
---@return number terminal_id
function TerminalManager:create_terminal(cmd, opts)
  local Terminal = require('terminal.terminal')
  
  -- Merge with global config
  local merged_opts = vim.tbl_deep_extend('force', {
    direction = self.config.default_direction,
    size = self.config.default_size,
    close_on_exit = self.config.close_on_exit,
    auto_scroll = self.config.auto_scroll,
    start_in_insert = self.config.start_in_insert,
    shell = self.config.shell,
  }, opts or {})
  
  local terminal = Terminal:new(cmd, merged_opts)
  local id = self._next_id
  self.terminals[id] = terminal
  self._next_id = self._next_id + 1
  
  return id
end

---Get a terminal by ID
---@param id number Terminal ID
---@return Terminal|nil terminal
function TerminalManager:get_terminal(id)
  return self.terminals[id]
end

---Get or create a terminal by ID
---Creates a new terminal if ID doesn't exist
---@param id number Terminal ID
---@param cmd string|nil Command to run (if creating new)
---@param opts TerminalOptions|nil Terminal options (if creating new)
---@return Terminal terminal
function TerminalManager:get_or_create(id, cmd, opts)
  if not self.terminals[id] then
    -- Ensure the ID is used
    local new_id = self:create_terminal(cmd, opts)
    if new_id ~= id then
      -- Move terminal to requested ID
      self.terminals[id] = self.terminals[new_id]
      self.terminals[new_id] = nil
    end
  end
  return self.terminals[id]
end

---Open a terminal by ID
---@param id number Terminal ID
---@return boolean success
function TerminalManager:open_terminal(id)
  local terminal = self.terminals[id]
  if not terminal then
    vim.notify('Terminal ' .. id .. ' does not exist', vim.log.levels.ERROR)
    return false
  end
  
  terminal:open()
  self._active_id = id
  return true
end

---Close a terminal by ID
---@param id number Terminal ID
---@return boolean success
function TerminalManager:close_terminal(id)
  local terminal = self.terminals[id]
  if not terminal then
    return false
  end
  
  terminal:close()
  if self._active_id == id then
    self._active_id = nil
  end
  return true
end

---Toggle a terminal by ID
---@param id number Terminal ID
---@param cmd string|nil Command to run (if creating new)
---@param opts TerminalOptions|nil Terminal options (if creating new)
---@return boolean success
function TerminalManager:toggle_terminal(id, cmd, opts)
  local terminal = self:get_or_create(id, cmd, opts)
  terminal:toggle()
  
  if terminal:is_open() then
    self._active_id = id
  elseif self._active_id == id then
    self._active_id = nil
  end
  
  return true
end

---Send text to a terminal
---@param id number Terminal ID
---@param text string|string[] Text to send
---@return boolean success
function TerminalManager:send_to_terminal(id, text)
  local terminal = self.terminals[id]
  if not terminal then
    vim.notify('Terminal ' .. id .. ' does not exist', vim.log.levels.ERROR)
    return false
  end
  
  terminal:send(text)
  return true
end

---Destroy a terminal by ID
---@param id number Terminal ID
---@return boolean success
function TerminalManager:destroy_terminal(id)
  local terminal = self.terminals[id]
  if not terminal then
    return false
  end
  
  terminal:destroy()
  self.terminals[id] = nil
  
  if self._active_id == id then
    self._active_id = nil
  end
  
  return true
end

---Destroy all terminals
function TerminalManager:destroy_all()
  for id, terminal in pairs(self.terminals) do
    terminal:destroy()
  end
  self.terminals = {}
  self._active_id = nil
end

---Get all terminal IDs
---@return number[] ids
function TerminalManager:get_all_ids()
  local ids = {}
  for id, _ in pairs(self.terminals) do
    table.insert(ids, id)
  end
  table.sort(ids)
  return ids
end

---Get the currently active terminal ID
---@return number|nil active_id
function TerminalManager:get_active_id()
  return self._active_id
end

---Get the currently active terminal
---@return Terminal|nil terminal
function TerminalManager:get_active_terminal()
  if self._active_id then
    return self.terminals[self._active_id]
  end
  return nil
end

---Close all open terminals
function TerminalManager:close_all()
  for _, terminal in pairs(self.terminals) do
    if terminal:is_open() then
      terminal:close()
    end
  end
  self._active_id = nil
end

---Kill all running terminal processes
function TerminalManager:kill_all()
  for _, terminal in pairs(self.terminals) do
    if terminal:is_running() then
      terminal:kill()
    end
  end
end

---Get count of terminals
---@return number count
function TerminalManager:count()
  local count = 0
  for _ in pairs(self.terminals) do
    count = count + 1
  end
  return count
end

---Get count of open terminals
---@return number count
function TerminalManager:count_open()
  local count = 0
  for _, terminal in pairs(self.terminals) do
    if terminal:is_open() then
      count = count + 1
    end
  end
  return count
end

---Get count of running terminals
---@return number count
function TerminalManager:count_running()
  local count = 0
  for _, terminal in pairs(self.terminals) do
    if terminal:is_running() then
      count = count + 1
    end
  end
  return count
end

---Execute function for each terminal
---@param fn function(id: number, terminal: Terminal) Function to execute
function TerminalManager:for_each(fn)
  for id, terminal in pairs(self.terminals) do
    fn(id, terminal)
  end
end

---Find terminal by predicate
---@param predicate function(id: number, terminal: Terminal): boolean
---@return number|nil id, Terminal|nil terminal
function TerminalManager:find(predicate)
  for id, terminal in pairs(self.terminals) do
    if predicate(id, terminal) then
      return id, terminal
    end
  end
  return nil, nil
end

---Get terminal info for display
---@param id number Terminal ID
---@return table|nil info
function TerminalManager:get_info(id)
  local terminal = self.terminals[id]
  if not terminal then
    return nil
  end
  
  return {
    id = id,
    cmd = terminal.cmd,
    direction = terminal.opts.direction,
    is_open = terminal:is_open(),
    is_running = terminal:is_running(),
    bufnr = terminal:get_bufnr(),
    winnr = terminal:get_winnr(),
    exit_code = terminal.state.exit_code,
  }
end

---Get info for all terminals
---@return table[] infos
function TerminalManager:get_all_info()
  local infos = {}
  for id in pairs(self.terminals) do
    table.insert(infos, self:get_info(id))
  end
  
  -- Sort by ID
  table.sort(infos, function(a, b)
    return a.id < b.id
  end)
  
  return infos
end

return TerminalManager
