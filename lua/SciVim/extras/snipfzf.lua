local M = {}

local fzf_lua = require("fzf-lua")
local api = vim.api
local fn = vim.fn

-- Default configuration
M.config = {
  -- Snippet sources
  sources = {
    friendly_snippets = {
      enabled = true,
      path = fn.stdpath("data") .. "/lazy/friendly-snippets/snippets",
    },
    user_snippets = {
      enabled = true,
      path = fn.stdpath("config") .. "/snippets",
    },
  },
  -- Supported snippet formats
  supported_formats = {
    json = true,
    lua = true,
    snippets = true, -- UltiSnips format
  },
  -- Window appearance
  window = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
    preview = {
      enabled = true,
      side = "right",
      width = 0.4,
      border = "rounded",
    },
  },
  -- Add placeholder styling configuration
  placeholder = {
    highlight = {
      current = "SnippetCurrentPlaceholder",
      others = "SnippetPlaceholder",
    },
    virtual_text = {
      enabled = true,
      current = "●",  -- Current placeholder indicator
      others = "○",   -- Other placeholders indicator
      position = "eol",
    },
    extmark_opts = {
      hl_mode = "combine",
      priority = 1000,
    },
  },
  -- Snippet formatting
  format = {
    entry = function(snippet)
      return string.format("%s [%s] %s",
        snippet.prefix or snippet.name,
        snippet.filetype,
        snippet.description or ""
      )
    end,
  },
  -- Visual placeholder settings
  placeholder = {
    highlight = "SnippetPlaceholder", -- Highlight group for placeholders
    current_highlight = "SnippetCurrentPlaceholder", -- Current placeholder highlight
    virtual_text = true, -- Show virtual text for placeholders
    virtual_text_pos = 'eol', -- Position of virtual text
  },
}


-- Cache for parsed snippets
local snippet_cache = {}
local preview_state = nil

-- Create highlight groups for placeholders
local function setup_highlights()
  local highlights = {
    SnippetCurrentPlaceholder = {
      fg = "#f38ba8",
      bg = "#313244",
      bold = true,
      italic = true,
    },
    SnippetPlaceholder = {
      fg = "#89b4fa",
      italic = true,
    },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-- Enhanced placeholder handling
local function setup_placeholder_highlights(bufnr, placeholders)
  local ns_id = vim.api.nvim_create_namespace('SnipFzfPlaceholders')
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  for idx, ph in ipairs(placeholders) do
    local is_current = idx == 1
    local hl_group = is_current and M.config.placeholder.highlight.current or M.config.placeholder.highlight.others
    local virt_text_icon = is_current and M.config.placeholder.virtual_text.current or M.config.placeholder.virtual_text.others

    -- Add highlight extmark
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, ph.range.start.line, ph.range.start.character, {
      end_line = ph.range["end"].line,
      end_col = ph.range["end"].character,
      hl_group = hl_group,
      priority = M.config.placeholder.extmark_opts.priority,
      hl_mode = M.config.placeholder.extmark_opts.hl_mode,
    })

    -- Add virtual text if enabled
    if M.config.placeholder.virtual_text.enabled then
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, ph.range.start.line, ph.range["end"].character, {
        virt_text = {{" " .. virt_text_icon .. idx, hl_group}},
        virt_text_pos = M.config.placeholder.virtual_text.position,
        priority = M.config.placeholder.extmark_opts.priority,
      })
    end
  end
end



-- Snippet format parsers
local snippet_parsers = {
  json = function(filepath)
    local file = io.open(filepath, "r")
    if not file then return {} end

    local content = file:read("*a")
    file:close()

    local ok, parsed = pcall(vim.json.decode, content)
    if not ok then
      vim.notify("Failed to parse " .. filepath, vim.log.levels.ERROR)
      return {}
    end

    local snippets = {}
    local filetype = vim.fn.fnamemodify(filepath, ":t:r")

    for name, data in pairs(parsed) do
      local body = type(data.body) == "table" and table.concat(data.body, "\n") or data.body
      table.insert(snippets, {
        name = name,
        prefix = data.prefix,
        body = body,
        description = data.description,
        filetype = filetype,
        source = vim.fn.fnamemodify(filepath, ":h:t"),
      })
    end

    return snippets
  end,

  lua = function(filepath)
    local chunk = loadfile(filepath)
    if not chunk then return {} end
    
    local snippets = {}
    local success, result = pcall(chunk)
    if not success then return {} end
    
    local filetype = vim.fn.fnamemodify(filepath, ":t:r")
    for name, snip in pairs(result) do
      table.insert(snippets, {
        name = name,
        prefix = snip.prefix,
        body = type(snip.body) == "table" and table.concat(snip.body, "\n") or snip.body,
        description = snip.description,
        filetype = filetype,
        source = vim.fn.fnamemodify(filepath, ":h:t"),
      })
    end
    return snippets
  end,

  snippets = function(filepath)
    local file = io.open(filepath, "r")
    if not file then return {} end

    local content = file:read("*a")
    file:close()

    local snippets = {}
    local current_snippet = {}
    local in_snippet = false
    local filetype = vim.fn.fnamemodify(filepath, ":t:r")

    for line in content:gmatch("[^\r\n]+") do
      if line:match("^snippet%s+") then
        if in_snippet and current_snippet.name then
          table.insert(snippets, current_snippet)
        end
        current_snippet = {
          name = line:match("^snippet%s+(%S+)"),
          body = {},
          filetype = filetype,
          source = "ultisnips",
          description = line:match("^snippet%s+%S+%s+\"(.-)\"") or "",
        }
        in_snippet = true
      elseif line:match("^endsnippet") then
        if current_snippet.name then
          current_snippet.body = table.concat(current_snippet.body, "\n")
          table.insert(snippets, current_snippet)
        end
        in_snippet = false
      elseif in_snippet then
        table.insert(current_snippet.body, line)
      end
    end

    if in_snippet and current_snippet.name then
      current_snippet.body = table.concat(current_snippet.body, "\n")
      table.insert(snippets, current_snippet)
    end

    return snippets
  end
}

-- Parse a snippet file
local function parse_snippet_file(filepath)
  if snippet_cache[filepath] then
    return snippet_cache[filepath]
  end

  local ext = vim.fn.fnamemodify(filepath, ":e")
  local parser = snippet_parsers[ext]
  
  if not parser or not M.config.supported_formats[ext] then
    return {}
  end

  local snippets = parser(filepath)
  snippet_cache[filepath] = snippets
  return snippets
end

-- Get snippets for current filetype
local function get_snippets()
  local current_ft = vim.bo.filetype
  local all_snippets = {}

  for source_name, source in pairs(M.config.sources) do
    if source.enabled then
      -- Get global snippets for all supported formats
      for ext, enabled in pairs(M.config.supported_formats) do
        if enabled then
          local global_pattern = string.format("%s/**/global.%s", source.path, ext)
          local global_files = vim.fn.glob(global_pattern, true, true)
          for _, file in ipairs(global_files) do
            local snippets = parse_snippet_file(file)
            for _, snip in ipairs(snippets) do
              snip.source = source_name
            end
            vim.list_extend(all_snippets, snippets)
          end

          -- Get filetype snippets
          local ft_pattern = string.format("%s/**/%s.%s", source.path, current_ft, ext)
          local ft_files = vim.fn.glob(ft_pattern, true, true)
          for _, file in ipairs(ft_files) do
            local snippets = parse_snippet_file(file)
            for _, snip in ipairs(snippets) do
              snip.source = source_name
            end
            vim.list_extend(all_snippets, snippets)
          end
        end
      end
    end
  end

  return all_snippets
end

-- Update preview content
local function update_preview(preview_state, snippet)
  if not preview_state or not preview_state.buf or not preview_state.win then return end
  
  -- Check if window still exists
  if not vim.api.nvim_win_is_valid(preview_state.win) then return end

  -- Format preview content
  local lines = {}
  table.insert(lines, "Name: " .. snippet.name)
  table.insert(lines, "Type: " .. snippet.filetype)
  table.insert(lines, "Prefix: " .. (snippet.prefix or ""))
  table.insert(lines, "Description: " .. (snippet.description or ""))
  table.insert(lines, "Source: " .. snippet.source)
  table.insert(lines, "")
  table.insert(lines, "Body:")
  table.insert(lines, "")

  -- Split and add body lines
  local body_lines = vim.split(snippet.body, "\n")
  vim.list_extend(lines, body_lines)

  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(preview_state.buf, 'modifiable', true)
  
  -- Set content
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  
  -- Apply syntax highlighting if enabled
  if M.config.window.preview.highlight then
    vim.api.nvim_buf_set_option(preview_state.buf, 'filetype', snippet.filetype)
    
    -- Create highlight namespace
    local ns_id = vim.api.nvim_create_namespace('SnipFzfPreview')
    vim.api.nvim_buf_clear_namespace(preview_state.buf, ns_id, 0, -1)
    
    -- Add highlighting for headers
    for i = 1, 5 do
      vim.api.nvim_buf_add_highlight(preview_state.buf, ns_id, 'Title', i-1, 0, -1)
    end

    -- Add highlighting for body section
    local body_start = 8  -- Index where body starts
    for i = body_start, #lines do
      vim.api.nvim_buf_add_highlight(preview_state.buf, ns_id, 'Normal', i-1, 0, -1)
    end
  end

  -- Make buffer non-modifiable again
  vim.api.nvim_buf_set_option(preview_state.buf, 'modifiable', false)
end

-- Convert VSCode-style placeholders to Neovim format
local function convert_placeholders(body)
  -- Convert ${1:label} style placeholders
  body = body:gsub("${(%d+):([^}]*)}", function(index, placeholder)
    return string.format("${%s:%s}", index, placeholder)
  end)

  -- Convert $1 style placeholders
  body = body:gsub("$(%d+)", "${%1}")

  -- Convert choice placeholders ${1|one,two,three|}
  body = body:gsub("${(%d+)|([^}]*)|}", function(index, choices)
    local options = vim.split(choices, ",")
    return string.format("${%s:%s}", index, options[1] or "")
  end)

  -- Convert variables ${TM_FILENAME} etc.
  body = body:gsub("${TM_([^}]*)}", function(var)
    -- Add more variables as needed
    local vars = {
      FILENAME = vim.fn.expand("%:t"),
      FILEPATH = vim.fn.expand("%:p"),
      DIRECTORY = vim.fn.expand("%:p:h"),
      LINE_NUMBER = tostring(vim.fn.line(".")),
      CURRENT_WORD = vim.fn.expand("<cword>"),
    }
    return vars[var] or ""
  end)

  return body
end

-- Insert snippet at cursor with visual jumping
local function insert_snippet(snippet)
  if not snippet or not snippet.body then return end

  -- Handle visual mode
  local mode = api.nvim_get_mode().mode
  if mode == "v" or mode == "V" then
    api.nvim_input("<Esc>")
    api.nvim_command("normal! gvd")
  end

  if vim.snippet then
    local converted_body = convert_placeholders(snippet.body)
    local ok, snip = pcall(vim.snippet.new, converted_body)

    if ok and snip then
      -- Expand snippet
      local expand_ok, _ = pcall(vim.snippet.expand, snip)
      if expand_ok then
        local bufnr = vim.api.nvim_get_current_buf()
        local placeholders = vim.snippet.get_placeholders()

        -- Setup initial placeholder highlights
        setup_placeholder_highlights(bufnr, placeholders)

        -- Setup autocommands for snippet session
        local group = api.nvim_create_augroup("SnipFzf", { clear = true })
        
        -- Update highlights when moving between placeholders
        api.nvim_create_autocmd("User", {
          pattern = "SnippetPlaceholderChanged",
          group = group,
          callback = function()
            setup_placeholder_highlights(bufnr, placeholders)
          end,
        })

        -- Cleanup when leaving snippet mode
        api.nvim_create_autocmd("InsertLeave", {
          group = group,
          buffer = bufnr,
          callback = function()
            vim.snippet.exit()
            vim.api.nvim_buf_clear_namespace(bufnr, vim.api.nvim_create_namespace('SnipFzfPlaceholders'), 0, -1)
            api.nvim_del_augroup_by_name("SnipFzf")
          end,
          once = true,
        })

        vim.schedule(function()
          vim.cmd("startinsert")
        end)
      else
        -- Fallback if expansion fails
        local lines = vim.split(converted_body, "\n")
        vim.api.nvim_put(lines, "c", true, true)
      end
    else
      -- Fallback with original body
      local lines = vim.split(snippet.body, "\n")
      api.nvim_put(lines, "c", true, true)
      vim.notify("Failed to create snippet\nFalling back to basic insertion", vim.log.levels.WARN)
    end
  else
    -- Fallback for older Neovim versions
    local lines = vim.split(snippet.body, "\n")
    api.nvim_put(lines, "c", true, true)
    vim.notify("Native snippet support not available (requires Neovim 0.10+)", vim.log.levels.INFO)
  end
end


-- Copy snippet to clipboard
local function copy_snippet(snippet)
  if snippet and snippet.body then
    vim.fn.setreg("+", snippet.body)
    vim.notify(string.format("Snippet '%s' copied to clipboard", snippet.name), vim.log.levels.INFO)
  end
end

-- Reload snippets cache
function M.reload()
  snippet_cache = {}
  vim.notify("Snippet cache cleared", vim.log.levels.INFO)
end

-- List available snippet sources
function M.list_sources()
  local sources = {}
  for name, source in pairs(M.config.sources) do
    if source.enabled then
      table.insert(sources, {
        name = name,
        path = source.path,
        formats = {},
      })
      
      -- Check available formats
      for ext, enabled in pairs(M.config.supported_formats) do
        if enabled then
          local pattern = string.format("%s/**/*.%s", source.path, ext)
          local files = vim.fn.glob(pattern, true, true)
          if #files > 0 then
            table.insert(sources[#sources].formats, ext)
          end
        end
      end
    end
  end

  -- Display sources info
  local lines = {"Available snippet sources:"}
  for _, source in ipairs(sources) do
    table.insert(lines, string.format(
      "- %s\n  Path: %s\n  Formats: %s",
      source.name,
      source.path,
      table.concat(source.formats, ", ")
    ))
  end
  
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Add a new snippet source
function M.add_source(name, opts)
  if M.config.sources[name] then
    vim.notify("Source '" .. name .. "' already exists", vim.log.levels.WARN)
    return
  end

  M.config.sources[name] = vim.tbl_extend("force", {
    enabled = true,
    path = "",
  }, opts or {})

  vim.notify("Added snippet source: " .. name, vim.log.levels.INFO)
end

-- Remove a snippet source
function M.remove_source(name)
  if not M.config.sources[name] then
    vim.notify("Source '" .. name .. "' does not exist", vim.log.levels.WARN)
    return
  end

  M.config.sources[name] = nil
  M.reload()
  vim.notify("Removed snippet source: " .. name, vim.log.levels.INFO)
end

-- Main search function
function M.find()
  local snippets = get_snippets()

  if #snippets == 0 then
    vim.notify("No snippets found for " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  -- Pre-format entries with indices
  local entries = {}
  for idx, snippet in ipairs(snippets) do
    table.insert(entries, string.format("%d\t%s", idx, M.config.format.entry(snippet)))
  end

  fzf_lua.fzf_exec(
    entries,
    {
      prompt = "Snippets> ",
      previewer = "builtin",
      preview_window = "right:40%",
      actions = {
        ["default"] = function(selected)
          if selected and selected[1] then
            -- Extract index from the selected entry
            local idx = tonumber(selected[1]:match("^(%d+)\t"))
            if idx and snippets[idx] then
              insert_snippet(snippets[idx])
            end
          end
        end,
        ["ctrl-y"] = function(selected)
          if selected and selected[1] then
            local idx = tonumber(selected[1]:match("^(%d+)\t"))
            if idx and snippets[idx] then
              copy_snippet(snippets[idx])
            end
          end
        end,
      },
      winopts = {
        height = M.config.window.height,
        width = M.config.window.width,
        border = M.config.window.border,
      },
      fzf_opts = {
        ["--header"] = [[
Enter: Insert snippet
Ctrl-y: Copy to clipboard
]],
        ["--layout"] = "reverse",
      },
    }
  )
end

-- Enhanced setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights() -- Setup placeholder highlights
  
  -- Create user snippets directory if it doesn't exist
  if M.config.sources.user_snippets.enabled then
    local user_snippets_path = M.config.sources.user_snippets.path
    if not vim.loop.fs_stat(user_snippets_path) then
      vim.fn.mkdir(user_snippets_path, "p")
      vim.notify("Created user snippets directory: " .. user_snippets_path, vim.log.levels.INFO)
    end
  end
end


return M