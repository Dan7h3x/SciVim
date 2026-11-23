--- Native sixel backend (st with the sixel patch, foot, mlterm, WezTerm, iTerm2, ...).
---
--- Sixel has no placeholders: pixels are painted onto the cell grid and are
--- wiped whenever the terminal repaints those cells. So the buffer reserves
--- blank virtual cells (inline virt_text / virt_lines) and this backend paints
--- the pre-encoded sixel data at the cells' screen position a moment after
--- Neovim has flushed. Whenever Neovim rewrites those cells (scroll, edit,
--- revealing source) the old image is erased by the terminal itself, so we
--- only need to draw again when a placement's position or image changed.
local util = require("mip.util")
local term = require("mip.term")
local pos = require("mip.backend.pos")
local api, fn = vim.api, vim.fn
local uv = vim.uv or vim.loop

local X = { name = "sixel", positional = true, max_cells = 200, encode = true }
local counter = 0

local TERMS = { "^st", "^foot", "^mlterm", "^contour", "^yaft", "^wezterm", "^mintty" }

function X.supported()
  if not util.sixel_encoder() then return false end
  if vim.g.mip_force_sixel then return true end
  local t = vim.env.TERM or ""
  for _, pat in ipairs(TERMS) do
    if t:find(pat) then return true end
  end
  local p = vim.env.TERM_PROGRAM
  return p == "WezTerm" or p == "iTerm.app"
end

function X.init()
  -- DECSDM must stay RESET (?80l): when set, terminals paint every sixel at the
  -- screen's top-left corner and ignore the cursor, which is where "(0,0)" came from.
  term.write("\27[?80l", true)
end

function X.new_id()
  counter = counter + 1
  return counter
end

function X.texts(img)
  local rows, blank = {}, (" "):rep(img.cols)
  for r = 1, img.rows do rows[r] = blank end
  return rows
end

function X.upload(img)
  api.nvim_set_hl(0, img.hl, {})
  local data = util.read_file(img.path)
  img.data = data and (data:gsub("%s+$", "")) or nil
end

function X.free(img)
  img.data = nil
end

local function draw(S)
  if S.six_dead then return end
  local want = pos.collect(S)
  local sig = {}
  for _, w in ipairs(want) do sig[#sig + 1] = ("%s@%d,%d"):format(w.p.img.k, w.x, w.y) end
  sig = table.concat(sig, ";")
  if not S.six_force and sig == S.six_sig then return end
  S.six_force = false
  S.six_sig = sig
  if fn.pumvisible() == 1 then
    S.six_sig = nil -- popup menu overlaps cells; draw again once it is gone
    return
  end
  local parts = {}
  for _, w in ipairs(want) do
    local data = w.p.img.data
    if data then
      -- DECSC, move, image, DECRC: Neovim's own cursor position is left untouched
      parts[#parts + 1] = "\27" .. "7" .. "\27[?80l" .. ("\27[%d;%dH"):format(w.y + 1, w.x + 1) .. data .. "\27" .. "8"
    end
  end
  if #parts > 0 then term.write(table.concat(parts), true) end
end

--- schedule a (debounced) paint of S's images; `force` repaints even if unchanged
function X.sync(S, force)
  S.six_dead = false
  if force then S.six_force = true end
  if not S.six_timer then S.six_timer = uv.new_timer() end
  S.six_timer:stop()
  S.six_timer:start(30, 0, vim.schedule_wrap(function() draw(S) end))
end

function X.redraw(S)
  X.sync(S, true)
end

--- cursor moved: 'cursorline' repaints the line, which can wipe inline images on it
function X.touch(S)
  local l = api.nvim_win_get_cursor(0)[1]
  if l ~= S.six_line then
    S.six_line = l
    X.sync(S, true)
  end
end

function X.clear(S)
  S.six_sig = nil
  S.six_dead = true
  if S.six_timer then
    S.six_timer:stop()
    S.six_timer:close()
    S.six_timer = nil
  end
end

function X.shutdown() end

return X
