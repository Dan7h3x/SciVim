--- Preview pane. Every update gets a token; async producers must check `p.valid()` before touching the buffer.
local util = require("fly.util")
local win_util = require("fly.win")

local uv = vim.uv or vim.loop
local api = vim.api

local M = {}
M.ns = api.nvim_create_namespace("fly.preview")

---@class fly.PreviewHandle
---@field picker table
---@field buf integer
---@field win integer
---@field valid fun(): boolean  false once a newer preview superseded this one
---@field set fun(lines: string[], opts?: fly.PreviewSetOpts)
---@field message fun(text: string)
---@field title fun(text: string)

---@class fly.PreviewSetOpts
---@field ft? string       filetype for highlighting
---@field line? integer    1-based line to highlight and center
---@field col? integer     1-based byte column of a match on `line`
---@field end_col? integer
---@field number? boolean  show line numbers (default true)

local function cfg(picker)
  local p = picker.opts.preview
  return type(p) == "table" and p or {}
end

local function reset(picker)
  local buf = picker.preview_buf
  pcall(vim.treesitter.stop, buf)
  vim.bo[buf].syntax = ""
  api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  if picker.image then
    require("fly.image").clear(picker)
  end
end

local function highlight(picker, buf, ft)
  if not ft or ft == "" then
    return
  end
  local lang = vim.treesitter.language.get_lang(ft) or ft
  if cfg(picker).treesitter ~= false and pcall(vim.treesitter.start, buf, lang) then
    return
  end
  pcall(function()
    vim.bo[buf].syntax = ft
  end)
end

---@param picker table
---@param valid fun(): boolean
---@param lines string[]
---@param o? fly.PreviewSetOpts
function M.set(picker, valid, lines, o)
  o = o or {}
  if not valid() or not win_util.valid(picker.preview_win) then
    return
  end
  local buf, win = picker.preview_buf, picker.preview_win
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local wo = function(k, v)
    api.nvim_set_option_value(k, v, { win = win })
  end
  wo("number", o.number ~= false and #lines > 1)
  wo("wrap", cfg(picker).wrap == true)
  wo("cursorline", false)
  highlight(picker, buf, o.ft)
  if o.line and #lines > 0 then
    local l = math.max(1, math.min(o.line, #lines))
    pcall(api.nvim_win_set_cursor, win, { l, 0 })
    pcall(api.nvim_win_call, win, function()
      vim.cmd("normal! zz")
    end)
    api.nvim_buf_set_extmark(buf, M.ns, l - 1, 0, { line_hl_group = "FlyPreviewLine", priority = 200 })
    if o.col then
      local text = lines[l] or ""
      local c = math.min(o.col - 1, #text)
      local e = math.min(o.end_col and (o.end_col - 1) or (c + 1), #text)
      if e > c then
        api.nvim_buf_set_extmark(buf, M.ns, l - 1, c, { end_col = e, hl_group = "FlyPreviewMatch", priority = 210 })
      end
    end
  else
    pcall(api.nvim_win_set_cursor, win, { 1, 0 })
    pcall(api.nvim_win_call, win, function()
      vim.fn.winrestview({ topline = 1, lnum = 1 })
    end)
  end
end

local function set_title(picker, text)
  local win = picker.preview_win
  if win_util.valid(win) and win_util.has_border(picker.border) then
    pcall(api.nvim_win_set_config, win, { title = " " .. text .. " ", title_pos = "left" })
  end
end

local function message(picker, valid, text)
  M.set(picker, valid, { text }, { number = false })
  if valid() and win_util.valid(picker.preview_win) then
    api.nvim_buf_set_extmark(picker.preview_buf, M.ns, 0, 0, { line_hl_group = "FlyEmpty" })
  end
end

local function dir_listing(picker, valid, path)
  local entries = {}
  local handle = uv.fs_scandir(path)
  while handle do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    entries[#entries + 1] = typ == "directory" and (name .. "/") or name
    if #entries >= cfg(picker).max_lines then
      break
    end
  end
  table.sort(entries)
  if #entries == 0 then
    return message(picker, valid, "(empty directory)")
  end
  M.set(picker, valid, entries, { number = false })
end

local function file_preview(picker, valid, item)
  local path = item.path
  local stat = uv.fs_stat(path)
  if not stat then
    return message(picker, valid, "not found: " .. path)
  end
  if stat.type == "directory" then
    return dir_listing(picker, valid, path)
  end
  local image = require("fly.image")
  if image.is_image(path) then
    image.show(picker, path, valid, function(ok, msg)
      if not valid() then
        return
      end
      if ok then
        M.set(picker, valid, { "" }, { number = false })
      else
        message(picker, valid, msg or "cannot preview image")
      end
    end)
    return
  end
  local max = cfg(picker).max_size or 1048576
  if stat.size > max then
    return message(picker, valid, ("file too large (%.1f MB)"):format(stat.size / 1048576))
  end
  local data = util.read_file(path, max)
  if not data then
    return message(picker, valid, "cannot read: " .. path)
  end
  if util.is_binary(data) then
    return message(picker, valid, "binary file")
  end
  local lines = util.split_lines(data, cfg(picker).max_line_length)
  local line = item.line
  if item.pattern and not line then
    for i, l in ipairs(lines) do
      if l:find(item.pattern, 1, true) then
        line = i
        break
      end
    end
  end
  local number = true
  local max_lines = cfg(picker).max_lines or 2000
  if #lines > max_lines then
    local first = 1
    if line and line > max_lines / 2 then
      first = math.min(line - math.floor(max_lines / 2), #lines - max_lines + 1)
    end
    lines = vim.list_slice(lines, first, first + max_lines - 1)
    if line then
      line = line - first + 1
    end
    number = first == 1 -- numbers would be wrong for a slice
  end
  local ft = item.ft or vim.filetype.match({ filename = path, contents = lines })
  M.set(picker, valid, lines, { ft = ft, line = line, col = item.col, end_col = item.end_col, number = number })
end

local function buffer_preview(picker, valid, item)
  local lines = api.nvim_buf_get_lines(item.bufnr, 0, cfg(picker).max_lines or 2000, false)
  M.set(picker, valid, lines, {
    ft = vim.bo[item.bufnr].filetype,
    line = item.line,
    col = item.col,
    end_col = item.end_col,
  })
end

--- Update the preview for the picker's current item.
---@param picker table
function M.update(picker)
  if picker.closed or not win_util.valid(picker.preview_win) then
    return
  end
  picker.pv_token = (picker.pv_token or 0) + 1
  local token = picker.pv_token
  local function valid()
    return not picker.closed and picker.pv_token == token
  end
  reset(picker)
  local item = picker:current()
  if not item then
    M.set(picker, valid, {}, { number = false })
    set_title(picker, "preview")
    return
  end
  local title = item.path and vim.fs.basename(item.path) or (item.title or "preview")
  set_title(picker, title)

  ---@type fly.PreviewHandle
  local handle = {
    picker = picker,
    buf = picker.preview_buf,
    win = picker.preview_win,
    valid = valid,
    set = function(lines, o)
      M.set(picker, valid, lines, o)
    end,
    message = function(text)
      message(picker, valid, text)
    end,
    title = function(text)
      if valid() then
        set_title(picker, text)
      end
    end,
  }

  local ok, err = pcall(function()
    local source = picker.source
    if type(source.preview) == "function" then
      if source.preview(picker:ctx(), item, handle) ~= false then
        return
      end
    end
    if type(item.preview) == "function" then
      item.preview(handle)
      return
    elseif type(item.preview) == "table" then
      local t = item.preview
      local lines = type(t.text) == "string" and vim.split(t.text, "\n", { plain = true }) or t.text or t.lines or {}
      return M.set(picker, valid, lines, { ft = t.ft, line = t.line })
    end
    if item.bufnr and api.nvim_buf_is_loaded(item.bufnr) and (item.from_buf or not item.path or vim.bo[item.bufnr].modified) then
      return buffer_preview(picker, valid, item)
    end
    if item.path then
      return file_preview(picker, valid, item)
    end
    local text = item.text or item.label or ""
    M.set(picker, valid, vim.split(text, "\n", { plain = true }), { number = false })
  end)
  if not ok then
    message(picker, valid, "preview error: " .. tostring(err))
  end
end

return M
