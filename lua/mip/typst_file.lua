--- Typst "in-file" rendering.
---
--- Instead of compiling every block as an isolated snippet (which loses the
--- document's #set / #show / #let / imports / numbering), the *real document*
--- is compiled once and the blocks are cut out of the resulting pages:
---
---   1. every block gets a label (or reuses its own label) and a show rule
---        #show <mip-3>: it => __mip(3, it)
---      that wraps the element in a natural-size box and records its page and
---      rectangle with `metadata` (position + `measure`);
---   2. `typst compile --format svg` writes the pages (vector) while
---      `typst query` reads the recorded rectangles, in parallel;
---   3. a block's master is "page SVG + crop rectangle"; the normal layout /
---      rasterise / display path then turns it into an exact-cell image.
---
--- Blocks that cannot be tagged safely (inside code, e.g. `#let x = $a$`) and
--- documents that fail to compile fall back to the isolated-snippet pipeline.
local config = require("mip.config")
local util = require("mip.util")
local P = require("mip.parse")
local api, fn, uv = vim.api, vim.fn, vim.uv or vim.loop

local TF = { on_done = function() end }

local PRELUDE = [[
#let __mip(i, it) = context {
  let s = measure(it)
  box(width: s.width, context {
    let p = here().position()
    [#metadata((i: i, page: p.page, x: p.x.pt(), y: p.y.pt(), w: s.width.pt(), h: s.height.pt())) <mip-rec>]
    it
  })
}
]]

-- crop padding in pt { x, y }: glyph overhang is not part of the measured box
local PAD = { inline = { 0.6, 2.2 } }
local DEFAULT_PAD = { 1, 1 }

function TF.block_id(b)
  return fn.sha256(b.kind .. "\0" .. b.src):sub(1, 16)
end

local function root_dir()
  return config.values.cache_dir .. "/tf"
end

--- Build the instrumented source. Returns text, ids[n] -> block id, kinds[n] -> kind.
local function instrument(S, blocks, fg)
  local lines = api.nvim_buf_get_lines(S.buf, 0, -1, false)
  local seen, ins, rules, ids, kinds, n = {}, {}, {}, {}, {}, 0
  for _, b in ipairs(blocks) do
    if b.safe ~= false then
      local id = TF.block_id(b)
      if not seen[id] then -- identical blocks share the first occurrence's rendering
        seen[id] = true
        n = n + 1
        ids[n], kinds[n] = id, b.kind
        local line = lines[b.erow + 1] or ""
        local lab = line:sub(b.ecol + 1):match("^%s*<([%w_:%.%-]+)>")
        if lab then -- keep the block's own label: references to it must still work
          rules[#rules + 1] = ("#show <%s>: it => __mip(%d, it)"):format(lab, n)
        else
          local col = b.ecol
          if b.kind == "section" then -- do not put the label inside a trailing // comment
            local c = line:find("%s//", 1)
            if c and c - 1 < col then col = c - 1 end
          end
          ins[#ins + 1] = { row = b.erow, col = col, text = (b.kind == "inline" and "" or " ") .. "<mip-" .. n .. ">" }
          rules[#rules + 1] = ("#show <mip-%d>: it => __mip(%d, it)"):format(n, n)
        end
      end
    end
  end
  table.sort(ins, function(a, b)
    if a.row ~= b.row then return a.row > b.row end
    return a.col > b.col
  end)
  for _, x in ipairs(ins) do
    local l = lines[x.row + 1]
    lines[x.row + 1] = l:sub(1, x.col) .. x.text .. l:sub(x.col + 1)
  end
  local c = ("rgb(\"#%s\")"):format(fg)
  local head = table.concat({
    PRELUDE,
    "#set page(fill: none)",
    ("#set text(fill: %s)"):format(c),
    ("#set table(stroke: 0.5pt + %s)"):format(c),
    ("#set line(stroke: 0.5pt + %s)"):format(c),
    table.concat(rules, "\n"),
    "",
  }, "\n")
  return head .. table.concat(lines, "\n") .. "\n", ids, kinds
end

local function flags()
  local cfg = config.values.typst
  local f = {}
  if cfg.root then vim.list_extend(f, { "--root", cfg.root }) end
  vim.list_extend(f, cfg.args or {})
  return f
end

local function first_error(text)
  local msg = (text or ""):match("(error:[^\n]*\n?[^\n]*)") or vim.trim(text or ""):sub(1, 200)
  return (msg:gsub("%s+", " "))
end

local function fail(S, tf, msg)
  tf.compiling, tf.state, tf.err = false, "failed", msg
  util.log("typst (in-file): " .. msg)
  util.warn_once("tf-" .. S.buf, "typst in-file render failed, falling back to snippets: " .. msg)
  TF.on_done(S)
end

local function finish(S, tf, ctx, res)
  tf.compiling = false
  if ctx.tmp_in_doc then fn.delete(ctx.infile) end
  local c, q = res.compile, res.query
  if not c or c.code ~= 0 then
    return fail(S, tf, first_error(c and (c.stderr or c.stdout)))
  end
  local ok, list = pcall(vim.json.decode, (q and q.stdout) or "")
  if not ok or type(list) ~= "table" then
    return fail(S, tf, "could not read block positions: " .. first_error(q and q.stderr))
  end
  local index, used = {}, {}
  for _, r in ipairs(list) do
    local id, kind = ctx.ids[r.i], ctx.kinds[r.i]
    local page = ("%s/p-%d.svg"):format(ctx.out, r.page)
    if id and uv.fs_stat(page) and r.w > 0 and r.h > 0 then
      local pad = PAD[kind] or DEFAULT_PAD
      local x, y, w, h = r.x - pad[1], r.y - pad[2], r.w + 2 * pad[1], r.h + 2 * pad[2]
      -- numbering / section context can change a block's look even when its source did not
      local ctxkey = (kind == "inline" or kind == "table") and "" or ctx.key
      index[id] = {
        ok = true, kind = "svg", path = page, crop = { x, y, w, h }, w = w, h = h, volatile = true,
        hash = fn.sha256(table.concat({ "tf", id, ("%.2f,%.2f"):format(w, h), ctx.fg, ctxkey }, "\0")),
      }
      used[page] = true
    end
  end
  -- keep only pages that contain blocks
  local h = uv.fs_scandir(ctx.out)
  while h do
    local name = uv.fs_scandir_next(h)
    if not name then break end
    local p = ctx.out .. "/" .. name
    if not used[p] then uv.fs_unlink(p) end
  end
  local old = tf.dir
  tf.index, tf.dir, tf.key, tf.state, tf.err = index, ctx.out, ctx.key, "idle", nil
  if old and old ~= ctx.out then -- late: rasters may still be reading the previous pages
    vim.defer_fn(function() fn.delete(old, "rf") end, 5000)
  end
  TF.on_done(S)
end

local function query(cmd, infile, cb)
  local function sys(argv, done)
    local ok, err = pcall(vim.system, argv, { text = true, timeout = 120000 }, done)
    if not ok then done({ code = 1, stdout = "", stderr = tostring(err) }) end
  end
  local a1 = { cmd, "query", infile, "<mip-rec>", "--field", "value" }
  vim.list_extend(a1, flags())
  sys(a1, function(res)
    if res.code == 0 and res.stdout ~= "" then return cb(res) end
    -- `typst query` was deprecated in favour of `typst eval`
    local a2 = { cmd, "eval", "query(<mip-rec>).map(it => it.value)", "--in", infile }
    vim.list_extend(a2, flags())
    sys(a2, cb)
  end)
end

--- Compile the whole document now (async).
function TF.compile(S)
  local tf, cfg = S.tf, config.values.typst
  if tf.compiling or not api.nvim_buf_is_valid(S.buf) then return end
  if not util.exe(cfg.cmd) then
    return fail(S, tf, ("typst executable '%s' not found"):format(cfg.cmd))
  end
  local nl = api.nvim_buf_line_count(S.buf)
  local blocks = P.parse(S, 0, nl)
  local text, ids, kinds = instrument(S, blocks, S.fg)
  local key = fn.sha256(text)
  if key == tf.key then
    tf.state = "idle"
    return TF.on_done(S)
  end
  local out = ("%s/%d-%d/%s"):format(root_dir(), uv.os_getpid(), S.buf, key:sub(1, 16))
  fn.mkdir(out, "p")
  -- compile next to the document so relative imports / images / bibliographies resolve
  local infile = ("%s/.mip-%d-%d.typ"):format(S.dir, uv.os_getpid(), S.buf)
  local tmp_in_doc = util.write_file(infile, text)
  if not tmp_in_doc then
    infile = out .. "/doc.typ"
    util.write_file(infile, text)
  end
  local ctx = { key = key, ids = ids, kinds = kinds, out = out, infile = infile, tmp_in_doc = tmp_in_doc, fg = S.fg }
  tf.compiling = true

  local res, pending = {}, 2
  local function done()
    pending = pending - 1
    if pending == 0 then vim.schedule(function() finish(S, tf, ctx, res) end) end
  end
  local argv = { cfg.cmd, "compile", "--format", "svg" }
  vim.list_extend(argv, flags())
  vim.list_extend(argv, { infile, out .. "/p-{p}.svg" })
  local ok, err = pcall(vim.system, argv, { text = true, timeout = 180000 }, function(r)
    res.compile = r
    done()
  end)
  if not ok then
    res.compile = { code = 1, stderr = tostring(err) }
    done()
  end
  query(cfg.cmd, infile, function(r)
    res.query = r
    done()
  end)
end

--- Called on every update of a Typst buffer: (re)starts a compile when the text changed.
function TF.sync(S)
  local tf = S.tf
  if not tf then
    tf = { index = {}, state = "pending", tick = -1 }
    S.tf = tf
  end
  local tick = api.nvim_buf_get_changedtick(S.buf)
  if tick ~= tf.tick then
    tf.tick, tf.want, tf.state = tick, true, "pending"
  end
  local mode = api.nvim_get_mode().mode:sub(1, 1)
  if tf.want and not tf.compiling and mode ~= "i" and mode ~= "R" then
    tf.want = false
    if not tf.timer then tf.timer = uv.new_timer() end
    tf.timer:stop()
    tf.timer:start(config.values.typst.debounce, 0, vim.schedule_wrap(function()
      if S.tf == tf then TF.compile(S) end
    end))
  end
end

--- "pending" while a render is expected, an entry, or nil (use the snippet pipeline).
function TF.lookup(S, b)
  local tf = S.tf
  if not tf or b.safe == false then return nil end
  local e = tf.index[TF.block_id(b)]
  if e then return e end
  if tf.state == "pending" then return "pending" end
  return nil
end

function TF.reset(S)
  local tf = S.tf
  if not tf then return end
  if tf.timer then
    tf.timer:stop()
    tf.timer:close()
  end
  if tf.dir then fn.delete(tf.dir, "rf") end
  S.tf = nil
end

--- remove directories left behind by crashed sessions
function TF.init()
  local dir = root_dir()
  local limit = os.time() - 86400
  local h = uv.fs_scandir(dir)
  while h do
    local name, typ = uv.fs_scandir_next(h)
    if not name then break end
    local st = typ == "directory" and uv.fs_stat(dir .. "/" .. name)
    if st and st.mtime.sec < limit then fn.delete(dir .. "/" .. name, "rf") end
  end
end

function TF.shutdown()
  local prefix = tostring(uv.os_getpid()) .. "-"
  local h = uv.fs_scandir(root_dir())
  while h do
    local name = uv.fs_scandir_next(h)
    if not name then break end
    if vim.startswith(name, prefix) then fn.delete(root_dir() .. "/" .. name, "rf") end
  end
end

return TF
