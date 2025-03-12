local M = {}

local config = require("ghchat.config").get()
local buffer = require("ghchat.buffer")
local api = require("ghchat.api")
local history = require("ghchat.history")

-- Prompt user for input
function M.prompt_user()
  vim.ui.input({
    prompt = "GHChat > ",
    default = "",
    completion = "file"
  }, function(input)
    if input and #input > 0 then
      buffer.append_message('user', input)
      api.send_request(input)
    end
  end)
end

-- Send current buffer to chat
function M.send_current_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filetype = vim.bo.filetype or "text"
  local filename = vim.fn.expand("%:t") or "untitled"

  -- If no chat window exists, initialize it
  if not buffer.is_window_open() then
    buffer.toggle_chat()
  end

  -- Format message
  local message = string.format(
    "Here's my code from %s (filetype: %s):\n\n```%s\n%s\n```\n\nCan you explain what this code does and suggest any improvements?",
    filename, filetype, filetype, content)

  -- Send to chat
  buffer.append_message('user', message)
  api.send_request(message)
end

-- Send selected code to chat
function M.send_selected_code()
  local selected_text = ""

  -- Get the visual selection using a more reliable method
  local pos1 = vim.fn.getpos("'<")
  local pos2 = vim.fn.getpos("'>")
  local start_row = pos1[2]
  local start_col = pos1[3]
  local end_row = pos2[2]
  local end_col = pos2[3]

  if start_row == 0 or end_row == 0 then
    buffer.append_message('system', "No text selected. Please make a selection first.")
    return
  end

  -- Adjust for visual block mode
  local mode = vim.fn.visualmode()
  if mode == "\22" then -- Visual block mode (CTRL-V)
    local lines = {}
    for i = start_row, end_row do
      local ok, line = pcall(vim.api.nvim_buf_get_lines, 0, i - 1, i, false)
      if ok and line and line[1] then
        local text = line[1]
        local len = #text
        if len >= start_col then
          local ending = math.min(end_col, len + 1)
          table.insert(lines, string.sub(text, start_col, ending))
        end
      end
    end
    selected_text = table.concat(lines, "\n")
  else
    -- Visual or Visual Line mode
    local ok, lines = pcall(vim.api.nvim_buf_get_text, 0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
    if ok and lines then
      selected_text = table.concat(lines, "\n")
    else
      -- Fallback method
      vim.api.nvim_command('normal! gvy')
      selected_text = vim.fn.getreg('"')
    end
  end

  if selected_text == "" then
    buffer.append_message('system', "Failed to get selected text.")
    return
  end

  -- Get file type
  local filetype = vim.bo.filetype or "text"

  -- If no chat window exists, initialize it
  if not buffer.is_window_open() then
    buffer.toggle_chat()
  end

  -- Format message
  local message = string.format(
    "Here's a code snippet (filetype: %s):\n\n```%s\n%s\n```\n\nCan you explain what this code does and suggest any improvements?",
    filetype, filetype, selected_text)

  -- Send to chat
  buffer.append_message('user', message)
  api.send_request(message)
end

-- Analyze project structure
function M.analyze_project()
  -- Get project root directory
  local root = vim.fn.getcwd()

  -- If no chat window exists, initialize it
  if not buffer.is_window_open() then
    buffer.toggle_chat()
  end

  buffer.append_message('system', "Analyzing project structure in: " .. root)
  is_loading = true

  -- Get file list (excluding .git, node_modules, etc.)
  local cmd = "find " .. vim.fn.shellescape(root) ..
      " -type f -not -path '*/\\.*' -not -path '*/node_modules/*'" ..
      " -not -path '*/target/*' -not -path '*/build/*' | sort"

  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local chunks = {}

  local handle, spawn_err = vim.loop.spawn('sh', {
    args = { '-c', cmd },
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

      if not code or code ~= 0 then
        buffer.append_message('system', "Failed to analyze project structure (exit code " .. (code or "unknown") .. ").")
        return
      end

      local files_raw = table.concat(chunks)
      local files = vim.split(files_raw, "\n", { plain = true, trimempty = true })

      if #files == 0 then
        buffer.append_message('system', "No files found in the project directory.")
        return
      end

      -- Limit number of files to avoid overwhelming the AI
      local file_count = #files
      local max_files = 20

      if file_count > max_files then
        files = vim.list_slice(files, 1, max_files)
        buffer.append_message('system',
          string.format("Found %d files, showing first %d for analysis", file_count, max_files))
      else
        buffer.append_message('system', string.format("Found %d files for analysis", file_count))
      end

      -- Format files relative to project root
      local formatted_files = {}
      for _, file in ipairs(files) do
        local rel_path = string.sub(file, #root + 2)
        table.insert(formatted_files, rel_path)
      end

      -- Format message for AI
      local message = string.format([[
Project analysis request for directory: %s

Directory structure (limited to %d files):
%s

Please analyze this project structure and provide insights on:
1. What type of project this appears to be
2. Main components and their organization
3. Suggestions for improvement or best practices
      ]], root, #formatted_files, table.concat(formatted_files, "\n"))

      -- Send to AI
      buffer.append_message('user', message)
      api.send_request(message)
    end)
  end)

  if not handle then
    buffer.append_message('system', "Failed to analyze project structure: " .. (spawn_err or "unknown error"))
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
          buffer.append_message('system', "Error analyzing project: " .. data)
        end)
      end
    end)
  end
end

-- Setup keybindings and commands
function M.setup()
  -- vim.api.nvim_set_keymap('n', config.bind_key, '<cmd>lua require("ghchat").prompt_user()<CR>',
  --   { noremap = true, silent = true, desc = "Open GitHub AI Chat" })

  vim.api.nvim_create_user_command('GHChat', function()
    buffer.toggle_chat()
  end, { desc = "Toggle GitHub AI Chat window" })

  vim.api.nvim_create_user_command('GHChatSendBuffer', function()
    M.send_current_buffer()
  end, { desc = "Send current buffer to GitHub AI Chat" })

  vim.api.nvim_create_user_command('GHChatSendSelection', function()
    M.send_selected_code()
  end, { desc = "Send visual selection to GitHub AI Chat" })

  vim.api.nvim_create_user_command('GHChatAnalyzeProject', function()
    M.analyze_project()
  end, { desc = "Analyze project structure with GitHub AI" })

  vim.api.nvim_create_user_command('GHChatClear', function()
    history.clear_chat()
  end, { desc = "Clear GitHub AI Chat history" })

  vim.api.nvim_create_user_command('GHChatSave', function()
    history.save_conversation()
  end, { desc = "Save GitHub AI Chat conversation" })

  vim.api.nvim_create_user_command('GHChatSelectModel', function()
    api.list_models()
  end, { desc = "Select GitHub AI model" })
end

return M
