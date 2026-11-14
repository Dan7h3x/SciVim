local util = require("fly.util")

---@type fly.Source
local M = { title = "git log", ordered = true, defaults = { max = 2000 } }

function M.start(ctx, push, done)
  local root = util.git_root(ctx.cwd)
  if not root then
    util.warn("not inside a git repository")
    done()
    return
  end
  local cmd = { "git", "-C", root, "log", "--no-color", "-n", tostring(ctx.opts.max or 2000), "--pretty=format:%h%x09%an%x09%ar%x09%s" }
  if ctx.opts.current_file then
    local name = vim.api.nvim_buf_get_name(ctx.origin.buf)
    if name ~= "" then
      vim.list_extend(cmd, { "--", name })
    end
  end
  return util.stream(cmd, nil, function(lines)
    local items = {}
    for _, line in ipairs(lines) do
      local hash, author, date, subject = line:match("^(%x+)\t([^\t]*)\t([^\t]*)\t(.*)$")
      if hash then
        items[#items + 1] = {
          label = hash .. " " .. subject,
          hl = { { 0, #hash, "Identifier" } },
          extra = author .. ", " .. date,
          kind = "commit",
          data = { hash = hash, root = root },
        }
      end
    end
    push(items)
  end, function()
    done()
  end)
end

function M.preview(ctx, item, p)
  p.title(item.data.hash)
  util.run({ "git", "-C", item.data.root, "show", "--no-color", "--stat", "--patch", item.data.hash }, nil, function(res)
    if p.valid() then
      p.set(util.split_lines(res.stdout or "", 400), { ft = "git", number = false })
    end
  end)
end

--- Show the commit in a scratch window.
function M.confirm(item, ctx)
  local res = vim.system({ "git", "-C", item.data.root, "show", "--no-color", item.data.hash }, { text = true }):wait()
  vim.cmd(({ tab = "tabnew", vsplit = "vnew", split = "new", edit = "new" })[ctx.how or "edit"])
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(res.stdout or "", "\n", { plain = true }))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "git"
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, "git://" .. item.data.hash)
end

M.keys = { ["<C-y>"] = "yank_hash" }

M.actions = {
  yank_hash = function(p)
    local item = p:current()
    if item then
      vim.fn.setreg("+", item.data.hash)
      vim.fn.setreg('"', item.data.hash)
      util.notify("yanked " .. item.data.hash)
    end
  end,
}

return M
