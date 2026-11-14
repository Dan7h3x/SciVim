--- MIP — Math In Place
---
--- Inline previews of LaTeX / Typst / Org math, tables, figures and sections,
--- drawn as real images with Neovim virtual text (needs Neovim >= 0.11).
---
---   require("mip").setup({})   -- see lua/mip/config.lua for every option
---
--- Commands: :MIP [enable|disable|toggle|refresh|clear|info|errors]
local config = require("mip.config")
local util = require("mip.util")
local term = require("mip.term")
local B = require("mip.backend")
local Store = require("mip.store")
local R = require("mip.render")
local P = require("mip.parse")
local J = require("mip.jobs")
local D = require("mip.decor")
local Text = require("mip.text")

local api, fn, uv = vim.api, vim.fn, vim.uv or vim.loop
local ns, ns_anchor = util.ns, util.ns_anchor

local M = {}
local aug = api.nvim_create_augroup("MIP", { clear = true })
local States = {}
local EDIT = {}
local schedule, update

---------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------

local function ensure_wo(S, win)
  if not S.wo[win] then
    S.wo[win] = { cl = vim.wo[win].conceallevel, cc = vim.wo[win].concealcursor }
  end
  if vim.wo[win].conceallevel < 2 then vim.wo[win].conceallevel = 1 end
  if vim.wo[win].concealcursor ~= "nvic" then vim.wo[win].concealcursor = "nvic" end
end

local function restore_wo(S, win)
  local old = S.wo[win]
  if old and api.nvim_win_is_valid(win) then
    vim.wo[win].conceallevel = old.cl
    vim.wo[win].concealcursor = old.cc
  end
  S.wo[win] = nil
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

local function layout_and_decorate(S, b, m)
  local spec = D.layout(S, S.win, b, m)
  local ent = m
  if m.kind == "svg" then
    local task = J.raster(m, spec)
    ent = task and R.ensure(task, S)
  end
  if not ent then return end
  if not ent.ok then return D.error_mark(S, b, ent.err) end
  if B.current.encode then -- sixel: png canvas -> sixel text
    local task = J.encode(ent, spec)
    ent = task and R.ensure(task, S)
    if not ent then return end
    if not ent.ok then return D.error_mark(S, b, ent.err) end
  end
  D.decorate(S, S.win, b, ent, spec)
end

update = function(S)
  local buf = S.buf
  if States[buf] ~= S or not api.nvim_buf_is_valid(buf) then return end
  local backend = B.current
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  S.placed, S.used = {}, {}

  local tab, wins, top, bot = api.nvim_get_current_tabpage(), {}, math.huge, 0
  for _, w in ipairs(fn.win_findbuf(buf)) do
    if api.nvim_win_get_tabpage(w) == tab then
      local i = fn.getwininfo(w)[1]
      wins[#wins + 1] = w
      top, bot = math.min(top, i.topline), math.max(bot, i.botline)
    end
  end
  if not S.enabled or #wins == 0 then
    D.clear_anchor(S)
    if backend.positional then backend.clear(S) end
    return
  end
  local cur = api.nvim_get_current_win()
  S.win = vim.tbl_contains(wins, cur) and cur or wins[1]
  for _, w in ipairs(wins) do ensure_wo(S, w) end

  local cfg = config.values
  S.fg = util.fg_hex()
  S.pxpt = term.ch / 14.5 * cfg.scale -- screen pixels per TeX point
  local name = api.nvim_buf_get_name(buf)
  S.dir = name ~= "" and vim.fs.dirname(vim.fs.normalize(name)) or fn.getcwd()
  S.pre = J.preamble(S)

  local nl = api.nvim_buf_line_count(buf)
  local lo, hi = math.max(0, top - 1 - cfg.margin), math.min(nl, bot + cfg.margin)
  for _ = 1, 100 do -- start scanning at a paragraph boundary
    if lo <= 0 then break end
    local l = api.nvim_buf_get_lines(buf, lo, lo + 1, false)[1]
    if not l or l:match("^%s*$") then break end
    lo = lo - 1
  end

  local editing, crow, ccol = false, 0, 0
  if api.nvim_win_get_buf(cur) == buf then
    editing = EDIT[api.nvim_get_mode().mode:sub(1, 1)] or cfg.reveal_on_cursor
    if editing then
      local pos = api.nvim_win_get_cursor(cur)
      crow, ccol = pos[1] - 1, pos[2]
    end
  end

  local anchored = false
  for _, b in ipairs(P.parse(S, lo, hi)) do
    if editing and D.inside(crow, ccol, b.srow, b.scol, b.erow, b.ecol, b.mode == "line") then
      D.set_anchor(S, b.srow, b.scol, b.erow, b.ecol, b.mode == "line")
      anchored = true
    elseif backend.text then
      local res = Text.render(S, b)
      if res then
        D.decorate_text(S, S.win, b, res)
      end
    else
      local task = J.master(S, b)
      local m = task and R.ensure(task, S)
      if m then
        if m.ok then layout_and_decorate(S, b, m) else D.error_mark(S, b, m.err) end
      end
    end
  end
  if not anchored then D.clear_anchor(S) end

  local live = {}
  for _, s in pairs(States) do
    for k in pairs(s.used) do live[k] = true end
  end
  Store.prune(live)
  if backend.positional then backend.sync(S) end
end

local function safe_update(S)
  local ok, err = pcall(update, S)
  if not ok then
    util.log(tostring(err))
    if not M._failed then
      M._failed = true
      util.notify("update failed (see :MIP errors): " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

schedule = function(S, delay)
  if States[S.buf] ~= S then return end
  if not S.timer then S.timer = uv.new_timer() end
  S.timer:stop()
  S.timer:start(delay, 0, vim.schedule_wrap(function()
    if States[S.buf] == S then safe_update(S) end
  end))
end

R.on_ready = function(S) schedule(S, 10) end

---------------------------------------------------------------------------
-- Attach / detach
---------------------------------------------------------------------------

function M.detach(buf)
  local S = States[buf]
  if not S then return end
  States[buf] = nil
  if S.timer then
    S.timer:stop()
    S.timer:close()
    S.timer = nil
  end
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    api.nvim_buf_clear_namespace(buf, ns_anchor, 0, -1)
    api.nvim_clear_autocmds({ group = aug, buffer = buf })
  end
  for win in pairs(S.wo) do restore_wo(S, win) end
  if B.current and B.current.positional then B.current.clear(S) end
end

local function attach(buf)
  if States[buf] or not B.current or not api.nvim_buf_is_valid(buf) then return end
  local lang = config.values.filetypes[vim.bo[buf].filetype]
  if not lang then return end
  local S = { buf = buf, lang = lang, placed = {}, used = {}, wo = {}, enabled = true, u_shown = {} }
  States[buf] = S

  local function au(ev, cb)
    api.nvim_create_autocmd(ev, { group = aug, buffer = buf, callback = function(a) cb(S, a) end })
  end
  local function leave(s) safe_update(s) end
  au("TextChanged", function() schedule(S, config.values.debounce) end)
  au("CursorMovedI", function()
    D.reveal_sync(S, leave)
    if B.current.touch then B.current.touch(S) end
  end)
  au("CursorMoved", function()
    if config.values.reveal_on_cursor then D.reveal_sync(S, leave) end
    if B.current.touch then B.current.touch(S) end
  end)
  au("BufWinEnter", function() schedule(S, 0) end)
  au("BufWinLeave", function()
    restore_wo(S, api.nvim_get_current_win())
    if B.current.positional then B.current.clear(S) end
  end)
  au({ "BufDelete", "BufWipeout" }, function() M.detach(buf) end)
  au("ModeChanged", function()
    local ev = vim.v.event
    if (ev.old_mode and EDIT[ev.old_mode:sub(1, 1)]) or (ev.new_mode and EDIT[ev.new_mode:sub(1, 1)]) then
      safe_update(S)
    end
  end)
  schedule(S, 0)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function M.refresh()
  Store.clear()
  R.reset()
  term.measure()
  for _, S in pairs(States) do schedule(S, 0) end
end

function M.clear()
  Store.clear()
  R.reset()
  fn.delete(config.values.cache_dir, "rf")
  fn.mkdir(config.values.cache_dir, "p")
  for _, S in pairs(States) do schedule(S, 0) end
end

--- repaint images (e.g. after <C-l> / :redraw! wiped sixel or ueberzug overlays)
function M.redraw()
  if not (B.current and B.current.redraw) then return end
  for _, S in pairs(States) do B.current.redraw(S) end
end

function M.enable(buf) attach(buf or api.nvim_get_current_buf()) end

function M.disable(buf) M.detach(buf or api.nvim_get_current_buf()) end

function M.toggle(buf)
  buf = buf or api.nvim_get_current_buf()
  if States[buf] then M.detach(buf) else attach(buf) end
end

function M.info()
  local c, d = config.values, J.describe()
  local S = States[api.nvim_get_current_buf()]
  util.notify(table.concat({
    "backend       : " .. (B.current and B.current.name or "none"),
    ("cell size    : %.1f x %.1f px"):format(term.cw, term.ch),
    "tmux / ssh    : " .. tostring(term.in_tmux) .. " / " .. tostring(term.remote),
    "parser        : " .. (S and (P.using_ts(S) and "treesitter" or "regex") or "-"),
    "latex         : " .. d.latex,
    "terminal bg   : " .. (term.bg or "-"),
    "svg rasteriser: " .. d.rasterizer,
    "sixel encoder : " .. d.sixel,
    "ueberzug      : " .. d.ueberzug,
    "typst         : " .. d.typst,
    "images        : " .. Store.count,
    "cache         : " .. c.cache_dir,
    "termguicolors : " .. tostring(vim.o.termguicolors),
  }, "\n"))
end

function M.setup(opts)
  if fn.has("nvim-0.11") == 0 then
    return util.notify("requires Neovim >= 0.11", vim.log.levels.ERROR)
  end
  config.setup(opts)
  local cfg = config.values
  EDIT = {}
  for _, m in ipairs(cfg.edit_modes) do EDIT[m] = true end

  local backend = B.pick()
  if not backend then
    return util.notify(
      "no image backend: need kitty/ghostty, a sixel terminal + img2sixel/magick/chafa, or ueberzug(pp)",
      vim.log.levels.WARN)
  end
  if not vim.o.termguicolors then
    util.notify("'termguicolors' is required for kitty placeholders; enabling it", vim.log.levels.WARN)
    vim.o.termguicolors = true
  end
  backend.init()
  if backend.encode and not vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
      and not cfg.sixel.bg then
    term.query_bg()
  end
  if backend.positional then
    backend.reset_cb = function()
      for _, S in pairs(States) do S.u_shown = {} end
    end
  end
  fn.mkdir(cfg.cache_dir .. "/work", "p")
  util.prune_disk()
  term.measure()

  api.nvim_clear_autocmds({ group = aug })
  api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = vim.tbl_keys(cfg.filetypes),
    callback = function(a) vim.schedule(function() attach(a.buf) end) end,
  })
  api.nvim_create_autocmd("WinScrolled", {
    group = aug,
    callback = function()
      for _, S in pairs(States) do
        if fn.bufwinid(S.buf) ~= -1 then
          if backend.positional then
            vim.schedule(function() if States[S.buf] == S then backend.sync(S) end end)
          end
          schedule(S, 40)
        end
      end
    end,
  })
  api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = aug,
    callback = function()
      term.measure()
      for _, S in pairs(States) do schedule(S, 60) end
    end,
  })
  api.nvim_create_autocmd({ "FocusGained", "CompleteDone", "VimResume" }, {
    group = aug,
    callback = M.redraw,
  })
  api.nvim_create_autocmd("TermResponse", {
    group = aug,
    callback = function(a)
      local seq = (type(a.data) == "table" and a.data.sequence) or vim.v.termresponse
      if term.parse_response(seq) then
        for _, S in pairs(States) do schedule(S, 0) end
      end
    end,
  })

  api.nvim_create_autocmd("ColorScheme", {
    group = aug,
    callback = function() for _, S in pairs(States) do schedule(S, 0) end end,
  })
  api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      if backend.positional then
        for _, S in pairs(States) do backend.clear(S) end
      end
      if backend.shutdown then backend.shutdown(Store) end
    end,
  })

  api.nvim_create_user_command("MIP", function(a)
    local cmd = a.args == "" and "toggle" or a.args
    if cmd == "enable" then
      M.enable()
    elseif cmd == "disable" then
      M.disable()
    elseif cmd == "toggle" then
      M.toggle()
    elseif cmd == "refresh" then
      M.refresh()
    elseif cmd == "redraw" then
      M.redraw()
    elseif cmd == "clear" then
      M.clear()
    elseif cmd == "info" then
      M.info()
    elseif cmd == "errors" then
      util.notify(#util.errors == 0 and "no errors" or table.concat(util.errors, "\n"))
    else
      util.notify("unknown subcommand: " .. cmd, vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function() return { "enable", "disable", "toggle", "refresh", "redraw", "clear", "info", "errors" } end,
    desc = "MIP: math in place",
  })

  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) then attach(b) end
  end
end

return M
