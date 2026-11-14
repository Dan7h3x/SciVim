local config = require("mip.config")
local api, fn, uv = vim.api, vim.fn, vim.uv or vim.loop

local U = {}
U.ns = api.nvim_create_namespace("mip")
U.ns_anchor = api.nvim_create_namespace("mip_anchor")
U.errors = {}

function U.log(msg)
  table.insert(U.errors, os.date("%H:%M:%S ") .. msg)
  if #U.errors > 50 then table.remove(U.errors, 1) end
end

function U.notify(msg, level)
  vim.notify("[MIP] " .. msg, level or vim.log.levels.INFO)
end

local warned = {}
function U.warn_once(key, msg)
  if warned[key] then return end
  warned[key] = true
  U.log(msg)
  U.notify(msg, vim.log.levels.WARN)
end

function U.exe(name)
  return fn.executable(name) == 1
end

function U.write_file(path, data)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(data)
  f:close()
  return true
end

function U.read_file(path)
  local f = io.open(path, "rb")
  if not f then return end
  local d = f:read("*a")
  f:close()
  return d
end

function U.png_size(path)
  local f = io.open(path, "rb")
  if not f then return end
  local d = f:read(24)
  f:close()
  if not d or #d < 24 or d:sub(2, 4) ~= "PNG" then return end
  local function u32(o)
    return d:byte(o) * 16777216 + d:byte(o + 1) * 65536 + d:byte(o + 2) * 256 + d:byte(o + 3)
  end
  return u32(17), u32(21)
end

function U.fg_hex()
  local c = config.values.fg
  if c then return (c:gsub("^#", "")):upper() end
  local hl = api.nvim_get_hl(0, { name = "Normal", link = false })
  return ("%06X"):format(hl.fg or (vim.o.background == "light" and 0x000000 or 0xffffff))
end

function U.resolve_path(S, f)
  if f:sub(1, 1) == "~" then f = (vim.env.HOME or "") .. f:sub(2) end
  if not vim.startswith(f, "/") then f = S.dir .. "/" .. f end
  return vim.fs.normalize(f)
end

--- mtimes of files referenced from `src` so cached renders die with the file
function U.stamp(S, src, patterns)
  local parts = {}
  for _, pat in ipairs(patterns) do
    for f in src:gmatch(pat) do
      local p = U.resolve_path(S, f)
      for _, ext in ipairs({ "", ".png", ".pdf", ".jpg", ".jpeg" }) do
        local st = uv.fs_stat(p .. ext)
        if st and st.type == "file" then
          parts[#parts + 1] = p .. ext .. st.mtime.sec
          break
        end
      end
    end
  end
  return table.concat(parts, "|")
end

---------------------------------------------------------------------------
-- SVG helpers (vector masters -> exact-pixel PNG canvases)
---------------------------------------------------------------------------

--- width, height, viewBox string of an <svg> root (user units)
function U.svg_dims(text)
  local tag = text:match("<svg[^>]*>")
  if not tag then return end
  local vb = tag:match("viewBox%s*=%s*[\"']([^\"']+)[\"']")
  if vb then
    local n = "([%-%d%.eE]+)"
    local _, _, w, h = vb:match(n .. "[,%s]+" .. n .. "[,%s]+" .. n .. "[,%s]+" .. n)
    if w then return tonumber(w), tonumber(h), vb end
  end
  local w = tag:match("%swidth%s*=%s*[\"']([%d%.]+)")
  local h = tag:match("%sheight%s*=%s*[\"']([%d%.]+)")
  if w and h then return tonumber(w), tonumber(h), ("0 0 %s %s"):format(w, h) end
end

--- Embed the master SVG into a W x H canvas at (tx,ty) with size (w,h) pixels.
function U.svg_wrap(src, spec)
  local _, e = src:find("<svg[^>]*>")
  local tag = src:sub(src:find("<svg[^>]*>"))
  local _, _, vb = U.svg_dims(src)
  local inner = (src:sub(e + 1):gsub("%s*</svg>%s*$", ""))
  local ns = {}
  for attr in tag:gmatch("xmlns:[%w%-]+%s*=%s*[\"'][^\"']+[\"']") do
    if not attr:find("xmlns:xlink", 1, true) then ns[#ns + 1] = attr end
  end
  return ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" %s '
        .. 'width="%d" height="%d" viewBox="0 0 %d %d">'
        .. '<svg x="%.2f" y="%.2f" width="%.2f" height="%.2f" viewBox="%s" preserveAspectRatio="none">%s</svg></svg>')
      :format(
        table.concat(ns, " "), spec.W, spec.H, spec.W, spec.H, spec.tx, spec.ty, spec.w, spec.h, vb, inner)
end

local RAST = {
  ["rsvg-convert"] = { "rsvg-convert", "-o", "out.png", "in.svg" },
  resvg = { "resvg", "in.svg", "out.png" },
  inkscape = { "inkscape", "in.svg", "--export-type=png", "--export-filename=out.png" },
  magick = { "magick", "-background", "none", "-density", "96", "in.svg", "out.png" },
}

--- command (reads in.svg, writes out.png) of the first available rasteriser
function U.rasterizer()
  local want = config.values.raster
  local order = want == "auto" and { "rsvg-convert", "resvg", "inkscape", "magick" } or { want }
  for _, n in ipairs(order) do
    if RAST[n] and U.exe(n) then return vim.deepcopy(RAST[n]) end
  end
end

function U.bg_hex()
  local hl = api.nvim_get_hl(0, { name = "Normal", link = false })
  return ("%06X"):format(hl.bg or (vim.o.background == "light" and 0xffffff or 0x000000))
end

--- Colour sixel images are composited on (sixel has no alpha):
--- config -> Normal's bg -> the terminal's real bg (OSC 11 reply) -> light/dark guess.
function U.sixel_bg()
  local c = config.values.sixel.bg
  if c then return (c:gsub("^#", "")):upper() end
  local hl = api.nvim_get_hl(0, { name = "Normal", link = false })
  if hl.bg then return ("%06X"):format(hl.bg) end
  return require("mip.term").bg or (vim.o.background == "light" and "FFFFFF" or "000000")
end

-- png -> sixel on stdout; `spec` carries the pixel canvas (W, H) and cell grid (cols, rows)
local ENC = {
  img2sixel = {
    name = "img2sixel",
    cmd = function(path, bg, spec)
      return { "img2sixel", "-B", "#" .. bg, "-p", "64", "-d", "none", "-w", tostring(spec.W), "-h", tostring(spec.H),
        path }
    end,
  },
  magick = {
    name = "magick",
    cmd = function(path, bg, spec)
      return { "magick", path, "-background", "#" .. bg, "-alpha", "remove", "-alpha", "off",
        "-resize", ("%dx%d!"):format(spec.W, spec.H), "+dither", "-colors", "64", "sixel:-" }
    end,
  },
  chafa = {
    name = "chafa",
    cmd = function(path, bg, spec)
      return { "chafa", "-f", "sixel", "--bg", "#" .. bg, "--stretch", "--animate=off", "--dither=none",
        "-s", ("%dx%d"):format(spec.cols, spec.rows), path }
    end,
  },
}

function U.sixel_encoder()
  local want = config.values.sixel.encoder
  local order = want == "auto" and { "img2sixel", "magick", "chafa" } or { want }
  for _, n in ipairs(order) do
    if ENC[n] and U.exe(n) then return ENC[n] end
  end
end

--- drop stale cache files
function U.prune_disk()
  local dir = config.values.cache_dir
  local limit = os.time() - config.values.cache_days * 86400
  local h = uv.fs_scandir(dir)
  while h do
    local name, typ = uv.fs_scandir_next(h)
    if not name then break end
    if typ == "file" then
      local st = uv.fs_stat(dir .. "/" .. name)
      if st and st.mtime.sec < limit then uv.fs_unlink(dir .. "/" .. name) end
    end
  end
end

return U
