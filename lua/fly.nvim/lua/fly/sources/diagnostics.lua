local util = require("fly.util")

---@type fly.Source
local M = { title = "diagnostics", ordered = true }

local sev = {
  [vim.diagnostic.severity.ERROR] = { "Error", "DiagnosticError" },
  [vim.diagnostic.severity.WARN] = { "Warn", "DiagnosticWarn" },
  [vim.diagnostic.severity.INFO] = { "Info", "DiagnosticInfo" },
  [vim.diagnostic.severity.HINT] = { "Hint", "DiagnosticHint" },
}

--- opts.buffer = true limits to the buffer the picker was opened from.
function M.find(ctx)
  local diags = vim.diagnostic.get(ctx.opts.buffer and ctx.origin.buf or nil)
  table.sort(diags, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    if a.bufnr ~= b.bufnr then
      return a.bufnr < b.bufnr
    end
    return a.lnum < b.lnum
  end)
  local items = {}
  for _, d in ipairs(diags) do
    local name = vim.api.nvim_buf_get_name(d.bufnr)
    local s = sev[d.severity] or sev[vim.diagnostic.severity.INFO]
    local where = (name ~= "" and util.relpath(name, ctx.cwd) or "[No Name]") .. ":" .. (d.lnum + 1)
    items[#items + 1] = {
      label = util.oneline((d.message:gsub("\n.*", ""))),
      extra = { { s[1] .. " ", s[2] }, { where, "FlyExtra" } },
      path = name ~= "" and name or nil,
      bufnr = d.bufnr,
      from_buf = name == "",
      line = d.lnum + 1,
      col = d.col + 1,
      end_col = (d.end_lnum == d.lnum and d.end_col) and (d.end_col + 1) or nil,
      kind = "diagnostic",
    }
  end
  return items
end

return M
