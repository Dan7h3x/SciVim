local M = {}

local config = require("ghchat.config").get()
local namespace = vim.api.nvim_create_namespace('GHChat')
local chat_buf = nil
local chat_win = nil

-- Ensure buffer exists and is valid
function M.ensure_buffer()
  if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
    chat_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(chat_buf, "syntax", "markdown")
    vim.api.nvim_buf_set_option(chat_buf, "conceallevel", config.markdown.conceallevel or 2)
    vim.api.nvim_buf_set_option(chat_buf, "undolevels", 1000)
    vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(chat_buf, "readonly", false)
  end
  return chat_buf
end

-- Create or focus the chat window
function M.create_window(size_toggle)
  M.ensure_buffer()

  if chat_win and vim.api.nvim_win_is_valid(chat_win) then
    vim.api.nvim_set_current_win(chat_win)
    return
  end

  local width = size_toggle and math.floor(vim.o.columns * 0.9) or config.width
  local height = size_toggle and math.floor(vim.o.lines * 0.8) or config.height

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = config.border,
    title = ' GitHub AI Chat ',
    title_pos = 'center'
  }

  chat_win = vim.api.nvim_open_win(chat_buf, true, opts)

  -- Window options
  vim.api.nvim_win_set_option(chat_win, "wrap", true)
  vim.api.nvim_win_set_option(chat_win, "linebreak", true)
  vim.api.nvim_win_set_option(chat_win, "cursorline", true)
  vim.api.nvim_win_set_option(chat_win, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")
end

-- Toggle chat window visibility
function M.toggle_chat()
  if chat_win and vim.api.nvim_win_is_valid(chat_win) then
    vim.api.nvim_win_close(chat_win, true)
    chat_win = nil
  else
    M.create_window()
  end
end

return M
