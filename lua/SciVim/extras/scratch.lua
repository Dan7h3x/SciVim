local uv = vim.uv or vim.loop

local Scratch = {}

---@class Scratch.Config
---@field win? table Window configuration
---@field template? string Template for new buffers
---@field file? string Scratch file path
---@field ft? string|fun():string Filetype of the scratch buffer
---@field name? string Name of the scratch buffer
---@field icon? string|string[] Icon for the file type
---@field root? string Root directory for scratch files
---@field autowrite? boolean Automatically write when buffer is hidden
---@field filekey? table Configuration for file naming
---@field win_by_ft? table<string, table> Window config overrides by filetype
---@field keymaps? table Global keymaps for the plugin
---@field visual_results? boolean Show execution results visually inline
---@field result_ns? number Namespace for visual results
---@field debug_ns? number Namespace for debug highlights
---@field interpreters? table<string, string> Interpreters for each filetype
---@field save_on_toggle? boolean Save scratch buffer content when toggling
---@field show_results_on_execute? boolean Show results immediately after execution
---@field real_time_execution? boolean Enable real-time execution when leaving insert mode
---@field line_by_line_results? boolean Show results for each line individually
---@field debug_mode? boolean Enable debug mode by default
---@field ui? table UI configuration options
---@field result_indicator? string Character to use as result indicator

local defaults = {
  name = "Scratch",
  ft = function()
    if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
      return vim.bo.filetype
    end
    return "markdown"
  end,
  icon = nil,
  root = vim.fn.stdpath("data") .. "/scratch",
  autowrite = true,
  save_on_toggle = true,
  show_results_on_execute = true,
  real_time_execution = true,
  line_by_line_results = true,
  debug_mode = false,
  result_indicator = "→",
  filekey = {
    cwd = true,
    branch = true,
    count = true,
  },
  win = {
    width = 100,
    height = 30,
    bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
    minimal = false,
    noautocmd = false,
    zindex = 20,
    wo = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual",
      cursorline = true,
      signcolumn = "yes",
      foldcolumn = "0",
      number = true,
      relativenumber = false,
      wrap = false,
    },
    border = "rounded",
    title_pos = "center",
    footer_pos = "center",
  },
  ui = {
    float_border = "rounded",
    float_shadow = true,
    float_title_style = "center",
    result_inline = true,
    result_virt_lines = false,
    result_padding = 2,
    themed = true,
    hl_result = "Special",
    hl_error = "DiagnosticError",
  },
  keymaps = {
    toggle = "<F5>",
    execute = "<CR>",
    hide = "<Esc>",
    toggle_results = "<leader>sr",
    save = "<leader>ss",
    toggle_real_time = "<leader>st",
    toggle_debug = "<leader>sd",
    clear_results = "<leader>sc",
    clear_scratch = "<leader>sx",
  },
  visual_results = true,
  result_ns = vim.api.nvim_create_namespace("ScratchResults"),
  debug_ns = vim.api.nvim_create_namespace("ScratchDebug"),
  interpreters = {
    python = "python",
    lua = "neovim",
    javascript = "node",
    typescript = "ts-node",
    ruby = "ruby",
    bash = "bash",
    sh = "sh",
    zsh = "zsh",
    r = "Rscript",
    julia = "julia",
    perl = "perl",
    php = "php",
  },
  win_by_ft = {
    python = {
      keys = {
        ["execute"] = {
          "<CR>",
          function(self)
            Scratch.execute_code(self.buf)
          end,
          desc = "Execute Python code",
          mode = { "n", "v" },
        },
      },
    },
    lua = {
      keys = {
        ["execute"] = {
          "<CR>",
          function(self)
            Scratch.execute_code(self.buf)
          end,
          desc = "Execute Lua code",
          mode = { "n", "v" },
        },
      },
    },
    javascript = {
      keys = {
        ["execute"] = {
          "<CR>",
          function(self)
            Scratch.execute_code(self.buf)
          end,
          desc = "Execute JavaScript code",
          mode = { "n", "v" },
        },
      },
    },
  },
}

-- Store active scratch buffers
Scratch.active_scratches = {}

-- Set highlight groups
vim.api.nvim_set_hl(0, "ScratchTitle", { link = "FloatTitle", default = true })
vim.api.nvim_set_hl(0, "ScratchFooter", { link = "FloatFooter", default = true })
vim.api.nvim_set_hl(0, "ScratchKey", { link = "DiagnosticVirtualTextInfo", default = true })
vim.api.nvim_set_hl(0, "ScratchDesc", { link = "DiagnosticInfo", default = true })
vim.api.nvim_set_hl(0, "ScratchResult", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "ScratchResultBorder", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "ScratchResultSuccess", { link = "DiagnosticOk", default = true })
vim.api.nvim_set_hl(0, "ScratchResultError", { link = "DiagnosticError", default = true })
vim.api.nvim_set_hl(0, "ScratchLineResult", { link = "Special", default = true })
vim.api.nvim_set_hl(0, "ScratchDebugHighlight", { bg = "#2D4F6D", default = true })

--- Helper function to merge tables
local function merge_tables(...)
  local result = {}
  for i = 1, select("#", ...) do
    local t = select(i, ...)
    if t then
      for k, v in pairs(t) do
        result[k] = v
      end
    end
  end
  return result
end

--- Helper function to get file icon
local function get_icon(ft, default)
  if vim.fn.exists("*nvim_get_hl") == 1 then
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      local icon, hl = devicons.get_icon_by_filetype(ft, { default = true })
      return icon, hl
    end
  end
  return default or ""
end

--- Helper function to normalize paths
local function normalize_path(path)
  if path:sub(1, 1) == "~" then
    local home = os.getenv("HOME")
    return home .. path:sub(2)
  end
  return path
end

--- Helper function to encode filename
local function file_encode(str)
  return str:gsub("[^%w%-_%.]", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

--- Helper function to decode filename
local function file_decode(str)
  return str:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
end

--- Create a floating window
local function create_win(opts)
  -- Apply UI customization
  local ui_opts = defaults.ui or {}

  -- Separate window options from nvim_open_win options
  local win_opts = {
    relative = "editor",
    width = opts.width or 80,
    height = opts.height or 20,
    row = (vim.o.lines - (opts.height or 20)) / 2,
    col = (vim.o.columns - (opts.width or 80)) / 2,
    style = "minimal",
    border = opts.border or ui_opts.float_border or "rounded",
    title = opts.title,
    title_pos = opts.title_pos or ui_opts.float_title_style or "left",
    zindex = opts.zindex or 20,
  }


  -- Only add footer-related options if a footer is provided
  if opts.footer then
    win_opts.footer = opts.footer
    win_opts.footer_pos = opts.footer_pos or "left"
  end

  local buf = opts.buf or vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Apply buffer options
  if opts.bo then
    for k, v in pairs(opts.bo) do
      vim.api.nvim_buf_set_option(buf, k, v)
    end
  end

  -- Apply window options
  if opts.wo then
    for k, v in pairs(opts.wo) do
      vim.api.nvim_win_set_option(win, k, v)
    end
  end

  -- Apply additional window configuration if available
  if opts.keys then
    local keymap_group = vim.api.nvim_create_augroup("ScratchWinKeymaps" .. win, { clear = true })
    for _, keymap in pairs(opts.keys) do
      if type(keymap) == "table" and #keymap >= 2 then
        local modes = keymap.mode or { "n" }
        if type(modes) == "string" then modes = { modes } end

        for _, mode in ipairs(modes) do
          vim.api.nvim_buf_set_keymap(buf, mode, keymap[1], "", {
            callback = function()
              if type(keymap[2]) == "function" then
                keymap[2]({ buf = buf, win = win })
              end
            end,
            noremap = true,
            silent = true,
            desc = keymap.desc,
          })
        end
      end
    end
  end

  return {
    buf = buf,
    win = win,
    close = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  }
end

--- Return a list of scratch buffers sorted by mtime.
---@return table[]
function Scratch.list()
  local root = defaults.root
  ---@type table[]
  local ret = {}

  -- Create root directory if it doesn't exist
  if not uv.fs_stat(root) then
    vim.fn.mkdir(root, "p")
    return ret
  end

  for file, t in vim.fs.dir(root) do
    if t == "file" then
      local decoded = file_decode(file)
      local count, icon, name, cwd, branch, ft = decoded:match("^(%d*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)%.([^|]*)$")
      if count and icon and name and cwd and branch and ft then
        file = normalize_path(root .. "/" .. file)
        table.insert(ret, {
          file = file,
          stat = uv.fs_stat(file),
          count = count ~= "" and tonumber(count) or nil,
          icon = icon ~= "" and icon or nil,
          name = name,
          cwd = cwd ~= "" and cwd or nil,
          branch = branch ~= "" and branch or nil,
          ft = ft,
        })
      end
    end
  end
  table.sort(ret, function(a, b)
    return a.stat.mtime.sec > b.stat.mtime.sec
  end)
  return ret
end

--- Select a scratch buffer from a list of scratch buffers.
function Scratch.select()
  local widths = { 0, 0, 0, 0 }
  local items = Scratch.list()
  for _, item in ipairs(items) do
    item.icon = item.icon or get_icon(item.ft)
    item.branch = item.branch and ("branch:%s"):format(item.branch) or ""
    item.cwd = item.cwd and vim.fn.fnamemodify(item.cwd, ":p:~") or ""
    widths[1] = math.max(widths[1], vim.api.nvim_strwidth(item.cwd))
    widths[2] = math.max(widths[2], vim.api.nvim_strwidth(item.icon))
    widths[3] = math.max(widths[3], vim.api.nvim_strwidth(item.name))
    widths[4] = math.max(widths[4], vim.api.nvim_strwidth(item.branch))
  end

  -- Check if fzf-lua is available
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

  if has_fzf_lua and #items > 0 then
    -- Format items for fzf-lua
    local fzf_items = {}
    for _, item in ipairs(items) do
      local parts = { item.cwd, item.icon, item.name, item.branch }
      for i, part in ipairs(parts) do
        parts[i] = part .. string.rep(" ", widths[i] - vim.api.nvim_strwidth(part))
      end
      table.insert(fzf_items, {
        table.concat(parts, " "),
        file = item.file,
        ft = item.ft,
        name = item.name,
        icon = item.icon,
      })
    end

    fzf_lua.fzf_exec(fzf_items, {
      prompt = "Scratch Buffers> ",
      winopts = {
        height = 0.6,
        width = 0.8,
        preview = {
          layout = "vertical",
          vertical = "down:50%",
        },
      },
      previewer = "buffer",
      actions = {
        ["default"] = function(selected)
          if selected and selected[1] then
            local entry = selected[1]
            Scratch.open({
              file = entry.file,
              ft = entry.ft,
              name = entry.name,
              icon = entry.icon,
            })
          end
        end,
        ["ctrl-x"] = function(selected)
          if selected and selected[1] then
            local entry = selected[1]
            -- Confirm deletion
            vim.ui.select({ "Yes", "No" }, {
              prompt = "Delete scratch file?",
            }, function(choice)
              if choice == "Yes" then
                if Scratch.delete_scratch(entry.file) then
                  -- Re-run the selection to refresh the list
                  vim.defer_fn(function()
                    Scratch.select()
                  end, 100)
                end
              end
            end)
          end
        end,
      },
      keymap = {
        fzf = {
          ["ctrl-x"] = "execute-silent(echo Delete)",
        },
      },
      -- Show keybindings in header
      prompt_fmt = function(...)
        local header = "▶ Enter: Open | CTRL-X: Delete"
        return fzf_lua.utils.ansi_codes.red ..
            header .. fzf_lua.utils.ansi_codes.reset .. "\n" .. fzf_lua.make_entry.prompt(...)
      end,
    })
  else
    -- Fallback to built-in select
    vim.ui.select(items, {
      prompt = "Select Scratch Buffer",
      ---@param item table
      format_item = function(item)
        local parts = { item.cwd, item.icon, item.name, item.branch }
        for i, part in ipairs(parts) do
          parts[i] = part .. string.rep(" ", widths[i] - vim.api.nvim_strwidth(part))
        end
        return table.concat(parts, " ")
      end,
    }, function(selected)
      if selected then
        -- Add option to delete
        vim.ui.select({ "Open", "Delete" }, {
          prompt = "Action for " .. selected.name,
        }, function(action)
          if action == "Open" then
            Scratch.open({ icon = selected.icon, file = selected.file, name = selected.name, ft = selected.ft })
          elseif action == "Delete" then
            Scratch.delete_scratch(selected.file)
          end
        end)
      end
    end)
  end
end

--- Execute code in the scratch buffer with line-by-line results
---@param buf number Buffer handle
---@param start_line? number Starting line (0-indexed)
---@param end_line? number Ending line (0-indexed)
---@param debug_mode? boolean Whether to execute in debug mode
function Scratch.execute_code(buf, start_line, end_line, debug_mode)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Skip execution if buffer is empty
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return
  end

  -- If no range specified, check for visual selection
  if start_line == nil or end_line == nil then
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" then
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      start_line = start_pos[2] - 1
      end_line = end_pos[2] - 1
      vim.api.nvim_input("<Esc>") -- Exit visual mode
    else
      -- Execute the entire buffer
      start_line = 0
      end_line = #lines - 1
    end
  end

  -- Don't try to execute empty regions
  if start_line > end_line or #lines == 0 then
    vim.notify("No code to execute", vim.log.levels.WARN)
    return
  end

  -- Clear previous results
  if defaults.visual_results then
    vim.api.nvim_buf_clear_namespace(buf, defaults.result_ns, 0, -1)
  end

  -- Get the appropriate interpreter for this filetype
  local interpreter = defaults.interpreters[ft]
  local all_results = {}
  local debug_results = {}

  -- Setup debug highlighting if in debug mode
  if debug_mode then
    vim.api.nvim_buf_clear_namespace(buf, defaults.debug_ns or 0, 0, -1)
    defaults.debug_ns = defaults.debug_ns or vim.api.nvim_create_namespace("ScratchDebug")
  end

  -- Line-by-line execution for Lua
  if ft == "lua" or interpreter == "neovim" then
    -- Store the full context for line-by-line execution
    local full_env = {}
    local context = _G

    -- Execute each line and collect results
    for i = start_line, end_line do
      local line = lines[i + 1]
      -- Skip empty lines or comment-only lines
      if line:match("^%s*$") or line:match("^%s*%-%-") then
        all_results[i] = { text = "", success = true }
      else
        -- Setup capture for print output
        local output = {}
        local old_print = print
        _G.print = function(...)
          local args = { ... }
          local str_args = {}
          for j, v in ipairs(args) do
            str_args[j] = tostring(v)
          end
          table.insert(output, table.concat(str_args, "\t"))
        end

        -- Try to execute line as expression first
        local chunk, load_err
        if _VERSION == "Lua 5.1" then
          -- LuaJIT/5.1 way
          chunk, load_err = loadstring("return " .. line)
          if not chunk then
            -- If it fails as expression, try as statement
            chunk, load_err = loadstring(line)
          end
        else
          -- Lua 5.2+ way
          chunk, load_err = load("return " .. line, "scratch_line", "t", context)
          if not chunk then
            -- Try as statement(s) if expression didn't work
            chunk, load_err = load(line, "scratch_line", "t", context)
          end
        end

        local result_text
        local success = true

        if not chunk then
          result_text = "Error: " .. tostring(load_err)
          success = false
        else
          -- Execute the chunk in the current context
          local func_result
          success, func_result = pcall(chunk)

          if not success then
            result_text = "Error: " .. tostring(func_result)
          else
            if #output > 0 then
              result_text = table.concat(output, ", ")
            elseif func_result ~= nil then
              result_text = vim.inspect(func_result)

              -- Update context for next line with the result if it was an assignment
              if line:match("^%s*local%s+[%w_]+%s*=") or line:match("^%s*[%w_%.]+%s*=") then
                local var_name = line:match("^%s*local%s+([%w_]+)%s*=") or line:match("^%s*([%w_%.]+)%s*=")
                if var_name then
                  full_env[var_name] = func_result
                end
              end
            else
              result_text = "✓"
            end
          end
        end

        -- Restore print
        _G.print = old_print

        -- Store the result
        all_results[i] = { text = result_text or "", success = success }

        -- If in debug mode, highlight the current line
        if debug_mode then
          -- Add debug highlight
          vim.api.nvim_buf_add_highlight(buf, defaults.debug_ns, "ScratchDebugHighlight", i, 0, -1)
          if i < end_line then
            -- If not the last line, wait for user keypress to continue
            vim.api.nvim_echo(
              { { ("Debug [%d/%d]: Press any key to continue..."):format(i - start_line + 1, end_line - start_line + 1), "WarningMsg" } },
              true, {})
            vim.fn.getchar()
          end
        end
      end
    end

    -- Show each result under its corresponding line
    for i = start_line, end_line do
      local result = all_results[i]
      if result and result.text ~= "" and defaults.visual_results then
        local hl_group = result.success and (defaults.ui.hl_result or "ScratchLineResult") or
            (defaults.ui.hl_error or "ScratchResultError")

        -- Add padding between code and result
        local padding = string.rep(" ", defaults.ui.result_padding or 2)

        -- Always use end-of-line virtual text for cleaner display
        vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, i, 0, {
          virt_text = { { padding .. defaults.result_indicator .. " " .. result.text, hl_group } },
          virt_text_pos = "eol",
          hl_mode = "combine",
        })
      end
    end

    -- Store the latest result
    Scratch.active_scratches[ft] = Scratch.active_scratches[ft] or {}
    Scratch.active_scratches[ft].last_results = all_results

    return all_results
  elseif interpreter then
    -- For other languages, we'll execute the whole block and try to parse line by line results
    local selected_lines = vim.list_slice(lines, start_line + 1, end_line + 1)
    local code = table.concat(selected_lines, "\n")

    -- Skip empty code
    if code:match("^%s*$") then return {} end

    local tempfile = os.tmpname() .. "." .. ft
    local fd = assert(uv.fs_open(tempfile, "w", 438))
    assert(uv.fs_write(fd, code, -1))
    assert(uv.fs_close(fd))

    -- Execute the code with the appropriate interpreter
    local cmd = interpreter .. " " .. vim.fn.shellescape(tempfile)
    local output = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    local success = exit_code == 0

    os.remove(tempfile)

    -- Try to split the output into lines corresponding to input
    local output_lines = vim.split(output, "\n")

    -- Show the entire output at the end of the selected region
    if defaults.visual_results then
      local hl_group = success and "ScratchResultSuccess" or "ScratchResultError"

      if success and #output_lines > 0 then
        -- Try to associate output lines with input lines
        local current_line = start_line
        for i, oline in ipairs(output_lines) do
          if oline ~= "" then
            -- Always use end-of-line results for clarity
            local padding = string.rep(" ", defaults.ui.result_padding or 2)
            vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, current_line, 0, {
              virt_text = { { padding .. defaults.result_indicator .. " " .. oline, defaults.ui.hl_result or "ScratchLineResult" } },
              virt_text_pos = "eol",
              hl_mode = "combine",
            })
          end
          -- Move to next line up to end_line
          if current_line < end_line then
            current_line = current_line + 1
          end
        end
      else
        -- Show entire output at the end
        for i, oline in ipairs(output_lines) do
          if oline ~= "" then
            local padding = string.rep(" ", defaults.ui.result_padding or 2)
            vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
              virt_text = { { padding .. defaults.result_indicator .. " " .. oline, success and (defaults.ui.hl_result or "ScratchLineResult") or (defaults.ui.hl_error or "ScratchResultError") } },
              virt_text_pos = "eol",
              hl_mode = "combine",
            })
          end
        end
      end
    end

    -- Store the latest result
    local all_results = {
      { line = end_line, text = output, success = success }
    }
    Scratch.active_scratches[ft] = Scratch.active_scratches[ft] or {}
    Scratch.active_scratches[ft].last_results = all_results

    return all_results
  else
    -- Unsupported filetype
    local result = "Execution not supported for filetype: " .. ft
    if defaults.visual_results then
      local padding = string.rep(" ", defaults.ui.result_padding or 2)
      vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
        virt_text = { { padding .. defaults.result_indicator .. " " .. result, defaults.ui.hl_error or "ScratchResultError" } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
    end
    vim.notify(result, vim.log.levels.WARN)
    return { { line = end_line, text = result, success = false } }
  end
end

--- Toggle debugging mode
function Scratch.toggle_debug_mode()
  local active = Scratch.get_active_scratch()
  if not active or not active.buf or not vim.api.nvim_buf_is_valid(active.buf) then
    vim.notify("No active scratch buffer to debug", vim.log.levels.WARN)
    return
  end

  local ft = vim.api.nvim_buf_get_option(active.buf, "filetype")
  active.debug_mode = not (active.debug_mode or false)

  if active.debug_mode then
    vim.notify("Debug mode enabled for " .. ft .. " scratch buffer", vim.log.levels.INFO)
    -- Execute in debug mode
    Scratch.execute_code(active.buf, nil, nil, true)
  else
    vim.notify("Debug mode disabled", vim.log.levels.INFO)
    -- Clear debug highlights
    if defaults.debug_ns then
      vim.api.nvim_buf_clear_namespace(active.buf, defaults.debug_ns, 0, -1)
    end
  end
end

--- Clear all unnamed scratch buffers
function Scratch.clear_unnamed()
  local root = defaults.root
  local count = 0

  for file, t in vim.fs.dir(root) do
    if t == "file" and not file:match("^named/") then
      local full_path = root .. "/" .. file
      os.remove(full_path)
      count = count + 1
    end
  end

  vim.notify("Cleared " .. count .. " unnamed scratch files", vim.log.levels.INFO)
end

--- Delete a scratch file
---@param file string Path to the scratch file
function Scratch.delete_scratch(file)
  if uv.fs_stat(file) then
    os.remove(file)
    vim.notify("Deleted scratch file: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
    return true
  else
    vim.notify("File not found: " .. file, vim.log.levels.ERROR)
    return false
  end
end

--- Show execution results in the buffer
---@param buf number Buffer handle
---@param end_line number End line of executed code
---@param result string Result text
---@param success boolean Whether execution was successful
function Scratch.show_results(buf, end_line, result, success)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Default to the stored result if not provided
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  if not result then
    if not Scratch.active_scratches[ft] or not Scratch.active_scratches[ft].last_results then
      return
    end
    result = Scratch.active_scratches[ft].last_results[end_line] and
        Scratch.active_scratches[ft].last_results[end_line].text or ""
    success = Scratch.active_scratches[ft].last_results[end_line] and
        Scratch.active_scratches[ft].last_results[end_line].success or false
  end

  local result_lines = vim.split(result, "\n")

  -- Remove trailing empty line that often appears in command output
  if result_lines[#result_lines] == "" then
    table.remove(result_lines)
  end

  -- Handle empty results
  if #result_lines == 0 then
    if success then
      result_lines = { "✓ Executed successfully with no output" }
    else
      result_lines = { "✗ Execution completed with no output" }
    end
  end

  -- Add virtual text for each line of the result
  if #result_lines > 0 then
    -- Choose highlight based on success
    local hl_group = success and "ScratchResultSuccess" or "ScratchResultError"

    -- Add separator line at the top
    vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
      virt_text = { { "─── Result ───", "ScratchResultBorder" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })

    -- Add all result lines
    for i, line in ipairs(result_lines) do
      if i == 1 then
        -- First line gets special treatment with an arrow indicator
        vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
          virt_lines = { { { "▸ " .. line, hl_group } } },
          virt_lines_above = false,
        })
      else
        -- Subsequent lines are indented
        vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
          virt_lines = { { { "  " .. line, "ScratchResult" } } },
          virt_lines_above = false,
        })
      end
    end

    -- Add separator line at the bottom if there are multiple lines
    if #result_lines > 1 then
      vim.api.nvim_buf_set_extmark(buf, defaults.result_ns, end_line, 0, {
        virt_lines = { { { "───────────", "ScratchResultBorder" } } },
        virt_lines_above = false,
      })
    end
  end
end

--- Toggle showing/hiding visual results
function Scratch.toggle_results(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  defaults.visual_results = not defaults.visual_results

  -- Clear the results if we're hiding them
  if not defaults.visual_results then
    vim.api.nvim_buf_clear_namespace(buf, defaults.result_ns, 0, -1)
    vim.notify("Visual results hidden")
  else
    -- Show the last result if we have one
    local ft = vim.api.nvim_buf_get_option(buf, "filetype")
    if Scratch.active_scratches[ft] and Scratch.active_scratches[ft].last_results then
      -- Find the end of the buffer to show the result
      local line_count = vim.api.nvim_buf_line_count(buf)
      Scratch.show_results(buf, line_count - 1,
        Scratch.active_scratches[ft].last_results[line_count - 1] and
        Scratch.active_scratches[ft].last_results[line_count - 1].text or "",
        Scratch.active_scratches[ft].last_results[line_count - 1] and
        Scratch.active_scratches[ft].last_results[line_count - 1].success or false)
      vim.notify("Visual results shown")
    else
      vim.notify("Visual results enabled (execute code to see results)")
    end
  end
end

--- Hide active scratch buffer without closing it
function Scratch.hide()
  local active = Scratch.get_active_scratch()
  if active and active.win and vim.api.nvim_win_is_valid(active.win) then
    if defaults.save_on_toggle and active.buf and vim.api.nvim_buf_is_valid(active.buf) then
      vim.api.nvim_buf_call(active.buf, function()
        vim.cmd("silent! write")
      end)
    end
    vim.api.nvim_win_close(active.win, true)
  end
end

--- Save scratch buffer with a custom name
---@param buf number Buffer handle
---@param custom_name? string Custom name for the file
function Scratch.save_named(buf, custom_name)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  -- Get or create a custom name
  if not custom_name then
    custom_name = vim.fn.input({
      prompt = "Save scratch as: ",
      default = Scratch.active_scratches[ft] and Scratch.active_scratches[ft].name or "scratch",
      completion = "file",
    })

    if custom_name == "" then
      return
    end
  end

  -- Create the target file path
  local dir = defaults.root .. "/named"
  vim.fn.mkdir(dir, "p")

  -- Sanitize the name for file system
  local safe_name = custom_name:gsub("[^%w%-_%.%s]", "_")
  local file_path = dir .. "/" .. safe_name .. "." .. ft

  -- Write the buffer content to the file
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local fd = assert(uv.fs_open(file_path, "w", 438))
  assert(uv.fs_write(fd, table.concat(lines, "\n"), -1))
  assert(uv.fs_close(fd))

  -- Update the active scratch info
  if Scratch.active_scratches[ft] then
    Scratch.active_scratches[ft].file = file_path
    Scratch.active_scratches[ft].name = custom_name
  end

  vim.notify("Saved scratch as: " .. custom_name, vim.log.levels.INFO)

  return file_path
end

--- Get active scratch for current filetype
function Scratch.get_active_scratch()
  local ft = vim.bo.filetype
  return Scratch.active_scratches[ft]
end

--- Toggle scratch buffer for current filetype
function Scratch.toggle()
  local ft = vim.bo.filetype
  local active = Scratch.active_scratches[ft]

  if active and active.win and vim.api.nvim_win_is_valid(active.win) then
    -- Hide if visible
    if defaults.save_on_toggle and active.buf and vim.api.nvim_buf_is_valid(active.buf) then
      vim.api.nvim_buf_call(active.buf, function()
        vim.cmd("silent! write")
      end)
    end

    -- Store window position and size for reopening in the same spot
    local win_config = vim.api.nvim_win_get_config(active.win)
    if win_config and win_config.relative ~= "" then
      active.last_win_config = {
        relative = win_config.relative,
        row = win_config.row,
        col = win_config.col,
        width = win_config.width,
        height = win_config.height,
      }
    end

    vim.api.nvim_win_close(active.win, true)
    return
  elseif active and active.buf and vim.api.nvim_buf_is_valid(active.buf) then
    -- Reopen if buffer exists but window is closed
    local win_config = merge_tables(defaults.win, defaults.win_by_ft[ft] or {})
    win_config.buf = active.buf

    -- Restore previous window position if available
    if active.last_win_config then
      win_config.row = active.last_win_config.row
      win_config.col = active.last_win_config.col
      win_config.width = active.last_win_config.width
      win_config.height = active.last_win_config.height
    end

    -- Add the title
    local icon, icon_hl = get_icon(ft)
    local title = {
      { " " },
      { icon .. string.rep(" ", 2 - vim.api.nvim_strwidth(icon)), icon_hl },
      { " " },
      { active.name or "Scratch",                                 "ScratchTitle" },
      { " " },
    }
    win_config.title = title

    -- Setup window keys
    win_config.keys = win_config.keys or {}
    win_config.keys.hide = { defaults.keymaps.hide, function() Scratch.hide() end, desc = "Hide scratch buffer" }
    win_config.keys.toggle_results = {
      defaults.keymaps.toggle_results,
      function() Scratch.toggle_results(active.buf) end,
      desc =
      "Toggle results"
    }
    win_config.keys.save = {
      defaults.keymaps.save,
      function() Scratch.save_named(active.buf) end,
      desc =
      "Save with name"
    }
    win_config.keys.execute = {
      defaults.keymaps.execute,
      function(self) Scratch.execute_code(self.buf) end,
      desc = "Execute code",
      mode = { "n", "v" }
    }

    -- Prepare footer with keybindings
    local footer = {}
    if win_config.keys then
      local keys = {}
      for name, key in pairs(win_config.keys) do
        if type(name) == "string" and type(key) == "table" then
          table.insert(keys, key)
        end
      end
      table.sort(keys, function(a, b)
        return a[1] < b[1]
      end)
      for _, key in ipairs(keys) do
        local keymap = vim.fn.keytrans(vim.api.nvim_replace_termcodes(key[1], true, true, true))
        table.insert(footer, { " " })
        table.insert(footer, { " " .. keymap .. " ", "ScratchKey" })
        table.insert(footer, { " " .. (key.desc or keymap) .. " ", "ScratchDesc" })
      end
      table.insert(footer, { " " })
    end

    -- Add footer to config
    win_config.footer = footer

    -- Create window - FIXED: pass win_config directly, not opts.win
    local win_obj = create_win(win_config)
    active.win = win_obj.win

    -- Execute any existing code to show results immediately if applicable
    if defaults.real_time_execution and defaults.visual_results then
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(active.win) and vim.api.nvim_buf_is_valid(active.buf) then
          vim.api.nvim_buf_call(active.buf, function()
            Scratch.execute_code(active.buf)
          end)
        end
      end, 100)
    end

    -- Setup the buffer
    Scratch.setup_buffer_commands(active.buf, ft)
    return active
  else
    -- Create new scratch
    return Scratch.open({ ft = ft })
  end
end

--- List all named scratch files
---@return table[] Named scratch files
function Scratch.list_named()
  local dir = defaults.root .. "/named"
  local named_files = {}

  -- Ensure the directory exists
  if not uv.fs_stat(dir) then
    vim.fn.mkdir(dir, "p")
    return named_files
  end

  -- Read the directory
  for file, t in vim.fs.dir(dir) do
    if t == "file" then
      local name, ft = file:match("^(.+)%.(.+)$")
      if name and ft then
        local full_path = dir .. "/" .. file
        table.insert(named_files, {
          name = name,
          ft = ft,
          file = full_path,
          stat = uv.fs_stat(full_path),
        })
      end
    end
  end

  -- Sort by last modified
  table.sort(named_files, function(a, b)
    return a.stat.mtime.sec > b.stat.mtime.sec
  end)

  return named_files
end

--- Select a named scratch file using fzf-lua if available
function Scratch.select_named()
  local named_files = Scratch.list_named()

  if #named_files == 0 then
    vim.notify("No named scratch files found", vim.log.levels.INFO)
    return
  end

  -- Check if fzf-lua is available
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

  if has_fzf_lua then
    -- Format items for fzf-lua
    local items = {}
    for _, file in ipairs(named_files) do
      local icon, hl = get_icon(file.ft)
      local modified = os.date("%Y-%m-%d %H:%M", file.stat.mtime.sec)
      table.insert(items, {
        file.name,
        icon,
        file.ft,
        modified,
        file = file.file,
      })
    end

    fzf_lua.fzf_exec(items, {
      prompt = "Scratch Files> ",
      winopts = {
        height = 0.6,
        width = 0.8,
        preview = {
          layout = "vertical",
          vertical = "down:50%",
        },
      },
      previewer = "buffer",
      actions = {
        ["default"] = function(selected)
          if selected and selected[1] then
            local entry = selected[1]
            Scratch.open({
              file = entry.file,
              ft = entry.value[3],
              name = entry.value[1],
            })
          end
        end,
        ["ctrl-x"] = function(selected)
          if selected and selected[1] then
            local entry = selected[1]
            -- Confirm deletion
            vim.ui.select({ "Yes", "No" }, {
              prompt = "Delete scratch file '" .. entry.value[1] .. "'?",
            }, function(choice)
              if choice == "Yes" then
                if Scratch.delete_scratch(entry.file) then
                  -- Re-run the selection to refresh the list
                  vim.defer_fn(function()
                    Scratch.select_named()
                  end, 100)
                end
              end
            end)
          end
        end,
      },
      fzf_opts = {
        ["--delimiter"] = "\t",
        ["--with-nth"] = "1,2,3,4",
      },
      keymap = {
        fzf = {
          ["ctrl-x"] = "execute-silent(echo Delete)",
        },
      },
      -- Show keybindings in header
      prompt_fmt = function(...)
        local header = "▶ Enter: Open | CTRL-X: Delete"
        return fzf_lua.utils.ansi_codes.red ..
            header .. fzf_lua.utils.ansi_codes.reset .. "\n" .. fzf_lua.make_entry.prompt(...)
      end,
    })
  else
    -- Fallback to built-in select
    vim.ui.select(named_files, {
      prompt = "Select Scratch File",
      format_item = function(item)
        local icon = get_icon(item.ft)
        local modified = os.date("%Y-%m-%d %H:%M", item.stat.mtime.sec)
        return string.format("%s %s (%s) - %s", icon, item.name, item.ft, modified)
      end,
    }, function(selected)
      if selected then
        -- Add option to delete
        vim.ui.select({ "Open", "Delete" }, {
          prompt = "Action for " .. selected.name,
        }, function(action)
          if action == "Open" then
            Scratch.open({
              file = selected.file,
              ft = selected.ft,
              name = selected.name,
            })
          elseif action == "Delete" then
            Scratch.delete_scratch(selected.file)
          end
        end)
      end
    end)
  end
end

--- Setup buffer-local commands for scratch buffer
function Scratch.setup_buffer_commands(buf)
  -- Add buffer-local keymaps for execution
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.execute,
    [[<cmd>lua require('SciVim.extras.scratch').execute_code(]] .. buf .. [[)<CR>]],
    { noremap = true, silent = true, desc = "Execute code" })

  vim.api.nvim_buf_set_keymap(buf, "v", defaults.keymaps.execute,
    [[<cmd>lua require('SciVim.extras.scratch').execute_code(]] .. buf .. [[)<CR>]],
    { noremap = true, silent = true, desc = "Execute selected code" })

  -- Add hide keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.hide,
    [[<cmd>lua require('SciVim.extras.scratch').hide()<CR>]],
    { noremap = true, silent = true, desc = "Hide scratch buffer" })

  -- Add toggle results keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.toggle_results,
    [[<cmd>lua require('SciVim.extras.scratch').toggle_results(]] .. buf .. [[)<CR>]],
    { noremap = true, silent = true, desc = "Toggle result display" })

  -- Add save keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.save,
    [[<cmd>lua require('SciVim.extras.scratch').save_named(]] .. buf .. [[)<CR>]],
    { noremap = true, silent = true, desc = "Save scratch with name" })

  -- Add toggle debug keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.toggle_debug,
    [[<cmd>lua require('SciVim.extras.scratch').toggle_debug_mode()<CR>]],
    { noremap = true, silent = true, desc = "Toggle debug mode" })

  -- Add clear results keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.clear_results,
    [[<cmd>lua require('SciVim.extras.scratch').clear_results(]] .. buf .. [[)<CR>]],
    { noremap = true, silent = true, desc = "Clear execution results" })

  -- Add toggle real-time execution keymap
  vim.api.nvim_buf_set_keymap(buf, "n", defaults.keymaps.toggle_real_time,
    [[<cmd>ScratchToggleRealTime<CR>]],
    { noremap = true, silent = true, desc = "Toggle real-time execution" })

  -- Add buffer autocmds
  local group = vim.api.nvim_create_augroup("ScratchBuffer" .. buf, { clear = true })

  -- Hide results when entering insert mode
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    buffer = buf,
    callback = function()
      vim.api.nvim_buf_clear_namespace(buf, defaults.result_ns, 0, -1)
    end,
  })

  -- Handle real-time execution when leaving insert mode
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    buffer = buf,
    callback = function()
      if defaults.visual_results then
        if defaults.real_time_execution then
          -- Execute code in real-time
          Scratch.execute_code(buf)
        elseif defaults.show_results_on_execute then
          -- Just show the last result if we have one
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")
          if Scratch.active_scratches[ft] and Scratch.active_scratches[ft].last_results then
            local line_count = vim.api.nvim_buf_line_count(buf)
            Scratch.show_results(buf, line_count - 1,
              Scratch.active_scratches[ft].last_results[line_count - 1] and
              Scratch.active_scratches[ft].last_results[line_count - 1].text or "",
              Scratch.active_scratches[ft].last_results[line_count - 1] and
              Scratch.active_scratches[ft].last_results[line_count - 1].success or false)
          end
        end
      end
    end,
  })

  -- Auto-write when hiding
  if defaults.autowrite then
    vim.api.nvim_create_autocmd("BufHidden", {
      group = group,
      buffer = buf,
      callback = function(ev)
        vim.api.nvim_buf_call(ev.buf, function()
          vim.cmd("silent! write")
        end)
      end,
    })
  end

  -- Set buffer-local commands
  vim.api.nvim_buf_create_user_command(buf, "ScratchToggleResults", function()
    Scratch.toggle_results(buf)
  end, {})

  vim.api.nvim_buf_create_user_command(buf, "ScratchSave", function(opts)
    Scratch.save_named(buf, opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_buf_create_user_command(buf, "ScratchToggleRealTime", function()
    defaults.real_time_execution = not defaults.real_time_execution
    local status = defaults.real_time_execution and "enabled" or "disabled"
    vim.notify("Real-time execution " .. status, vim.log.levels.INFO)
  end, {})

  vim.api.nvim_buf_create_user_command(buf, "ScratchToggleDebug", function()
    Scratch.toggle_debug_mode()
  end, {})

  vim.api.nvim_buf_create_user_command(buf, "ScratchClearResults", function()
    Scratch.clear_results(buf)
  end, {})

  -- Set as scratch buffer
  vim.api.nvim_buf_set_var(buf, "is_scratch", true)
end

--- Open a scratch buffer with the given options.
---@param opts? Scratch.Config
function Scratch.open(opts)
  opts = merge_tables(defaults, opts or {})
  local ft = "markdown"
  if type(opts.ft) == "function" then
    ft = opts.ft()
  elseif type(opts.ft) == "string" then
    ft = opts.ft --[[@as string]]
  end

  opts.win = merge_tables(defaults.win, opts.win_by_ft[ft] or {}, {})
  opts.win.bo = opts.win.bo or {}
  opts.win.bo.filetype = ft

  local file = opts.file
  if not file then
    -- Check if this is a named scratch file
    if opts.name and opts.name ~= "Scratch" then
      local dir = defaults.root .. "/named"
      vim.fn.mkdir(dir, "p")
      local safe_name = opts.name:gsub("[^%w%-_%.%s]", "_")
      file = dir .. "/" .. safe_name .. "." .. ft
    else
      -- Create a regular scratch file
      local branch = ""
      if opts.filekey.branch and uv.fs_stat(".git") then
        local ret = vim.fn.systemlist("git branch --show-current")[1]
        if vim.v.shell_error == 0 then
          branch = ret
        end
      end

      local filekey = {
        opts.filekey.count and tostring(vim.v.count1) or "",
        opts.icon or "",
        opts.name:gsub("|", " "),
        opts.filekey.cwd and normalize_path(assert(uv.cwd())) or "",
        branch,
      }

      vim.fn.mkdir(opts.root, "p")
      local fname = file_encode(table.concat(filekey, "|") .. "." .. ft)
      file = opts.root .. "/" .. fname
    end
  end
  file = normalize_path(file)

  local icon, icon_hl = unpack(type(opts.icon) == "table" and opts.icon or { opts.icon, nil })
  if not icon then
    icon, icon_hl = get_icon(ft)
  end

  local title = {
    { " " },
    { icon .. string.rep(" ", 2 - vim.api.nvim_strwidth(icon)),     icon_hl },
    { " " },
    { opts.name .. (vim.v.count1 > 1 and " " .. vim.v.count1 or "") },
    { " " },
  }
  for _, t in ipairs(title) do
    t[2] = t[2] or "ScratchTitle"
  end

  local is_new = not uv.fs_stat(file)
  local buf = vim.fn.bufadd(file)

  -- Check for existing scratch buffer
  local active = Scratch.active_scratches[ft]
  if active and active.win and vim.api.nvim_win_is_valid(active.win) then
    vim.api.nvim_win_close(active.win, true)
  end

  is_new = is_new
      and vim.api.nvim_buf_line_count(buf) == 0
      and #(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == 0

  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  if opts.template and is_new then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.template, "\n"))
  end

  -- Setup window keys
  opts.win.keys = opts.win.keys or {}
  opts.win.keys.hide = { defaults.keymaps.hide, function() Scratch.hide() end, desc = "Hide scratch buffer" }
  opts.win.keys.toggle_results = {
    defaults.keymaps.toggle_results,
    function() Scratch.toggle_results(buf) end,
    desc =
    "Toggle results"
  }
  opts.win.keys.save = { defaults.keymaps.save, function() Scratch.save_named(buf) end, desc = "Save with name" }

  -- Add execution key if not already set
  if not opts.win.keys.execute then
    opts.win.keys.execute = {
      defaults.keymaps.execute,
      function(self) Scratch.execute_code(self.buf) end,
      desc = "Execute code",
      mode = { "n", "v" }
    }
  end

  if opts.template then
    local function reset()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.template, "\n"))
    end
    opts.win.keys.reset = { "R", reset, desc = "Reset buffer" }
  end

  opts.win.buf = buf
  opts.win.title = title

  -- Prepare footer with keybindings
  local footer = {}
  if opts.win.keys then
    local keys = {}
    for name, key in pairs(opts.win.keys) do
      if type(name) == "string" and type(key) == "table" then
        table.insert(keys, key)
      end
    end
    table.sort(keys, function(a, b)
      return a[1] < b[1]
    end)
    for _, key in ipairs(keys) do
      local keymap = vim.fn.keytrans(vim.api.nvim_replace_termcodes(key[1], true, true, true))
      table.insert(footer, { " " })
      table.insert(footer, { " " .. keymap .. " ", "ScratchKey" })
      table.insert(footer, { " " .. (key.desc or keymap) .. " ", "ScratchDesc" })
    end
    table.insert(footer, { " " })
  end

  local win = create_win(merge_tables(opts.win, {
    footer = footer,
  }))

  -- Setup buffer commands and mappings
  Scratch.setup_buffer_commands(buf)

  -- Store active scratch buffer
  Scratch.active_scratches[ft] = {
    buf = buf,
    win = win.win,
    file = file,
    ft = ft,
    name = opts.name or "Scratch"
  }

  return win
end

-- Setup function
function Scratch.setup(opts)
  -- Merge user config with defaults
  defaults = merge_tables(defaults, opts or {})

  -- Apply theme if enabled
  if defaults.ui.themed then
    -- Set highlight groups with user's colorscheme
    vim.api.nvim_set_hl(0, "ScratchTitle", { link = "FloatTitle", default = true })
    vim.api.nvim_set_hl(0, "ScratchFooter", { link = "FloatFooter", default = true })
    vim.api.nvim_set_hl(0, "ScratchKey", { link = "DiagnosticVirtualTextInfo", default = true })
    vim.api.nvim_set_hl(0, "ScratchDesc", { link = "DiagnosticInfo", default = true })
    vim.api.nvim_set_hl(0, "ScratchResult", { link = "Comment", default = true })
    vim.api.nvim_set_hl(0, "ScratchResultBorder", { link = "Comment", default = true })
    vim.api.nvim_set_hl(0, "ScratchResultSuccess", { link = "DiagnosticOk", default = true })
    vim.api.nvim_set_hl(0, "ScratchResultError", { link = "DiagnosticError", default = true })
    vim.api.nvim_set_hl(0, "ScratchLineResult", { link = "Special", default = true })
    vim.api.nvim_set_hl(0, "ScratchDebugHighlight", { bg = "#2D4F6D", default = true })
  end

  -- Setup global keymaps
  vim.keymap.set("n", defaults.keymaps.toggle, function()
    Scratch.toggle()
  end, { noremap = true, silent = true, desc = "Toggle scratch buffer" })

  -- Setup keymap for clearing all scratch files
  vim.keymap.set("n", defaults.keymaps.clear_scratch, function()
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Clear all unnamed scratch files?",
    }, function(choice)
      if choice == "Yes" then
        Scratch.clear_unnamed()
      end
    end)
  end, { noremap = true, silent = true, desc = "Clear all unnamed scratch files" })

  -- Create scratch directories if they don't exist
  vim.fn.mkdir(defaults.root, "p")
  vim.fn.mkdir(defaults.root .. "/named", "p")

  -- Create global commands
  vim.api.nvim_create_user_command("ScratchOpen", function(opts)
    Scratch.open({
      name = opts.args ~= "" and opts.args or "Scratch",
      ft = opts.fargs[1],
    })
  end, { nargs = "?", complete = "filetype" })

  vim.api.nvim_create_user_command("ScratchSelect", Scratch.select, {})
  vim.api.nvim_create_user_command("ScratchSelectNamed", Scratch.select_named, {})
  vim.api.nvim_create_user_command("ScratchToggle", Scratch.toggle, {})
  vim.api.nvim_create_user_command("ScratchHide", Scratch.hide, {})
  vim.api.nvim_create_user_command("ScratchClear", Scratch.clear_unnamed, {})
  vim.api.nvim_create_user_command("ScratchDebug", Scratch.toggle_debug_mode, {})

  return Scratch
end

--- Clear results from the current scratch buffer
function Scratch.clear_results(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Clear result namespaces
  vim.api.nvim_buf_clear_namespace(buf, defaults.result_ns, 0, -1)
  if defaults.debug_ns then
    vim.api.nvim_buf_clear_namespace(buf, defaults.debug_ns, 0, -1)
  end

  -- Clear stored results for this buffer
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  if Scratch.active_scratches[ft] then
    Scratch.active_scratches[ft].last_results = nil
  end

  vim.notify("Execution results cleared", vim.log.levels.INFO)
end

return Scratch
