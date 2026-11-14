--- Screen coordinates of placed images, for backends that draw at absolute
--- positions (sixel, ueberzug). Positions are 0-based terminal cells.
local util = require("mip.util")
local api, fn = vim.api, vim.fn

local P = {}

local function xy(S, win, info, p)
  local m = api.nvim_buf_get_extmark_by_id(S.buf, util.ns, p.ids[1], { details = true })
  if not m or #m == 0 then return end
  local d = m[3]
  local rows = p.img.rows
  if p.block.mode == "line" then
    local erow = d.end_row
    if erow + 1 < info.topline or erow + 1 > info.botline then return end
    local y
    -- the image rows sit right above the next buffer line
    local nxt = fn.screenpos(win, erow + 2, 1)
    if nxt.row > 0 then
      y = nxt.row - 1 - rows
    else
      local h = api.nvim_win_text_height(win, { start_row = info.topline - 1, end_row = erow })
      y = info.winrow - 1 + h.all - rows
    end
    local top = info.winrow - 1
    if y < top or y + rows > top + info.height then return end
    return info.wincol - 1 + info.textoff + p.pad, y
  end
  -- inline: the image ends where the first character after the concealed range starts
  local sp = fn.screenpos(win, d.end_row + 1, d.end_col + 1)
  if sp.row == 0 then return end
  local x = sp.col - 1 - p.img.cols
  if x < info.wincol - 1 + info.textoff then return end
  return x, sp.row - 1
end

--- list of { x, y, p } for every visible, non-revealed placement of S
function P.collect(S)
  local out = {}
  local win = S.win
  if not (win and api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == S.buf) then return out end
  local info = fn.getwininfo(win)[1]
  for _, p in ipairs(S.placed) do
    if not p.dead then
      local ok, x, y = pcall(xy, S, win, info, p)
      -- never touch the last terminal row (sixel would scroll the screen)
      if ok and x and y + p.img.rows < vim.o.lines then
        out[#out + 1] = { x = x, y = y, p = p }
      end
    end
  end
  return out
end

return P
