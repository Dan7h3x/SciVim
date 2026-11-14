--- Write raw escape sequences to the terminal (bypassing Neovim's grid).
local uv = vim.uv or vim.loop
local M = {}

local fd

---@param data string
function M.write(data)
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    -- tmux DCS passthrough (requires `set -g allow-passthrough on`)
    data = "\27Ptmux;" .. data:gsub("\27", "\27\27") .. "\27\\"
  end
  if vim.api.nvim_ui_send then -- 0.11+: ordered with the TUI's own output
    pcall(vim.api.nvim_ui_send, data)
    return
  end
  if fd == nil then
    fd = uv.fs_open("/dev/tty", "w", 438) or false
  end
  if fd then
    uv.fs_write(fd, data, -1)
  else
    pcall(vim.api.nvim_chan_send, vim.v.stderr, data)
  end
end

--- Offset of the current tmux pane inside the outer terminal (rows, cols), or 0,0.
---@return integer row, integer col
function M.pane_offset()
  if not (vim.env.TMUX and vim.env.TMUX ~= "") then
    return 0, 0
  end
  local ok, res = pcall(function()
    return vim.system({ "tmux", "display-message", "-p", "#{pane_top},#{pane_left}" }, { text = true }):wait()
  end)
  if ok and res.code == 0 then
    local r, c = res.stdout:match("(%d+),(%d+)")
    if r then
      return tonumber(r), tonumber(c)
    end
  end
  return 0, 0
end

return M
