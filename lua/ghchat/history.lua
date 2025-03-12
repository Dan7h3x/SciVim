local M = {}

local config = require("ghchat.config").get()
local conversation_history = {}

-- Clear chat history
function M.clear_chat()
  local chat_buf = require("ghchat.buffer").ensure_buffer()
  if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
    return
  end

  -- Clear buffer
  pcall(vim.api.nvim_buf_set_option, chat_buf, "modifiable", true)
  pcall(vim.api.nvim_buf_set_lines, chat_buf, 0, -1, false, {})
  pcall(vim.api.nvim_buf_set_option, chat_buf, "modifiable", false)

  -- Clear conversation history
  conversation_history = {}
end

-- Save conversation to file
function M.save_conversation()
  if #conversation_history == 0 then
    return
  end

  -- Create history directory if it doesn't exist
  if vim.fn.isdirectory(config.history_path) == 0 then
    local mkdir_ok, mkdir_err = pcall(vim.fn.mkdir, config.history_path, "p")
    if not mkdir_ok then
      return
    end
  end

  -- Generate filename with timestamp
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local filename = config.history_path .. "/chat_" .. timestamp .. ".md"

  local file, open_err = io.open(filename, "w")
  if not file then
    return
  end

  file:write("# GitHub AI Chat - " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
  for _, msg in ipairs(conversation_history) do
    local role_display = {
      user = "You",
      assistant = "AI",
      system = "System"
    }
    file:write("## " .. (role_display[msg.role] or "Unknown") .. "\n\n")
    file:write(msg.content .. "\n\n")
  end

  file:close()
end

return M
