local util = require("fly.util")

---@type fly.Source
local M = { title = "keymaps", preview = false }

function M.find(ctx)
  local items, seen = {}, {}
  local function add(maps, scope)
    for _, m in ipairs(maps) do
      local key = m.mode .. "\0" .. m.lhs .. "\0" .. (m.buffer or 0)
      if not seen[key] and not m.lhs:find("^<Plug>") then
        seen[key] = true
        local rhs = m.desc or m.rhs or (m.callback and "<lua function>") or ""
        items[#items + 1] = {
          label = ("%s  %s  %s"):format(m.mode, m.lhs, util.oneline(rhs)), -- searchable by description too
          hl = { { #m.mode + 2 + #m.lhs + 2, #m.mode + 2 + #m.lhs + 2 + #util.oneline(rhs), "FlyExtra" } },
          extra = scope == "buf" and "[buffer]" or nil,
          kind = "keymap",
          data = m,
        }
      end
    end
  end
  for _, mode in ipairs({ "n", "i", "v", "x", "o", "t", "c" }) do
    add(vim.api.nvim_buf_get_keymap(ctx.origin.buf, mode), "buf")
    add(vim.api.nvim_get_keymap(mode), "global")
  end
  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  return items
end

--- Jump to the definition when it is a Lua mapping with a known location.
function M.confirm(item)
  local m = item.data
  if m.callback then
    local info = debug.getinfo(m.callback, "S")
    if info and info.source:sub(1, 1) == "@" then
      require("fly.picker").jump({ path = info.source:sub(2), line = info.linedefined })
      return
    end
  end
  require("fly.util").notify(("%s → %s"):format(m.lhs, m.rhs or m.desc or "<callback>"))
end

return M
