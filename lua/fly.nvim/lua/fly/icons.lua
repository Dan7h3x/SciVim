--- Optional file icons via mini.icons or nvim-web-devicons (never required).
local M = { _cache = {} }

---@param path string
---@return string? icon, string? hl
function M.get(path)
  local name = vim.fs.basename(path)
  local hit = M._cache[name]
  if hit ~= nil then
    return hit[1], hit[2]
  end
  local icon, hl
  if _G.MiniIcons and _G.MiniIcons.get then
    local ok, i, h = pcall(_G.MiniIcons.get, "file", name)
    if ok then
      icon, hl = i, h
    end
  else
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      local ok2, i, h = pcall(devicons.get_icon, name, vim.fn.fnamemodify(name, ":e"), { default = true })
      if ok2 then
        icon, hl = i, h
      end
    end
  end
  M._cache[name] = { icon, hl }
  return icon, hl
end

return M
