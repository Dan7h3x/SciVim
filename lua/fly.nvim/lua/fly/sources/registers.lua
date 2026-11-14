---@type fly.Source
local M = { title = "registers", preview = true, ordered = true }

function M.find()
  local items = {}
  local names = '"0123456789abcdefghijklmnopqrstuvwxyz-/.:%#'
  if vim.fn.has("clipboard") == 1 then
    names = names .. "*+" -- querying them without a provider only produces warnings
  end
  for r in names:gmatch(".") do
    local ok, v = pcall(vim.fn.getreg, r)
    if ok and v ~= "" then
      items[#items + 1] = {
        label = ("%s  %s"):format(r, (v:gsub("[\r\n]+", "⏎"):sub(1, 200))),
        text = v,
        kind = "register",
        data = { reg = r },
      }
    end
  end
  return items
end

--- Paste the register at the cursor of the origin window.
function M.confirm(item)
  vim.api.nvim_paste(vim.fn.getreg(item.data.reg), false, -1)
end

return M
