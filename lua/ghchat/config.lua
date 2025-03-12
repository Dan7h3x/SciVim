local M = {}

-- Default configuration
local default_config = {
  max_tokens = 1000,
  temperature = 0.7,
  system_message = "You are a helpful AI assistant",
  bind_key = "<leader>cc",
  border = "rounded",
  width = 80,
  height = 20,
  markdown = {
    highlight = true,
    conceallevel = 2,
  },
  auto_scroll = true,
  loading_animation = true,
  save_history = true,
  history_path = vim.fn.stdpath("data") .. "/ghchat_history",
  shortcuts = {
    close = "q",
    clear = "c",
    save = "s",
    toggle_size = "z",
  },
  theme = {
    user = { fg = "#89B4FA", bold = true },
    assistant = { fg = "#A6E3A1" },
    system = { fg = "#F38BA8" },
    loading = { fg = "#F9E2AF" },
  }
}

-- Current configuration
local config = {}

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})
end

-- Get configuration
function M.get()
  return config
end

return M
