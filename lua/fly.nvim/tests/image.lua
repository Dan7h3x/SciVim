-- nvim --headless -u NONE -l tests/image.lua   (needs ImageMagick `convert`/`magick` to build fixtures)
io.stdout:setvbuf("no")
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.cmd("runtime plugin/fly.lua")
local pass, fail = 0, 0
local function check(name, cond, extra)
  if cond then pass = pass + 1; print("  ok    " .. name) else fail = fail + 1; print("  FAIL  " .. name .. (extra and ("  -> " .. tostring(extra)) or "")) end
end

local dir = vim.fn.tempname(); vim.fn.mkdir(dir, "p")
local conv = vim.fn.executable("magick") == 1 and "magick" or "convert"
vim.fn.system({ conv, "-size", "400x200", "xc:red", dir .. "/wide.png" })
vim.fn.system({ conv, "-size", "100x300", "xc:blue", dir .. "/tall.jpg" })
vim.cmd("cd " .. dir)

-- capture terminal output
local sent = {}
vim.api.nvim_ui_send = function(s) sent[#sent + 1] = s end
vim.env.TMUX = nil

local fly = require("fly")
local image = require("fly.image")
fly.setup({ image = { backend = "kitty", cell_ratio = 0.5 } })
check("backend resolved to kitty", image.name() == "kitty")
check("is_image", image.is_image("a/b.PNG") and image.is_image("x.webp") and not image.is_image("x.lua"))

local p = fly.images({ preview = { enabled = true } })
vim.wait(500, function() return p.filter_done and #p.results == 2 end, 10)
check("images source lists only images", #p.results == 2)
local function find(label) for i, r in ipairs(p.results) do if r.label == label then return i end end end

p:set_cursor(find("wide.png"))
vim.wait(500, function() return #sent > 0 end, 10)
local seq = table.concat(sent)
check("kitty: transmit+display APC sequence", seq:find("a=T", 1, true) ~= nil and seq:find("\27_G", 1, true) ~= nil, vim.inspect(seq:sub(1, 120)))
local payload = seq:match(";([%w+/=]+)\27\\")
check("kitty: payload is base64(path)", payload and vim.base64.decode(payload):find("wide.png", 1, true) ~= nil, payload)
check("kitty: cursor positioned before drawing", seq:find("\27%[%d+;%d+H") ~= nil)
check("kitty: cursor saved/restored", seq:find("\0277", 1, true) ~= nil and seq:find("\0278", 1, true) ~= nil)
check("kitty: no stray cursor-follow (C=1)", seq:find("C=1", 1, true) ~= nil)
local c, r = seq:match("c=(%d+)"), seq:match("r=(%d+)")
local geo = require("fly.win").geometry(p.preview_win)
c, r = tonumber(c), tonumber(r)
check(("aspect kept 2:1 (cols=%s rows=%s, cell ratio .5)"):format(c, r), c and r and math.abs(c * 0.5 / r - 2) < 0.3, c and r and (c * 0.5 / r))
check("fits preview window", c <= geo.width and r <= geo.height)

sent = {}
p:set_cursor(find("tall.jpg"))
vim.wait(3000, function() return #table.concat(sent) > 0 and table.concat(sent):find("a=T", 1, true) end, 20)
seq = table.concat(sent)
local pl = seq:match(";([%w+/=]+)\27\\")
local sent_path = pl and vim.base64.decode(pl)
check("jpg converted to cached png for kitty", sent_path and sent_path:match("%.png$") and sent_path:find("fly/img", 1, true) ~= nil, sent_path)
local c2, r2 = tonumber(seq:match("c=(%d+)")), tonumber(seq:match("r=(%d+)"))
check("tall image: height-limited, narrower than wide", c2 and c2 < c and r2 == geo.height, vim.inspect({ c2, r2, geo.height }))
check("previous image replaced (delete before place)", seq:find("a=d", 1, true) ~= nil)

sent = {}
p:close()
check("close deletes image from terminal", table.concat(sent):find("a=d,d=I", 1, true) ~= nil, vim.inspect(sent))

-- tmux passthrough wrapping
vim.env.TMUX = "/tmp/tmux-1/default,1,0"
package.loaded["fly.image.tty"].pane_offset = function() return 3, 5 end
sent = {}
require("fly.image.kitty").show({ row = 2, col = 4, width = 20, height = 10 }, "/x.png")
local w = table.concat(sent)
check("tmux: DCS passthrough with doubled ESC", w:sub(1, 7) == "\27Ptmux;" and w:find("\27\27_G", 1, true) ~= nil)
check("tmux: pane offset added to cursor position", w:find("\27\27%[6;10H") ~= nil, vim.inspect(w:sub(1, 60)))
vim.env.TMUX = nil

-- ueberzug JSON IPC through a fake binary
local log = dir .. "/ueberzug.log"
local fake = dir .. "/fakeueberzug"
vim.fn.writefile({ "#!/bin/sh", "cat >> " .. log }, fake)
vim.uv.fs_chmod(fake, 493)
fly.setup({ image = { backend = "ueberzug", ueberzug = { bin = fake } } })
check("backend resolved to ueberzug", image.name() == "ueberzug")
p = fly.images()
vim.wait(500, function() return p.filter_done and #p.results == 2 end, 10)
p:set_cursor(find("wide.png"))
vim.wait(1000, function() return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) > 0 end, 20)
local jl = vim.fn.filereadable(log) == 1 and vim.fn.readfile(log) or {}
local ok, msg = pcall(vim.json.decode, jl[1] or "")
check("ueberzug: valid JSON add action", ok and msg.action == "add" and msg.path:find("wide.png", 1, true) ~= nil, vim.inspect(jl))
check("ueberzug: geometry from preview window", ok and msg.max_width > 0 and msg.max_height > 0 and msg.x >= 0 and msg.y >= 0)
p:close()
vim.wait(300, function() return #vim.fn.readfile(log) >= 2 end, 20)
local last = vim.fn.readfile(log)
local ok2, rm = pcall(vim.json.decode, last[#last] or "")
check("ueberzug: remove on close", ok2 and rm.action == "remove", vim.inspect(last))

-- no backend
fly.setup({ image = { backend = "none" } })
p = fly.images()
vim.wait(500, function() return p.filter_done end, 10)
p:set_cursor(1)
vim.wait(100)
local txt = table.concat(vim.api.nvim_buf_get_lines(p.preview_buf, 0, -1, false), "\n")
check("no backend: explanatory message", txt:find("no image backend", 1, true) ~= nil, txt)
p:close()

print(("\n%d passed, %d failed"):format(pass, fail))
vim.cmd(fail == 0 and "qa!" or "cq!")
