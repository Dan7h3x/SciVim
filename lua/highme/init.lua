local config = require('highme.config')
local M = {}

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace('highme')
local current_matches = {} -- Store current matches for jumping

-- Track f/F motion state
local in_f_motion = false

-- Check if current buffer should be excluded
local function should_exclude_buffer()
  local ft = vim.bo.filetype
  for _, excluded_ft in ipairs(config.config.excluded_filetypes) do
    if ft == excluded_ft then
      return true
    end
  end
  return false
end

-- Check if word should be ignored
local function should_ignore_word(word)
  -- Ignore empty strings
  if word == '' then return true end

  -- Ignore single characters that are likely to be special
  if #word == 1 then
    -- Ignore brackets, parentheses, quotes, and other special characters
    local ignored_chars = {
      '[', ']', '(', ')', '{', '}', '<', '>', 
      '"', "'", '`',
      ',', '.', ';', ':', '/', '\\',
      '+', '-', '*', '=', '~', '@', '#',
      '|', '&'
    }
    for _, char in ipairs(ignored_chars) do
      if word == char then return true end
    end
  end

  -- Ignore common whitespace patterns
  if word:match('^%s+$') then return true end

  -- Ignore numbers only
  if word:match('^%d+$') then return true end

  return false
end

-- Highlight word under cursor and prepare for jumping
function M.highme()
  -- Skip if in f/F motion or filetype is excluded
  if in_f_motion or should_exclude_buffer() then
    return
  end

  -- Clear previous highlights and matches
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  current_matches = {}

  -- Get the word under the cursor
  local word = vim.fn.expand('<cword>')
  
  -- Skip if word should be ignored
  if should_ignore_word(word) then
    return
  end

  -- Update search register if enabled (silently)
  if config.config.use_search_register then
    pcall(function()
      vim.fn.setreg('/', '\\<' .. word .. '\\>', 'n') -- 'n' flag for silent
      vim.opt.hlsearch = true
    end)
  end

  -- Cache the highlight color to avoid repeated vim.cmd calls
  if not M._highlight_setup then
    vim.api.nvim_command('silent! highlight HighMe ' .. config.config.highlight_color)
    M._highlight_setup = true
  end

  -- Optimize buffer reading by getting all lines at once
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1] - 1
  local current_col = cursor_pos[2]

  -- Pre-compile pattern for better performance
  local pattern = vim.regex('\\<' .. vim.fn.escape(word, '\\') .. '\\>')

  -- Process matches in a single pass
  for lnum, line in ipairs(lines) do
    local start_idx = 0
    while true do
      local s, e = pattern:match_str(line:sub(start_idx + 1))
      if not s then break end

      s = s + start_idx
      e = e + start_idx

      vim.api.nvim_buf_add_highlight(0, ns, 'HighMe', lnum - 1, s, e + 1)
      table.insert(current_matches, {
        line = lnum - 1,
        col = s,
        end_col = e + 1
      })
      start_idx = e + 1
    end
  end

  -- Optimize sorting with local variables and single calculation
  if #current_matches > 0 then
    local function calc_dist(match)
      return math.abs(match.line - current_line) * 1000 + math.abs(match.col - current_col)
    end

    table.sort(current_matches, function(a, b)
      return calc_dist(a) < calc_dist(b)
    end)
  end
end

-- Optimize jumplist addition
local function add_to_jumplist()
  if config.config.add_to_jumplist then
    pcall(function()
      vim.cmd("silent! normal! m'")
    end)
  end
end

-- Optimize jump functions
function M.jump_next()
  if #current_matches == 0 then
    M.highme()
    if #current_matches == 0 then return end
  end

  add_to_jumplist()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1] - 1
  local current_col = cursor_pos[2]

  -- Use binary search for better performance
  local next_match
  local left, right = 1, #current_matches
  while left <= right do
    local mid = math.floor((left + right) / 2)
    local match = current_matches[mid]

    if match.line < current_line or (match.line == current_line and match.col <= current_col) then
      left = mid + 1
    else
      next_match = match
      right = mid - 1
    end
  end

  -- Wrap around if no match found
  if not next_match and #current_matches > 0 then
    next_match = current_matches[1]
  end

  if next_match then
    pcall(function()
      vim.api.nvim_win_set_cursor(0, { next_match.line + 1, next_match.col })
    end)
  end
end

function M.jump_prev()
  if #current_matches == 0 then
    M.highme()
    if #current_matches == 0 then return end
  end

  add_to_jumplist()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1] - 1
  local current_col = cursor_pos[2]

  -- Use binary search for better performance
  local prev_match
  local left, right = 1, #current_matches
  while left <= right do
    local mid = math.floor((left + right) / 2)
    local match = current_matches[mid]

    if match.line > current_line or (match.line == current_line and match.col >= current_col) then
      right = mid - 1
    else
      prev_match = match
      left = mid + 1
    end
  end

  -- Wrap around if no match found
  if not prev_match and #current_matches > 0 then
    prev_match = current_matches[#current_matches]
  end

  if prev_match then
    pcall(function()
      vim.api.nvim_win_set_cursor(0, { prev_match.line + 1, prev_match.col })
    end)
  end
end

-- Toggle highlight on/off
function M.toggle_highlight()
  config.config.highlight_enabled = not config.config.highlight_enabled
  if config.config.highlight_enabled then
    M.highme()
  else
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end
end

-- Clear all highlights
function M.clear_highlights()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

-- Setup function with optimizations
function M.setup(user_config)
  config.setup(user_config)

  -- Create augroups only once
  local highme_group = vim.api.nvim_create_augroup("HighMe", { clear = true })

  -- Handle f/F motions
  vim.api.nvim_create_autocmd({"CmdlineEnter", "CmdlineLeave"}, {
    group = highme_group,
    callback = function(ev)
      if ev.event == "CmdlineEnter" then
        -- Check if the cmdtype is f or F
        local char = vim.fn.getcmdtype()
        if char == "f" or char == "F" then
          in_f_motion = true
          M.clear_highlights()
        end
      else
        -- Reset the f motion state after a short delay
        vim.defer_fn(function()
          in_f_motion = false
          if config.config.highlight_on_cursor_move then
            M.highme()
          end
        end, 100)
      end
    end
  })

  if config.config.highlight_on_cursor_move then
    -- Debounce the cursor moved event for better performance
    local timer = vim.loop.new_timer()
    local debounce_ms = 50 -- Adjust this value based on preference

    vim.api.nvim_create_autocmd("CursorMoved", {
      group = highme_group,
      callback = function()
        if should_exclude_buffer() then return end

        timer:stop()
        timer:start(debounce_ms, 0, vim.schedule_wrap(M.highme))
      end
    })
  end

  if config.config.clear_highlights_on_exit then
    vim.api.nvim_create_autocmd("BufLeave", {
      group = highme_group,
      callback = M.clear_highlights
    })
  end
end

return M
