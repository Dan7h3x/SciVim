--- kitty graphics protocol, rendered through Unicode placeholders.
---
--- Images are transmitted once (virtual placement, U=1) and then displayed by
--- ordinary text cells (U+10EEEE + row/column diacritics, image id in the
--- foreground colour). Because they are plain virt_text / virt_lines they
--- scroll, wrap, fold and survive redraws exactly like text.
local term = require("mip.term")
local fn, uv = vim.fn, vim.uv or vim.loop

local K = { name = "kitty", positional = false }

-- first 100 entries of kitty's rowcolumn-diacritics table
local DIAC_CP = {
  0x0305, 0x030D, 0x030E, 0x0310, 0x0312, 0x033D, 0x033E, 0x033F, 0x0346, 0x034A,
  0x034B, 0x034C, 0x0350, 0x0351, 0x0352, 0x0357, 0x035B, 0x0363, 0x0364, 0x0365,
  0x0366, 0x0367, 0x0368, 0x0369, 0x036A, 0x036B, 0x036C, 0x036D, 0x036E, 0x036F,
  0x0483, 0x0484, 0x0485, 0x0486, 0x0487, 0x0592, 0x0593, 0x0594, 0x0595, 0x0597,
  0x0598, 0x0599, 0x059C, 0x059D, 0x059E, 0x059F, 0x05A0, 0x05A1, 0x05A8, 0x05A9,
  0x05AB, 0x05AC, 0x05AF, 0x05C4, 0x0610, 0x0611, 0x0612, 0x0613, 0x0614, 0x0615,
  0x0616, 0x0617, 0x0657, 0x0658, 0x0659, 0x065A, 0x065B, 0x065D, 0x065E, 0x06D6,
  0x06D7, 0x06D8, 0x06D9, 0x06DA, 0x06DB, 0x06DC, 0x06DF, 0x06E0, 0x06E1, 0x06E2,
  0x06E4, 0x06E7, 0x06E8, 0x06EB, 0x06EC, 0x0730, 0x0732, 0x0733, 0x0735, 0x0736,
  0x073A, 0x073D, 0x073F, 0x0740, 0x0741, 0x0743, 0x0745, 0x0747, 0x0749, 0x074A,
}
K.max_cells = #DIAC_CP

local PH, DIAC
local ID_LO, ID_SPAN = 0x100000, 0xD00000
local next_id

function K.supported()
  local e = vim.env
  return vim.g.mip_force_kitty == true
    or e.KITTY_WINDOW_ID ~= nil
    or e.TERM == "xterm-kitty"
    or e.TERM == "xterm-ghostty"
    or e.TERM_PROGRAM == "ghostty"
end

function K.init()
  PH = fn.nr2char(0x10EEEE)
  DIAC = {}
  for i, cp in ipairs(DIAC_CP) do DIAC[i] = fn.nr2char(cp) end
  -- image ids live per terminal window: randomise per nvim instance so several
  -- instances (tmux panes) never collide
  next_id = ID_LO + ((uv.os_getpid() * 2654435761) % ID_SPAN)
  term.check_tmux()
end

function K.new_id()
  local id = next_id
  next_id = ID_LO + ((next_id - ID_LO + 1) % ID_SPAN)
  return id
end

--- one placeholder string per image row
function K.texts(img)
  local rows = {}
  for r = 1, img.rows do
    local t = {}
    for c = 1, img.cols do t[c] = PH .. DIAC[r] .. DIAC[c] end
    rows[r] = table.concat(t)
  end
  return rows
end

function K.upload(img)
  vim.api.nvim_set_hl(0, img.hl, { fg = img.id })
  local ctl = ("a=T,U=1,f=100,i=%d,c=%d,r=%d,q=2"):format(img.id, img.cols, img.rows)
  if not term.remote then
    term.write(("\27_G%s,t=f;%s\27\\"):format(ctl, vim.base64.encode(img.path)))
    return
  end
  -- over ssh the terminal can't read our files: stream the data in chunks
  local f = io.open(img.path, "rb")
  if not f then return end
  local data = vim.base64.encode(f:read("*a"))
  f:close()
  local out, CH = {}, 4096
  for i = 1, #data, CH do
    local more = (i + CH <= #data) and 1 or 0
    local chunk = data:sub(i, i + CH - 1)
    if i == 1 then
      out[#out + 1] = ("\27_G%s,m=%d;%s\27\\"):format(ctl, more, chunk)
    else
      out[#out + 1] = ("\27_Gm=%d;%s\27\\"):format(more, chunk)
    end
  end
  term.write(table.concat(out))
end

function K.free(img)
  term.write(("\27_Ga=d,d=I,i=%d,q=2\27\\"):format(img.id))
end

function K.shutdown(store)
  for _, img in pairs(store.imgs) do K.free(img) end
end

return K
