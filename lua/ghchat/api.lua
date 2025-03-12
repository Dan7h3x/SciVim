local M = {}

local config = require("ghchat.config").get()
local buffer = require("ghchat.buffer")
local history = require("ghchat.history")
local utils = require("ghchat.utils")
local namespace = vim.api.nvim_create_namespace('GHChat')
local selected_model = nil
local loading_timer = nil
local is_loading = false

-- Check if GitHub CLI is installed
function M.check_gh_cli()
  local handle = io.popen("command -v gh")
  local result = handle:read("*a")
  handle:close()
  return result and #result > 0
end

-- List available models
function M.list_models(callback)
  if not M.check_gh_cli() then
    buffer.append_message('system',
      "Error: GitHub CLI (gh) is not installed or not in your PATH. Please install it first: https://cli.github.com/")
    return
  end

  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local chunks = {}

  -- Create window and show loading message
  buffer.create_window()
  buffer.append_message('system', "Fetching available models...")
  is_loading = true

  local handle, spawn_error = vim.loop.spawn('gh', {
    args = { 'models', 'list' },
    stdio = { nil, stdout, stderr },
  }, function(code)
    if stdout then stdout:read_stop() end
    if stderr then stderr:read_stop() end

    pcall(function()
      if stdout then stdout:close() end
      if stderr then stderr:close() end
      if handle then handle:close() end
    end)

    vim.schedule(function()
      is_loading = false

      if code ~= 0 then
        buffer.append_message('system', "Failed to list models (exit code " .. (code or "unknown") .. ")")
        return
      end

      local raw = table.concat(chunks)
      local ok, models = pcall(vim.json.decode, raw)
      if not ok or not models then
        buffer.append_message('system', "Failed to parse models list. Output: " .. (raw:sub(1, 100) or ""))
        return
      end

      -- Add proper error handling for models listing
      if not models or #models == 0 then
        buffer.append_message('system',
          "No models available. Make sure you're authenticated with GitHub CLI and have access to AI features.")
        return
      end

      local model_names = {}
      for _, m in ipairs(models) do
        if type(m) == "table" and m.name then
          table.insert(model_names, m.name)
        end
      end

      if #model_names == 0 then
        buffer.append_message('system', "No valid models found. Make sure you have access to GitHub Copilot features.")
        return
      end

      vim.ui.select(
        model_names,
        { prompt = 'Select AI Model:' },
        function(choice)
          if choice then
            selected_model = choice
            if callback then callback() end
          end
        end
      )
    end)
  end)

  if not handle then
    buffer.append_message('system', "Failed to spawn GitHub CLI: " .. (spawn_error or "unknown error"))
    return
  end

  if stdout then
    vim.loop.read_start(stdout, function(err, data)
      if err then
        vim.schedule(function()
          buffer.append_message('system', "Error reading stdout: " .. err)
        end)
        return
      end
      if data then chunks[#chunks + 1] = data end
    end)
  end

  if stderr then
    vim.loop.read_start(stderr, function(err, data)
      if err then
        vim.schedule(function()
          buffer.append_message('system', "Error reading stderr: " .. err)
        end)
        return
      end
      if data then
        vim.schedule(function()
          buffer.append_message('system', "Error from GitHub CLI: " .. data)
        end)
      end
    end)
  end
end

-- Send request to GitHub AI
function M.send_request(prompt)
  if not selected_model then
    buffer.append_message('system', "No model selected. Please select a model first.")
    return
  end

  -- Verify GitHub CLI is installed
  if not M.check_gh_cli() then
    buffer.append_message('system', "Error: GitHub CLI (gh) is not installed or not in your PATH.")
    return
  end

  is_loading = true

  -- Create JSON payload with conversation history
  local messages = {}
  table.insert(messages, { role = "system", content = config.system_message })

  -- Add relevant conversation history (up to 10 previous exchanges)
  local history_limit = math.min(#history.get_history(), 10)
  for i = #history.get_history() - history_limit + 1, #history.get_history() do
    if history.get_history()[i] then
      table.insert(messages, history.get_history()[i])
    end
  end

  -- Add current user message if not already in history
  if history.get_history()[#history.get_history()] and
      history.get_history()[#history.get_history()].role ~= "user" then
    table.insert(messages, { role = "user", content = prompt })
  end

  -- Create JSON data - wrapped in pcall for safety
  local ok, json_data = pcall(vim.json.encode, {
    model = selected_model,
    messages = messages,
    temperature = config.temperature,
    max_tokens = config.max_tokens
  })

  if not ok then
    buffer.append_message('system', "Failed to encode JSON data.")
    return
  end

  -- Create temporary file for the payload
  local tmp_file = vim.fn.tempname()
  local fd, open_err = io.open(tmp_file, "w")
  if not fd then
    buffer.append_message('system', "Failed to create temporary file: " .. (open_err or ""))
    return
  end

  fd:write(json_data)
  fd:close()

  -- Prepare for GitHub CLI request
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local chunks = {}

  local handle, spawn_err = vim.loop.spawn('gh', {
    args = { 'ai', 'chat', '--json-file', tmp_file },
    stdio = { nil, stdout, stderr },
  }, function(code)
    if stdout then stdout:read_stop() end
    if stderr then stderr:read_stop() end

    pcall(function()
      if stdout then stdout:close() end
      if stderr then stderr:close() end
      if handle then handle:close() end
    end)

    -- Clean up temp file
    vim.loop.fs_unlink(tmp_file)

    vim.schedule(function()
      is_loading = false

      if not code or code ~= 0 then
        buffer.append_message('system', "Request failed (exit code " .. (code or "unknown") .. ")")
        return
      end

      local response = table.concat(chunks)
      -- Trim response to remove trailing whitespace/newlines
      response = response:gsub("^%s*(.-)%s*$", "%1")

      if response == "" then
        buffer.append_message('system', "Received empty response from GitHub AI.")
        return
      end

      buffer.append_message('assistant', response)
    end)
  end)

  if not handle then
    buffer.append_message('system', "Failed to spawn GitHub CLI: " .. (spawn_err or "unknown error"))
    -- Clean up temp file
    vim.loop.fs_unlink(tmp_file)
    return
  end

  if stdout then
    vim.loop.read_start(stdout, function(err, data)
      if err then
        vim.schedule(function()
          buffer.append_message('system', "Error reading stdout: " .. err)
        end)
        return
      end
      if data then chunks[#chunks + 1] = data end
    end)
  end

  if stderr then
    vim.loop.read_start(stderr, function(err, data)
      if err then
        vim.schedule(function()
          buffer.append_message('system', "Error reading stderr: " .. err)
        end)
        return
      end
      if data then
        vim.schedule(function()
          buffer.append_message('system', "Error from GitHub CLI: " .. data)
        end)
      end
    end)
  end
end

return M
