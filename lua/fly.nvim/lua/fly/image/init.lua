--- Image previews. Backends: kitty (Kitty/Ghostty), ueberzug (ueberzugpp).
local detect = require("fly.image.detect")
local util = require("fly.util")

local uv = vim.uv or vim.loop

local M = { opts = {} }

local backend, backend_name

M.exts = {
  png = true, jpg = true, jpeg = true, webp = true, gif = true, bmp = true,
  svg = true, tif = true, tiff = true, avif = true, ico = true, heic = true,
}

---@param path string
function M.is_image(path)
  local ext = path:match("%.([%w]+)$")
  return ext ~= nil and M.exts[ext:lower()] == true
end

function M.setup(opts)
  M.opts = opts or {}
  backend, backend_name = nil, nil -- re-detect lazily
end

--- Lazily select the backend (never spawns anything until an image is shown).
---@return table? backend
function M.backend()
  if backend_name == nil then
    local name = M.opts.backend or "auto"
    if name == "auto" then
      name = detect.preferred()
    end
    if name == "kitty" then
      backend = require("fly.image.kitty")
    elseif name == "ueberzug" then
      backend = require("fly.image.ueberzug")
    else
      backend, name = nil, "none"
    end
    if backend then
      backend.setup(M.opts[name] or {})
    end
    backend_name = name
  end
  return backend
end

function M.name()
  M.backend()
  return backend_name
end

--- Whether any image backend is usable.
function M.supports()
  return M.backend() ~= nil
end

--- PNG pixel size from the IHDR chunk.
---@return { w: integer, h: integer }?
local function png_size(path)
  local data = util.read_file(path, 32)
  if not data or #data < 24 or data:sub(2, 4) ~= "PNG" then
    return nil
  end
  local function u32(i)
    local a, b, c, d = data:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return { w = u32(17), h = u32(21) }
end

--- Cached PNG conversion (async). Calls `cb(png_path | nil, err?)`.
local function to_png(path, cb)
  local conv = detect.converter()
  if not conv then
    return cb(nil, "install ImageMagick to preview this format in kitty")
  end
  local stat = uv.fs_stat(path)
  local dir = vim.fn.stdpath("cache") .. "/fly/img"
  vim.fn.mkdir(dir, "p")
  local key = vim.fn.sha256(path .. ":" .. (stat and stat.mtime.sec or 0)):sub(1, 24)
  local out = dir .. "/" .. key .. ".png"
  if uv.fs_stat(out) then
    return cb(out)
  end
  local cmd = vim.list_extend(vim.deepcopy(conv), { path .. "[0]", "-resize", "1600x1600>", out })
  util.run(cmd, nil, function(res)
    if res.code == 0 and uv.fs_stat(out) then
      cb(out)
    else
      cb(nil, "image conversion failed")
    end
  end)
end

local function geometry(picker)
  return require("fly.win").geometry(picker.preview_win)
end

--- Show `path` in the preview window of `picker`.
--- `valid()` must return false once the preview target changed (stale async result).
---@param picker table
---@param path string
---@param valid fun(): boolean
---@param cb fun(ok: boolean, msg?: string)
function M.show(picker, path, valid, cb)
  local be = M.backend()
  if not be then
    return cb(false, "no image backend (kitty/ghostty terminal or ueberzugpp required)")
  end
  local function place(file)
    if not valid() then
      return
    end
    picker.image = { path = file, orig = path }
    local geo = geometry(picker)
    if backend_name == "kitty" then
      be.show(geo, file, png_size(file), M.opts.cell_ratio or 0.5)
    else
      be.show(geo, file)
    end
    cb(true)
  end
  if backend_name == "kitty" then
    if path:lower():match("%.png$") then
      place(path)
    elseif M.opts.convert == false then
      cb(false, "format not supported by kitty without conversion")
    else
      to_png(path, function(png, err)
        if not valid() then
          return
        end
        if png then
          place(png)
        else
          cb(false, err)
        end
      end)
    end
  else
    place(path)
  end
end

--- Re-draw the current image (after relayout).
function M.redraw(picker)
  local img = picker.image
  local be = backend
  if not (img and be and picker.preview_win and vim.api.nvim_win_is_valid(picker.preview_win)) then
    return
  end
  local geo = geometry(picker)
  if backend_name == "kitty" then
    be.show(geo, img.path, png_size(img.path), M.opts.cell_ratio or 0.5)
  else
    be.show(geo, img.path)
  end
end

function M.clear(picker)
  if picker then
    picker.image = nil
  end
  if backend and backend.hide then
    backend.hide()
  end
end

return M
