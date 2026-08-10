local M = {}

-- Configuration with fancy options
M.config = {
  -- Output formatting
  output = {
    -- Style for output section
    style = 'fancy', -- 'fancy', 'minimal', 'simple'
    -- Show execution time
    show_execution_time = true,
    -- Show exit code
    show_exit_code = true,
    -- Show timestamp
    show_timestamp = true,
    -- Box drawing characters
    box = {
      horizontal = '─',
      vertical = '│',
      top_left = '╭',
      top_right = '╮',
      bottom_left = '╰',
      bottom_right = '╯',
      title_left = '┤',
      title_right = '├',
    },
    -- Colors (using highlight groups)
    highlights = {
      border = 'MarkdownRunnerBorder',
      title = 'MarkdownRunnerTitle',
      stdout = 'MarkdownRunnerStdout',
      stderr = 'MarkdownRunnerStderr',
      timestamp = 'MarkdownRunnerTimestamp',
      exit_success = 'MarkdownRunnerSuccess',
      exit_error = 'MarkdownRunnerError',
      spinner = 'MarkdownRunnerSpinner',
    },
  },
  -- Virtual text for status
  virtual_text = {
    enabled = true,
    running_icon = '⚡',
    success_icon = '✅',
    error_icon = '❌',
    position = 'right_align', -- 'eol', 'right_align', 'overlay'
  },
  -- Progress indication
  progress = {
    spinner = true,
    spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
    spinner_interval = 80,
    progress_bar = true,
    progress_bar_width = 20,
  },
  -- Auto commands
  auto_run = false,         -- Auto run on save?
  auto_clear_on_run = true, -- Clear previous output before re-run?
  -- Keymaps
  keymaps = {
    run_current_block = '<leader>mb',
    run_all_blocks = '<leader>ma',
    clear_outputs = '<leader>mc',
    toggle_output_style = '<leader>mt',
  },
  -- File type to attach
  filetypes = { 'markdown', 'md' },
  -- Maximum output lines to show (0 = unlimited)
  max_output_lines = 50,
  -- Default timeout in seconds
  timeout = 30,
}

-- Shared namespaces (created once)
local NS = {
  spinner = vim.api.nvim_create_namespace('markdown-runner-spinner'),
  status = vim.api.nvim_create_namespace('markdown-runner-status'),
  output = vim.api.nvim_create_namespace('markdown-runner-output'),
  success = vim.api.nvim_create_namespace('markdown-runner-success'),
}

-- State management
local state = {
  running = false,
  timers = {}, -- bufnr -> timer
}

--- Create highlight groups
local function create_highlights()
  local highlights = {
    MarkdownRunnerBorder = { fg = '#89b4fa', bg = 'NONE' },
    MarkdownRunnerTitle = { fg = '#cba6f7', bg = 'NONE', bold = true },
    MarkdownRunnerStdout = { fg = '#a6e3a1', bg = 'NONE' },
    MarkdownRunnerStderr = { fg = '#f38ba8', bg = 'NONE' },
    MarkdownRunnerTimestamp = { fg = '#6c7086', bg = 'NONE', italic = true },
    MarkdownRunnerSuccess = { fg = '#a6e3a1', bg = 'NONE', bold = true },
    MarkdownRunnerError = { fg = '#f38ba8', bg = 'NONE', bold = true },
    MarkdownRunnerSpinner = { fg = '#f9e2af', bg = 'NONE' },
    MarkdownRunnerVirtualText = { fg = '#585b70', bg = 'NONE', italic = true },
    MarkdownRunnerProgressBar = { fg = '#89b4fa', bg = '#313244' },
  }
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

--- Get current timestamp
local function get_timestamp()
  return os.date('%Y-%m-%d %H:%M:%S')
end

--- Format execution time
local function format_time(seconds)
  if seconds < 1 then
    return string.format('%.0fms', seconds * 1000)
  elseif seconds < 60 then
    return string.format('%.2fs', seconds)
  else
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%dm %.1fs', mins, secs)
  end
end

--- Strip ANSI escape sequences
local function strip_ansi(s)
  return (s:gsub('\27%[[0-9;]*[a-zA-Z]', ''))
end

--- Create a fancy box around text
---@param lines string[]
---@param opts table|nil
---@return string[]
local function create_fancy_box(lines, opts)
  opts = opts or {}
  local box = M.config.output.box
  local title = opts.title or 'Output'
  local max_width = opts.width or 100

  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, vim.fn.strdisplaywidth(strip_ansi(line)))
  end

  -- width includes the two vertical borders + one space padding each side
  local inner = math.max(content_width, vim.fn.strdisplaywidth(title) + 2)
  inner = math.min(inner, max_width - 4)
  local width = inner + 4 -- "│ " + content + " │"

  local result = {}

  table.insert(result, '```bash')
  -- Top border: ╭─ Title ────────╮
  local title_display = ' ' .. title .. ' '
  local title_w = vim.fn.strdisplaywidth(title_display)
  local left_pad = 1
  local right_fill = math.max(0, width - 2 - left_pad - title_w)
  local top = box.top_left
      .. string.rep(box.horizontal, left_pad)
      .. title_display
      .. string.rep(box.horizontal, right_fill)
      .. box.top_right
  table.insert(result, top)

  -- Empty line after title
  -- table.insert(result, box.vertical .. string.rep(' ', width - 2) .. box.vertical)

  -- Content lines
  for _, line in ipairs(lines) do
    local clean = strip_ansi(line)
    local disp = vim.fn.strdisplaywidth(clean)
    if disp <= inner then
      local padding = string.rep(' ', inner - disp)
      table.insert(result, box.vertical .. ' ' .. clean .. padding .. ' ' .. box.vertical)
    else
      -- Simple character wrap by display width
      local remaining = clean
      while #remaining > 0 do
        local chunk = ''
        local chunk_w = 0
        for i = 1, #remaining do
          local ch = remaining:sub(i, i)
          local ch_w = vim.fn.strdisplaywidth(ch)
          if chunk_w + ch_w > inner then
            break
          end
          chunk = chunk .. ch
          chunk_w = chunk_w + ch_w
        end
        if chunk == '' then
          -- single wide char wider than inner – force take one
          chunk = remaining:sub(1, 1)
        end
        remaining = remaining:sub(#chunk + 1)
        local padding = string.rep(' ', inner - vim.fn.strdisplaywidth(chunk))
        table.insert(result, box.vertical .. ' ' .. chunk .. padding .. ' ' .. box.vertical)
      end
    end
  end

  -- Empty line before bottom
  table.insert(result, box.vertical .. string.rep(' ', width - 2) .. box.vertical)

  -- Bottom border
  table.insert(result, box.bottom_left .. string.rep(box.horizontal, width - 2) .. box.bottom_right)
  table.insert(result, '```')

  return result
end

--- Create a minimal box
local function create_minimal_box(lines, opts)
  opts = opts or {}
  local result = {}
  table.insert(result, '```bash')
  if opts.title then
    table.insert(result, '# ─── ' .. opts.title .. ' ' .. string.rep('─', 40))
  end
  for _, line in ipairs(lines) do
    table.insert(result, line)
  end
  table.insert(result, '# ' .. string.rep('─', 50))
  table.insert(result, '```')
  return result
end

--- Create a simple (no decoration) output
local function create_simple_box(lines, opts)
  opts = opts or {}
  local result = {}
  if opts.title then
    table.insert(result, '### ' .. opts.title)
  end
  for _, line in ipairs(lines) do
    table.insert(result, line)
  end
  return result
end

--- Stop and clear any spinner for a buffer
local function stop_spinner(bufnr)
  local t = state.timers[bufnr]
  if t then
    pcall(function()
      t:stop()
      t:close()
    end)
    state.timers[bufnr] = nil
  end
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, NS.spinner, 0, -1)
end

--- Create spinner animation on a given 1-based line
---@param bufnr number
---@param line number 1-based
---@return userdata|nil timer
local function create_spinner(bufnr, line)
  if not M.config.progress.spinner then
    return nil
  end

  stop_spinner(bufnr)

  local frames = M.config.progress.spinner_frames
  local interval = M.config.progress.spinner_interval
  local frame_idx = 1
  local row = line - 1 -- 0-based

  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, NS.spinner, row, 0, {
    virt_text = { { frames[frame_idx], 'MarkdownRunnerSpinner' } },
    virt_text_pos = 'eol',
  })

  local timer = vim.uv.new_timer()
  state.timers[bufnr] = timer

  timer:start(0, interval, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      stop_spinner(bufnr)
      return
    end
    frame_idx = (frame_idx % #frames) + 1
    local ok = pcall(vim.api.nvim_buf_set_extmark, bufnr, NS.spinner, row, 0, {
      id = extmark_id,
      virt_text = { { frames[frame_idx], 'MarkdownRunnerSpinner' } },
      virt_text_pos = 'eol',
    })
    if not ok then
      stop_spinner(bufnr)
    end
  end))

  return timer
end

--- Show virtual text status on a 1-based line
local function show_virtual_status(bufnr, line, status_type, message)
  if not M.config.virtual_text.enabled then
    return
  end

  -- Clear previous status on this buffer
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, NS.status, 0, -1)

  local icon_map = {
    running = M.config.virtual_text.running_icon,
    success = M.config.virtual_text.success_icon,
    error = M.config.virtual_text.error_icon,
  }
  local icon = icon_map[status_type] or ''
  local text = (icon ~= '' and (icon .. ' ') or '') .. (message or '')
  local position = M.config.virtual_text.position
  local virt_pos = position
  if position == 'right_align' then
    virt_pos = 'right_align'
  elseif position ~= 'eol' and position ~= 'overlay' then
    virt_pos = 'eol'
  end

  vim.api.nvim_buf_set_extmark(bufnr, NS.status, line - 1, 0, {
    virt_text = { { text, 'MarkdownRunnerVirtualText' } },
    virt_text_pos = virt_pos,
  })
end

--- Parse a fence opening line. Returns fence, lang, meta_str or nil
local function parse_fence_open(line)
  -- Match: ```lang optional-meta...
  -- Also accept ~~~ fences
  local fence, lang, rest = line:match('^([`~][`~][`~]+)(%w*)%s*(.*)$')
  if not fence then
    return nil
  end
  -- Require at least 3 fence chars
  if #fence < 3 then
    return nil
  end
  -- lang may be empty (plain code block)
  return fence, lang ~= '' and lang or nil, rest
end

--- Parse metadata key=value pairs from the rest of the fence line
local function parse_metadata(meta_str)
  local meta = {}
  if not meta_str or meta_str == '' then
    return meta
  end
  -- Support: key="value"  key='value'  key=value
  for key, value in meta_str:gmatch('([%w_]+)%s*=%s*["\']([^"\']*)["\']') do
    meta[key] = value
  end
  for key, value in meta_str:gmatch('([%w_]+)%s*=%s*([^%s"\']+)') do
    if meta[key] == nil then
      meta[key] = value
    end
  end
  return meta
end

--- Get code blocks from buffer.
--- All line numbers are 1-based (matching nvim_win_get_cursor / human view).
---@return table[]
local function get_code_blocks(bufnr)
  local blocks = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local in_block = false
  local current = nil

  for i, line in ipairs(lines) do
    if not in_block then
      local fence, lang, rest = parse_fence_open(line)
      if fence and lang then
        current = {
          lang = lang:lower(),
          fence = fence,
          start_line = i, -- 1-based (opening fence)
          end_line = nil, -- 1-based (closing fence)
          code = {},
          metadata = parse_metadata(rest),
        }
        in_block = true
      end
    else
      -- Look for matching closing fence (same character, at least same length)
      local close = line:match('^(' .. current.fence:sub(1, 1) .. '+)%s*$')
      if close and #close >= #current.fence then
        current.end_line = i
        table.insert(blocks, current)
        in_block = false
        current = nil
      else
        table.insert(current.code, line)
      end
    end
  end

  return blocks
end

--- Execute bash code (synchronous but short-lived; prefer for small blocks)
---@param code string[]
---@param opts table|nil
---@return table
local function execute_bash(code, opts)
  opts = opts or {}
  local code_str = table.concat(code, '\n')
  local tmpfile = vim.fn.tempname() .. '.sh'
  local start_time = vim.uv.hrtime()

  local file = io.open(tmpfile, 'w')
  if not file then
    return {
      stdout = '',
      stderr = 'Failed to create temporary file',
      exit_code = 1,
      elapsed = 0,
      success = false,
    }
  end

  if not code_str:match('^#!/') then
    file:write('#!/usr/bin/env bash\n')
  end
  file:write(code_str)
  if not code_str:match('\n$') then
    file:write('\n')
  end
  file:close()

  local timeout = tonumber(opts.timeout) or M.config.timeout or 30
  -- Use a marker that is extremely unlikely to appear in real output
  local marker = '___MARKDOWN_RUNNER_EXIT___'
  -- Proper exit-code capture:
  -- timeout ... ; ec=$?; printf "\nMARKER%d" "$ec"
  local cmd = string.format(
    'timeout %d bash %s 2>&1; ec=$?; printf "\\n%s%%d" "$ec"',
    timeout,
    vim.fn.shellescape(tmpfile),
    marker
  )
  -- The %% becomes % in the final string so printf sees %d

  local handle = io.popen(cmd)
  if not handle then
    os.remove(tmpfile)
    return {
      stdout = '',
      stderr = 'Failed to start process',
      exit_code = 1,
      elapsed = 0,
      success = false,
    }
  end

  local raw = handle:read('*a') or ''
  handle:close()
  os.remove(tmpfile)

  local exit_code = 1
  local output = raw
  local m_start, m_end, code_str_match = raw:find('\n?' .. marker .. '(%d+)%s*$')
  if m_start then
    exit_code = tonumber(code_str_match) or 1
    output = raw:sub(1, m_start - 1)
  end

  -- Trim a single trailing newline that scripts often produce
  if output:sub(-1) == '\n' then
    output = output:sub(1, -2)
  end

  local end_time = vim.uv.hrtime()
  local elapsed = (end_time - start_time) / 1e9

  return {
    stdout = output,
    stderr = '',
    exit_code = exit_code,
    elapsed = elapsed,
    success = exit_code == 0,
  }
end

--- Format result into a list of plain strings (for boxing)
local function format_output_lines(result)
  local lines = {}

  if M.config.output.show_timestamp then
    table.insert(lines, '⏰ ' .. get_timestamp())
  end

  if M.config.output.show_execution_time then
    local time_str = format_time(result.elapsed)
    local icon = result.success and '⚡' or '⏱️'
    table.insert(lines, string.format('%s Executed in %s', icon, time_str))
  end

  if M.config.output.show_exit_code then
    table.insert(lines, string.format('# 📊 Exit code: %d', result.exit_code))
  end

  -- if #lines > 0 then
  --   table.insert(lines, string.rep('·', 40))
  -- end

  if result.stdout and #result.stdout > 0 then
    local stdout_lines = vim.split(result.stdout, '\n', { plain = true })
    local max = M.config.max_output_lines
    if max and max > 0 and #stdout_lines > max then
      for i = 1, max do
        table.insert(lines, stdout_lines[i])
      end
      table.insert(lines, string.format('… (%d more lines truncated)', #stdout_lines - max))
    else
      for _, line in ipairs(stdout_lines) do
        table.insert(lines, line)
      end
    end
  else
    table.insert(lines, '(no output)')
  end

  return lines
end

--- Build the final lines that will be inserted after a code block
local function build_output_block(result, title)
  local content = format_output_lines(result)
  local style = M.config.output.style or 'fancy'

  if style == 'minimal' then
    return create_minimal_box(content, { title = title })
  elseif style == 'simple' then
    return create_simple_box(content, { title = title })
  else
    return create_fancy_box(content, { title = title or 'Execution Result' })
  end
end

--- Detect and remove previously inserted output that sits right after a code block.
--- block.end_line is 1-based (the closing fence line).
--- Returns the number of lines removed.
local function clear_output_after_block(bufnr, end_line_1based)
  -- Output is inserted starting at the line *after* the closing fence.
  -- In 0-based indexing that is end_line_1based (because line N (1-based) is index N-1;
  -- the next line is index N).
  local start_idx = end_line_1based -- 0-based index of the first line after the fence
  local total = vim.api.nvim_buf_line_count(bufnr)
  if start_idx >= total then
    return 0
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_idx, math.min(start_idx + 200, total), false)
  if #lines == 0 then
    return 0
  end

  local to_remove = 0

  -- Optional blank line we insert before the box
  if lines[1] == '' then
    to_remove = 1
  end

  local box_start = to_remove + 1
  if box_start > #lines then
    if to_remove > 0 then
      vim.api.nvim_buf_set_lines(bufnr, start_idx, start_idx + to_remove, false, {})
    end
    return to_remove
  end

  local first = lines[box_start]
  -- Fancy box starts with ╭
  -- Minimal starts with ───
  -- Simple starts with ###
  local is_output = first:match('^╭')
      or first:match('^───')
      or first:match('^### ')

  if not is_output then
    if to_remove > 0 then
      -- only a blank line – leave it
      return 0
    end
    return 0
  end

  -- Count until we leave the output block
  if first:match('^╭') then
    -- fancy: consume until ╰
    for i = box_start, #lines do
      to_remove = to_remove + 1
      if lines[i]:match('^╰') then
        break
      end
    end
  elseif first:match('^───') then
    -- minimal: header + body + trailing ─ line
    to_remove = to_remove + 1 -- header
    for i = box_start + 1, #lines do
      to_remove = to_remove + 1
      if lines[i]:match('^─+$') then
        break
      end
    end
  elseif first:match('^### ') then
    -- simple: ### title then content until blank or next fence / heading
    to_remove = to_remove + 1
    for i = box_start + 1, #lines do
      if lines[i]:match('^```') or lines[i]:match('^#') or lines[i]:match('^╭') then
        break
      end
      to_remove = to_remove + 1
    end
  end

  if to_remove > 0 then
    vim.api.nvim_buf_set_lines(bufnr, start_idx, start_idx + to_remove, false, {})
  end
  return to_remove
end

--- Insert output lines right after the code block's closing fence.
--- end_line_1based = 1-based line number of the closing ```
local function insert_output(bufnr, end_line_1based, output_lines)
  -- 0-based index of the line after the closing fence
  local insert_at = end_line_1based
  local payload = { '' } -- leading blank line
  for _, l in ipairs(output_lines) do
    table.insert(payload, l)
  end
  vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, payload)
end

--- Run a single block (shared by run_current and run_all)
local function run_block(bufnr, block)
  if block.lang ~= 'bash' and block.lang ~= 'sh' then
    return nil, 'Only bash/sh code blocks are supported'
  end

  if M.config.auto_clear_on_run then
    clear_output_after_block(bufnr, block.end_line)
  end

  show_virtual_status(bufnr, block.start_line, 'running', 'Running...')
  create_spinner(bufnr, block.start_line)

  local result = execute_bash(block.code, block.metadata)

  stop_spinner(bufnr)

  local title = block.metadata.title or 'Execution Result'
  local fancy_lines = build_output_block(result, title)

  -- Re-clear in case something changed, then insert
  if M.config.auto_clear_on_run then
    clear_output_after_block(bufnr, block.end_line)
  end
  insert_output(bufnr, block.end_line, fancy_lines)

  if result.success then
    show_virtual_status(bufnr, block.start_line, 'success', 'Success')
  else
    show_virtual_status(bufnr, block.start_line, 'error', 'Failed')
  end

  return result
end

--- Run the code block under the cursor
function M.run_current_block()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
  local blocks = get_code_blocks(bufnr)

  for _, block in ipairs(blocks) do
    if cursor_line >= block.start_line and cursor_line <= block.end_line then
      local result, err = run_block(bufnr, block)
      if err then
        vim.notify('⚠️ ' .. err, vim.log.levels.WARN)
        return
      end
      if result then
        if result.success then
          vim.notify('✅ Execution completed successfully', vim.log.levels.INFO)
        else
          vim.notify('❌ Execution completed with errors (exit ' .. result.exit_code .. ')', vim.log.levels.ERROR)
        end
      end
      return
    end
  end

  vim.notify('No code block found under cursor', vim.log.levels.WARN)
end

--- Run all bash/sh blocks sequentially
function M.run_all_blocks()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Snapshot blocks first (line numbers will shift as we insert)
  local blocks = get_code_blocks(bufnr)
  local bash_blocks = {}
  for _, block in ipairs(blocks) do
    if block.lang == 'bash' or block.lang == 'sh' then
      table.insert(bash_blocks, {
        lang = block.lang,
        code = block.code,
        metadata = block.metadata,
        code_hash = table.concat(block.code, '\n'),
      })
    end
  end

  if #bash_blocks == 0 then
    vim.notify('No bash code blocks found', vim.log.levels.WARN)
    return
  end

  local progress_buf = vim.api.nvim_create_buf(false, true)
  local progress_win = vim.api.nvim_open_win(progress_buf, false, {
    relative = 'editor',
    width = 42,
    height = 6,
    row = 2,
    col = 2,
    style = 'minimal',
    border = 'rounded',
    title = ' Running Code Blocks ',
    title_pos = 'center',
  })

  local total = #bash_blocks
  local completed = 0
  local failed = 0

  local function update_progress()
    if not vim.api.nvim_buf_is_valid(progress_buf) then
      return
    end
    local done = completed + failed
    local pct = total > 0 and math.floor(done / total * 100) or 0
    local bar_width = M.config.progress.progress_bar_width
    local filled = math.floor(pct / 100 * bar_width)
    local bar = string.rep('█', filled) .. string.rep('░', bar_width - filled)
    local lines = {
      string.format('Progress: %d/%d (%d%%)', done, total, pct),
      bar,
      string.format('✓ Successful: %d', completed),
      string.format('✗ Failed: %d', failed),
    }
    vim.api.nvim_buf_set_lines(progress_buf, 0, -1, false, lines)
  end

  update_progress()

  local function find_block_by_code(code_hash)
    local current_blocks = get_code_blocks(bufnr)
    for _, b in ipairs(current_blocks) do
      if (b.lang == 'bash' or b.lang == 'sh') and table.concat(b.code, '\n') == code_hash then
        return b
      end
    end
    return nil
  end

  local function execute_next(index)
    if index > #bash_blocks then
      vim.defer_fn(function()
        if progress_win and vim.api.nvim_win_is_valid(progress_win) then
          vim.api.nvim_win_close(progress_win, true)
        end
        vim.notify(
          string.format('✅ Executed %d blocks (%d failed)', total, failed),
          failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO
        )
      end, 400)
      return
    end

    local snap = bash_blocks[index]
    local block = find_block_by_code(snap.code_hash)
    if not block then
      failed = failed + 1
      update_progress()
      vim.defer_fn(function()
        execute_next(index + 1)
      end, 50)
      return
    end

    show_virtual_status(bufnr, block.start_line, 'running', string.format('Running (%d/%d)', index, total))
    create_spinner(bufnr, block.start_line)

    -- Small delay so the spinner is visible
    vim.defer_fn(function()
      local result = execute_bash(block.code, block.metadata)
      stop_spinner(bufnr)

      local title = block.metadata.title or 'Execution Result'
      local fancy_lines = build_output_block(result, title)

      if M.config.auto_clear_on_run then
        clear_output_after_block(bufnr, block.end_line)
      end
      insert_output(bufnr, block.end_line, fancy_lines)

      if result.success then
        completed = completed + 1
        show_virtual_status(bufnr, block.start_line, 'success', '✓')
      else
        failed = failed + 1
        show_virtual_status(bufnr, block.start_line, 'error', '✗')
      end

      update_progress()
      vim.defer_fn(function()
        execute_next(index + 1)
      end, 150)
    end, 120)
  end

  execute_next(1)
end

--- Clear output that follows a specific block
function M.clear_output_at_block(bufnr, block)
  clear_output_after_block(bufnr, block.end_line)
end

--- Clear all outputs in the current buffer
function M.clear_outputs()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Work from bottom to top so line numbers stay valid
  local blocks = get_code_blocks(bufnr)
  for i = #blocks, 1, -1 do
    clear_output_after_block(bufnr, blocks[i].end_line)
  end
  -- Also clear status / spinner namespaces
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, NS.status, 0, -1)
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, NS.spinner, 0, -1)
  vim.notify('🧹 All outputs cleared', vim.log.levels.INFO)
end

--- Toggle output style
function M.toggle_output_style()
  local styles = { 'fancy', 'minimal', 'simple' }
  local current = M.config.output.style
  local current_idx = 1
  for i, s in ipairs(styles) do
    if s == current then
      current_idx = i
      break
    end
  end
  local next_idx = (current_idx % #styles) + 1
  M.config.output.style = styles[next_idx]
  vim.notify(string.format('Output style: %s', M.config.output.style), vim.log.levels.INFO)
end

--- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  create_highlights()

  -- Re-apply highlights when colorscheme changes
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('MarkdownRunnerColors', { clear = true }),
    callback = create_highlights,
  })

  vim.api.nvim_create_user_command('MarkdownRunBlock', M.run_current_block, {
    desc = 'Run the bash/sh code block under the cursor',
  })
  vim.api.nvim_create_user_command('MarkdownRunAll', M.run_all_blocks, {
    desc = 'Run all bash/sh code blocks in the buffer',
  })
  vim.api.nvim_create_user_command('MarkdownClearOutputs', M.clear_outputs, {
    desc = 'Clear all markdown-runner outputs',
  })
  vim.api.nvim_create_user_command('MarkdownToggleStyle', M.toggle_output_style, {
    desc = 'Cycle output style (fancy / minimal / simple)',
  })

  local augroup = vim.api.nvim_create_augroup('MarkdownRunner', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = M.config.filetypes,
    callback = function(args)
      local buf = args.buf
      local map_opts = { buffer = buf, silent = true }

      if M.config.keymaps.run_current_block then
        vim.keymap.set(
          'n',
          M.config.keymaps.run_current_block,
          M.run_current_block,
          vim.tbl_extend('force', map_opts, { desc = '⚡ Run code block' })
        )
      end
      if M.config.keymaps.run_all_blocks then
        vim.keymap.set(
          'n',
          M.config.keymaps.run_all_blocks,
          M.run_all_blocks,
          vim.tbl_extend('force', map_opts, { desc = '⚡ Run all blocks' })
        )
      end
      if M.config.keymaps.clear_outputs then
        vim.keymap.set(
          'n',
          M.config.keymaps.clear_outputs,
          M.clear_outputs,
          vim.tbl_extend('force', map_opts, { desc = '🧹 Clear outputs' })
        )
      end
      if M.config.keymaps.toggle_output_style then
        vim.keymap.set(
          'n',
          M.config.keymaps.toggle_output_style,
          M.toggle_output_style,
          vim.tbl_extend('force', map_opts, { desc = '🎨 Toggle style' })
        )
      end

      if M.config.auto_run then
        vim.api.nvim_create_autocmd('BufWritePost', {
          group = augroup,
          buffer = buf,
          callback = function()
            M.run_all_blocks()
          end,
        })
      end
    end,
  })

  -- vim.notify('🎨 Markdown Runner loaded', vim.log.levels.INFO)
end

return M
