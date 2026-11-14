local util = require("fly.util")

---@type fly.Source
local M = { title = "jumplist", icons = true, ordered = true }

function M.find(ctx)
  local jumps = vim.fn.getjumplist(ctx.origin.win)[1]
  local items, seen = {}, {}
  for i = #jumps, 1, -1 do
    local j = jumps[i]
    local name = vim.api.nvim_buf_is_valid(j.bufnr) and vim.api.nvim_buf_get_name(j.bufnr) or ""
    local key = j.bufnr .. ":" .. j.lnum
    if name ~= "" and not seen[key] then
      seen[key] = true
      local text = ""
      if vim.api.nvim_buf_is_loaded(j.bufnr) then
        text = (vim.api.nvim_buf_get_lines(j.bufnr, j.lnum - 1, j.lnum, false)[1] or ""):gsub("^%s+", "")
      end
      items[#items + 1] = {
        label = ("%s:%d  %s"):format(util.relpath(name, ctx.cwd), j.lnum, util.oneline(text)),
        path = name,
        line = j.lnum,
        col = j.col + 1,
        kind = "jump",
      }
    end
  end
  return items
end

return M
