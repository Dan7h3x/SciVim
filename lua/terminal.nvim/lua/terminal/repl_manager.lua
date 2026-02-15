---@class ReplManager
---@field repls table<string, TerminalRepl> Map of language to REPL instance
---@field active_repl string|nil Currently active REPL language
---@field config ReplManagerConfig Manager configuration
local ReplManager = {}
ReplManager.__index = ReplManager

---@class ReplManagerConfig
---@field auto_start boolean Auto-start REPL when sending code
---@field auto_close boolean Auto-close REPL when buffer closes
---@field save_history boolean Save REPL history to file
---@field history_file string Path to history file
---@field keymaps table<string, string> Default keymaps
local ReplManager = {}
ReplManager.__index = ReplManager

---Default configuration
---@type ReplManagerConfig
ReplManager.default_config = {
  auto_start = true,
  auto_close = false,
  save_history = true,
  history_file = vim.fn.stdpath('data') .. '/terminal_repl_history',
  keymaps = {
    send_line = '<leader>rl',
    send_selection = '<leader>rs',
    send_paragraph = '<leader>rp',
    send_buffer = '<leader>rb',
    toggle_repl = '<leader>rt',
    clear_repl = '<leader>rc',
    interrupt = '<leader>ri',
    exit = '<leader>rq',
  },
}

---Create a new ReplManager instance
---@param config ReplManagerConfig|nil Configuration
---@return ReplManager
function ReplManager:new(config)
  ---@type ReplManager
  local instance = setmetatable({}, self)
  
  instance.repls = {}
  instance.active_repl = nil
  instance.config = vim.tbl_deep_extend('force', self.default_config, config or {})
  
  return instance
end

---Singleton instance
---@type ReplManager|nil
ReplManager._instance = nil

---Get singleton instance
---@param config ReplManagerConfig|nil Configuration (only on first call)
---@return ReplManager
function ReplManager:get_instance(config)
  if not ReplManager._instance then
    ReplManager._instance = ReplManager:new(config)
  end
  return ReplManager._instance
end

---Get or create REPL for language
---@param language string Programming language
---@param terminal_opts table|nil Terminal options
---@param repl_config table|nil REPL configuration
---@return TerminalRepl
function ReplManager:get_or_create(language, terminal_opts, repl_config)
  if not self.repls[language] then
    local TerminalRepl = require('terminal.repl')
    self.repls[language] = TerminalRepl:new(language, terminal_opts, repl_config)
  end
  
  self.active_repl = language
  return self.repls[language]
end

---Get REPL for language
---@param language string Programming language
---@return TerminalRepl|nil
function ReplManager:get(language)
  return self.repls[language]
end

---Get REPL for current buffer's filetype
---@return TerminalRepl|nil, string|nil language
function ReplManager:get_for_current_buffer()
  local ft = vim.bo.filetype
  local language = self:_filetype_to_language(ft)
  
  if not language then
    return nil, nil
  end
  
  return self.repls[language], language
end

---Get or create REPL for current buffer
---@param terminal_opts table|nil Terminal options
---@param repl_config table|nil REPL configuration
---@return TerminalRepl|nil, string|nil language
function ReplManager:get_or_create_for_buffer(terminal_opts, repl_config)
  local ft = vim.bo.filetype
  local language = self:_filetype_to_language(ft)
  
  if not language then
    vim.notify('No REPL available for filetype: ' .. ft, vim.log.levels.WARN)
    return nil, nil
  end
  
  local repl = self:get_or_create(language, terminal_opts, repl_config)
  return repl, language
end

---Map filetype to REPL language
---@param filetype string Neovim filetype
---@return string|nil language
function ReplManager:_filetype_to_language(filetype)
  local map = {
    python = 'python',
    javascript = 'node',
    typescript = 'node',
    javascriptreact = 'node',
    typescriptreact = 'node',
    lua = 'lua',
    ruby = 'ruby',
    julia = 'julia',
    r = 'r',
    sh = 'bash',
    bash = 'bash',
    zsh = 'zsh',
    scheme = 'scheme',
    racket = 'racket',
    clojure = 'clojure',
    haskell = 'haskell',
    scala = 'scala',
    ocaml = 'ocaml',
    elixir = 'elixir',
    erlang = 'erlang',
  }
  
  return map[filetype]
end

---Toggle REPL for language
---@param language string Programming language
---@param terminal_opts table|nil Terminal options
---@return boolean success
function ReplManager:toggle(language, terminal_opts)
  local repl = self:get_or_create(language, terminal_opts)
  repl:toggle()
  return true
end

---Toggle REPL for current buffer
---@param terminal_opts table|nil Terminal options
---@return boolean success
function ReplManager:toggle_for_buffer(terminal_opts)
  local repl, language = self:get_or_create_for_buffer(terminal_opts)
  
  if not repl then
    return false
  end
  
  repl:toggle()
  return true
end

---Send code to REPL
---@param language string Programming language
---@param code string|string[] Code to send
---@param opts table|nil Send options
---@return boolean success
function ReplManager:send(language, code, opts)
  local repl = self.repls[language]
  
  if not repl then
    if self.config.auto_start then
      repl = self:get_or_create(language)
      repl:open()
    else
      vim.notify('REPL for ' .. language .. ' is not running', vim.log.levels.WARN)
      return false
    end
  end
  
  repl:send(code, opts)
  return true
end

---Send line to appropriate REPL
---@param bufnr number|nil Buffer number
---@param linenr number|nil Line number
---@return boolean success
function ReplManager:send_line(bufnr, linenr)
  local repl, language = self:get_or_create_for_buffer()
  
  if not repl then
    return false
  end
  
  if not repl:is_running() then
    if self.config.auto_start then
      repl:open()
    else
      vim.notify('REPL is not running. Use :ReplStart', vim.log.levels.WARN)
      return false
    end
  end
  
  repl:send_line(bufnr, linenr)
  return true
end

---Send selection to appropriate REPL
---@return boolean success
function ReplManager:send_selection()
  local repl = self:get_or_create_for_buffer()
  
  if not repl then
    return false
  end
  
  if not repl:is_running() then
    if self.config.auto_start then
      repl:open()
    else
      vim.notify('REPL is not running. Use :ReplStart', vim.log.levels.WARN)
      return false
    end
  end
  
  repl:send_selection()
  return true
end

---Send paragraph to appropriate REPL
---@return boolean success
function ReplManager:send_paragraph()
  local repl = self:get_or_create_for_buffer()
  
  if not repl then
    return false
  end
  
  if not repl:is_running() then
    if self.config.auto_start then
      repl:open()
    else
      vim.notify('REPL is not running. Use :ReplStart', vim.log.levels.WARN)
      return false
    end
  end
  
  repl:send_paragraph()
  return true
end

---Send entire buffer to appropriate REPL
---@return boolean success
function ReplManager:send_buffer()
  local repl = self:get_or_create_for_buffer()
  
  if not repl then
    return false
  end
  
  if not repl:is_running() then
    if self.config.auto_start then
      repl:open()
    else
      vim.notify('REPL is not running. Use :ReplStart', vim.log.levels.WARN)
      return false
    end
  end
  
  repl:send_buffer()
  return true
end

---Clear REPL screen
---@param language string|nil Language (nil for current buffer's REPL)
---@return boolean success
function ReplManager:clear(language)
  local repl
  
  if language then
    repl = self.repls[language]
  else
    repl = self:get_for_current_buffer()
  end
  
  if not repl then
    return false
  end
  
  repl:clear()
  return true
end

---Interrupt REPL execution
---@param language string|nil Language (nil for current buffer's REPL)
---@return boolean success
function ReplManager:interrupt(language)
  local repl
  
  if language then
    repl = self.repls[language]
  else
    repl = self:get_for_current_buffer()
  end
  
  if not repl then
    return false
  end
  
  repl:interrupt()
  return true
end

---Exit REPL
---@param language string Language
---@return boolean success
function ReplManager:exit(language)
  local repl = self.repls[language]
  
  if not repl then
    return false
  end
  
  repl:exit()
  return true
end

---Destroy REPL
---@param language string Language
---@return boolean success
function ReplManager:destroy(language)
  local repl = self.repls[language]
  
  if not repl then
    return false
  end
  
  repl:destroy()
  self.repls[language] = nil
  
  if self.active_repl == language then
    self.active_repl = nil
  end
  
  return true
end

---Destroy all REPLs
function ReplManager:destroy_all()
  for language, repl in pairs(self.repls) do
    repl:destroy()
  end
  self.repls = {}
  self.active_repl = nil
end

---Get all active REPL languages
---@return string[] languages
function ReplManager:get_languages()
  local languages = {}
  for language, _ in pairs(self.repls) do
    table.insert(languages, language)
  end
  table.sort(languages)
  return languages
end

---Setup buffer-local keymaps for REPL
---@param bufnr number|nil Buffer number
function ReplManager:setup_buffer_keymaps(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  local opts = { buffer = bufnr, silent = true }
  local km = self.config.keymaps
  
  -- Send operations
  vim.keymap.set('n', km.send_line, function()
    self:send_line()
  end, vim.tbl_extend('force', opts, { desc = 'Send line to REPL' }))
  
  vim.keymap.set('v', km.send_selection, function()
    self:send_selection()
  end, vim.tbl_extend('force', opts, { desc = 'Send selection to REPL' }))
  
  vim.keymap.set('n', km.send_paragraph, function()
    self:send_paragraph()
  end, vim.tbl_extend('force', opts, { desc = 'Send paragraph to REPL' }))
  
  vim.keymap.set('n', km.send_buffer, function()
    self:send_buffer()
  end, vim.tbl_extend('force', opts, { desc = 'Send buffer to REPL' }))
  
  -- REPL control
  vim.keymap.set('n', km.toggle_repl, function()
    self:toggle_for_buffer()
  end, vim.tbl_extend('force', opts, { desc = 'Toggle REPL' }))
  
  vim.keymap.set('n', km.clear_repl, function()
    self:clear()
  end, vim.tbl_extend('force', opts, { desc = 'Clear REPL' }))
  
  vim.keymap.set('n', km.interrupt, function()
    self:interrupt()
  end, vim.tbl_extend('force', opts, { desc = 'Interrupt REPL' }))
  
  vim.keymap.set('n', km.exit, function()
    local _, language = self:get_for_current_buffer()
    if language then
      self:exit(language)
    end
  end, vim.tbl_extend('force', opts, { desc = 'Exit REPL' }))
end

---Setup autocommands for REPL management
function ReplManager:setup_autocommands()
  local group = vim.api.nvim_create_augroup('TerminalReplManager', { clear = true })
  
  -- Setup keymaps for supported filetypes
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = {
      'python', 'javascript', 'typescript', 'lua', 'ruby', 'julia', 'r',
      'sh', 'bash', 'zsh', 'scheme', 'racket', 'clojure', 'haskell',
      'scala', 'ocaml', 'elixir', 'erlang'
    },
    callback = function(args)
      self:setup_buffer_keymaps(args.buf)
    end,
  })
  
  -- Auto-close REPL when buffer closes
  if self.config.auto_close then
    vim.api.nvim_create_autocmd('BufDelete', {
      group = group,
      callback = function(args)
        local ft = vim.api.nvim_buf_get_option(args.buf, 'filetype')
        local language = self:_filetype_to_language(ft)
        
        if language then
          self:destroy(language)
        end
      end,
    })
  end
  
  -- Save history on VimLeavePre
  if self.config.save_history then
    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = group,
      callback = function()
        self:_save_history()
      end,
    })
  end
end

---Save REPL history to file
function ReplManager:_save_history()
  local history_data = {}
  
  for language, repl in pairs(self.repls) do
    if #repl.history > 0 then
      history_data[language] = repl.history
    end
  end
  
  if next(history_data) then
    local json = vim.fn.json_encode(history_data)
    vim.fn.writefile({ json }, self.config.history_file)
  end
end

---Load REPL history from file
function ReplManager:_load_history()
  if vim.fn.filereadable(self.config.history_file) == 1 then
    local lines = vim.fn.readfile(self.config.history_file)
    if #lines > 0 then
      local ok, history_data = pcall(vim.fn.json_decode, lines[1])
      if ok and type(history_data) == 'table' then
        for language, history in pairs(history_data) do
          if self.repls[language] then
            self.repls[language].history = history
            self.repls[language]._history_index = #history + 1
          end
        end
      end
    end
  end
end

return ReplManager
