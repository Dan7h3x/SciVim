local util = require("fly.util")

---@type fly.Source
local M = { title = "git files", icons = true }

function M.start(ctx, push, done)
  if not util.git_root(ctx.cwd) then
    util.warn("not inside a git repository")
    done()
    return
  end
  local cwd = ctx.cwd
  return util.stream({ "git", "ls-files", "--cached", "--others", "--exclude-standard" }, { cwd = cwd }, function(lines)
    local items = {}
    for _, rel in ipairs(lines) do
      if rel ~= "" then
        items[#items + 1] = { label = rel, path = vim.fs.joinpath(cwd, rel), kind = "file" }
      end
    end
    push(items)
  end, function()
    done()
  end)
end

return M
