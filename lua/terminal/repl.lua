---@class TerminalRepl
---@field terminal Terminal Terminal instance
---@field language string Programming language
---@field config ReplConfig REPL configuration
---@field history string[] Command history
---@field _history_index number Current history position
---@field _temp_files table<string, string> Temporary files for code execution
local TerminalRepl = {}
TerminalRepl.__index = TerminalRepl

---@class ReplConfig
---@field command string REPL command to execute
---@field prompt_pattern string Pattern to detect REPL prompt
---@field startup_commands string[] Commands to run on REPL start
---@field setup_code string Code to run before first command
---@field teardown_code string Code to run on REPL close
---@field code_wrapper function|nil Function to wrap code before sending
---@field result_pattern string|nil Pattern to extract results
---@field error_pattern string|nil Pattern to detect errors
---@field multiline_start string|nil Start marker for multiline input
---@field multiline_end string|nil End marker for multiline input
---@field clear_command string|nil Command to clear REPL screen
---@field interrupt_sequence string Key sequence to interrupt execution
---@field auto_import boolean Auto-import common libraries
---@field bracketed_paste boolean Use bracketed paste mode

---Language-specific REPL configurations
---@type table<string, ReplConfig>
TerminalRepl.language_configs = {
  python = {
    command = 'python3 -i',
    prompt_pattern = '>>> ',
    startup_commands = {},
    setup_code = 'import sys; sys.ps1 = ">>> "; sys.ps2 = "... "',
    teardown_code = 'exit()',
    code_wrapper = function(code)
      -- Handle indentation for Python
      return code
    end,
    result_pattern = nil,
    error_pattern = 'Traceback|Error|Exception',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'import os; os.system("clear")',
    interrupt_sequence = '\x03',  -- Ctrl-C
    auto_import = true,
    bracketed_paste = true,
  },
  
  ipython = {
    command = 'ipython --no-banner --no-confirm-exit',
    prompt_pattern = 'In \\[%d+\\]:',
    startup_commands = {
      '%colors Linux',
      '%matplotlib inline',
    },
    setup_code = nil,
    teardown_code = 'exit',
    code_wrapper = function(code)
      -- IPython handles code well, just send it
      return code
    end,
    result_pattern = 'Out\\[%d+\\]:',
    error_pattern = 'Error|Exception',
    multiline_start = '%cpaste',
    multiline_end = '--',
    clear_command = 'clear',
    interrupt_sequence = '\x03',
    auto_import = true,
    bracketed_paste = true,
  },
  
  node = {
    command = 'node',
    prompt_pattern = '> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = '.exit',
    code_wrapper = function(code)
      -- Wrap in IIFE for clean scope
      if code:match('async') or code:match('await') then
        return '(async () => { ' .. code .. ' })()'
      end
      return code
    end,
    result_pattern = nil,
    error_pattern = 'Error|Exception',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'console.clear()',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  lua = {
    command = 'lua',
    prompt_pattern = '> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = 'os.exit()',
    code_wrapper = function(code)
      -- Handle return values
      if not code:match('^return') and not code:match('=') then
        return '= ' .. code
      end
      return code
    end,
    result_pattern = nil,
    error_pattern = 'error|Error',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'os.execute("clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  ruby = {
    command = 'irb',
    prompt_pattern = 'irb%(%w+%):(%d+):(%d+)> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = 'exit',
    code_wrapper = nil,
    result_pattern = '=> ',
    error_pattern = 'Error|Exception',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'system("clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  julia = {
    command = 'julia',
    prompt_pattern = 'julia> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = 'exit()',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = 'ERROR|Exception',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'run(`clear`)',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  r = {
    command = 'R --quiet --no-save',
    prompt_pattern = '> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = 'q(save="no")',
    code_wrapper = nil,
    result_pattern = '\\[%d+\\]',
    error_pattern = 'Error|Warning',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'system("clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  bash = {
    command = 'bash',
    prompt_pattern = '$ ',
    startup_commands = { 'PS1="$ "' },
    setup_code = nil,
    teardown_code = 'exit',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = nil,
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'clear',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  zsh = {
    command = 'zsh',
    prompt_pattern = '$ ',
    startup_commands = { 'PS1="$ "' },
    setup_code = nil,
    teardown_code = 'exit',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = nil,
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'clear',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  scheme = {
    command = 'guile',
    prompt_pattern = 'scheme@%(%w+%)> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = ',quit',
    code_wrapper = nil,
    result_pattern = '\\$%d+ = ',
    error_pattern = 'ERROR|Backtrace',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = '(system "clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  racket = {
    command = 'racket',
    prompt_pattern = '> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = '(exit)',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = 'error',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = '(system "clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  clojure = {
    command = 'clojure',
    prompt_pattern = 'user=> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = '(System/exit 0)',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = 'Exception|Error',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = '(clojure.java.shell/sh "clear")',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  haskell = {
    command = 'ghci',
    prompt_pattern = 'Prelude> ',
    startup_commands = { ':set prompt "λ> "' },
    setup_code = nil,
    teardown_code = ':quit',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = 'error|Exception',
    multiline_start = ':{',
    multiline_end = ':}',
    clear_command = ':!clear',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  scala = {
    command = 'scala',
    prompt_pattern = 'scala> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = ':quit',
    code_wrapper = nil,
    result_pattern = 'res%d+:',
    error_pattern = 'error|Error',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = nil,
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  ocaml = {
    command = 'ocaml',
    prompt_pattern = '# ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = '#quit;;',
    code_wrapper = nil,
    result_pattern = '- :',
    error_pattern = 'Error',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = nil,
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
  
  elixir = {
    command = 'iex',
    prompt_pattern = 'iex%(%d+%)> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = nil,  -- Ctrl-C twice
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = '\\*\\* %(%w+Error%)',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'IO.puts(IO.ANSI.clear())',
    interrupt_sequence = '\x03\x03',
    auto_import = false,
    bracketed_paste = true,
  },
  
  erlang = {
    command = 'erl',
    prompt_pattern = '%d+> ',
    startup_commands = {},
    setup_code = nil,
    teardown_code = 'q().',
    code_wrapper = nil,
    result_pattern = nil,
    error_pattern = '\\*\\* exception',
    multiline_start = nil,
    multiline_end = nil,
    clear_command = 'io:format("\\e[H\\e[2J").',
    interrupt_sequence = '\x03',
    auto_import = false,
    bracketed_paste = false,
  },
}

---Create a new REPL instance
---@param language string Programming language
---@param terminal_opts table|nil Terminal options
---@param repl_config ReplConfig|nil Custom REPL configuration
---@return TerminalRepl
function TerminalRepl:new(language, terminal_opts, repl_config)
  local Terminal = require('terminal.terminal')
  
  -- Get language config
  local base_config = self.language_configs[language]
  if not base_config then
    error('Unsupported language: ' .. language)
  end
  
  -- Merge with custom config
  local config = vim.tbl_deep_extend('force', base_config, repl_config or {})
  
  -- Merge terminal options with defaults
  local default_term_opts = {
    direction = 'vertical',
    size = 80,
    start_in_insert = true,
    auto_scroll = true,
  }
  terminal_opts = vim.tbl_deep_extend('force', default_term_opts, terminal_opts or {})
  
  -- Create terminal
  local terminal = Terminal:new(config.command, terminal_opts)
  
  ---@type TerminalRepl
  local instance = setmetatable({}, self)
  instance.terminal = terminal
  instance.language = language
  instance.config = config
  instance.history = {}
  instance._history_index = 0
  instance._temp_files = {}
  
  -- Setup REPL after terminal opens
  if terminal_opts.on_open then
    local original_on_open = terminal_opts.on_open
    terminal.opts.on_open = function(term)
      original_on_open(term)
      instance:_setup_repl()
    end
  else
    terminal.opts.on_open = function(term)
      instance:_setup_repl()
    end
  end
  
  return instance
end

---Setup REPL environment
function TerminalRepl:_setup_repl()
  -- Wait for REPL to be ready
  vim.defer_fn(function()
    -- Run startup commands
    for _, cmd in ipairs(self.config.startup_commands) do
      self.terminal:send(cmd)
    end
    
    -- Run setup code
    if self.config.setup_code then
      self.terminal:send(self.config.setup_code)
    end
    
    -- Auto-import common libraries
    if self.config.auto_import then
      self:_auto_import_libraries()
    end
  end, 100)
end

---Auto-import common libraries based on language
function TerminalRepl:_auto_import_libraries()
  if self.language == 'python' then
    local imports = {
      'import numpy as np',
      'import pandas as pd',
      'import matplotlib.pyplot as plt',
    }
    for _, imp in ipairs(imports) do
      self.terminal:send(imp)
    end
  elseif self.language == 'ipython' then
    local imports = {
      'import numpy as np',
      'import pandas as pd',
      'import matplotlib.pyplot as plt',
      'from pathlib import Path',
    }
    for _, imp in ipairs(imports) do
      self.terminal:send(imp)
    end
  end
end

---Open the REPL
---@return TerminalRepl self
function TerminalRepl:open()
  self.terminal:open()
  return self
end

---Close the REPL
---@return TerminalRepl self
function TerminalRepl:close()
  self.terminal:close()
  return self
end

---Toggle REPL visibility
---@return TerminalRepl self
function TerminalRepl:toggle()
  self.terminal:toggle()
  return self
end

---Send code to REPL
---@param code string|string[] Code to send
---@param opts table|nil Options: { multiline: boolean, wrap: boolean }
---@return TerminalRepl self
function TerminalRepl:send(code, opts)
  opts = opts or {}
  
  -- Convert to table if string
  if type(code) == 'string' then
    code = { code }
  end
  
  -- Join lines
  local code_str = table.concat(code, '\n')
  
  -- Wrap code if configured
  if opts.wrap ~= false and self.config.code_wrapper then
    code_str = self.config.code_wrapper(code_str)
  end
  
  -- Add to history
  table.insert(self.history, code_str)
  self._history_index = #self.history + 1
  
  -- Handle multiline input
  if opts.multiline and self.config.multiline_start then
    self.terminal:send(self.config.multiline_start)
    self.terminal:send(code_str)
    self.terminal:send(self.config.multiline_end)
  elseif self.config.bracketed_paste and #code > 1 then
    -- Use bracketed paste for multiple lines
    self:_send_bracketed_paste(code_str)
  else
    -- Send line by line
    for _, line in ipairs(code) do
      self.terminal:send(line)
    end
  end
  
  return self
end

---Send code using bracketed paste mode
---@param code string Code to send
function TerminalRepl:_send_bracketed_paste(code)
  -- Start bracketed paste
  self.terminal:send('\x1b[200~' .. code .. '\x1b[201~')
end

---Send current line from buffer
---@param bufnr number|nil Buffer number (default: current)
---@param linenr number|nil Line number (default: current)
---@return TerminalRepl self
function TerminalRepl:send_line(bufnr, linenr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  linenr = linenr or vim.api.nvim_win_get_cursor(0)[1]
  
  local line = vim.api.nvim_buf_get_lines(bufnr, linenr - 1, linenr, false)[1]
  
  if line and line ~= '' then
    self:send(line)
  end
  
  return self
end

---Send visual selection
---@return TerminalRepl self
function TerminalRepl:send_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines > 0 then
    self:send(lines, { multiline = #lines > 1 })
  end
  
  return self
end

---Send entire buffer or range
---@param start_line number|nil Start line (default: 1)
---@param end_line number|nil End line (default: last)
---@return TerminalRepl self
function TerminalRepl:send_buffer(start_line, end_line)
  start_line = start_line or 1
  end_line = end_line or vim.api.nvim_buf_line_count(0)
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines > 0 then
    self:send(lines, { multiline = #lines > 1 })
  end
  
  return self
end

---Send paragraph (current blank-line separated block)
---@return TerminalRepl self
function TerminalRepl:send_paragraph()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Find start of paragraph
  local start_line = current_line
  while start_line > 1 do
    local line = vim.api.nvim_buf_get_lines(0, start_line - 2, start_line - 1, false)[1]
    if line == '' then
      break
    end
    start_line = start_line - 1
  end
  
  -- Find end of paragraph
  local end_line = current_line
  while end_line < total_lines do
    local line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]
    if line == '' then
      break
    end
    end_line = end_line + 1
  end
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines > 0 then
    self:send(lines, { multiline = #lines > 1 })
  end
  
  return self
end

---Clear REPL screen
---@return TerminalRepl self
function TerminalRepl:clear()
  if self.config.clear_command then
    self.terminal:send(self.config.clear_command)
  else
    self.terminal:clear()
  end
  return self
end

---Interrupt current execution
---@return TerminalRepl self
function TerminalRepl:interrupt()
  if self.config.interrupt_sequence then
    self.terminal:send(self.config.interrupt_sequence)
  end
  return self
end

---Exit the REPL
---@return TerminalRepl self
function TerminalRepl:exit()
  if self.config.teardown_code then
    self.terminal:send(self.config.teardown_code)
  else
    self.terminal:kill()
  end
  return self
end

---Get command from history
---@param offset number Offset from current position (negative = backward)
---@return string|nil command
function TerminalRepl:history_get(offset)
  local index = self._history_index + offset
  if index >= 1 and index <= #self.history then
    self._history_index = index
    return self.history[index]
  end
  return nil
end

---Navigate history backward
---@return string|nil command
function TerminalRepl:history_prev()
  return self:history_get(-1)
end

---Navigate history forward
---@return string|nil command
function TerminalRepl:history_next()
  return self:history_get(1)
end

---Clear history
---@return TerminalRepl self
function TerminalRepl:history_clear()
  self.history = {}
  self._history_index = 0
  return self
end

---Execute file in REPL
---@param filepath string Path to file
---@return TerminalRepl self
function TerminalRepl:execute_file(filepath)
  if self.language == 'python' or self.language == 'ipython' then
    self:send('exec(open("' .. filepath .. '").read())')
  elseif self.language == 'node' then
    self:send('.load ' .. filepath)
  elseif self.language == 'lua' then
    self:send('dofile("' .. filepath .. '")')
  elseif self.language == 'ruby' then
    self:send('load "' .. filepath .. '"')
  elseif self.language == 'julia' then
    self:send('include("' .. filepath .. '")')
  elseif self.language == 'r' then
    self:send('source("' .. filepath .. '")')
  elseif self.language == 'haskell' then
    self:send(':load ' .. filepath)
  else
    -- Generic approach
    local lines = vim.fn.readfile(filepath)
    self:send(lines, { multiline = true })
  end
  
  return self
end

---Save current buffer to temp file and execute
---@return TerminalRepl self
function TerminalRepl:execute_buffer()
  -- Create temp file
  local extension = self:_get_file_extension()
  local tmpfile = vim.fn.tempname() .. extension
  
  -- Save buffer to temp file
  vim.cmd('write! ' .. tmpfile)
  
  -- Store temp file reference
  self._temp_files[tmpfile] = true
  
  -- Execute file
  self:execute_file(tmpfile)
  
  return self
end

---Get file extension for language
---@return string extension
function TerminalRepl:_get_file_extension()
  local extensions = {
    python = '.py',
    ipython = '.py',
    node = '.js',
    lua = '.lua',
    ruby = '.rb',
    julia = '.jl',
    r = '.R',
    bash = '.sh',
    zsh = '.sh',
    haskell = '.hs',
    scala = '.scala',
    ocaml = '.ml',
    elixir = '.exs',
    erlang = '.erl',
    clojure = '.clj',
    scheme = '.scm',
    racket = '.rkt',
  }
  return extensions[self.language] or '.txt'
end

---Clean up temp files
function TerminalRepl:cleanup_temp_files()
  for tmpfile, _ in pairs(self._temp_files) do
    if vim.fn.filereadable(tmpfile) == 1 then
      vim.fn.delete(tmpfile)
    end
  end
  self._temp_files = {}
end

---Destroy REPL completely
function TerminalRepl:destroy()
  self:cleanup_temp_files()
  self.terminal:destroy()
end

---Check if REPL is running
---@return boolean
function TerminalRepl:is_running()
  return self.terminal:is_running()
end

---Focus REPL window
---@return TerminalRepl self
function TerminalRepl:focus()
  self.terminal:focus()
  return self
end

return TerminalRepl
