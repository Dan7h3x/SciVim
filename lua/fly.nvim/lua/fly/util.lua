local uv = vim.uv or vim.loop

local M = {}

---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "fly" })
end

function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

--- Path relative to `cwd` when inside it, otherwise `~`-shortened.
---@param path string
---@param cwd? string
function M.relpath(path, cwd)
  cwd = cwd or uv.cwd() or ""
  if cwd ~= "" and path:sub(1, #cwd + 1) == cwd .. "/" then
    return path:sub(#cwd + 2)
  end
  return vim.fn.fnamemodify(path, ":~")
end

--- Debounced function backed by a libuv timer. `close()` must be called on teardown.
---@param ms integer
---@param fn function
function M.debounce(ms, fn)
  local timer = assert(uv.new_timer())
  local d = {}
  function d.call(...)
    local args = vim.F.pack_len(...)
    timer:stop()
    timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        fn(vim.F.unpack_len(args))
      end)
    )
  end
  function d.cancel()
    timer:stop()
  end
  function d.close()
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
  end
  return d
end

--- Read at most `max_bytes` from `path`.
---@return string? data, integer? size
function M.read_file(path, max_bytes)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end
  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil
  end
  local data = uv.fs_read(fd, math.min(stat.size, max_bytes), 0)
  uv.fs_close(fd)
  return data, stat.size
end

function M.is_binary(data)
  return data:sub(1, 4096):find("\0", 1, true) ~= nil
end

--- Split text into lines, dropping the trailing empty line and CR of CRLF files.
---@param data string
---@param max_len? integer truncate lines longer than this (in characters)
function M.split_lines(data, max_len)
  local lines = vim.split(data, "\n", { plain = true })
  if lines[#lines] == "" then
    lines[#lines] = nil
  end
  for i, l in ipairs(lines) do
    if l:sub(-1) == "\r" then
      l = l:sub(1, -2)
    end
    if max_len and #l > max_len then
      l = vim.fn.strcharpart(l, 0, max_len) .. "…"
    end
    lines[i] = l
  end
  return lines
end

--- Make a string safe for nvim_buf_set_lines.
---@param s string
function M.oneline(s)
  return (s:gsub("[\r\n]", " "))
end

---@class fly.Proc
---@field kill fun()

--- Run a command and collect its output. Callback runs on the main loop.
---@param cmd string[]
---@param opts? { cwd?: string }
---@param cb fun(res: vim.SystemCompleted)
---@return fly.Proc
function M.run(cmd, opts, cb)
  opts = opts or {}
  local dead = false
  local ok, proc = pcall(vim.system, cmd, { cwd = opts.cwd, text = true }, function(res)
    vim.schedule(function()
      if not dead then
        cb(res)
      end
    end)
  end)
  if not ok then
    vim.schedule(function()
      cb({ code = -1, signal = 0, stdout = "", stderr = tostring(proc) })
    end)
    return { kill = function() end }
  end
  return {
    kill = function()
      dead = true
      pcall(proc.kill, proc, 15)
    end,
  }
end

--- Run a command and stream its stdout line by line.
--- `on_lines` / `on_exit` run on the main loop and are never called after `kill()`.
---@param cmd string[]
---@param opts? { cwd?: string }
---@param on_lines fun(lines: string[])
---@param on_exit? fun(code: integer, stderr: string)
---@return fly.Proc
function M.stream(cmd, opts, on_lines, on_exit)
  opts = opts or {}
  local dead = false
  local partial = ""
  local ok, proc = pcall(vim.system, cmd, {
    cwd = opts.cwd,
    text = true,
    stdout = function(_, data)
      if dead or not data then
        return
      end
      partial = partial .. data
      local lines, n, last = {}, 0, 1
      for line, pos in partial:gmatch("([^\n]*)\n()") do
        n = n + 1
        lines[n] = line
        last = pos
      end
      partial = partial:sub(last)
      if n > 0 then
        vim.schedule(function()
          if not dead then
            on_lines(lines)
          end
        end)
      end
    end,
  }, function(res)
    vim.schedule(function()
      if dead then
        return
      end
      if partial ~= "" then
        on_lines({ partial })
        partial = ""
      end
      if on_exit then
        on_exit(res.code, res.stderr or "")
      end
    end)
  end)
  if not ok then
    vim.schedule(function()
      if on_exit then
        on_exit(-1, tostring(proc))
      end
    end)
    return { kill = function() end }
  end
  return {
    kill = function()
      dead = true
      pcall(proc.kill, proc, 15)
    end,
  }
end

--- Absolute path of the git toplevel containing `cwd`, or nil.
---@param cwd string
function M.git_root(cwd)
  local ok, res = pcall(function()
    return vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

return M
