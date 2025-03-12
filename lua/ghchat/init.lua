local M = {}

-- Import modules
local config = require("ghchat.config")
local buffer = require("ghchat.buffer")
local history = require("ghchat.history")
local api = require("ghchat.api")
local ui = require("ghchat.ui")

-- Initialize the plugin
function M.setup(user_config)
  -- Load configuration
  config.setup(user_config)

  -- Initialize UI (keybindings, commands, etc.)
  ui.setup()


  -- Initialize history
  history.setup()
end

-- Expose public API
M.toggle_chat = buffer.toggle_chat
M.prompt_user = ui.prompt_user
M.send_current_buffer = ui.send_current_buffer
M.send_selected_code = ui.send_selected_code
M.analyze_project = ui.analyze_project
M.clear_chat = history.clear_chat
M.save_conversation = history.save_conversation

return M
