local util = require("fly.util")

---@type fly.Source
local M = { title = "help" }

function M.find()
  local items, seen = {}, {}
  for _, tagfile in ipairs(vim.api.nvim_get_runtime_file("doc/tags", true)) do
    local dir = vim.fs.dirname(tagfile)
    local ok, lines = pcall(vim.fn.readfile, tagfile)
    for _, line in ipairs(ok and lines or {}) do
      local tag, file = line:match("^([^\t]+)\t([^\t]+)\t")
      if tag and not tag:find("^!_TAG") and not seen[tag] then
        seen[tag] = true
        items[#items + 1] = {
          label = tag,
          path = vim.fs.joinpath(dir, file),
          pattern = "*" .. tag .. "*",
          ft = "help",
          extra = file,
          kind = "help",
          data = { tag = tag },
        }
      end
    end
  end
  return items
end

function M.confirm(item, ctx)
  local tag = item.data.tag
  local how = ctx.how or "edit"
  if how == "tab" then
    vim.cmd("tab help " .. vim.fn.escape(tag, "|\" \\"))
  else
    vim.cmd({ cmd = "help", args = { tag }, mods = { vertical = how == "vsplit" } })
  end
end

return M
