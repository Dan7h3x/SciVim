local M = {}

local function env(name)
  local v = vim.env[name]
  return v ~= nil and v ~= ""
end

--- Terminals speaking the Kitty graphics protocol (Kitty, Ghostty). Override with FLY_KITTY=true|false.
function M.kitty()
  if env("FLY_KITTY") then
    return vim.env.FLY_KITTY == "true"
  end
  if env("KITTY_WINDOW_ID") or env("GHOSTTY_RESOURCES_DIR") then
    return true
  end
  local term = (vim.env.TERM or ""):lower()
  local prog = (vim.env.TERM_PROGRAM or ""):lower()
  return term:find("kitty", 1, true) ~= nil or term:find("ghostty", 1, true) ~= nil or prog == "ghostty"
end

--- ueberzug(pp) available. Override with FLY_UEBERZUG=true|false.
function M.ueberzug()
  if env("FLY_UEBERZUG") then
    return vim.env.FLY_UEBERZUG == "true"
  end
  return vim.fn.executable("ueberzugpp") == 1 or vim.fn.executable("ueberzug") == 1
end

---@return "kitty"|"ueberzug"|"none"
function M.preferred()
  if M.kitty() then
    return "kitty"
  end
  if M.ueberzug() then
    return "ueberzug"
  end
  return "none"
end

--- First available ImageMagick-compatible converter.
---@return string[]? cmd prefix
function M.converter()
  if vim.fn.executable("magick") == 1 then
    return { "magick" }
  end
  if vim.fn.executable("convert") == 1 then
    return { "convert" }
  end
end

return M
