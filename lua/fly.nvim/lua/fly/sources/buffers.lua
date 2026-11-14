local util = require("fly.util")

---@type fly.Source
local M = { title = "buffers", icons = true, ordered = true }

function M.find(ctx)
  local infos = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(infos, function(a, b)
    return a.lastused > b.lastused
  end)
  local cur = ctx.origin.buf
  local alt = vim.fn.bufnr("#", false)
  local items, current = {}, nil
  for _, b in ipairs(infos) do
    local name = b.name
    local flags = {}
    if b.bufnr == cur then
      flags[#flags + 1] = "%"
    elseif b.bufnr == alt then
      flags[#flags + 1] = "#"
    end
    if b.changed == 1 then
      flags[#flags + 1] = "+"
    end
    local item = {
      label = name ~= "" and util.relpath(name, ctx.cwd) or ("[No Name] " .. b.bufnr),
      path = name ~= "" and name or nil,
      bufnr = b.bufnr,
      kind = "buffer",
      extra = #flags > 0 and table.concat(flags, "") or nil,
    }
    if b.bufnr == cur then
      current = item -- keep the current buffer last: the top entry is the one to switch to
    else
      items[#items + 1] = item
    end
  end
  if current then
    items[#items + 1] = current
  end
  return items
end

M.keys = { ["<C-x>"] = "bufdelete" }

M.actions = {
  --- Delete the selected (or current) buffers.
  bufdelete = function(p)
    local targets = p:selected_items()
    if #targets == 0 and p:current() then
      targets = { p:current() }
    end
    for _, item in ipairs(targets) do
      local ok, err = pcall(vim.api.nvim_buf_delete, item.bufnr, {})
      if not ok then
        util.warn(tostring(err))
      end
    end
    p:run_source()
  end,
}

return M
