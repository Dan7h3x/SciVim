--- Async task runner with two kinds of cached artefacts:
---   master : vector SVG (or PNG fallback) compiled from LaTeX / Typst
---   raster : exact-pixel PNG canvas rasterised from a master for one cell layout
--- A task is { hash, ext, steps = function(dir, meta) -> steps, cleanup } or
--- { hash, direct = path } for ready-made PNG files.
local config = require("mip.config")
local util = require("mip.util")
local uv = vim.uv or vim.loop
local fn = vim.fn

local R = { cache = {}, waiting = {}, queue = {}, running = 0, on_ready = function() end }

local function final_path(task)
  return config.values.cache_dir .. "/" .. task.hash .. "." .. task.ext
end

local function load_entry(task, path)
  local meta = {}
  local raw = util.read_file(config.values.cache_dir .. "/" .. task.hash .. ".json")
  if raw then
    local ok, d = pcall(vim.json.decode, raw)
    if ok and type(d) == "table" then meta = d end
  end
  if task.ext == "svg" then
    local f = io.open(path, "rb")
    if not f then return end
    local head = f:read(4096) or ""
    f:close()
    local w, h = util.svg_dims(head)
    if not w then return end
    return { ok = true, kind = "svg", path = path, w = w, h = h, base = meta.base, hash = task.hash, key = task.hash }
  end
  if task.ext == "six" then
    local st = uv.fs_stat(path)
    if not st or st.size == 0 then return end
    return { ok = true, kind = "six", path = path, hash = task.hash, key = task.hash }
  end
  local w, h = util.png_size(path)
  if not w then return end
  return { ok = true, kind = "png", path = path, w = w, h = h, base = meta.base, hash = task.hash, key = task.hash }
end

local function run_steps(steps, i, done)
  local s = steps[i]
  if not s then return done(true) end
  local ok, err = pcall(vim.system, s.cmd, { cwd = s.cwd, env = s.env, text = not s.binary, timeout = 30000 },
    function(res)
      local out = s.binary and (res.stderr or "") or ((res.stdout or "") .. "\n" .. (res.stderr or ""))
      if res.code ~= 0 then
        local msg = out:match("(![^\n]+)") or out:match("([Ee]rror[^\n]+)") or vim.trim(out):sub(1, 300)
        return done(false, s.cmd[1] .. ": " .. msg)
      end
      if s.stdout then util.write_file(s.cwd .. "/" .. s.stdout, res.stdout or "") end
      if s.capture then s.capture(out) end
      run_steps(steps, i + 1, done)
    end)
  if not ok then done(false, tostring(err)) end
end

local function run(task, done)
  local dir = config.values.cache_dir .. "/work/" .. task.hash:sub(1, 16)
  fn.mkdir(dir, "p")
  local meta = {}
  local steps, cleanup = task.steps(dir, meta)
  run_steps(steps, 1, function(ok, err)
    vim.schedule(function()
      if ok and not uv.fs_rename(dir .. "/out." .. task.ext, final_path(task)) then
        ok, err = false, "renderer produced no output"
      end
      if ok and next(meta) then
        util.write_file(config.values.cache_dir .. "/" .. task.hash .. ".json", vim.json.encode(meta))
      end
      fn.delete(dir, "rf")
      if cleanup then cleanup() end
      done(ok, err)
    end)
  end)
end

function R.pump()
  while R.running < config.values.concurrency and #R.queue > 0 do
    local task = table.remove(R.queue, 1)
    R.running = R.running + 1
    run(task, function(ok, err)
      R.running = R.running - 1
      local entry = ok and load_entry(task, final_path(task)) or nil
      if not entry then
        entry = { ok = false, err = err or "render failed" }
        util.log(entry.err)
      end
      R.cache[task.hash] = entry
      local waiters = R.waiting[task.hash] or {}
      R.waiting[task.hash] = nil
      for S in pairs(waiters) do R.on_ready(S) end
      R.pump()
    end)
  end
end

--- Cached entry, or nil while it renders (S is re-scheduled when ready).
function R.ensure(task, S)
  if task.direct then
    local c = R.cache[task.hash]
    if not c then
      local w, h = util.png_size(task.direct)
      c = w and { ok = true, kind = "png", path = task.direct, w = w, h = h, hash = task.hash, key = task.hash }
          or { ok = false, err = "not a valid png: " .. task.direct }
      R.cache[task.hash] = c
    end
    return c
  end
  local c = R.cache[task.hash]
  if c and (not c.ok or uv.fs_stat(c.path)) then return c end
  local path = final_path(task)
  if uv.fs_stat(path) then
    local e = load_entry(task, path)
    if e then
      R.cache[task.hash] = e
      return e
    end
  end
  if R.waiting[task.hash] then
    R.waiting[task.hash][S] = true
    return nil
  end
  R.waiting[task.hash] = { [S] = true }
  table.insert(R.queue, task)
  R.pump()
  return nil
end

function R.reset()
  R.cache = {}
end

return R
