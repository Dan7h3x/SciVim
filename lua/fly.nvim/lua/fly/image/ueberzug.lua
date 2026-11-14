-- ueberzugpp JSON IPC. The overlay is drawn *over* the terminal cells (X11 / Wayland / sixel...).
local M = {}

local job
local identifier = "fly-preview"
local shown = false

function M.setup(opts)
  M.opts = opts or {}
end

local function ensure()
  if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
    return true
  end
  local bin = (M.opts and M.opts.bin) or "ueberzugpp"
  if vim.fn.executable(bin) == 0 then
    bin = "ueberzug"
  end
  if vim.fn.executable(bin) == 0 then
    return false
  end
  job = vim.fn.jobstart({ bin, "layer", "--parser", "json", "--silent" }, { stdin = "pipe", pty = false })
  return job > 0
end

local function send(obj)
  if ensure() then
    vim.fn.chansend(job, vim.json.encode(obj) .. "\n")
  end
end

---@param geo { row: integer, col: integer, width: integer, height: integer }
function M.show(geo, path)
  shown = true
  send({
    action = "add",
    identifier = identifier,
    x = geo.col,
    y = geo.row,
    max_width = geo.width,
    max_height = geo.height,
    path = path,
    scaler = (M.opts and M.opts.scaler) or "contain",
    synchronously_draw = true,
  })
end

function M.hide()
  if shown then
    shown = false
    send({ action = "remove", identifier = identifier })
  end
end

return M
