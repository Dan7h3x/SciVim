---@type fly.Source
local M = { title = "buffer lines", ordered = true }

function M.find(ctx)
  local buf = ctx.origin.buf
  local name = vim.api.nvim_buf_get_name(buf)
  local items = {}
  local max = ctx.opts.max_lines or 100000
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, max, false)) do
    local trimmed = line:gsub("^%s+", "")
    if trimmed ~= "" then
      items[#items + 1] = {
        label = trimmed,
        line = i,
        col = #line - #trimmed + 1,
        path = name ~= "" and name or nil,
        bufnr = buf,
        from_buf = true,
        extra = tostring(i),
        kind = "line",
      }
    end
  end
  return items
end

return M
