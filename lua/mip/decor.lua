--- Turns rendered images into Neovim virtual text:
---   inline blocks -> conceal + `virt_text_pos = "inline"` (sits in the line, baseline aligned)
---   other blocks  -> `conceal_lines` + `virt_lines` (centered under the hidden source)
--- plus the "show source while editing" anchor logic.
local config = require("mip.config")
local util = require("mip.util")
local term = require("mip.term")
local Store = require("mip.store")
local B = require("mip.backend")
local api, fn = vim.api, vim.fn
local ns, ns_anchor = util.ns, util.ns_anchor

local D = {}

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

---------------------------------------------------------------------------
-- Layout: master size -> cell grid + pixel canvas
---------------------------------------------------------------------------

--- Returns spec { cols, rows, W, H, tx, ty, w, h, text_w } (pixels; the SVG is drawn
--- at (tx,ty) with size (w,h) on a W x H transparent canvas == cols x rows cells).
function D.layout(S, win, b, m)
  local cfg = config.values
  local cw, ch = term.cw, term.ch
  local info = fn.getwininfo(win)[1]
  local text_w = info.width - info.textoff
  local maxcells = B.current.max_cells
  local maxc = clamp(math.floor(text_w * cfg.max_width), 1, maxcells)
  local maxr = clamp(math.floor(info.height * cfg.max_height), 1, maxcells)

  local wpx, hpx = m.w, m.h
  if m.kind == "svg" then wpx, hpx = m.w * S.pxpt, m.h * S.pxpt end
  wpx, hpx = math.max(wpx, 1), math.max(hpx, 1)

  local spec = { text_w = text_w }
  if b.mode == "inline" then
    local s = math.min(1, (ch * 0.96) / hpx, (maxc * cw * 0.8) / wpx)
    wpx, hpx = wpx * s, hpx * s
    spec.cols = clamp(math.ceil(wpx / cw - 0.03), 1, maxcells)
    spec.rows = 1
    spec.W, spec.H = spec.cols * cw, ch
    spec.tx = (spec.W - wpx) / 2
    if m.base then -- align the TeX baseline with the text baseline
      spec.ty = ch * cfg.baseline + m.base * S.pxpt * s - hpx
    else
      spec.ty = (ch - hpx) / 2
    end
    spec.ty = clamp(spec.ty, 0, math.max(0, ch - hpx))
  else
    local s = math.min(1, (maxc * cw) / wpx, (maxr * ch) / hpx)
    wpx, hpx = wpx * s, hpx * s
    spec.cols = clamp(math.ceil(wpx / cw - 0.03), 1, maxcells)
    spec.rows = clamp(math.ceil(hpx / ch - 0.03), 1, maxcells)
    spec.W, spec.H = spec.cols * cw, spec.rows * ch
    spec.tx, spec.ty = (spec.W - wpx) / 2, (spec.H - hpx) / 2
  end
  spec.W, spec.H = math.floor(spec.W + 0.5), math.floor(spec.H + 0.5)
  spec.w, spec.h = wpx, hpx
  return spec
end

---------------------------------------------------------------------------
-- Extmarks
---------------------------------------------------------------------------

local function set_mark(buf, row, col, opts)
  opts.strict = false
  return api.nvim_buf_set_extmark(buf, ns, row, col, opts)
end

function D.decorate(S, win, b, ent, spec)
  local img = Store.get(ent, spec.cols, spec.rows)
  S.used[img.k] = true
  local p = { block = b, img = img, ids = {}, pad = 0 }
  if b.mode == "inline" then
    p.ids[1] = set_mark(S.buf, b.srow, b.scol, { end_row = b.erow, end_col = b.ecol, conceal = "", priority = 100 })
    p.ids[2] = set_mark(S.buf, b.srow, b.scol, {
      virt_text = { { img.texts[1], img.hl } }, virt_text_pos = "inline", priority = 100,
    })
  else
    if config.values.align == "center" then
      p.pad = math.max(0, math.floor((spec.text_w - spec.cols) / 2))
    else
      p.pad = b.indent or 0
    end
    p.ids[1] = set_mark(S.buf, b.srow, 0, { end_row = b.erow, end_col = b.ecol, conceal_lines = "" })
    local vl = {}
    for r = 1, spec.rows do
      local chunks = {}
      if p.pad > 0 then chunks[1] = { (" "):rep(p.pad) } end
      chunks[#chunks + 1] = { img.texts[r], img.hl }
      vl[r] = chunks
    end
    p.ids[2] = set_mark(S.buf, b.erow, 0, { virt_lines = vl, virt_lines_overflow = "scroll" })
  end
  S.placed[#S.placed + 1] = p
end

--- Text backend: show `res.lines` (see mip/text.lua) in place of block `b`.
function D.decorate_text(S, win, b, res)
  local p = { block = b, ids = {}, pad = 0, text = true }
  if b.mode == "inline" then
    p.ids[1] = set_mark(S.buf, b.srow, b.scol, { end_row = b.erow, end_col = b.ecol, conceal = "", priority = 100 })
    p.ids[2] = set_mark(S.buf, b.srow, b.scol, {
      virt_text = { { res.lines[1], res.hl } }, virt_text_pos = "inline", priority = 100,
    })
  else
    local info = fn.getwininfo(win)[1]
    local text_w = info.width - info.textoff
    local maxw = 0
    for _, l in ipairs(res.lines) do maxw = math.max(maxw, fn.strdisplaywidth(l)) end
    local centered = res.center and config.values.align == "center"
    local vl = {}
    for _, l in ipairs(res.lines) do
      local pad = b.indent or 0
      if centered then
        pad = math.max(0, math.floor((text_w - (res.center_each and fn.strdisplaywidth(l) or maxw)) / 2))
      end
      vl[#vl + 1] = pad > 0 and { { (" "):rep(pad) }, { l, res.hl } } or { { l, res.hl } }
    end
    p.ids[1] = set_mark(S.buf, b.srow, 0, { end_row = b.erow, end_col = b.ecol, conceal_lines = "" })
    p.ids[2] = set_mark(S.buf, b.erow, 0, { virt_lines = vl, virt_lines_overflow = "scroll" })
  end
  S.placed[#S.placed + 1] = p
end

function D.error_mark(S, b, err)
  if not config.values.show_errors then return end
  local msg = (err or "render failed"):gsub("%s+", " "):sub(1, 90)
  set_mark(S.buf, b.srow, 0, { virt_text = { { "  ✗ " .. msg, "DiagnosticVirtualTextError" } }, virt_text_pos = "eol" })
end

---------------------------------------------------------------------------
-- Source reveal (anchors)
---------------------------------------------------------------------------

function D.inside(row, col, sr, sc, er, ec, line)
  if row < sr or row > er then return false end
  if line then return true end
  if row == sr and col < sc then return false end
  if row == er and col > ec then return false end
  return true
end

function D.clear_anchor(S)
  if S.anchor then
    pcall(api.nvim_buf_del_extmark, S.buf, ns_anchor, S.anchor)
    S.anchor = nil
  end
end

function D.set_anchor(S, sr, sc, er, ec, line)
  D.clear_anchor(S)
  S.anchor = api.nvim_buf_set_extmark(S.buf, ns_anchor, sr, sc, {
    end_row = er, end_col = ec, end_right_gravity = true, strict = false,
  })
  S.anchor_line = line
end

local function anchor_contains(S, row, col)
  local m = api.nvim_buf_get_extmark_by_id(S.buf, ns_anchor, S.anchor, { details = true })
  if not m or #m == 0 then return false end
  return D.inside(row, col, m[1], m[2], m[3].end_row, m[3].end_col, S.anchor_line)
end

--- Cursor moved while editing: reveal the block under it (strip its decorations),
--- or ask `on_leave` to re-render once the cursor has left the revealed block.
function D.reveal_sync(S, on_leave)
  local win = api.nvim_get_current_win()
  if api.nvim_win_get_buf(win) ~= S.buf then return end
  local pos = api.nvim_win_get_cursor(win)
  local row, col = pos[1] - 1, pos[2]
  if S.anchor then
    if anchor_contains(S, row, col) then return end
    D.clear_anchor(S)
    return on_leave(S)
  end
  for _, p in ipairs(S.placed) do
    if not p.dead then
      local m = api.nvim_buf_get_extmark_by_id(S.buf, ns, p.ids[1], { details = true })
      if m and #m > 0 then
        local line = p.block.mode == "line"
        if D.inside(row, col, m[1], m[2], m[3].end_row, m[3].end_col, line) then
          D.set_anchor(S, m[1], m[2], m[3].end_row, m[3].end_col, line)
          for _, id in ipairs(p.ids) do pcall(api.nvim_buf_del_extmark, S.buf, ns, id) end
          p.dead = true
          if B.current.positional then B.current.sync(S) end
          return
        end
      end
    end
  end
end

return D
