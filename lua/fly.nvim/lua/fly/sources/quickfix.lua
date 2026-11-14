local util = require("fly.util")

---@type fly.Source
local M = { title = "quickfix", icons = true, ordered = true }

--- opts.loclist = true uses the location list of the origin window.
function M.find(ctx)
  local list = ctx.opts.loclist and vim.fn.getloclist(ctx.origin.win) or vim.fn.getqflist()
  local items = {}
  for _, e in ipairs(list) do
    if e.valid == 1 then
      local path = e.bufnr > 0 and vim.api.nvim_buf_get_name(e.bufnr) or ""
      items[#items + 1] = {
        label = ("%s:%d  %s"):format(path ~= "" and util.relpath(path, ctx.cwd) or "[No Name]", e.lnum, util.oneline(vim.trim(e.text))),
        path = path ~= "" and path or nil,
        bufnr = e.bufnr,
        line = e.lnum,
        col = e.col > 0 and e.col or 1,
        text = e.text,
        kind = "quickfix",
      }
    end
  end
  return items
end

return M
