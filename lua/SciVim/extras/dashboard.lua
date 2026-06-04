local group = vim.api.nvim_create_augroup("Dashboard", { clear = true })

local M = {}

local config = {
  pi_art = {
    "███████╗ ██████╗██╗██╗   ██╗██╗███╗   ███╗",
    "██╔════╝██╔════╝██║██║   ██║██║████╗ ████║",
    "███████╗██║     ██║██║   ██║██║██╔████╔██║",
    "╚════██║██║     ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    "███████║╚██████╗██║ ╚████╔╝ ██║██║ ╚═╝ ██║",
    "╚══════╝ ╚═════╝╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
  },

  shortcuts = {
    { key = "f", desc = "Find File",      action = "<cmd>FzfLua files<CR>" },
    { key = "o", desc = "Recent Files",   action = "<cmd>FzfLua oldfiles<CR>" },
    { key = "d", desc = "Dotfiles",       action = "<cmd>FzfLua files cwd=$HOME/.config<CR>" },
    { key = "g", desc = "Live Grep",      action = "<cmd>FzfLua live_grep<CR>" },
    { key = "p", desc = "Project",        action = "<cmd>lua require('SciVim.extras.cdfzf').CdFzf()<CR>" },
    { key = "c", desc = "Root Dir",       action = "<Cmd> lua vim.cmd('cd' .. vim.fn.fnamemodify(vim.env.MYVIMRC,':p:h')) <CR>" },
    { key = "n", desc = "New File",       action = "<cmd>enew<CR>" },
    { key = "l", desc = "Update Plugins", action = "<cmd>Lazy<CR>" },
    { key = "q", desc = "Quit",           action = "<cmd>qa<CR>" },
  },

  mru_limit = 5,

  -- Use Neovim default highlight groups
  highlights = {
    pi = "Special",         -- Default: usually cyan/blue, stands out
    key = "Identifier",     -- Default: usually cyan/light blue
    desc = "String",        -- Default: usually green
    date = "Comment",       -- Default: usually gray
    footer = "NonText",     -- Default: usually dark gray
    mru_file = "Directory", -- Default: usually blue/purple
    mru_key = "Statement",  -- Default: usually yellow
    mru_header = "Title",   -- Default: usually bold magenta
  },

  layout = {
    top_offset = 1,
    logo_bottom_padding = 1,
    shortcuts_top_offset = 1,
    mru_top_offset = 1,
    plugin_info_offset = 1,
  },
}

local function calculate_max_width()
  local max_width = 0

  for _, line in ipairs(config.pi_art) do
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
  end

  for _, shortcut in ipairs(config.shortcuts) do
    local text = string.format("[%s]  %s", shortcut.key, shortcut.desc)
    max_width = math.max(max_width, vim.fn.strdisplaywidth(text))
  end

  local sample_mru = "9. ~/.config/nvim/lua/config/init.lua"
  max_width = math.max(max_width, vim.fn.strdisplaywidth(sample_mru))

  local sample_info = "load 999/999 plugins in 9999.999ms"
  max_width = math.max(max_width, vim.fn.strdisplaywidth(sample_info))

  return max_width
end

local function calculate_center_offset()
  local screen_width = vim.o.columns
  local max_content_width = calculate_max_width()
  return math.max(1, math.floor((screen_width - max_content_width) / 2))
end

local function get_datetime()
  local datetime = os.date("*t")
  local weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
  local months = { "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" }

  local weekday = weekdays[datetime.wday]
  local year = datetime.year
  local month = months[datetime.month]
  local day = datetime.day
  local hour = string.format("%02d", datetime.hour)
  local min = string.format("%02d", datetime.min)

  return string.format("%s %d %s %d %s:%s", weekday, year, month, day, hour, min)
end

local function get_recent_files()
  local oldfiles = vim.v.oldfiles or {}
  local recent = {}
  local home = vim.fn.expand("~")

  for _, file in ipairs(oldfiles) do
    if #recent >= config.mru_limit then
      break
    end
    if vim.fn.filereadable(file) == 1 and not file:match("^%w+://") then
      local display_path = file:gsub("^" .. vim.pesc(home), "~")
      table.insert(recent, { path = file, display = display_path })
    end
  end

  return recent
end

local function create_dashboard_buffer()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  return buf
end

local function render_dashboard(buf)
  local lines = {}
  local highlights_to_apply = {}
  local recent_files = get_recent_files()
  local center_offset = calculate_center_offset()

  -- Add empty lines at the top
  for _ = 1, config.layout.top_offset do
    table.insert(lines, "")
  end

  -- 1. Logo (Pi art) - centered
  for _, pi_line in ipairs(config.pi_art) do
    local centered_line = string.rep(" ", center_offset - 1) .. pi_line
    table.insert(lines, centered_line)
    table.insert(highlights_to_apply, {
      line = #lines - 1,
      col_start = center_offset - 1,
      col_end = center_offset - 1 + #pi_line,
      hl_group = config.highlights.pi,
    })
  end

  -- Add padding after logo
  for _ = 1, config.layout.logo_bottom_padding do
    table.insert(lines, "")
  end

  -- 2. Shortcuts - centered below logo
  local shortcut_start = #lines
  for _, shortcut in ipairs(config.shortcuts) do
    local text = string.format("[%s]  %s", shortcut.key, shortcut.desc)
    local centered_text = string.rep(" ", center_offset - 1) .. text
    table.insert(lines, centered_text)

    local text_start = center_offset - 1
    table.insert(highlights_to_apply, {
      line = #lines - 1,
      col_start = text_start + 1, -- "["
      col_end = text_start + 2,   -- "x"
      hl_group = config.highlights.key,
    })
    table.insert(highlights_to_apply, {
      line = #lines - 1,
      col_start = text_start + 5, -- After "]  "
      col_end = text_start + #text,
      hl_group = config.highlights.desc,
    })
  end

  -- Add padding before MRU
  for _ = 1, config.layout.mru_top_offset do
    table.insert(lines, "")
  end

  -- 3. MRU section - centered
  if #recent_files > 0 then
    local header_text = "Recent Files:"
    local centered_header = string.rep(" ", center_offset - 10) .. header_text
    table.insert(lines, centered_header)
    table.insert(highlights_to_apply, {
      line = #lines - 1,
      col_start = center_offset - 10,
      col_end = center_offset - 10 + #header_text,
      hl_group = config.highlights.mru_header,
    })

    for i, file in ipairs(recent_files) do
      local file_text = string.format("  %d. %s", i, file.display)
      local centered_text = string.rep(" ", center_offset - 10) .. file_text
      table.insert(lines, centered_text)

      local text_start = center_offset - 10
      -- Highlight number
      table.insert(highlights_to_apply, {
        line = #lines - 1,
        col_start = text_start + 2, -- After "  "
        col_end = text_start + 3,   -- Just the number
        hl_group = config.highlights.mru_key,
      })
      -- Highlight file path
      table.insert(highlights_to_apply, {
        line = #lines - 1,
        col_start = text_start + 5, -- After "  N. "
        col_end = text_start + #file_text,
        hl_group = config.highlights.mru_file,
      })
    end
  end

  -- Add padding before plugin info
  for _ = 1, config.layout.plugin_info_offset do
    table.insert(lines, "")
  end

  -- 4. Plugin info and date
  local lazystats = require("lazy.stats").stats()
  local icon = "⚡ "
  local plugin_info_str = icon .. " Neovim loaded " .. lazystats.loaded .. "/" .. lazystats.count .. " !"
  local centered_info = string.rep(" ", center_offset - 1) .. plugin_info_str
  table.insert(lines, centered_info)
  table.insert(highlights_to_apply, {
    line = #lines - 1,
    col_start = center_offset - 1,
    col_end = center_offset - 1 + #plugin_info_str,
    hl_group = config.highlights.footer,
  })

  local datetime_str = get_datetime()
  local centered_date = string.rep(" ", center_offset - 1) .. datetime_str
  table.insert(lines, centered_date)
  table.insert(highlights_to_apply, {
    line = #lines - 1,
    col_start = center_offset - 1,
    col_end = center_offset - 1 + #datetime_str,
    hl_group = config.highlights.date,
  })

  -- Apply all lines
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Set cursor position to first shortcut
  if shortcut_start <= #lines then
    vim.api.nvim_win_set_cursor(0, { shortcut_start + 1, center_offset })
  end

  -- Apply highlights
  local ns_id = vim.api.nvim_create_namespace("dashboard")
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, hl in ipairs(highlights_to_apply) do
    pcall(vim.hl.range, buf, ns_id, hl.hl_group, { hl.line, hl.col_start }, { hl.line, hl.col_end })
  end
end

local function open_mru_file(file_num)
  local recent_files = get_recent_files()
  if file_num >= 1 and file_num <= #recent_files then
    local file_path = recent_files[file_num].path
    vim.cmd("e " .. vim.fn.fnameescape(file_path) .. " | cd %:p:h")
  end
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Shortcut keymaps
  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set("n", shortcut.key, shortcut.action, opts)
  end

  -- MRU number keymaps (1-9)
  for i = 1, config.mru_limit do
    vim.keymap.set("n", tostring(i), function()
      open_mru_file(i)
    end, opts)
  end

  -- Quit keymaps
  vim.keymap.set("n", "<Esc>", ":q<CR>", opts)
  vim.keymap.set("n", "q", ":q<CR>", opts)
end

local function opt_handler()
  local save_opts = {}

  save_opts.number = vim.wo.number
  save_opts.relativenumber = vim.wo.relativenumber
  save_opts.cursorline = vim.wo.cursorline
  save_opts.cursorcolumn = vim.wo.cursorcolumn
  save_opts.colorcolumn = vim.wo.colorcolumn
  save_opts.signcolumn = vim.wo.signcolumn
  save_opts.wrap = vim.wo.wrap
  save_opts.listchars = vim.o.listchars

  return function()
    vim.wo.number = save_opts.number
    vim.wo.relativenumber = save_opts.relativenumber
    vim.wo.cursorline = save_opts.cursorline
    vim.wo.cursorcolumn = save_opts.cursorcolumn
    vim.wo.colorcolumn = save_opts.colorcolumn
    vim.wo.signcolumn = save_opts.signcolumn
    vim.wo.wrap = save_opts.wrap
    vim.o.listchars = save_opts.listchars
  end
end

function M.show()
  if vim.fn.argc() > 0 or vim.fn.line2byte("$") ~= -1 then
    vim.o.laststatus = 0
    return
  end

  local buf = create_dashboard_buffer()
  vim.api.nvim_set_current_buf(buf)
  render_dashboard(buf)
  setup_keymaps(buf)

  local restore_opt = opt_handler()

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.colorcolumn = "0"
  vim.wo.signcolumn = "no"
  vim.wo.wrap = false
  vim.wo.listchars = "precedes: "


  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    group = group,
    callback = function()
      if vim.bo.buftype == "nofile" and vim.bo.filetype == "" then
        render_dashboard(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    group = group,
    callback = function()
      restore_opt()
    end,
  })
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 then
      M.show()
    end
  end,
})

vim.api.nvim_create_user_command("Dashboard", function()
  M.show()
end, {})

return M
