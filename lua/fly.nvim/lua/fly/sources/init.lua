--- Source registry. A source is a table (see `fly.Source` in picker.lua); built-ins live in this directory.
local M = { _registry = {} }

local builtin = {
  "files", "recent", "buffers", "grep", "lines", "git", "git_files", "git_log", "help",
  "commands", "symbols", "workspace_symbols", "diagnostics", "images", "colorschemes",
  "keymaps", "marks", "registers", "quickfix", "jumps",
}

---@param name string
---@param source fly.Source
function M.register(name, source)
  M._registry[name] = source
end

---@return string[]
function M.names()
  local names = vim.deepcopy(builtin)
  for name in pairs(M._registry) do
    if not vim.tbl_contains(names, name) then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

--- Resolve a source by name or pass a source table straight through.
---@param spec string|fly.Source
---@return fly.Source?, string name
function M.get(spec)
  if type(spec) == "table" then
    return spec, spec.title or "custom"
  end
  local name = spec or "files"
  if M._registry[name] then
    return M._registry[name], name
  end
  if vim.tbl_contains(builtin, name) then
    local ok, mod = pcall(require, "fly.sources." .. name)
    if ok then
      return mod, name
    end
    require("fly.util").error(("failed to load source '%s': %s"):format(name, mod))
    return nil, name
  end
  require("fly.util").warn(("unknown source '%s' (available: %s)"):format(name, table.concat(M.names(), ", ")))
  return nil, name
end

return M
