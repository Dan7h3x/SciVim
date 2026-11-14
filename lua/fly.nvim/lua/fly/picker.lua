local matcher = require("fly.matcher")
local layout = require("fly.layout")
local win_util = require("fly.win")
local util = require("fly.util")
local preview = require("fly.preview")
local sources = require("fly.sources")

local api = vim.api
local uv = vim.uv or vim.loop

local M = {}

---@class fly.Item
---@field label string          text that is fuzzy-matched
---@field display? string       text shown instead of `label`
---@field offset? integer       byte offset of `label` inside `display`
---@field hl? { [1]: integer, [2]: integer, [3]: string }[]  extra highlights (0-based byte cols in `display`)
---@field extra? string|table   right-aligned virtual text (string or {{text, hl}, ...})
---@field extra_hl? string
---@field path? string          absolute path
---@field bufnr? integer
---@field line? integer         1-based
---@field col? integer          1-based
---@field end_col? integer
---@field text? string          preview / quickfix text
---@field kind? string
---@field data? any             anything the source wants to keep
---@field ft? string
---@field pattern? string       plain text to locate in the previewed file
---@field preview? function|table

---@class fly.Source
---@field title string
---@field find? fun(ctx: fly.Ctx): fly.Item[]?
---@field start? fun(ctx: fly.Ctx, push: fun(items: fly.Item[]), done: fun()): (fun()|fly.Proc|nil)
---@field live? boolean       re-run on every (debounced) query change instead of fuzzy filtering
---@field ordered? boolean    keep source order on an empty query
---@field icons? boolean
---@field preview? boolean|fun(ctx: fly.Ctx, item: fly.Item, p: fly.PreviewHandle): boolean?
---@field confirm? fun(item: fly.Item, ctx: fly.Ctx)
---@field actions? table<string, fun(picker: fly.Picker)>
---@field keys? table<string, string|function|false>
---@field defaults? table

---@class fly.Ctx
---@field picker fly.Picker
---@field opts table
---@field source fly.Source
---@field cwd string
---@field query string
---@field origin { win: integer, buf: integer, cwd: string }
---@field how? "edit"|"split"|"vsplit"|"tab"
---@field items? fly.Item[]

---@type fly.Picker?
M.active = nil
---@type table<string, string[]>
M.history = {}
---@type { opts: table, query: string }?
M.last = nil

---@class fly.Picker
local Picker = {}
Picker.__index = Picker

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function items_of(picker)
  local out = {}
  for _, item in ipairs(picker.results) do
    if picker.selected[item] then
      out[#out + 1] = item
    end
  end
  return out
end

--- Send items to the quickfix list and open it.
---@param items fly.Item[]
---@param title? string
function M.to_quickfix(items, title)
  local qf = {}
  for _, item in ipairs(items) do
    if item.path or item.bufnr then
      qf[#qf + 1] = {
        filename = item.path,
        bufnr = (not item.path) and item.bufnr or nil,
        lnum = item.line or 1,
        col = item.col or 1,
        text = util.oneline(item.text or item.label),
      }
    end
  end
  if #qf == 0 then
    return util.warn("nothing to send to the quickfix list")
  end
  vim.fn.setqflist({}, " ", { title = title or "fly", items = qf })
  vim.cmd("copen")
end

---@param item fly.Item
---@param how? "edit"|"split"|"vsplit"|"tab"
function M.jump(item, how)
  how = how or "edit"
  vim.cmd("normal! m'") -- keep the jumplist useful
  if item.bufnr and api.nvim_buf_is_valid(item.bufnr) then
    if how == "edit" then
      vim.cmd("buffer " .. item.bufnr)
    else
      vim.cmd(({ split = "sbuffer", vsplit = "vertical sbuffer", tab = "tab sbuffer" })[how] .. " " .. item.bufnr)
    end
  elseif item.path then
    local cmd = ({ edit = "edit", split = "split", vsplit = "vsplit", tab = "tabedit" })[how] or "edit"
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(item.path))
  else
    return
  end
  if item.line then
    local col = math.max((item.col or 1) - 1, 0)
    if not pcall(api.nvim_win_set_cursor, 0, { item.line, col }) then
      pcall(api.nvim_win_set_cursor, 0, { item.line, 0 })
    end
    vim.cmd("normal! zvzz")
  end
end

---@param item fly.Item
---@param ctx fly.Ctx
function M.default_confirm(item, ctx)
  local items = vim.tbl_filter(function(i)
    return i.path or i.bufnr
  end, ctx.items or { item })
  if #items == 0 then
    return
  end
  if #items > 1 then
    M.to_quickfix(items, "fly: " .. (ctx.source.title or ""))
    vim.cmd("silent! cfirst")
    return
  end
  M.jump(items[1], ctx.how)
end

-- ---------------------------------------------------------------------------
-- actions (bind them in `keys`, or call `picker:run_action(name)`)
-- ---------------------------------------------------------------------------

---@type table<string, fun(picker: fly.Picker)>
M.actions = {
  close = function(p)
    p:close()
  end,
  confirm = function(p)
    p:confirm("edit")
  end,
  split = function(p)
    p:confirm("split")
  end,
  vsplit = function(p)
    p:confirm("vsplit")
  end,
  tab = function(p)
    p:confirm("tab")
  end,
  next = function(p)
    p:move(1)
  end,
  prev = function(p)
    p:move(-1)
  end,
  first = function(p)
    p:set_cursor(1)
  end,
  last = function(p)
    p:set_cursor(p:shown())
  end,
  page_down = function(p)
    p:move(p:list_height(), true)
  end,
  page_up = function(p)
    p:move(-p:list_height(), true)
  end,
  toggle = function(p)
    p:toggle_selection()
    p:move(1)
  end,
  toggle_up = function(p)
    p:toggle_selection()
    p:move(-1)
  end,
  select_all = function(p)
    for _, item in ipairs(p.results) do
      p.selected[item] = true
    end
    p:render()
  end,
  clear_selection = function(p)
    p.selected = {}
    p:render()
  end,
  quickfix = function(p)
    local items = items_of(p)
    if #items == 0 then
      items = p.results
    end
    local title = "fly: " .. (p.source.title or "")
    p:close()
    vim.schedule(function()
      M.to_quickfix(items, title)
    end)
  end,
  preview_down = function(p)
    p:scroll_preview(1)
  end,
  preview_up = function(p)
    p:scroll_preview(-1)
  end,
  toggle_preview = function(p)
    p.show_preview = not p.show_preview
    p:relayout()
  end,
  history_prev = function(p)
    p:history(1)
  end,
  history_next = function(p)
    p:history(-1)
  end,
  refresh = function(p)
    p:run_source()
  end,
  toggle_hidden = function(p)
    p.opts.hidden = not p.opts.hidden
    p:run_source()
    util.notify("hidden files: " .. (p.opts.hidden and "on" or "off"))
  end,
  toggle_ignored = function(p)
    p.opts.ignored = not p.opts.ignored
    p:run_source()
    util.notify("ignored files: " .. (p.opts.ignored and "on" or "off"))
  end,
}

-- ---------------------------------------------------------------------------
-- Picker
-- ---------------------------------------------------------------------------

function Picker:ctx()
  return {
    picker = self,
    opts = self.opts,
    source = self.source,
    cwd = self.cwd,
    query = self.query,
    origin = self.origin,
  }
end

function Picker:shown()
  return math.min(#self.results, self.opts.limit or 1000)
end

function Picker:list_height()
  return win_util.valid(self.list_win) and api.nvim_win_get_height(self.list_win) or 10
end

---@return fly.Item?
function Picker:current()
  if self.closed or self.cursor < 1 or self.cursor > self:shown() then
    return nil
  end
  return self.results[self.cursor]
end

---@return fly.Item[]
function Picker:selected_items()
  return items_of(self)
end

function Picker:toggle_selection()
  local item = self:current()
  if item then
    self.selected[item] = not self.selected[item] or nil
    self:render()
  end
end

function Picker:get_query()
  if not api.nvim_buf_is_valid(self.input_buf) then
    return self.query
  end
  return table.concat(api.nvim_buf_get_lines(self.input_buf, 0, -1, false), " ")
end

--- Replace the prompt text and re-run the search immediately.
---@param q string
function Picker:set_query(q)
  if self.closed then
    return
  end
  if not api.nvim_buf_is_valid(self.input_buf) then
    return self:close()
  end
  api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { q })
  pcall(api.nvim_win_set_cursor, self.input_win, { 1, #q })
  self:on_query(q)
end

function Picker:on_query(q)
  if q == self.query then
    return
  end
  self.query = q
  self.cursor = 1
  if self.source.live then
    self.live_debounce.call()
  else
    self.parsed = matcher.parse(q, self.opts.matcher)
    self:refilter()
  end
end

-- source / filtering ---------------------------------------------------------

function Picker:stop_source()
  local c = self.cancel_source
  self.cancel_source = nil
  if type(c) == "function" then
    pcall(c)
  elseif type(c) == "table" and c.kill then
    pcall(c.kill)
  end
end

function Picker:push(items)
  local list = self.items
  local n = #list
  for _, item in ipairs(items) do
    n = n + 1
    item._idx = n
    list[n] = item
  end
  self:kick()
end

function Picker:run_source()
  if self.closed then
    return
  end
  self:stop_source()
  self.gen = self.gen + 1
  local gen = self.gen
  self.items, self.results, self.selected = {}, {}, {}
  self.fpos, self.source_done, self.filter_done, self.dirty_sort = 1, false, false, true
  self.parsed = self.parsed or matcher.parse(self.query, self.opts.matcher)

  local function push(items)
    if not self.closed and gen == self.gen and items then
      self:push(items)
    end
  end
  local function done()
    if not self.closed and gen == self.gen then
      self.source_done = true
      self:kick()
    end
  end

  local source = self.source
  local ctx = self:ctx()
  if source.start then
    local ok, cancel = pcall(source.start, ctx, push, done)
    if ok then
      self.cancel_source = cancel
    else
      util.error(("source '%s' failed: %s"):format(source.title or "?", tostring(cancel)))
      done()
    end
  elseif source.find then
    local ok, items = pcall(source.find, ctx)
    if not ok then
      util.error(("source '%s' failed: %s"):format(source.title or "?", tostring(items)))
    end
    push(ok and items or {})
    done()
  else
    done()
  end
  self:kick()
end

function Picker:refilter()
  self.results = {}
  self.fpos = 1
  self.filter_done = false
  self.dirty_sort = true
  self:kick()
end

function Picker:kick()
  if self.kicked or self.closed then
    return
  end
  self.kicked = true
  vim.schedule(function()
    self.kicked = false
    if not self.closed then
      self:filter_step()
    end
  end)
end

--- Filter new items under a small time budget so typing never blocks.
function Picker:filter_step()
  local items, results = self.items, self.results
  local n, rn = #items, #results
  local passthrough = self.source.live or not self.parsed.has_query
  local parsed = self.parsed
  local t0 = uv.hrtime()
  local i = self.fpos
  while i <= n do
    local item = items[i]
    if passthrough then
      rn = rn + 1
      results[rn] = item
    else
      local score = matcher.match(parsed, item)
      if score then
        item._score = score
        rn = rn + 1
        results[rn] = item
      end
    end
    i = i + 1
    if i % 512 == 0 and (uv.hrtime() - t0) > 8e6 then
      break
    end
  end
  self.fpos = i
  if i <= n then
    self:kick()
  end
  self.filter_done = i > n and self.source_done
  self.dirty_sort = true
  self:schedule_render()
end

function Picker:schedule_render()
  if self.render_pending then
    return
  end
  self.render_pending = true
  vim.defer_fn(function()
    self.render_pending = false
    if not self.closed then
      self:render()
    end
  end, self.filter_done and 0 or 30)
end

function Picker:sort()
  if not self.dirty_sort then
    return
  end
  local results = self.results
  if self.source.live then
    self.dirty_sort = false
    return
  end
  if self.parsed.has_query then
    if #results <= 5000 or self.filter_done then
      table.sort(results, matcher.compare)
      self.dirty_sort = false
    end
  elseif self.opts.matcher.sort_empty ~= false and not self.source.ordered then
    if self.filter_done then
      table.sort(results, function(a, b)
        if a.label ~= b.label then
          return a.label < b.label
        end
        return a._idx < b._idx
      end)
      self.dirty_sort = false
    end
  else
    self.dirty_sort = false
  end
end

-- rendering -------------------------------------------------------------------

function Picker:row(i, shown)
  if self.flip then
    return self.pad + (shown - i)
  end
  return i - 1
end

function Picker:render()
  if self.closed or not win_util.valid(self.list_win) then
    return
  end
  self:sort()
  local icons = require("fly.icons")
  local use_icons = self.opts.icons ~= false and self.source.icons
  local shown = self:shown()
  local height = self:list_height()
  self.pad = (self.flip and shown < height) and (height - shown) or 0
  if self.flip and shown == 0 then
    self.pad = height - 1
  end
  local buf = self.list_buf
  local ns = self.ns
  local total = self.pad + math.max(shown, 1)
  local lines = {}
  for i = 1, total do
    lines[i] = ""
  end
  local marks = {}
  local fuzzy = not self.source.live and self.parsed.has_query

  for i = 1, shown do
    local item = self.results[i]
    local text = util.oneline(item.display or item.label)
    local off = item.offset or 0
    local shift = 0
    local row = self:row(i, shown)
    if use_icons and item.path then
      local icon, ihl = icons.get(item.path)
      if icon then
        text = icon .. " " .. text
        shift = #icon + 1
        if ihl then
          marks[#marks + 1] = { row, 0, { end_col = #icon, hl_group = ihl, priority = 100 } }
        end
      end
    end
    lines[row + 1] = text
    -- dim directory part of path-like labels
    if not item.display and item.path then
      local dir_end = item.label:match("^.*()/")
      if dir_end then
        marks[#marks + 1] = { row, shift, { end_col = shift + dir_end, hl_group = "FlyDir", priority = 100 } }
      end
    end
    for _, h in ipairs(item.hl or {}) do
      marks[#marks + 1] = { row, shift + h[1], { end_col = shift + h[2], hl_group = h[3], priority = 150 } }
    end
    if fuzzy then
      local pos = matcher.positions(self.parsed, item)
      if pos then
        local s, e = pos[1], pos[1]
        local function flush()
          marks[#marks + 1] = { row, shift + off + s - 1, { end_col = shift + off + e, hl_group = "FlyMatch", priority = 300 } }
        end
        for k = 2, #pos do
          if pos[k] == e + 1 then
            e = pos[k]
          else
            flush()
            s, e = pos[k], pos[k]
          end
        end
        flush()
      end
    end
    if item.extra then
      local chunks = item.extra
      if type(chunks) == "string" then
        chunks = { { " " .. util.oneline(chunks), item.extra_hl or "FlyExtra" } }
      end
      marks[#marks + 1] = { row, 0, { virt_text = chunks, virt_text_pos = "right_align", hl_mode = "combine" } }
    end
    if self.selected[item] then
      marks[#marks + 1] = { row, 0, { sign_text = "●", sign_hl_group = "FlySelected" } }
    end
  end

  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    pcall(api.nvim_buf_set_extmark, buf, ns, m[1], m[2], m[3])
  end
  if shown == 0 then
    local hint
    if self.source.live and #self.query < (self.opts.min_query or 2) then
      hint = "type to search…"
    elseif not self.source_done then
      hint = "searching…"
    else
      hint = "no results"
    end
    pcall(api.nvim_buf_set_extmark, buf, ns, total - 1, 0, { virt_text = { { hint, "FlyEmpty" } }, virt_text_pos = "overlay" })
  end

  if self.cursor > shown then
    self.cursor = math.max(shown, 1)
  end
  self:update_cursor()
  self:update_status()
  self:update_preview()
end

function Picker:update_cursor()
  local shown = self:shown()
  if shown == 0 or not win_util.valid(self.list_win) then
    return
  end
  local row = self:row(self.cursor, shown) + 1
  pcall(api.nvim_win_set_cursor, self.list_win, { row, 0 })
end

function Picker:update_status()
  if not (win_util.valid(self.input_win) and self.has_border) then
    return
  end
  local sel = 0
  for _ in pairs(self.selected) do
    sel = sel + 1
  end
  local footer = (" %d/%d%s%s "):format(
    math.min(self.cursor, #self.results),
    #self.results,
    sel > 0 and (" · " .. sel .. " selected") or "",
    self.source_done and "" or " …"
  )
  pcall(api.nvim_win_set_config, self.input_win, { footer = footer, footer_pos = "right" })
end

function Picker:update_preview()
  if not (self.show_preview and win_util.valid(self.preview_win)) then
    return
  end
  if not self.preview_started then
    self.preview_started = true
    preview.update(self)
  else
    self.pv_debounce.call()
  end
end

function Picker:scroll_preview(dir)
  if not win_util.valid(self.preview_win) then
    return
  end
  pcall(api.nvim_win_call, self.preview_win, function()
    vim.cmd("normal! " .. vim.keycode(dir > 0 and "<C-d>" or "<C-u>"))
  end)
end

-- navigation ---------------------------------------------------------------

---@param i integer
function Picker:set_cursor(i)
  local shown = self:shown()
  if shown == 0 then
    return
  end
  self.cursor = math.max(1, math.min(i, shown))
  self:update_cursor()
  self:update_status()
  self:update_preview()
end

--- Move visually: positive = down.
---@param delta integer
---@param nowrap? boolean
function Picker:move(delta, nowrap)
  local shown = self:shown()
  if shown == 0 then
    return
  end
  if self.flip then
    delta = -delta -- best match sits at the bottom
  end
  local target = self.cursor + delta
  if (self.opts.cycle ~= false) and not nowrap then
    target = ((target - 1) % shown) + 1
  end
  self:set_cursor(target)
end

-- history ------------------------------------------------------------------

function Picker:remember_query()
  local q = vim.trim(self.query)
  if q == "" then
    return
  end
  local h = M.history[self.name] or {}
  M.history[self.name] = h
  for i = #h, 1, -1 do
    if h[i] == q then
      table.remove(h, i)
    end
  end
  table.insert(h, 1, q)
  for i = #h, (self.opts.history or 100) + 1, -1 do
    h[i] = nil
  end
end

---@param dir integer 1 = older, -1 = newer
function Picker:history(dir)
  local h = M.history[self.name] or {}
  if self.hist_idx == 0 or self.hist_idx == nil then
    self.hist_draft = self.query
  end
  local idx = math.max(0, math.min((self.hist_idx or 0) + dir, #h))
  self.hist_idx = idx
  self:set_query(idx == 0 and (self.hist_draft or "") or h[idx])
end

-- actions / keys -----------------------------------------------------------

---@param action string|function
function Picker:run_action(action)
  if self.closed then
    return
  end
  local fn = type(action) == "function" and action or self.actions[action]
  if not fn then
    return util.warn("unknown action: " .. tostring(action))
  end
  local ok, err = pcall(fn, self)
  if not ok then
    util.error(("action '%s' failed: %s"):format(tostring(action), tostring(err)))
  end
end

function Picker:setup_keys()
  local buf = self.input_buf
  local function map(mode, lhs, action)
    if action == false then
      return
    end
    vim.keymap.set(mode, lhs, function()
      self:run_action(action)
    end, { buffer = buf, nowait = true, silent = true, desc = "fly: " .. (type(action) == "string" and action or "custom") })
  end
  for lhs, action in pairs(self.keys) do
    map({ "i", "n" }, lhs, action)
  end
  for lhs, action in pairs(self.opts.normal_keys or {}) do
    map("n", lhs, action)
  end
end

-- windows ------------------------------------------------------------------

local WINHL = "Normal:FlyNormal,NormalFloat:FlyNormal,FloatBorder:FlyBorder,FloatTitle:FlyTitle,FloatFooter:FlyFooter"

function Picker:open_preview(rect)
  self.preview_buf = win_util.scratch("preview", "fly_preview")
  vim.bo[self.preview_buf].modifiable = false
  self.preview_win = win_util.open(self.preview_buf, {
    row = rect.row,
    col = rect.col,
    width = rect.width,
    height = rect.height,
    border = self.border,
    title = " preview ",
    title_pos = "left",
    focusable = false,
    zindex = self.zindex,
  }, false, {
    winhighlight = WINHL .. ",CursorLine:FlyCursorLine",
    wrap = false,
    signcolumn = "no",
    foldenable = false,
    scrolloff = 0,
  })
  self.preview_started = false
end

function Picker:create_windows()
  local opts = self.opts
  self.border = win_util.border(opts.win and opts.win.border)
  self.has_border = win_util.has_border(self.border)
  self.zindex = (opts.win and opts.win.zindex) or 50
  self.layout_spec = layout.resolve(opts.layout, opts.layouts)
  local pv = opts.preview
  self.show_preview = pv ~= false and (type(pv) ~= "table" or pv.enabled ~= false) and self.source.preview ~= false
  local geo = layout.compute(self.layout_spec, self.show_preview, self.has_border)
  self.flip = geo.flip

  local backdrop = opts.win and opts.win.backdrop
  if self.layout_spec.backdrop ~= nil then
    backdrop = self.layout_spec.backdrop
  end
  if backdrop == true then
    backdrop = 60
  end
  if backdrop and backdrop ~= false then
    self.backdrop_buf = win_util.scratch("backdrop", "fly_backdrop")
    self.backdrop_win = win_util.open(self.backdrop_buf, {
      row = 0,
      col = 0,
      width = vim.o.columns,
      height = vim.o.lines,
      border = "none",
      focusable = false,
      zindex = self.zindex - 1,
    }, false, { winblend = backdrop, winhighlight = "Normal:FlyBackdrop" })
  end

  self.input_buf = win_util.scratch("input", "fly_input")
  self.list_buf = win_util.scratch("list", "fly_list")
  vim.bo[self.list_buf].modifiable = false

  local title = (" %s "):format(opts.title or self.source.title or "fly")
  self.input_win = win_util.open(self.input_buf, {
    row = geo.input.row,
    col = geo.input.col,
    width = geo.input.width,
    height = 1,
    border = self.border,
    title = title,
    title_pos = "left",
    zindex = self.zindex + 1,
  }, true, {
    winhighlight = WINHL,
    wrap = false,
    statuscolumn = "%#FlyPrompt#" .. (opts.prompt or "❯ "):gsub("%%", "%%%%") .. "%*",
    scrolloff = 0,
  })
  self.list_win = win_util.open(self.list_buf, {
    row = geo.list.row,
    col = geo.list.col,
    width = geo.list.width,
    height = geo.list.height,
    border = self.border,
    focusable = false,
    zindex = self.zindex,
  }, false, {
    winhighlight = WINHL .. ",CursorLine:FlyCursorLine",
    cursorline = true,
    wrap = false,
    signcolumn = "yes:1",
    foldenable = false,
    scrolloff = 0,
  })
  if geo.preview then
    self:open_preview(geo.preview)
  end
end

function Picker:relayout()
  if self.closed then
    return
  end
  local geo = layout.compute(self.layout_spec, self.show_preview, self.has_border)
  self.flip = geo.flip
  local function place(win, r)
    if win_util.valid(win) then
      pcall(api.nvim_win_set_config, win, { relative = "editor", row = r.row, col = r.col, width = r.width, height = r.height })
    end
  end
  place(self.input_win, { row = geo.input.row, col = geo.input.col, width = geo.input.width, height = 1 })
  place(self.list_win, geo.list)
  if win_util.valid(self.backdrop_win) then
    place(self.backdrop_win, { row = 0, col = 0, width = vim.o.columns, height = vim.o.lines })
  end
  if geo.preview then
    if win_util.valid(self.preview_win) then
      place(self.preview_win, geo.preview)
    else
      self:open_preview(geo.preview)
    end
  elseif win_util.valid(self.preview_win) then
    require("fly.image").clear(self)
    win_util.close(self.preview_win)
    self.preview_win = nil
  end
  self.dirty_sort = true
  self:render()
  if geo.preview then
    preview.update(self)
  end
end

function Picker:setup_autocmds()
  local group = api.nvim_create_augroup("fly.picker." .. self.input_buf, { clear = true })
  self.augroup = group
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = self.input_buf,
    callback = function()
      self:on_query(self:get_query())
    end,
  })
  api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = self.input_buf,
    callback = function()
      vim.schedule(function()
        if not self.closed and api.nvim_get_current_win() ~= self.input_win then
          self:close()
        end
      end)
    end,
  })
  api.nvim_create_autocmd({ "VimResized" }, {
    group = group,
    callback = function()
      self:relayout()
    end,
  })
  api.nvim_create_autocmd("TabLeave", {
    group = group,
    callback = function()
      vim.schedule(function()
        self:close()
      end)
    end,
  })
  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = self.input_buf,
    callback = function()
      vim.schedule(function()
        self:close()
      end)
    end,
  })
end

function Picker:open()
  self.ns = api.nvim_create_namespace("fly.list")
  self:create_windows()
  self:setup_keys()
  self:setup_autocmds()
  self.pv_debounce = util.debounce(self.opts.preview and self.opts.preview.debounce or 15, function()
    if not self.closed then
      preview.update(self)
    end
  end)
  self.live_debounce = util.debounce(self.opts.debounce or 120, function()
    if not self.closed then
      self:run_source()
    end
  end)
  self.query = self.opts.query or ""
  self.parsed = matcher.parse(self.query, self.opts.matcher)
  if self.query ~= "" then
    api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { self.query })
  end
  self:run_source()
  self:render()
  vim.cmd("startinsert!")
end

--- Close the picker and restore the origin window. Safe to call repeatedly.
function Picker:close()
  if self.closed then
    return
  end
  self.closed = true
  if M.active == self then
    M.active = nil
  end
  self:stop_source()
  self.pv_debounce.close()
  self.live_debounce.close()
  pcall(api.nvim_del_augroup_by_id, self.augroup)
  require("fly.image").clear(self)
  pcall(vim.cmd, "stopinsert")
  for _, w in ipairs({ self.input_win, self.list_win, self.preview_win, self.backdrop_win }) do
    win_util.close(w)
  end
  if win_util.valid(self.origin.win) then
    pcall(api.nvim_set_current_win, self.origin.win)
  end
  M.last = { opts = self.user_opts, query = self.query }
  if self.opts.on_close then
    pcall(self.opts.on_close, self.confirmed == true)
  end
end

---@param how? "edit"|"split"|"vsplit"|"tab"
function Picker:confirm(how)
  if self.closed then
    return
  end
  local items = items_of(self)
  if #items == 0 then
    local cur = self:current()
    if cur then
      items = { cur }
    end
  end
  if #items == 0 then
    return
  end
  self:remember_query()
  local ctx = self:ctx()
  ctx.how, ctx.items = how or "edit", items
  local confirm = self.opts.confirm or self.source.confirm or M.default_confirm
  self.confirmed = true
  self:close()
  -- let `stopinsert` take effect before acting on the origin window
  vim.schedule(function()
    local ok, err = pcall(confirm, items[1], ctx)
    if not ok then
      util.error(tostring(err):gsub("^.-:%d+: ", ""))
    end
  end)
end

-- ---------------------------------------------------------------------------
-- entry points
-- ---------------------------------------------------------------------------

---@param user_opts? table
---@return fly.Picker?
function M.open(user_opts)
  local fly = require("fly")
  user_opts = user_opts or {}
  if M.active then
    M.active:close()
  end

  local source_spec = user_opts.source
  if source_spec == nil and user_opts.items then
    local items = user_opts.items
    source_spec = {
      title = user_opts.title or "select",
      ordered = true,
      find = function()
        return vim.deepcopy(items)
      end,
    }
  end
  local source, name = sources.get(source_spec or "files")
  if not source then
    return nil
  end

  local shallow = vim.tbl_extend("force", {}, user_opts)
  shallow.items, shallow.source = nil, nil
  local per_source = fly.config.sources[name] or {}
  local opts = vim.tbl_deep_extend("force", fly.config, source.defaults or {}, per_source, shallow)
  opts.keys = vim.tbl_extend("force", fly.config.keys, source.keys or {}, per_source.keys or {}, user_opts.keys or {})

  local origin = {
    win = api.nvim_get_current_win(),
    buf = api.nvim_get_current_buf(),
    cwd = vim.fn.getcwd(),
  }
  local self = setmetatable({
    opts = opts,
    user_opts = user_opts,
    source = source,
    name = name,
    origin = origin,
    cwd = vim.fs.normalize(vim.fn.fnamemodify(opts.cwd or origin.cwd, ":p")),
    keys = opts.keys,
    actions = vim.tbl_extend("force", M.actions, source.actions or {}, user_opts.actions or {}),
    items = {},
    results = {},
    selected = {},
    cursor = 1,
    query = "",
    gen = 0,
    fpos = 1,
    pad = 0,
    closed = false,
  }, Picker)
  M.active = self
  local ok, err = pcall(self.open, self)
  if not ok then
    self:close()
    util.error("failed to open picker: " .. tostring(err))
    return nil
  end
  return self
end

--- Re-open the last picker with its query.
function M.resume()
  if not M.last then
    return util.warn("nothing to resume")
  end
  local opts = vim.tbl_extend("force", {}, M.last.opts, { query = M.last.query })
  return M.open(opts)
end

--- `vim.ui.select` implementation.
function M.select(items, opts, on_choice)
  opts = opts or {}
  local fmt = opts.format_item or tostring
  local list = {}
  for i, it in ipairs(items) do
    list[i] = { label = util.oneline(fmt(it)), data = it, idx = i }
  end
  M.open({
    items = list,
    title = (opts.prompt or "select"):gsub("[:%s]+$", ""),
    preview = { enabled = false },
    layout = { preset = "default", width = 0.5, height = math.min(#list + 6, 20) },
    confirm = function(item)
      on_choice(item.data, item.idx)
    end,
    on_close = function(confirmed)
      if not confirmed then
        on_choice(nil, nil)
      end
    end,
  })
end

return M
