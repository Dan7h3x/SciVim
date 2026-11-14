local util = require("fly.util")

---@type fly.Source
local M = { title = "files", icons = true }

local function command(opts)
  local fd = vim.fn.executable("fd") == 1 and "fd" or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)
  if fd then
    local cmd = { fd, "--color=never", "--type", "f", "--exclude", ".git" }
    if opts.hidden then
      cmd[#cmd + 1] = "--hidden"
    end
    if opts.ignored then
      cmd[#cmd + 1] = "--no-ignore"
    end
    if opts.follow then
      cmd[#cmd + 1] = "--follow"
    end
    return cmd
  end
  if vim.fn.executable("rg") == 1 then
    local cmd = { "rg", "--files", "--color=never", "-g", "!.git" }
    if opts.hidden then
      cmd[#cmd + 1] = "--hidden"
    end
    if opts.ignored then
      cmd[#cmd + 1] = "--no-ignore"
    end
    if opts.follow then
      cmd[#cmd + 1] = "--follow"
    end
    return cmd
  end
  local cmd = { "find" }
  if opts.follow then
    cmd[#cmd + 1] = "-L"
  end
  vim.list_extend(cmd, { ".", "-type", "f", "-not", "-path", "*/.git/*" })
  if not opts.hidden then
    vim.list_extend(cmd, { "-not", "-path", "*/.*" })
  end
  return cmd
end

--- Stream files below `ctx.cwd`. `filter(rel)` may reject entries (used by the images source).
---@param ctx fly.Ctx
---@param push fun(items: fly.Item[])
---@param done fun()
---@param filter? fun(rel: string): boolean
function M.start(ctx, push, done, filter)
  local cwd = ctx.cwd
  return util.stream(command(ctx.opts), { cwd = cwd }, function(lines)
    local items, n = {}, 0
    for _, rel in ipairs(lines) do
      rel = rel:gsub("^%./", "")
      if rel ~= "" and (not filter or filter(rel)) then
        n = n + 1
        items[n] = { label = rel, path = vim.fs.joinpath(cwd, rel), kind = "file" }
      end
    end
    push(items)
  end, function(code, stderr)
    if code == -1 then
      util.warn("could not list files: " .. stderr)
    end
    done()
  end)
end

return M
