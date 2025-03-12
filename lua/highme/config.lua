local M = {}

-- Default configuration
M.default_config = {
  highlight_color = "guibg=#feaaa2", -- Default highlight color
  highlight_enabled = true,          -- Enable highlighting by default
  highlight_on_cursor_move = true,   -- Automatically highlight on cursor move
  clear_highlights_on_exit = true,   -- Clear highlights when exiting buffer
  highlight_multiple_words = true,   -- Highlight multiple words under cursor
  use_search_register = true,        -- Update search register (/)
  add_to_jumplist = true,            -- Add matches to jumplist
  -- Exclude specific filetypes
  excluded_filetypes = {
    "NvimTree",
    "TelescopePrompt",
    "TelescopeResults",
    "help",
    "quickfix",
    "trouble",
    "mason",
    "notify",
    "toggleterm",
    "lazy",
  },
}

-- Merge user config with defaults
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
  return M.config
end

return M
