local config = require("mip.config")
local util = require("mip.util")
local api, uv = vim.api, vim.uv or vim.loop

local T = { cw = 10, ch = 20 }
T.in_tmux = vim.env.TMUX ~= nil
T.remote = (vim.env.SSH_TTY or vim.env.SSH_CONNECTION) ~= nil

--- Measure the cell size in pixels (TIOCGWINSZ), falling back to 10x20.
function T.measure()
  local cs = config.values.cell_size
  if cs then
    T.cw, T.ch = cs[1], cs[2]
    return
  end
  local ok, ffi = pcall(require, "ffi")
  if not ok then return end
  if not T._cdef then
    pcall(ffi.cdef, [[
      typedef struct { unsigned short row, col, xpixel, ypixel; } mip_winsize;
      int ioctl(int fd, unsigned long req, ...);
    ]])
    T._cdef = true
  end
  local ok2, res = pcall(function()
    local ws = ffi.new("mip_winsize[1]")
    local req = (jit.os == "Linux") and 0x5413 or 0x40087468
    if ffi.C.ioctl(1, req, ws) == 0 and ws[0].xpixel > 0 and ws[0].col > 0 and ws[0].row > 0 then
      return { ws[0].xpixel / ws[0].col, ws[0].ypixel / ws[0].row }
    end
  end)
  if ok2 and res then T.cw, T.ch = res[1], res[2] end
end

local tty
--- Write raw escape sequences to the terminal (tmux passthrough aware).
function T.write(seq, raw)
  if T.in_tmux and not raw then
    seq = "\27Ptmux;" .. (seq:gsub("\27", "\27\27")) .. "\27\\"
  end
  if api.nvim_ui_send then
    api.nvim_ui_send(seq)
    return
  end
  if not tty then tty = uv.new_tty(1, false) end
  if tty then tty:write(seq) end
end

--- Ask the terminal for its background colour (OSC 11); the reply arrives via
--- TermResponse and is parsed by T.parse_response.
function T.query_bg()
  T.write("\27]11;?\27\\", true)
end

--- returns true when `seq` was an OSC 11 reply that changed T.bg
function T.parse_response(seq)
  local r, g, b = (seq or ""):match("\27%]11;rgb:(%x+)/(%x+)/(%x+)")
  if not r then return false end
  local function c8(h) return (#h == 1) and (h .. h) or h:sub(1, 2) end
  local bg = (c8(r) .. c8(g) .. c8(b)):upper()
  if bg == T.bg then return false end
  T.bg = bg
  return true
end

function T.check_tmux()
  if not T.in_tmux then return end
  pcall(vim.system, { "tmux", "show", "-Apv", "allow-passthrough" }, { text = true }, function(res)
    local v = vim.trim(res.stdout or "")
    if v ~= "on" and v ~= "all" then
      vim.schedule(function()
        util.warn_once("tmux", "tmux: images need `set -g allow-passthrough on`")
      end)
    end
  end)
end

return T
