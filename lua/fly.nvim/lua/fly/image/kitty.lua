-- Kitty graphics protocol (Kitty, Ghostty).
--   transmit+display: ESC _ G a=T,f=100,t=f,i=<id>,c=<cols>,r=<rows>,C=1 ; base64(path) ESC \
--   delete:           ESC _ G a=d,d=I,i=<id> ESC \
-- Only PNG can be transmitted by file path; `fly.image` converts other formats first.
local tty = require("fly.image.tty")

local M = {}

local ID = 0x464C59 -- "FLY": unlikely to collide with other plugins
local placed = false

function M.setup(opts)
  M.opts = opts or {}
end

local function esc_g(params, payload)
  local keys = {}
  for k in pairs(params) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. tostring(params[k])
  end
  local body = table.concat(parts, ",")
  if payload then
    body = body .. ";" .. payload
  end
  return "\27_G" .. body .. "\27\\"
end

---@param geo { row: integer, col: integer, width: integer, height: integer } content area, 0-based
---@param png string
---@param px? { w: integer, h: integer } pixel size (keeps aspect ratio)
---@param cell_ratio number cell width / cell height
function M.show(geo, png, px, cell_ratio)
  local cols, rows = geo.width, geo.height
  local off_r, off_c = 0, 0
  if px and px.w > 0 and px.h > 0 then
    local aspect = px.h / px.w
    rows = math.floor(cols * cell_ratio * aspect + 0.5)
    if rows > geo.height then
      rows = geo.height
      cols = math.floor(rows / (cell_ratio * aspect) + 0.5)
    end
    cols, rows = math.max(1, math.min(cols, geo.width)), math.max(1, rows)
    off_r = math.floor((geo.height - rows) / 2)
    off_c = math.floor((geo.width - cols) / 2)
  end
  local pr, pc = tty.pane_offset()
  local seq = table.concat({
    "\0277", -- save cursor
    ("\27[%d;%dH"):format(geo.row + off_r + 1 + pr, geo.col + off_c + 1 + pc),
    esc_g({ a = "d", d = "I", i = ID, q = 2 }), -- replace any previous image
    esc_g({
      a = "T",
      f = 100,
      t = "f",
      i = ID,
      c = cols,
      r = rows,
      C = 1,
      z = (M.opts and M.opts.zindex) or 1,
      q = 2,
    }, vim.base64.encode(png)),
    "\0278", -- restore cursor
  })
  tty.write(seq)
  placed = true
end

function M.hide()
  if not placed then
    return
  end
  placed = false
  tty.write(esc_g({ a = "d", d = "I", i = ID, q = 2 }))
end

return M
