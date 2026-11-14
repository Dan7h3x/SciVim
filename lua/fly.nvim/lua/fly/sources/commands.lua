---@type fly.Source
local M = { title = "commands", preview = false }

function M.find(ctx)
  local user = vim.api.nvim_get_commands({})
  local ok, buf_user = pcall(vim.api.nvim_buf_get_commands, ctx.origin.buf, {})
  if ok then
    user = vim.tbl_extend("force", user, buf_user)
  end
  local seen, items = {}, {}
  local function add(name)
    if seen[name] or name == "" then
      return
    end
    seen[name] = true
    local u = user[name]
    local extra
    if u then
      extra = u.desc or (type(u.definition) == "string" and u.definition ~= "" and u.definition) or nil
    end
    items[#items + 1] = {
      label = name,
      extra = extra,
      kind = "command",
      data = { nargs = u and u.nargs or nil, user = u ~= nil },
    }
  end
  for _, name in ipairs(vim.fn.getcompletion("", "command")) do
    add(name)
  end
  for name in pairs(user) do
    add(name)
  end
  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  return items
end

--- Run argument-less user commands directly, otherwise pre-fill the command line.
function M.confirm(item)
  if item.data.user and item.data.nargs == "0" then
    vim.cmd(item.label)
  else
    local keys = vim.api.nvim_replace_termcodes(":" .. item.label .. " ", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end
end

return M
