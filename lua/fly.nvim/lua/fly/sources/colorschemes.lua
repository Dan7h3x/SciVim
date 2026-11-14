---@type fly.Source
local M = { title = "colorschemes", preview = false }

function M.find()
  local current = vim.g.colors_name
  local items = {}
  for _, name in ipairs(vim.fn.getcompletion("", "color")) do
    items[#items + 1] = { label = name, extra = name == current and "current" or nil, kind = "colorscheme" }
  end
  return items
end

function M.confirm(item)
  local ok, err = pcall(vim.cmd.colorscheme, item.label)
  if not ok then
    require("fly.util").error(tostring(err))
  end
end

return M
