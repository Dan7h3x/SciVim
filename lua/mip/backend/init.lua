local config = require("mip.config")
local util = require("mip.util")

local B = { current = nil }

--- Terminals that cannot show any inline graphics.
local function no_graphics()
  local t, e = vim.env.TERM or "", vim.env
  return t:find("^alacritty") ~= nil or e.ALACRITTY_LOG ~= nil or e.ALACRITTY_SOCKET ~= nil
    or t == "linux" or e.TERM_PROGRAM == "Apple_Terminal"
end

--- Choose the backend. auto: kitty > sixel > ueberzug > text (unicode).
--- Terminals known to lack graphics skip ueberzug (it would overlay an X11 window).
function B.pick()
  local want = config.values.backend
  local kitty = require("mip.backend.kitty")
  local sixel = require("mip.backend.sixel")
  local uz = require("mip.backend.ueberzug")
  local text = require("mip.backend.text")
  B.current = nil
  if want == "text" then
    B.current = text
  elseif (want == "auto" or want == "kitty") and (kitty.supported() or want == "kitty") then
    B.current = kitty
  elseif (want == "auto" or want == "sixel") and sixel.supported() then
    B.current = sixel
  elseif want == "sixel" and util.sixel_encoder() then
    B.current = sixel -- forced: skip terminal heuristics
  elseif (want == "auto" and not no_graphics() or want == "ueberzug") and uz.supported() then
    B.current = uz
  elseif want == "auto" and config.values.fallback then
    B.current = text
    util.notify("no graphics-capable terminal/backend found: using unicode text rendering", vim.log.levels.INFO)
  end
  return B.current
end

return B
