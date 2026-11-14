-- One process per screen size (resizing a UI-less headless nvim repeatedly is unreliable):
--   FLY_COLS=120 FLY_LINES=40 nvim --headless -u NONE -l tests/layouts.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.cmd("runtime plugin/fly.lua")
local cols, lines = tonumber(vim.env.FLY_COLS or 120), tonumber(vim.env.FLY_LINES or 40)
vim.o.columns, vim.o.lines = cols, lines

local fly = require("fly")
local fail = 0
for _, name in ipairs({ "default", "ivy", "vertical", "telescope" }) do
  for _, preview in ipairs({ true, false }) do
    local p = fly.pick({ source = "files", layout = name, preview = { enabled = preview }, cwd = root })
    vim.wait(300, function() return p.filter_done end, 10)
    local wins = { p.input_win, p.list_win }
    if p.preview_win then wins[#wins + 1] = p.preview_win end
    local ok = (preview == (p.preview_win ~= nil))
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      local pos = vim.api.nvim_win_get_position(w)
      if cfg.width < 1 or cfg.height < 1 or pos[1] < 0 or pos[2] < 0
        or pos[2] + cfg.width + 2 > vim.o.columns or pos[1] + cfg.height + 2 > vim.o.lines then
        ok = false
        print(("   %s win %d: pos=%s size=%dx%d"):format(name, w, vim.inspect(pos), cfg.width, cfg.height))
      end
    end
    if not ok then fail = fail + 1 end
    p:close()
  end
end
print(("%dx%d: %s"):format(cols, lines, fail == 0 and "all layouts fit" or (fail .. " layout(s) overflow")))
vim.cmd(fail == 0 and "qa!" or "cq!")
