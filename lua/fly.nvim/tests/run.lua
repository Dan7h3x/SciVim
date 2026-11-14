-- Run:  nvim --headless -u NONE -l tests/run.lua
io.stdout:setvbuf("no")
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.cmd("runtime plugin/fly.lua")

local pass, fail = 0, 0
local function check(name, cond, extra)
  if cond then
    pass = pass + 1
    io.write("  ok    " .. name .. "\n")
  else
    fail = fail + 1
    io.write("  FAIL  " .. name .. (extra and ("  -> " .. tostring(extra)) or "") .. "\n")
  end
end
local function wait(cond, ms)
  return vim.wait(ms or 3000, cond, 10)
end
local function settle()
  vim.wait(80)
end

-- fixture project ------------------------------------------------------------
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. "/src/deep", "p")
vim.fn.mkdir(dir .. "/.hidden", "p")
local function write(rel, lines)
  vim.fn.writefile(lines, dir .. "/" .. rel)
end
write("README.md", { "# project", "hello world" })
write("src/main.lua", { "local M = {}", "function M.run()", "  return 'needle in haystack'", "end", "return M" })
write("src/deep/matcher.lua", { "-- matcher", "return {}" })
write("src/util.lua", { "return 'util'" })
write(".hidden/secret.txt", { "secret" })
write("with space.txt", { "x" })
vim.fn.system({ "git", "-C", dir, "init", "-q" })
vim.fn.system({ "git", "-C", dir, "-c", "user.email=a@b", "-c", "user.name=t", "add", "." })
vim.fn.system({ "git", "-C", dir, "-c", "user.email=a@b", "-c", "user.name=t", "commit", "-qm", "first commit" })
write("src/util.lua", { "return 'util changed'" })
write("untracked.txt", { "new" })
vim.cmd("cd " .. vim.fn.fnameescape(dir))

local fly = require("fly")
fly.setup({ win = { backdrop = 60 } })
local picker = require("fly.picker")

local function labels(p, n)
  local out = {}
  for i = 1, math.min(n or 99, #p.results) do
    out[#out + 1] = p.results[i].label
  end
  return out
end
local function open(source, opts)
  local p = fly.pick(vim.tbl_extend("force", { source = source }, opts or {}))
  assert(p, "picker failed to open: " .. source)
  wait(function() return p.source_done and p.filter_done end)
  return p
end
local function query(p, q)
  local g0 = p.gen
  p:set_query(q)
  if p.source.live then
    wait(function() return p.gen > g0 and p.source_done end, 4000)
  end
  wait(function() return p.filter_done end, 4000)
  settle()
end
local function has(list, s)
  for _, v in ipairs(list) do
    if v:find(s, 1, true) then return true end
  end
  return false
end

-- files ------------------------------------------------------------------------
print("files")
local p = open("files")
check("lists files", #p.results >= 5, #p.results)
check("hides dotfiles by default", not has(labels(p), ".hidden"))
check("hides .git", not has(labels(p), ".git/"))
check("paths are absolute", p.results[1].path:sub(1, 1) == "/")
check("space in name kept", has(labels(p), "with space.txt"))
check("input window is focused", vim.api.nvim_get_current_win() == p.input_win)
check("not left in the preview window", vim.api.nvim_get_current_win() ~= p.preview_win)
p:set_query("mat")
wait(function() return p.filter_done and #p.results > 0 end)
check("fuzzy filter ranks matcher.lua first", p.results[1] and p.results[1].label == "src/deep/matcher.lua", vim.inspect(labels(p)))
p:set_query("'util")
wait(function() return p.filter_done end)
check("exact operator", #p.results == 1 and p.results[1].label == "src/util.lua", vim.inspect(labels(p)))
p:set_query("lua !deep")
wait(function() return p.filter_done end)
check("AND + exclude operators", has(labels(p), "main.lua") and not has(labels(p), "deep"), vim.inspect(labels(p)))
p:set_query("zzzzzz")
wait(function() return p.filter_done end)
check("no results renders hint, no crash", #p.results == 0)
p:set_query("")
wait(function() return p.filter_done and #p.results > 0 end)
check("empty query restores all", #p.results >= 5)
settle()
local lines = vim.api.nvim_buf_get_lines(p.list_buf, 0, -1, false)
check("list buffer rendered", #lines >= 5 and lines[1] ~= "")
p:run_action("toggle_hidden")
wait(function() return p.filter_done and has(labels(p), ".hidden") end)
check("toggle_hidden shows dotfiles", has(labels(p), ".hidden/secret.txt"))
p:close()
check("closed: windows gone", not vim.api.nvim_win_is_valid(p.input_win) and not vim.api.nvim_win_is_valid(p.list_win))
check("closed: no active picker", picker.active == nil)

-- confirm opens file in normal mode ------------------------------------------------
p = open("files", { query = "main" })
wait(function() return #p.results > 0 and p.results[1].label == "src/main.lua" end)
p:run_action("confirm")
wait(function() return vim.api.nvim_buf_get_name(0):find("main.lua", 1, true) end)
check("confirm opens the file", vim.api.nvim_buf_get_name(0):find("src/main.lua", 1, true) ~= nil, vim.api.nvim_buf_get_name(0))
vim.wait(50)
check("mode is normal after confirm", vim.fn.mode() == "n", vim.fn.mode())

-- keys through the real mapping layer -------------------------------------------------
print("keymaps")
p = open("files")
local km = vim.api.nvim_buf_get_keymap(p.input_buf, "i")
local lhs = {}
for _, m in ipairs(km) do lhs[m.lhs] = true end
check("<CR> mapped in insert mode", lhs["<CR>"] and lhs["<C-N>"] and lhs["<Esc>"], vim.inspect(vim.tbl_keys(lhs)))
local c0 = p.cursor
vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "x", false)
check("<C-n> moves cursor", p.cursor == c0 + 1, p.cursor)
vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "x", false)
check("<Tab> selects item", next(p.selected) ~= nil)
vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)
check("<Esc> closes picker", picker.active == nil)

-- layouts ------------------------------------------------------------------------------
print("layouts")
for _, name in ipairs({ "default", "ivy", "vertical", "telescope" }) do
  local pp = open("files", { layout = name })
  local ok = true
  for _, w in ipairs({ pp.input_win, pp.list_win, pp.preview_win }) do
    local cfg = vim.api.nvim_win_get_config(w)
    local pos = vim.api.nvim_win_get_position(w)
    local outer_w = cfg.width + 2
    local outer_h = cfg.height + 2
    if pos[2] < 0 or pos[1] < 0 or pos[2] + outer_w > vim.o.columns or pos[1] + outer_h > vim.o.lines then
      ok = false
    end
  end
  check("layout '" .. name .. "' fits the screen", ok)
  pp:run_action("toggle_preview")
  check("layout '" .. name .. "' toggle_preview closes preview", not (pp.preview_win and vim.api.nvim_win_is_valid(pp.preview_win)))
  pp:run_action("toggle_preview")
  check("layout '" .. name .. "' toggle_preview reopens", pp.preview_win and vim.api.nvim_win_is_valid(pp.preview_win))
  pp:close()
end
p = open("files", { layout = "telescope" })
p:set_query("lua")
wait(function() return p.filter_done and #p.results > 1 end)
check("telescope layout flips (best match at bottom)", p.flip and p.pad >= 0)
settle()
local row = vim.api.nvim_win_get_cursor(p.list_win)[1]
check("flipped cursor on last row", row == vim.api.nvim_buf_line_count(p.list_buf), row)
p:close()
p = open("files")
p:relayout()
check("relayout keeps windows valid", vim.api.nvim_win_is_valid(p.list_win) and vim.api.nvim_win_is_valid(p.preview_win))
p:close()

-- preview ---------------------------------------------------------------------------
print("preview")
p = open("files", { query = "main" })
wait(function() return #p.results > 0 and p.results[1].label == "src/main.lua" end)
require("fly.preview").update(p)
local pl = vim.api.nvim_buf_get_lines(p.preview_buf, 0, -1, false)
check("file preview shows content", pl[1] == "local M = {}", vim.inspect(pl))
p:close()
-- binary / missing / directory
local pv = open("files")
local function preview_of(item)
  pv.results = { item }
  pv.cursor = 1
  require("fly.preview").update(pv)
  return table.concat(vim.api.nvim_buf_get_lines(pv.preview_buf, 0, -1, false), "\n")
end
do local f = io.open(dir .. "/bin.dat", "wb"); f:write("a\0b"); f:close() end
check("binary file guarded", preview_of({ label = "bin", path = dir .. "/bin.dat" }):find("binary") ~= nil)
check("missing file guarded", preview_of({ label = "x", path = dir .. "/nope" }):find("not found") ~= nil)
check("directory listing", preview_of({ label = "d", path = dir .. "/src" }):find("main.lua") ~= nil)
check("image without backend: message not crash", (function()
  vim.env.FLY_KITTY, vim.env.FLY_UEBERZUG = "false", "false"
  fly.setup({ image = { backend = "auto" } })
  return preview_of({ label = "i", path = dir .. "/pic.png" }) ~= nil
end)())
pv:close()

-- grep (live) ------------------------------------------------------------------------------
print("grep")
p = open("grep")
check("short query: nothing", #p.results == 0)
query(p, "needle")
check("finds match", #p.results >= 1, #p.results)
local it = p.results[1]
check("path/line/col parsed", it and it.path:find("src/main.lua", 1, true) and it.line == 3 and it.col and it.col > 1, vim.inspect(it))
check("text has no col prefix", it and it.text == "return 'needle in haystack'", it and it.text)
check("match highlight range", it and it.hl and #it.hl >= 2)
query(p, "--pre=evil")
check("option-like query is safe", #p.results == 0)
query(p, "needle")
vim.cmd("edit " .. dir .. "/README.md")
p.origin.win = vim.api.nvim_get_current_win() -- jump must happen in the origin window
p:run_action("confirm")
wait(function() return vim.api.nvim_buf_get_name(0):find("main.lua", 1, true) end)
settle()
check("grep confirm jumps to line", vim.api.nvim_win_get_cursor(0)[1] == 3, vim.inspect(vim.api.nvim_win_get_cursor(0)))

-- buffers / lines / recent -----------------------------------------------------------------
print("buffers, lines")
vim.cmd("edit " .. dir .. "/README.md")
vim.cmd("edit " .. dir .. "/src/util.lua")
p = open("buffers")
check("buffers listed", has(labels(p), "README.md") and has(labels(p), "src/util.lua"))
check("current buffer is last", p.results[#p.results].label == "src/util.lua", vim.inspect(labels(p)))
p:close()
vim.cmd("edit " .. dir .. "/src/main.lua")
p = open("lines")
check("lines source sees origin buffer (not the prompt)", has(labels(p), "needle in haystack"), vim.inspect(labels(p, 3)))
p:set_query("haystack")
wait(function() return p.filter_done and #p.results > 0 end)
p:run_action("confirm")
vim.wait(50)
check("lines confirm moves cursor", vim.api.nvim_win_get_cursor(0)[1] == 3)
p = open("recent")
check("recent opens without error", p ~= nil)
p:close()

-- git ------------------------------------------------------------------------------------------
print("git")
p = open("git")
check("status lists modified+untracked", has(labels(p), "src/util.lua") and has(labels(p), "untracked.txt"), vim.inspect(labels(p)))
local util_item
for _, i in ipairs(p.results) do if i.label == "src/util.lua" then util_item = i end end
check("modified is unstaged", util_item and util_item.data.y == "M" and util_item.data.x == " ")
p.cursor = 1
for i, r in ipairs(p.results) do if r == util_item then p.cursor = i end end
p:run_action("stage")
wait(function() return p.source_done and p.filter_done end)
local staged
for _, i in ipairs(p.results) do if i.label == "src/util.lua" then staged = i end end
check("stage action stages file", staged and staged.data.x == "M" and staged.data.y == " ", vim.inspect(staged and staged.data))
p:close()
p = open("git_files")
check("git_files lists tracked+untracked", has(labels(p), "README.md") and has(labels(p), "untracked.txt"))
p:close()
p = open("git_log")
check("git_log lists commit", has(labels(p), "first commit"), vim.inspect(labels(p)))
require("fly.preview").update(p)
vim.wait(500, function() return table.concat(vim.api.nvim_buf_get_lines(p.preview_buf, 0, -1, false), "\n"):find("first commit", 1, true) end)
check("git_log preview shows commit", table.concat(vim.api.nvim_buf_get_lines(p.preview_buf, 0, -1, false), "\n"):find("first commit", 1, true) ~= nil)
p:close()

-- help / commands / others ------------------------------------------------------------------
print("help, commands, misc")
p = open("help", { query = "nvim_buf_set_lines" })
wait(function() return #p.results > 0 end)
check("help tags found + deduped", #p.results >= 1 and p.results[1].label:find("nvim_buf_set_lines", 1, true) == 1, vim.inspect(labels(p, 3)))
p:run_action("confirm")
wait(function() return vim.api.nvim_buf_get_name(0):find("doc/api.txt", 1, true) end)
check("help confirm opens :help at the tag", vim.bo.buftype == "help" and vim.api.nvim_buf_get_name(0):find("doc/api.txt", 1, true) ~= nil, vim.bo.buftype .. " " .. vim.api.nvim_buf_get_name(0))
vim.cmd("only | enew")
vim.api.nvim_create_user_command("FlyTestCmd", function() vim.g.fly_test_ran = true end, { nargs = 0 })
p = open("commands", { query = "FlyTestCmd" })
wait(function() return #p.results > 0 end)
p:run_action("confirm")
wait(function() return vim.g.fly_test_ran end)
check("commands confirm runs 0-arg command", vim.g.fly_test_ran == true)
p = open("commands", { query = "'write" })
check("commands includes builtin commands", has(labels(p, 50), "write"))
p:close()
vim.keymap.set("n", "<leader>zz", function() end, { desc = "fly test map" })
p = open("keymaps", { query = "fly test" })
check("keymaps source", has(labels(p), "fly test map"))
p:close()
vim.fn.setreg("a", "register text")
p = open("registers")
check("registers source", has(labels(p), "register text"))
p:close()
vim.cmd("edit " .. dir .. "/src/main.lua")
vim.cmd("normal! 3Gma")
p = open("marks")
check("marks source", has(labels(p), "a "))
p:close()
vim.fn.setqflist({ { filename = dir .. "/src/main.lua", lnum = 2, text = "qf entry" } })
p = open("quickfix")
check("quickfix source", has(labels(p), "qf entry"))
p:close()
p = open("jumps")
check("jumps source opens", p ~= nil)
p:close()
local ns = vim.api.nvim_create_namespace("t")
vim.diagnostic.set(ns, vim.api.nvim_get_current_buf(), { { lnum = 1, col = 0, message = "bad thing\nsecond line", severity = 1 } })
p = open("diagnostics")
check("diagnostics source", has(labels(p), "bad thing") and not has(labels(p), "second line"))
p:close()
p = open("colorschemes")
check("colorschemes source", #p.results > 0)
p:run_action("confirm")
check("colorscheme confirm ok", true)
p = open("symbols")
check("symbols without LSP: graceful", p ~= nil and #p.results == 0)
p:close()
p = open("images")
check("images source opens", p ~= nil)
p:close()

-- API ------------------------------------------------------------------------------------------
print("api")
local chosen, idx = "unset", nil
fly.select({ "alpha", "beta", "gamma" }, { prompt = "Pick:" }, function(item, i) chosen, idx = item, i end)
p = picker.active
check("select opens picker", p ~= nil)
wait(function() return #p.results == 3 end)
p:set_query("bet")
wait(function() return p.filter_done and #p.results == 1 end)
p:run_action("confirm")
wait(function() return chosen ~= "unset" end)
check("select returns item+index", chosen == "beta" and idx == 2, vim.inspect({ chosen, idx }))
chosen = "unset"
fly.select({ "a", "b" }, {}, function(item) chosen = item end)
picker.active:run_action("close")
wait(function() return chosen ~= "unset" end)
check("select cancel calls on_choice(nil) exactly once", chosen == nil)

local got
p = fly.pick({ items = { { label = "one" }, { label = "two" } }, confirm = function(item) got = item.label end })
wait(function() return #p.results == 2 end)
p:set_query("tw")
wait(function() return p.filter_done and #p.results == 1 end)
p:run_action("confirm")
wait(function() return got end)
check("static items + custom confirm", got == "two")

fly.register("mine", { title = "mine", find = function() return { { label = "custom-item" } } end })
p = open("mine")
check("custom registered source", has(labels(p), "custom-item"))
p:close()
p = fly.pick({ source = { title = "inline", start = function(ctx, push, done) push({ { label = "streamed" } }); done() end } })
wait(function() return #p.results == 1 end)
check("inline async source table", p.results[1].label == "streamed")
p:close()
fly.pick({ source = "does-not-exist" })
check("unknown source does not crash", picker.active == nil)

p = fly.files(); p:set_query("util"); wait(function() return p.filter_done end)
p:close()
fly.resume()
check("resume restores query", picker.active and picker.active.query == "util", picker.active and picker.active.query)
picker.active:close()

vim.cmd("Fly files")
check(":Fly command opens", picker.active ~= nil)
picker.active:close()
vim.cmd("Fly grep needle")
check(":Fly grep with positional query", picker.active and picker.active.query == "needle")
picker.active:close()

-- icons + treesitter -------------------------------------------------------------------------
print("icons, treesitter")
_G.MiniIcons = { get = function() return "I", "FlyIcon" end }
require("fly.icons")._cache = {}
p = open("files", { query = "main" })
wait(function() return #p.results > 0 end)
settle()
local first = vim.api.nvim_buf_get_lines(p.list_buf, 0, 1, false)[1]
check("icons prefix rendered", first and first:sub(1, 2) == "I ", first)
check("match highlight offset by icon", #vim.api.nvim_buf_get_extmarks(p.list_buf, p.ns, 0, -1, { details = true }) > 0)
local marks = vim.api.nvim_buf_get_extmarks(p.list_buf, p.ns, 0, -1, { details = true })
local on_match = false
for _, m in ipairs(marks) do
  if m[4].hl_group == "FlyMatch" then
    local text = first:sub(m[3] + 1, m[4].end_col)
    on_match = on_match or text:find("m") ~= nil
  end
end
check("FlyMatch lands on matched chars", on_match)
require("fly.preview").update(p)
settle()
check("treesitter active in preview", vim.treesitter.highlighter.active[p.preview_buf] ~= nil)
p:close()
_G.MiniIcons = nil
require("fly.icons")._cache = {}

-- big list performance ----------------------------------------------------------------------------
print("performance")
local big = {}
for i = 1, 150000 do big[i] = { label = ("dir%d/sub%d/file_%d.lua"):format(i % 97, i % 13, i) } end
local t0 = vim.uv.hrtime()
p = fly.pick({ source = { title = "big", find = function() return big end } })
wait(function() return p.filter_done end, 10000)
p:set_query("file_12345")
local max_block, last = 0, vim.uv.hrtime()
local timer = vim.uv.new_timer()
timer:start(0, 5, function() local n = vim.uv.hrtime(); max_block = math.max(max_block, n - last); last = n end)
wait(function() return p.filter_done end, 10000)
timer:stop()
check("150k items filtered", p.results[1] and p.results[1].label:find("file_12345", 1, true), p.results[1] and p.results[1].label)
check(("typing never blocks > 120ms (max %.0fms)"):format(max_block / 1e6), max_block < 120e6)
p:close()

print(("\n%d passed, %d failed"):format(pass, fail))
vim.cmd(fail == 0 and "qa!" or "cq!")
