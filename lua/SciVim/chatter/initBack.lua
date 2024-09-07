local api = vim.api
local fn = vim.fn
local Job = require('plenary.job')
local curl = require('plenary.curl')
local fzf = require('fzf-lua')

local Chatter = {}
Chatter.__index = Chatter

-- Default configuration
local default_config = {
  offline_api_url = os.getenv("OLLAMA_HOST") or "http://localhost:8888",
  sidebar_width = 60,
  sidebar_height = vim.o.lines - 12,
  models = {},
  highlight = {
    title = "Title",
    user = "Comment",
    assistant = "String",
    system = "Type",
    error = "ErrorMsg",
    loading = "WarningMsg", -- New highlight group for loading animation

  }
}

function Chatter.new(user_config)
  local self = setmetatable({}, Chatter)
  self.config = vim.tbl_deep_extend("force", default_config, user_config or {})
  self.sidebar_bufnr = nil
  self.sidebar_winid = nil
  self.chat_history = {}
  self.current_model = nil
  self.ollama_job = nil
  return self
end

function Chatter:send_chat_message(message)
  if not self.current_model then
    self:notify("No model selected. Please start a chat first.", vim.log.levels.ERROR)
    return
  end

  table.insert(self.chat_history, { role = "user", content = message })
  self:update_chat_display()
  self:start_loading_animation()

  local body = fn.json_encode({
    model = self.current_model,
    prompt = message,
    stream = false
  })

  curl.post(self.config.offline_api_url .. "/api/generate", {
    body = body,
    headers = { ["Content-Type"] = "application/json" },
    callback = vim.schedule_wrap(function(response)
      self:stop_loading_animation()

      if response.status == 200 then
        local ok, decoded = pcall(fn.json_decode, response.body)
        if ok and decoded.response then
          table.insert(self.chat_history, { role = "assistant", content = decoded.response })
          self:update_chat_display()
        else
          self:notify("Failed to decode API response: " .. vim.inspect(response.body), vim.log.levels.ERROR)
        end
      else
        self:notify("API request failed: " .. response.status .. " - " .. vim.inspect(response.body),
          vim.log.levels.ERROR)
      end
    end)
  })
end

function Chatter:start_loading_animation()
  self.loading = true
  self.loading_frame = 0
  self.loading_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  self.loading_timer = vim.loop.new_timer()
  self.loading_timer:start(0, 100, vim.schedule_wrap(function()
    if not self.loading then return end
    self.loading_frame = (self.loading_frame + 1) % #self.loading_frames
    self:update_loading_display()
  end))
end

function Chatter:stop_loading_animation()
  self.loading = false
  if self.loading_timer then
    self.loading_timer:stop()
    self.loading_timer:close()
    self.loading_timer = nil
  end
  self:update_chat_display()
end

function Chatter:update_loading_display()
  if not self.sidebar_bufnr or not api.nvim_buf_is_valid(self.sidebar_bufnr) then return end

  local lines = api.nvim_buf_get_lines(self.sidebar_bufnr, 0, -1, false)
  local last_line = #lines
  local loading_text = self.loading_frames[self.loading_frame + 1] .. " Waiting for response..."

  api.nvim_set_option_value("modifiable", true, { buf = self.sidebar_bufnr })
  api.nvim_buf_set_lines(self.sidebar_bufnr, last_line - 1, last_line, false, { loading_text })
  api.nvim_set_option_value("modifiable", false, { buf = self.sidebar_bufnr })

  -- Apply loading animation highlight
  api.nvim_buf_add_highlight(self.sidebar_bufnr, -1, self.config.highlight.loading, last_line - 1, 0, -1)

  if self.sidebar_winid and api.nvim_win_is_valid(self.sidebar_winid) then
    api.nvim_win_set_cursor(self.sidebar_winid, { last_line, 0 })
  end
end

function Chatter:update_chat_display()
  if not self.sidebar_bufnr or not api.nvim_buf_is_valid(self.sidebar_bufnr) then return end

  local lines = {}
  -- Add title
  local title = string.format("#Chatter - Model: %s", self.current_model or "Not Selected")
  local padding = math.floor((self.config.sidebar_width - #title) / 2)
  table.insert(lines, string.rep(" ", padding) .. title)
  table.insert(lines, "##Hint: press `i` to send message,`<C-c>` to clear chat. ##")
  table.insert(lines, "##Hint: press `<C-r>` to reload and select model again + <C-c> to refresh chat. ##")
  table.insert(lines, "=========================================")

  for _, msg in ipairs(self.chat_history) do
    table.insert(lines, string.format("### %s:", msg.role:upper()))
    vim.list_extend(lines, vim.split(msg.content, "\n"))
    table.insert(lines, "")
  end

  -- Add an empty line for the loading animation
  table.insert(lines, "")

  api.nvim_set_option_value("modifiable", true, { buf = self.sidebar_bufnr })
  api.nvim_buf_set_lines(self.sidebar_bufnr, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = self.sidebar_bufnr })
  api.nvim_set_option_value("filetype", "markdown", { buf = self.sidebar_bufnr })
  api.nvim_buf_add_highlight(self.sidebar_bufnr, -1, self.config.highlight.title, 0, 0, -1)
  for i, msg in ipairs(self.chat_history) do
    local line_num = i * 3 -- Adjust for title and empty lines
    api.nvim_buf_add_highlight(self.sidebar_bufnr, -1, self.config.highlight[msg.role], line_num, 0, -1)
  end

  if self.sidebar_winid and api.nvim_win_is_valid(self.sidebar_winid) then
    local last_line = api.nvim_buf_line_count(self.sidebar_bufnr)
    pcall(api.nvim_win_set_cursor, self.sidebar_winid, { last_line, 0 })
  end
end

-- function Chatter:update_chat_display()
--   if not self.sidebar_bufnr or not api.nvim_buf_is_valid(self.sidebar_bufnr) then return end
--
--   local lines = {}
--   -- Add centered title
--   local title = string.format("#Chatter - Model: %s", self.current_model or "Not Selected")
--   local padding = math.floor((self.config.sidebar_width - #title) / 2)
--   table.insert(lines, string.rep(" ", padding) .. title)
--   table.insert(lines, "")
--   table.insert(lines, "Hint: press `i` to send message.")
--   table.insert(lines, "Hint: press `<C-c>` to clear chat.")
--   table.insert(lines, "Hint: press `<C-r>` to reload and select model again + <C-c> to refresh chat.")
--   table.insert(lines, string.rep("=", self.config.sidebar_width))
--
--   for _, msg in ipairs(self.chat_history) do
--     table.insert(lines, string.format("### %s:", msg.role:upper()))
--     for _, line in ipairs(vim.split(msg.content, "\n")) do
--       if line:match("^```%w*%s*$") then
--         table.insert(lines, line)
--       elseif line:match("^```$") then
--         table.insert(lines, line)
--       else
--         table.insert(lines, "  " .. line)
--       end
--     end
--     table.insert(lines, "")
--   end
--
--   -- Add an empty line for the loading animation
--   table.insert(lines, "")
--
--   api.nvim_buf_set_option(self.sidebar_bufnr, "modifiable", true)
--   api.nvim_buf_set_lines(self.sidebar_bufnr, 0, -1, false, lines)
--   api.nvim_buf_set_option(self.sidebar_bufnr, "modifiable", false)
--
--   -- Apply syntax highlighting
--   api.nvim_buf_set_option(self.sidebar_bufnr, "filetype", "markdown")
--
--   -- Custom highlighting
--   api.nvim_buf_add_highlight(self.sidebar_bufnr, -1, self.config.highlight.title, 0, 0, -1)
--   local line_num = 6 -- Start after the header
--   for _, msg in ipairs(self.chat_history) do
--     api.nvim_buf_add_highlight(self.sidebar_bufnr, -1, self.config.highlight[msg.role], line_num, 0, -1)
--     line_num = line_num + #vim.split(msg.content, "\n") + 2 -- +2 for the role line and empty line
--   end
--
--   if self.sidebar_winid and api.nvim_win_is_valid(self.sidebar_winid) then
--     local last_line = api.nvim_buf_line_count(self.sidebar_bufnr)
--     pcall(api.nvim_win_set_cursor, self.sidebar_winid, { last_line, 0 })
--   end
-- end

function Chatter:prompt_user_input()
  local input_bufnr = api.nvim_create_buf(false, true)
  local input_winid = api.nvim_open_win(input_bufnr, true, {
    relative = 'editor',
    width = self.config.sidebar_width,
    height = 1,
    col = vim.o.columns - self.config.sidebar_width,
    row = vim.o.lines - 8,
    style = 'minimal',
    border = 'rounded'
  })

  api.nvim_set_option_value("buftype", "prompt", { buf = input_bufnr })
  vim.fn.prompt_setprompt(input_bufnr, "|> Prompt: ")

  vim.fn.prompt_setcallback(input_bufnr, function(message)
    if message and message ~= "" then
      self:send_chat_message(message)
    end
    api.nvim_win_close(input_winid, true)
    api.nvim_set_current_win(self.sidebar_winid)
  end)

  vim.cmd("startinsert!")
end

function Chatter:open_chat_sidebar()
  if self.sidebar_bufnr and api.nvim_buf_is_valid(self.sidebar_bufnr) then
    if not self.sidebar_winid or not api.nvim_win_is_valid(self.sidebar_winid) then
      self.sidebar_winid = api.nvim_open_win(self.sidebar_bufnr, true, {
        relative = 'editor',
        width = self.config.sidebar_width,
        height = vim.o.lines - 12,
        col = vim.o.columns - self.config.sidebar_width,
        row = 2,
        style = 'minimal',
        border = 'rounded',

      })
    end
    return
  end

  self.sidebar_bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(self.sidebar_bufnr, "buftype", "nofile")
  api.nvim_buf_set_option(self.sidebar_bufnr, "swapfile", false)
  api.nvim_buf_set_option(self.sidebar_bufnr, "bufhidden", "hide")
  api.nvim_buf_set_name(self.sidebar_bufnr, "Chatter")

  self.sidebar_winid = api.nvim_open_win(self.sidebar_bufnr, true, {
    relative = 'editor',
    width = self.config.sidebar_width,
    height = vim.o.lines - 12,
    col = vim.o.columns - self.config.sidebar_width,
    row = 2,
    style = 'minimal',
    border = 'rounded',

  })

  api.nvim_win_set_option(self.sidebar_winid, "wrap", true)
  api.nvim_win_set_option(self.sidebar_winid, "linebreak", true)

  local opts = { noremap = true, silent = true }
  api.nvim_buf_set_keymap(self.sidebar_bufnr, 'n', 'q', '<cmd>lua require("SciVim.chatter").close_sidebar()<CR>', opts)
  api.nvim_buf_set_keymap(self.sidebar_bufnr, 'n', '<C-c>', '<cmd>lua require("SciVim.chatter").clear_chat()<CR>', opts)
  api.nvim_buf_set_keymap(self.sidebar_bufnr, 'n', '<C-r>', '<cmd>lua require("SciVim.chatter").restart_chat()<CR>', opts)
  api.nvim_buf_set_keymap(self.sidebar_bufnr, 'n', 'i', '<cmd>lua require("SciVim.chatter").prompt_user_input()<CR>',
    opts)

  -- Set up autocommand to kill Ollama server when closing the sidebar
  api.nvim_create_autocmd("WinClosed", {
    buffer = self.sidebar_bufnr,
    callback = function()
      self:stop_ollama_server()
    end,
  })

  self:update_chat_display()
end

function Chatter:close_sidebar()
  if self.sidebar_winid and api.nvim_win_is_valid(self.sidebar_winid) then
    api.nvim_win_close(self.sidebar_winid, true)
    self.sidebar_winid = nil
  end
  self:stop_ollama_server()
  self:kill_all_ollama_models()
end

function Chatter:kill_all_ollama_models()
  local job = Job:new({
    command = "killall",
    args = { "ollama" },
    on_exit = function(j, return_val)
      if return_val == 0 then
        self:notify("All Ollama models stopped", vim.log.levels.INFO)
      else
        self:notify("Failed to stop Ollama models", vim.log.levels.ERROR)
      end
    end
  })
  job:start()
end

function Chatter:clear_chat()
  self.chat_history = {}
  self:update_chat_display()
end

function Chatter:restart_chat()
  self:clear_chat()
  self:start_chat()
end

function Chatter:start_ollama_server()
  if self.ollama_job then
    self:notify("Ollama server is already running", vim.log.levels.INFO)
    return
  end

  self.ollama_job = Job:new({
    command = "ollama",
    args = { "serve" },
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        self:notify("Ollama server stopped unexpectedly", vim.log.levels.ERROR)
      end
      self.ollama_job = nil
    end
  })

  self.ollama_job:start()
  self:notify("Ollama server started", vim.log.levels.INFO)
end

function Chatter:stop_ollama_server()
  if self.ollama_job then
    self.ollama_job:shutdown()
    self.ollama_job = nil
    self:kill_all_ollama_models()
    self:notify("Ollama server stopped", vim.log.levels.INFO)
  end
end

function Chatter:get_ollama_models(callback)
  curl.get(self.config.offline_api_url .. "/api/tags", {
    callback = vim.schedule_wrap(function(response)
      if response.status == 200 then
        local ok, decoded = pcall(fn.json_decode, response.body)
        if ok and decoded.models then
          local models = vim.tbl_map(function(model) return model.name end, decoded.models)
          callback(models)
        else
          self:notify("Failed to decode Ollama models response: " .. vim.inspect(response.body), vim.log.levels.ERROR)
          callback({})
        end
      else
        self:notify("Failed to get Ollama models: " .. response.status .. " - " .. vim.inspect(response.body),
          vim.log.levels.ERROR)
        callback({})
      end
    end)
  })
end

function Chatter:select_model(models)
  fzf.fzf_exec(models, {
    prompt = "Select Ollama Model >> ",
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          self.current_model = selected[1]
          self:open_chat_sidebar()
        else
          self:notify("No model selected", vim.log.levels.WARN)
        end
      end
    }
  })
end

function Chatter:start_chat()
  self:start_ollama_server()
  vim.defer_fn(function()
    self:get_ollama_models(function(models)
      if #models == 0 then
        self:notify("No Ollama models found", vim.log.levels.ERROR)
        return
      end
      self:select_model(models)
    end)
  end, 1000) -- Wait for 1 second to allow the Ollama server to start
end

function Chatter:notify(message, level)
  vim.notify(message, level)
end

function Chatter:setup()
  -- Set up commands
  api.nvim_create_user_command('ChatterStart', function() self:start_chat() end, {})
  api.nvim_create_user_command('ChatterToggle', function() self:toggle() end, {})
  api.nvim_create_user_command('ChatterClear', function() self:clear_chat() end, {})
  api.nvim_create_user_command('ChatterRestart', function() self:restart_chat() end, {})
  api.nvim_create_user_command('ChatterSend', function() self:prompt_user_input() end, {})

  -- Set up autocommand to kill Ollama server when exiting Neovim
  api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      self:stop_ollama_server()
      self:kill_all_ollama_models()
    end,
  })
end

function Chatter:toggle()
  if self.sidebar_winid and api.nvim_win_is_valid(self.sidebar_winid) then
    self:close_sidebar()
  else
    self:open_chat_sidebar()
  end
end

-- Create a single instance of Chatter
local chatter_instance = nil

-- Module functions that interact with
local M = {}

function M.setup(opts)
  if not chatter_instance then
    chatter_instance = Chatter.new(opts)
    chatter_instance:setup()
  else
    print("Chatter is already set up")
  end
end

function M.start_chat()
  if chatter_instance then
    chatter_instance:start_chat()
  else
    print("Chatter is not set up. Call setup() first.")
  end
end

function M.close_sidebar()
  if chatter_instance then
    chatter_instance:close_sidebar()
  end
end

function M.clear_chat()
  if chatter_instance then
    chatter_instance:clear_chat()
  end
end

function M.restart_chat()
  if chatter_instance then
    chatter_instance:restart_chat()
  end
end

function M.toggle()
  if chatter_instance then
    chatter_instance:toggle()
  else
    print("Chatter is not set up. Call setup() first.")
  end
end

function M.prompt_user_input()
  if chatter_instance then
    chatter_instance:prompt_user_input()
  else
    print("Chatter is not set up. Call setup() first.")
  end
end

return M
