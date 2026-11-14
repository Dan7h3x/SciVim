local M = {}

local api = vim.api

---@param name string
---@param ft string
---@return integer
function M.scratch(name, ft)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = ft
  vim.b[buf].completion = false -- blink.cmp
  vim.b[buf].minicompletion_disable = true
  vim.b[buf].miniindentscope_disable = true
  pcall(api.nvim_buf_set_name, buf, ("fly://%s/%d"):format(name, buf))
  return buf
end

---@param border any
function M.has_border(border)
  return border ~= nil and border ~= "none" and border ~= ""
end

--- Resolve the configured border: explicit > 'winborder' > "rounded".
---@param configured any
function M.border(configured)
  if configured ~= nil then
    return configured
  end
  local ok, wb = pcall(function()
    return vim.o.winborder
  end)
  if ok and wb ~= nil and wb ~= "" then
    return wb
  end
  return "rounded"
end

---@param buf integer
---@param cfg table  nvim_open_win config (without relative/style)
---@param enter boolean
---@param wo? table window-local options
---@return integer
function M.open(buf, cfg, enter, wo)
  local full = vim.tbl_extend("force", {
    relative = "editor",
    style = "minimal",
    noautocmd = true,
  }, cfg)
  if not M.has_border(full.border) then
    full.title, full.title_pos, full.footer, full.footer_pos = nil, nil, nil, nil
  end
  local win = api.nvim_open_win(buf, enter, full)
  for k, v in pairs(wo or {}) do
    api.nvim_set_option_value(k, v, { win = win })
  end
  return win
end

function M.valid(win)
  return win ~= nil and api.nvim_win_is_valid(win)
end

function M.close(win)
  if M.valid(win) then
    pcall(api.nvim_win_close, win, true)
  end
end

--- Screen geometry of the *content* area of a window (0-based row/col).
function M.geometry(win)
  local pos = vim.fn.win_screenpos(win)
  return {
    row = pos[1] - 1,
    col = pos[2] - 1,
    width = api.nvim_win_get_width(win),
    height = api.nvim_win_get_height(win),
  }
end

return M
