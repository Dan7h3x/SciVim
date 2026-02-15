-- Example configuration for terminal.nvim
-- Copy this to your Neovim config and customize as needed

local term = require('terminal')

-- Setup with custom configuration
term.setup({
  -- Default terminal direction
  default_direction = 'horizontal',
  
  -- Default size (15 rows for horizontal, 80 columns for vertical)
  default_size = 15,
  
  -- Close terminal when process exits
  close_on_exit = false,
  
  -- Auto-scroll to bottom on new output
  auto_scroll = true,
  
  -- Start in insert mode when opening
  start_in_insert = true,
  
  -- Default shell
  shell = vim.o.shell,
  
  -- Remember terminal sizes across toggles
  persist_size = true,
  
  -- Remember insert/normal mode state
  persist_mode = true,
})

-- ==============================================================================
-- KEYMAPS
-- ==============================================================================

-- Toggle main terminal (ID 1)
vim.keymap.set('n', '<C-\\>', function() term.toggle(1) end, { desc = 'Toggle terminal' })
vim.keymap.set('t', '<C-\\>', function() term.toggle(1) end, { desc = 'Toggle terminal' })

-- Quick terminal types
vim.keymap.set('n', '<leader>tf', term.float, { desc = 'Float terminal' })
vim.keymap.set('n', '<leader>th', term.horizontal, { desc = 'Horizontal terminal' })
vim.keymap.set('n', '<leader>tv', term.vertical, { desc = 'Vertical terminal' })
vim.keymap.set('n', '<leader>tt', term.tab, { desc = 'Tab terminal' })

-- Terminal navigation (from terminal mode)
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Go to left window' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Go to lower window' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Go to upper window' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Go to right window' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal selector
vim.keymap.set('n', '<leader>ts', term.select, { desc = 'Select terminal' })

-- Send code to terminal
vim.keymap.set('n', '<leader>sl', function() 
  term.send_line(1) 
end, { desc = 'Send line to terminal' })

vim.keymap.set('v', '<leader>ss', function() 
  term.send_selection(1) 
end, { desc = 'Send selection to terminal' })

-- Send custom command
vim.keymap.set('n', '<leader>sc', function()
  local cmd = vim.fn.input('Command: ')
  if cmd ~= '' then
    term.send(1, cmd)
  end
end, { desc = 'Send command to terminal' })

-- Close all terminals
vim.keymap.set('n', '<leader>tC', term.close_all, { desc = 'Close all terminals' })

-- Kill all terminals
vim.keymap.set('n', '<leader>tK', term.kill_all, { desc = 'Kill all terminals' })

-- ==============================================================================
-- CUSTOM TERMINALS
-- ==============================================================================

-- Python REPL
vim.keymap.set('n', '<leader>tp', function()
  term.toggle(2, 'python3', { 
    direction = 'vertical', 
    size = 80,
    start_in_insert = true,
  })
end, { desc = 'Python REPL' })

-- Node REPL
vim.keymap.set('n', '<leader>tn', function()
  term.toggle(3, 'node', { 
    direction = 'float',
    float_opts = {
      width = 0.7,
      height = 0.7,
      border = 'rounded',
    }
  })
end, { desc = 'Node REPL' })

-- Lazygit
vim.keymap.set('n', '<leader>tg', function()
  term.toggle(4, 'lazygit', { 
    direction = 'float',
    close_on_exit = true,
    float_opts = {
      width = 0.9,
      height = 0.9,
      border = 'rounded',
    },
    on_open = function(terminal)
      -- Hide line numbers in lazygit
      vim.wo[terminal:get_winnr()].number = false
      vim.wo[terminal:get_winnr()].relativenumber = false
    end,
  })
end, { desc = 'Lazygit' })

-- htop
vim.keymap.set('n', '<leader>tH', function()
  term.run('htop', { 
    direction = 'tab',
    close_on_exit = true,
  })
end, { desc = 'htop' })

-- ==============================================================================
-- DEVELOPMENT WORKFLOW
-- ==============================================================================

-- Example: Multi-terminal development setup
local function setup_dev_terminals()
  -- Terminal 1: Main shell (horizontal split)
  term.toggle(1, nil, { 
    direction = 'horizontal', 
    size = 15,
  })
  
  -- Terminal 2: Dev server (vertical split)
  term.toggle(2, 'npm run dev', { 
    direction = 'vertical', 
    size = 80,
    on_close = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify('Dev server exited with error', vim.log.levels.ERROR)
      end
    end,
  })
  
  -- Terminal 3: Test watcher (float)
  term.toggle(3, 'npm run test:watch', { 
    direction = 'float',
    float_opts = {
      width = 0.6,
      height = 0.6,
    },
    on_stdout = function(_, _, data)
      for _, line in ipairs(data) do
        if line:match('FAIL') then
          vim.notify('Test failed!', vim.log.levels.WARN)
        elseif line:match('PASS') then
          vim.notify('Tests passed!', vim.log.levels.INFO)
        end
      end
    end,
  })
end

vim.keymap.set('n', '<leader>td', setup_dev_terminals, { desc = 'Setup dev terminals' })

-- ==============================================================================
-- FILETYPE-SPECIFIC TERMINALS
-- ==============================================================================

-- Run current file based on filetype
vim.keymap.set('n', '<leader>tr', function()
  local ft = vim.bo.filetype
  local file = vim.fn.expand('%:p')
  local cmd = nil
  
  if ft == 'python' then
    cmd = 'python3 ' .. file
  elseif ft == 'javascript' or ft == 'typescript' then
    cmd = 'node ' .. file
  elseif ft == 'lua' then
    cmd = 'lua ' .. file
  elseif ft == 'sh' or ft == 'bash' then
    cmd = 'bash ' .. file
  elseif ft == 'ruby' then
    cmd = 'ruby ' .. file
  elseif ft == 'rust' then
    cmd = 'cargo run'
  elseif ft == 'go' then
    cmd = 'go run ' .. file
  end
  
  if cmd then
    term.run(cmd, {
      direction = 'horizontal',
      size = 15,
      close_on_exit = false,
    })
  else
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
  end
end, { desc = 'Run current file' })

-- ==============================================================================
-- AUTOCOMMANDS
-- ==============================================================================

-- Auto-insert mode for terminals
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
  end,
})

-- Exit insert mode when leaving terminal
vim.api.nvim_create_autocmd('BufLeave', {
  pattern = 'term://*',
  callback = function()
    vim.cmd('stopinsert')
  end,
})

-- ==============================================================================
-- CUSTOM COMMANDS
-- ==============================================================================

-- Quick terminal for command execution
vim.api.nvim_create_user_command('T', function(opts)
  term.run(opts.args, {
    direction = 'float',
    close_on_exit = false,
  })
end, {
  nargs = '+',
  desc = 'Run command in floating terminal',
})

-- Execute and capture output
vim.api.nvim_create_user_command('TE', function(opts)
  term.exec(opts.args, function(output)
    -- Display output in new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, buf)
  end)
end, {
  nargs = '+',
  desc = 'Execute command and show output in buffer',
})

-- ==============================================================================
-- ADVANCED: Custom Terminal Class Usage
-- ==============================================================================

-- Example of using the Terminal class directly for advanced use cases
local Terminal = require('terminal.terminal')

-- Create a custom log viewer terminal
local log_terminal = Terminal:new('tail -f /var/log/system.log', {
  direction = 'horizontal',
  size = 10,
  auto_scroll = true,
  on_stdout = function(self, _, data)
    -- Process log lines
    for _, line in ipairs(data) do
      if line:match('ERROR') then
        vim.notify('Error in logs!', vim.log.levels.ERROR)
      end
    end
  end,
})

vim.keymap.set('n', '<leader>tl', function()
  log_terminal:toggle()
end, { desc = 'Toggle log viewer' })

-- ==============================================================================
-- TIPS
-- ==============================================================================

--[[
Tips for using terminal.nvim:

1. Use different terminal IDs (1-9) for different purposes
2. Assign memorable keymaps for frequently used terminals
3. Use callbacks for automation (on_stdout, on_close)
4. Leverage send_line and send_selection for REPL workflows
5. Use float terminals for quick commands, splits for persistent shells
6. Customize float_opts for different terminal sizes
7. Set close_on_exit = true for one-off commands
8. Use the terminal selector (<leader>ts) to see all active terminals
9. Remember terminal state persists until you destroy them
10. Use term.manager to access advanced features
]]
