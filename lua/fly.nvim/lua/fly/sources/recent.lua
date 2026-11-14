local util = require("fly.util")
local uv = vim.uv or vim.loop

---@type fly.Source
local M = { title = "recent files", icons = true, ordered = true }

function M.find(ctx)
  local items, seen = {}, {}
  local cwd_only = ctx.opts.cwd_only
  for _, p in ipairs(vim.v.oldfiles or {}) do
    local path = vim.fs.normalize(p)
    if not seen[path] and uv.fs_stat(path) then
      seen[path] = true
      if not cwd_only or path:sub(1, #ctx.cwd + 1) == ctx.cwd .. "/" then
        items[#items + 1] = { label = util.relpath(path, ctx.cwd), path = path, kind = "file" }
      end
    end
  end
  return items
end

return M
