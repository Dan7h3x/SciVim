---@type fly.Source
local M = { title = "marks", ordered = true }

function M.find(ctx)
  local items = {}
  local function add(list, global)
    for _, m in ipairs(list) do
      local name = m.mark:sub(2)
      if name:match("^%a$") then
        local pos = m.pos
        local path = global and m.file and vim.fs.normalize(vim.fn.fnamemodify(m.file, ":p")) or nil
        local bufnr = global and pos[1] > 0 and pos[1] or ctx.origin.buf
        path = path or vim.api.nvim_buf_get_name(bufnr)
        local text = ""
        if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
          text = (vim.api.nvim_buf_get_lines(bufnr, pos[2] - 1, pos[2], false)[1] or ""):gsub("^%s+", "")
        end
        items[#items + 1] = {
          label = ("%s  %s"):format(name, text ~= "" and text or path),
          extra = require("fly.util").relpath(path, ctx.cwd) .. ":" .. pos[2],
          path = path ~= "" and path or nil,
          line = pos[2],
          col = pos[3] + 1,
          kind = "mark",
        }
      end
    end
  end
  add(vim.fn.getmarklist(ctx.origin.buf), false)
  add(vim.fn.getmarklist(), true)
  return items
end

return M
