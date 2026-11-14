--- ueberzugpp backend. ueberzugpp >= 2.9 installs its binary as `ueberzug`
--- (older packages: `ueberzugpp`); both are auto-detected. Images are overlaid
--- at screen coordinates while the buffer reserves blank virtual cells for them.
local config = require("mip.config")
local util = require("mip.util")
local pos = require("mip.backend.pos")
local api = vim.api

local U = { name = "ueberzug", positional = true, max_cells = 200 }
local counter = 0

function U.cmd()
  local c = config.values.ueberzug.cmd
  for _, n in ipairs(c and { c } or { "ueberzugpp", "ueberzug" }) do
    if util.exe(n) then return n end
  end
end

function U.supported()
  return U.cmd() ~= nil
end

function U.init() end

function U.new_id()
  counter = counter + 1
  return counter
end

function U.texts(img)
  local rows, blank = {}, (" "):rep(img.cols)
  for r = 1, img.rows do rows[r] = blank end
  return rows
end

function U.upload(img)
  api.nvim_set_hl(0, img.hl, {})
end

function U.free() end

function U.reset_cb() end -- replaced by init.lua (forget shown images)

function U.start()
  if U.proc then return true end
  local cmd = U.cmd()
  if not cmd then return false end
  local argv = { cmd, "layer", "--silent" }
  local out = config.values.ueberzug.output
  if out then vim.list_extend(argv, { "-o", out }) end
  local ok, p = pcall(vim.system, argv, { stdin = true }, function(res)
    U.proc = nil
    if res.code ~= 0 and res.stderr and res.stderr ~= "" then util.log("ueberzug: " .. res.stderr) end
    U.reset_cb()
  end)
  if not ok then
    util.warn_once("ueberzug", "failed to start " .. cmd .. ": " .. tostring(p))
    return false
  end
  U.proc = p
  return true
end

function U.send(msg)
  if not U.start() then return end
  pcall(function() U.proc:write(vim.json.encode(msg) .. "\n") end)
end

function U.clear(S)
  for id in pairs(S.u_shown) do U.send({ action = "remove", identifier = id }) end
  S.u_shown = {}
end

function U.sync(S)
  local want = {}
  for _, w in ipairs(pos.collect(S)) do
    want[("mip:%d:%d:%d"):format(S.buf, w.p.block.srow, w.p.block.scol)] = w
  end
  for id, w in pairs(want) do
    local key = ("%d,%d,%s,%d,%d"):format(w.x, w.y, w.p.img.path, w.p.img.cols, w.p.img.rows)
    if S.u_shown[id] ~= key then
      S.u_shown[id] = key
      U.send({
        action = "add",
        identifier = id,
        x = w.x,
        y = w.y,
        path = w.p.img.path,
        max_width = w.p.img.cols,
        max_height = w.p.img.rows,
      })
    end
  end
  for id in pairs(S.u_shown) do
    if not want[id] then
      S.u_shown[id] = nil
      U.send({ action = "remove", identifier = id })
    end
  end
end

function U.redraw(S)
  U.clear(S)
  U.sync(S)
end

function U.shutdown()
  if U.proc then pcall(function() U.proc:kill(15) end) end
  U.proc = nil
end

return U
