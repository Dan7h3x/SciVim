local util = require("fly.util")

---@type fly.Source
local M = { title = "git status", icons = true, ordered = true }

local names = { M = "modified", A = "added", D = "deleted", R = "renamed", C = "copied", U = "unmerged", ["?"] = "untracked" }

function M.start(ctx, push, done)
  local root = util.git_root(ctx.cwd)
  if not root then
    util.warn("not inside a git repository")
    done()
    return
  end
  return util.run({ "git", "-C", root, "status", "--porcelain=v1", "-z", "--untracked-files=all" }, nil, function(res)
    local parts = vim.split(res.stdout or "", "\0", { plain = true })
    local items = {}
    local i = 1
    while i <= #parts do
      local entry = parts[i]
      if #entry >= 4 then
        local x, y, path = entry:sub(1, 1), entry:sub(2, 2), entry:sub(4)
        if x == "R" or x == "C" then
          i = i + 1 -- porcelain -z lists the original path next
        end
        local extra
        if x == "?" then
          extra = { { " ?", "DiagnosticHint" } }
        else
          extra = {
            { " " .. (x ~= " " and x or "·"), "DiagnosticOk" }, -- staged
            { " " .. (y ~= " " and y or "·"), "DiagnosticWarn" }, -- unstaged
          }
        end
        items[#items + 1] = {
          label = path,
          path = vim.fs.joinpath(root, path),
          extra = extra,
          kind = "git",
          data = { x = x, y = y, root = root, rel = path, status = names[y] or names[x] or "changed" },
        }
      end
      i = i + 1
    end
    push(items)
    done()
  end)
end

---@param ctx fly.Ctx
---@param item fly.Item
---@param p fly.PreviewHandle
function M.preview(ctx, item, p)
  local d = item.data
  if d.x == "?" then
    return false -- untracked: show the file itself
  end
  local function show(res, fallback)
    if not p.valid() then
      return
    end
    if res.code ~= 0 and fallback then
      return util.run(fallback, nil, function(r)
        show(r)
      end)
    end
    local out = res.stdout or ""
    if out == "" then
      return p.message("no diff")
    end
    p.set(util.split_lines(out, 400), { ft = "diff", number = false })
  end
  util.run({ "git", "-C", d.root, "diff", "HEAD", "--no-color", "--", d.rel }, nil, function(res)
    show(res, { "git", "-C", d.root, "diff", "--cached", "--no-color", "--", d.rel }) -- repo without commits
  end)
end

M.keys = { ["<M-s>"] = "stage" }

M.actions = {
  --- Stage unstaged/untracked files, unstage staged-only ones.
  stage = function(p)
    local targets = p:selected_items()
    if #targets == 0 and p:current() then
      targets = { p:current() }
    end
    for _, item in ipairs(targets) do
      local d = item.data
      local cmd
      if d.y ~= " " then
        cmd = { "git", "-C", d.root, "add", "--", d.rel }
      else
        cmd = { "git", "-C", d.root, "restore", "--staged", "--", d.rel }
      end
      local res = vim.system(cmd, { text = true }):wait()
      if res.code ~= 0 then
        util.warn(vim.trim(res.stderr or "git failed"))
      end
    end
    local cursor = p.cursor
    p:run_source()
    p.cursor = cursor
  end,
}

return M
