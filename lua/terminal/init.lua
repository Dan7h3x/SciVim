---Terminal.nvim - High-performance terminal plugin for Neovim
---@class TerminalNvim
---@field manager TerminalManager Terminal manager instance
---@field ui TerminalUI UI module instance
---@field config table Plugin configuration
local M = {}

---@type TerminalManager|nil
M.manager = nil

---@type TerminalUI|nil
M.ui = nil

---@type table
M.config = {}

---Setup the plugin with configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  opts = opts or {}
  
  -- Initialize manager
  local TerminalManager = require('terminal.manager')
  M.manager = TerminalManager:get_instance(opts)
  
  -- Initialize UI
  local TerminalUI = require('terminal.ui')
  M.ui = TerminalUI:new(M.manager)
  
  -- Store config
  M.config = M.manager.config
  
  -- Create user commands
  M._create_commands()
  
  -- Setup autocommands
  M._setup_autocommands()
end

---Create user commands
function M._create_commands()
  -- Toggle terminal by ID
  vim.api.nvim_create_user_command('TermToggle', function(opts)
    local id = tonumber(opts.args) or 1
    M.toggle(id)
  end, {
    nargs = '?',
    desc = 'Toggle terminal by ID',
  })
  
  -- Create new terminal
  vim.api.nvim_create_user_command('TermNew', function(opts)
    local id = M.create(opts.args ~= '' and opts.args or nil)
    M.open(id)
  end, {
    nargs = '?',
    desc = 'Create and open new terminal',
  })
  
  -- Open terminal by ID
  vim.api.nvim_create_user_command('TermOpen', function(opts)
    local id = tonumber(opts.args) or 1
    M.open(id)
  end, {
    nargs = '?',
    desc = 'Open terminal by ID',
  })
  
  -- Close terminal by ID
  vim.api.nvim_create_user_command('TermClose', function(opts)
    if opts.args == 'all' then
      M.close_all()
    else
      local id = tonumber(opts.args) or 1
      M.close(id)
    end
  end, {
    nargs = '?',
    desc = 'Close terminal by ID or all',
  })
  
  -- Kill terminal by ID
  vim.api.nvim_create_user_command('TermKill', function(opts)
    if opts.args == 'all' then
      M.kill_all()
    else
      local id = tonumber(opts.args) or 1
      M.kill(id)
    end
  end, {
    nargs = '?',
    desc = 'Kill terminal process by ID or all',
  })
  
  -- Destroy terminal by ID
  vim.api.nvim_create_user_command('TermDestroy', function(opts)
    if opts.args == 'all' then
      M.destroy_all()
    else
      local id = tonumber(opts.args) or 1
      M.destroy(id)
    end
  end, {
    nargs = '?',
    desc = 'Destroy terminal by ID or all',
  })
  
  -- Show terminal selector
  vim.api.nvim_create_user_command('TermSelect', function()
    M.select()
  end, {
    desc = 'Show terminal selector',
  })
  
  -- Show terminal info
  vim.api.nvim_create_user_command('TermInfo', function(opts)
    if opts.args == 'all' then
      M.ui:show_all()
    else
      local id = tonumber(opts.args) or 1
      M.ui:show_info(id)
    end
  end, {
    nargs = '?',
    desc = 'Show terminal info',
  })
  
  -- Send command to terminal
  vim.api.nvim_create_user_command('TermSend', function(opts)
    local parts = vim.split(opts.args, ' ', { plain = false, trimempty = true })
    local id = tonumber(parts[1]) or 1
    local cmd = table.concat(vim.list_slice(parts, 2), ' ')
    M.send(id, cmd)
  end, {
    nargs = '+',
    desc = 'Send command to terminal',
  })
end

---Setup autocommands
function M._setup_autocommands()
  local group = vim.api.nvim_create_augroup('TerminalNvim', { clear = true })
  
  -- Clean up on VimLeavePre
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      M.kill_all()
    end,
    desc = 'Kill all terminal processes on exit',
  })
end

---Create a new terminal
---@param cmd string|nil Command to run
---@param opts table|nil Terminal options
---@return number id Terminal ID
function M.create(cmd, opts)
  if not M.manager then
    M.setup()
  end
  return M.manager:create_terminal(cmd, opts)
end

---Open a terminal by ID
---@param id number Terminal ID
---@param cmd string|nil Command to run (if creating new)
---@param opts table|nil Terminal options (if creating new)
---@return boolean success
function M.open(id, cmd, opts)
  if not M.manager then
    M.setup()
  end
  
  -- Get or create terminal
  M.manager:get_or_create(id, cmd, opts)
  return M.manager:open_terminal(id)
end

---Close a terminal by ID
---@param id number Terminal ID
---@return boolean success
function M.close(id)
  if not M.manager then
    return false
  end
  return M.manager:close_terminal(id)
end

---Toggle a terminal by ID
---@param id number Terminal ID
---@param cmd string|nil Command to run (if creating new)
---@param opts table|nil Terminal options (if creating new)
---@return boolean success
function M.toggle(id, cmd, opts)
  if not M.manager then
    M.setup()
  end
  return M.manager:toggle_terminal(id, cmd, opts)
end

---Send text to a terminal
---@param id number Terminal ID
---@param text string|string[] Text to send
---@return boolean success
function M.send(id, text)
  if not M.manager then
    return false
  end
  return M.manager:send_to_terminal(id, text)
end

---Kill a terminal process
---@param id number Terminal ID
---@return boolean success
function M.kill(id)
  if not M.manager then
    return false
  end
  
  local terminal = M.manager:get_terminal(id)
  if terminal then
    terminal:kill()
    return true
  end
  return false
end

---Destroy a terminal
---@param id number Terminal ID
---@return boolean success
function M.destroy(id)
  if not M.manager then
    return false
  end
  return M.manager:destroy_terminal(id)
end

---Close all terminals
function M.close_all()
  if M.manager then
    M.manager:close_all()
  end
end

---Kill all terminal processes
function M.kill_all()
  if M.manager then
    M.manager:kill_all()
  end
end

---Destroy all terminals
function M.destroy_all()
  if M.manager then
    M.manager:destroy_all()
  end
end

---Show terminal selector
function M.select()
  if not M.ui then
    M.setup()
  end
  M.ui:show_selector()
end

---Get terminal by ID
---@param id number Terminal ID
---@return Terminal|nil terminal
function M.get_terminal(id)
  if not M.manager then
    return nil
  end
  return M.manager:get_terminal(id)
end

---Get all terminal IDs
---@return number[] ids
function M.get_all_ids()
  if not M.manager then
    return {}
  end
  return M.manager:get_all_ids()
end

---Get terminal count
---@return number count
function M.count()
  if not M.manager then
    return 0
  end
  return M.manager:count()
end

---Convenience functions for quick access

---Toggle floating terminal
---@param cmd string|nil Command to run
function M.float(cmd)
  M.toggle(1, cmd, { direction = 'float' })
end

---Toggle horizontal terminal
---@param cmd string|nil Command to run
function M.horizontal(cmd)
  M.toggle(1, cmd, { direction = 'horizontal' })
end

---Toggle vertical terminal
---@param cmd string|nil Command to run
function M.vertical(cmd)
  M.toggle(1, cmd, { direction = 'vertical' })
end

---Toggle tab terminal
---@param cmd string|nil Command to run
function M.tab(cmd)
  M.toggle(1, cmd, { direction = 'tab' })
end

---Send current line to terminal
---@param id number|nil Terminal ID (default: 1)
function M.send_line(id)
  id = id or 1
  local line = vim.api.nvim_get_current_line()
  M.send(id, line)
end

---Send visual selection to terminal
---@param id number|nil Terminal ID (default: 1)
function M.send_selection(id)
  id = id or 1
  
  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  
  -- Get lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  -- Send to terminal
  M.send(id, lines)
end

---Run a command in a new terminal and close when done
---@param cmd string Command to run
---@param opts table|nil Terminal options
function M.run(cmd, opts)
  opts = opts or {}
  opts.close_on_exit = true
  local id = M.create(cmd, opts)
  M.open(id)
end

---Execute a command and capture output
---@param cmd string Command to run
---@param callback function Callback with output
function M.exec(cmd, callback)
  local output = {}
  
  local opts = {
    direction = 'float',
    close_on_exit = true,
    on_stdout = function(_, _, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(output, line)
        end
      end
    end,
    on_close = function()
      callback(output)
    end,
  }
  
  local id = M.create(cmd, opts)
  M.open(id)
end

return M
