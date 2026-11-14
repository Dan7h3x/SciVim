--- Text scanner used for Org (no math nodes in tree-sitter-org) and as the
--- fallback for LaTeX / Typst when no tree-sitter parser is installed.
local C = require("mip.parse.common")
local api, fn = vim.api, vim.fn

local M = {}

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function line_of(starts, off)
  local lo, hi = 1, #starts
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    if starts[mid] <= off then lo = mid else hi = mid - 1 end
  end
  return lo
end

local function make_ctx(lines, base)
  local starts, pos = {}, 1
  for i, l in ipairs(lines) do
    starts[i] = pos
    pos = pos + #l + 1
  end
  return { lines = lines, base = base, starts = starts, text = table.concat(lines, "\n") }
end

local function ws_before(ctx, off)
  local ri = line_of(ctx.starts, off)
  return ctx.text:sub(ctx.starts[ri], off - 1):match("^%s*$") ~= nil
end

local function merge(ranges)
  table.sort(ranges, function(a, b) return a[1] < b[1] end)
  local out = {}
  for _, r in ipairs(ranges) do
    local last = out[#out]
    if last and r[1] <= last[2] then
      last[2] = math.max(last[2], r[2])
    else
      out[#out + 1] = { r[1], r[2] }
    end
  end
  return out
end

local function blank_ranges(text, ranges)
  if #ranges == 0 then return text end
  local out, last = {}, 1
  for _, r in ipairs(merge(ranges)) do
    out[#out + 1] = text:sub(last, r[1] - 1)
    out[#out + 1] = (text:sub(r[1], r[2]):gsub("[^\n]", " "))
    last = r[2] + 1
  end
  out[#out + 1] = text:sub(last)
  return table.concat(out)
end

local function match_delim(s, pos, open, close)
  local set = "[\\%" .. open .. "%" .. close .. "]"
  local depth, i = 0, pos
  while true do
    local p = s:find(set, i)
    if not p then return nil end
    local c = s:sub(p, p)
    if c == "\\" then
      i = p + 2
    elseif c == open then
      depth, i = depth + 1, p + 1
    else
      depth = depth - 1
      if depth == 0 then return p end
      i = p + 1
    end
  end
end

--- closing `$` for an inline math opened just before `from`
local function dollar_end(s, from, strict)
  local i = from
  while true do
    local p = s:find("[\\$\n]", i)
    if not p then return nil end
    local ch = s:byte(p)
    if ch == 92 then
      i = p + 2
    elseif ch == 10 then
      if p + 1 > #s or s:find("^[ \t]*\n", p + 1) then return nil end
      i = p + 1
    else
      if p == from then return nil end
      if strict then -- org: no padding spaces, closer not followed by alnum
        if s:sub(from, from):match("%s") or s:sub(p - 1, p - 1):match("%s") then return nil end
        if s:sub(p + 1, p + 1):match("%w") then return nil end
      end
      return p
    end
  end
end

local function push(raw, s, e, kind, extra)
  local r = extra or {}
  r.s, r.e, r.kind = s, e, kind
  raw[#raw + 1] = r
end

---------------------------------------------------------------------------
-- LaTeX (+ Org fragments)
---------------------------------------------------------------------------

local function mask_tex(text)
  local ranges, i = {}, 1
  while true do
    local p = text:find("%", i, true)
    if not p then break end
    local bs, k = 0, p - 1
    while k >= 1 and text:byte(k) == 92 do bs, k = bs + 1, k - 1 end
    if bs % 2 == 1 then
      i = p + 1
    else
      local e = text:find("\n", p, true)
      e = e and (e - 1) or #text
      ranges[#ranges + 1] = { p, e }
      i = e + 1
    end
  end
  for _, env in ipairs({ "verbatim", "Verbatim", "lstlisting", "minted", "comment" }) do
    local j = 1
    while true do
      local s = text:find("\\begin{" .. env .. "}", j, true)
      if not s then break end
      local _, e = text:find("\\end{" .. env .. "}", s, true)
      if not e then break end
      ranges[#ranges + 1] = { s, e }
      j = e + 1
    end
  end
  return blank_ranges(text, ranges)
end

local function scan_tex(ctx, masked, raw, opts)
  local text, i = ctx.text, 1
  while true do
    local p = masked:find("[\\$]", i)
    if not p then break end
    if masked:byte(p) == 36 then
      if masked:byte(p + 1) == 36 then
        local q = masked:find("$$", p + 2, true)
        if q then push(raw, p, q + 1, "display"); i = q + 2 else i = p + 2 end
      else
        local q = dollar_end(masked, p + 1, opts.strict)
        if q then push(raw, p, q, "inline"); i = q + 1 else i = p + 1 end
      end
    else
      local nx = masked:sub(p + 1, p + 1)
      if nx == "[" then
        local q = masked:find("\\]", p + 2, true)
        if q then push(raw, p, q + 1, "display"); i = q + 2 else i = p + 2 end
      elseif nx == "(" then
        local q = masked:find("\\)", p + 2, true)
        if q then push(raw, p, q + 1, "inline"); i = q + 2 else i = p + 2 end
      elseif nx == "" then
        break
      elseif not nx:match("%a") then
        i = p + 2
      else
        local name = masked:match("^begin{([%w%*]+)}", p + 1)
        local cmd = masked:match("^(%a+)", p + 1)
        if name then
          local kind = C.env_kind(name)
          local q1, q2 = masked:find("\\end{" .. name .. "}", p, true)
          if kind and q1 then
            push(raw, p, q2, kind, { env = name })
            i = q2 + 1
          else
            i = p + 6
          end
        elseif opts.sections and C.SECTION_LEVEL[cmd] and ws_before(ctx, p) then
          local pos = p + 1 + #cmd
          if masked:sub(pos, pos) == "*" then pos = pos + 1 end
          if masked:sub(pos, pos) == "[" then
            local rb = masked:find("]", pos, true)
            if rb then pos = rb + 1 end
          end
          local close = masked:sub(pos, pos) == "{" and match_delim(masked, pos, "{", "}")
          if close then
            local title = vim.trim((text:sub(pos + 1, close - 1):gsub("%s+", " ")))
            push(raw, p, close, "section", { level = C.SECTION_LEVEL[cmd], title = title })
            i = close + 1
          else
            i = p + 1 + #cmd
          end
        else
          i = p + 1 + #cmd
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Typst
---------------------------------------------------------------------------

local TYP_CALL = { table = "table", figure = "figure", image = "figure" }

local function mask_typst(text)
  local ranges = {}
  for p in text:gmatch("()//") do
    if text:sub(p - 1, p - 1) ~= ":" then
      local e = text:find("\n", p, true)
      ranges[#ranges + 1] = { p, e and (e - 1) or #text }
    end
  end
  local j = 1
  while true do
    local s = text:find("/*", j, true)
    if not s then break end
    local _, e = text:find("*/", s + 2, true)
    ranges[#ranges + 1] = { s, e or #text }
    j = (e or #text) + 1
  end
  j = 1
  while true do
    local s = text:find("```", j, true)
    if not s then break end
    local _, e = text:find("```", s + 3, true)
    if not e then break end
    ranges[#ranges + 1] = { s, e }
    j = e + 1
  end
  for p, m in text:gmatch("()(`[^`\n]*`)") do ranges[#ranges + 1] = { p, p + #m - 1 } end
  return blank_ranges(text, ranges)
end

local function typst_paren(s, pos)
  local depth, i = 0, pos
  while true do
    local p = s:find('[()"\\]', i)
    if not p then return nil end
    local ch = s:sub(p, p)
    if ch == "\\" then
      i = p + 2
    elseif ch == '"' then
      local j = p + 1
      while true do
        local k = s:find('["\\]', j)
        if not k then return nil end
        if s:sub(k, k) == "\\" then j = k + 2 else j = k break end
      end
      i = j + 1
    elseif ch == "(" then
      depth, i = depth + 1, p + 1
    else
      depth = depth - 1
      if depth == 0 then return p end
      i = p + 1
    end
  end
end

local function scan_typst(ctx, raw)
  local masked = mask_typst(ctx.text)
  for r, l in ipairs(ctx.lines) do
    local eq, title = l:match("^(=+)[ \t]+(.-)[ \t]*$")
    if eq and title ~= "" and masked:sub(ctx.starts[r], ctx.starts[r]) == "=" then
      push(raw, ctx.starts[r], ctx.starts[r] + #l - 1, "section", { level = math.min(#eq, 4), title = title })
    end
  end
  local i = 1
  while true do
    local p = masked:find("[%$#\\]", i)
    if not p then break end
    local c = masked:sub(p, p)
    if c == "\\" then
      i = p + 2
    elseif c == "$" then
      local j, q = p + 1, nil
      while true do
        local k = masked:find("[\\$]", j)
        if not k then break end
        if masked:sub(k, k) == "\\" then j = k + 2 else q = k break end
      end
      if q and q > p + 1 and not masked:sub(p, q):find("\n[ \t]*\n") then
        local display = masked:sub(p + 1, p + 1):match("%s") and masked:sub(q - 1, q - 1):match("%s")
        push(raw, p, q, display and "display" or "inline")
        i = q + 1
      else
        i = p + 1
      end
    else
      local name = masked:match("^#([%a][%w_%-]*)%(", p)
      local kind = name and TYP_CALL[name]
      local close = kind and typst_paren(masked, p + 1 + #name)
      if close then
        while masked:sub(close + 1, close + 1) == "[" do
          local c2 = match_delim(masked, close + 1, "[", "]")
          if not c2 then break end
          close = c2
        end
        push(raw, p, close, kind)
        i = close + 1
      else
        i = p + 1
      end
    end
  end
end

---------------------------------------------------------------------------
-- Org
---------------------------------------------------------------------------

local IMG_EXT = { png = 1, jpg = 1, jpeg = 1, gif = 1, webp = 1, svg = 1, bmp = 1, tif = 1, tiff = 1, pdf = 1 }
local TODO_KW = { "TODO", "DONE", "NEXT", "WAITING", "STARTED", "CANCELLED", "HOLD" }

local function tex_escape(s)
  if s:find("$", 1, true) then return s end
  return (s:gsub("([&%%#_{}])", "\\%1"))
end

local function mask_org(text)
  local low, ranges, i = text:lower(), {}, 1
  while true do
    local s, _, name = low:find("#%+begin_(%w+)", i)
    if not s then break end
    local es, ee = low:find("#%+end_" .. name, s)
    if not es then break end
    ranges[#ranges + 1] = { s, ee }
    i = ee + 1
  end
  return blank_ranges(text, ranges)
end

local function org_table_tex(lines)
  local rows, ncol = {}, 0
  for _, l in ipairs(lines) do
    l = vim.trim(l)
    if l:match("^|[%-+|]*$") and l:find("-", 1, true) then
      rows[#rows + 1] = false
    else
      local inner = l:sub(2)
      if inner:sub(-1) == "|" then inner = inner:sub(1, -2) end
      local cells = {}
      for cell in (inner .. "|"):gmatch("([^|]*)|") do
        cell = vim.trim(cell)
        if cell:match("^<[lrc]?%d*>$") then cell = "" end
        cells[#cells + 1] = tex_escape(cell)
      end
      ncol = math.max(ncol, #cells)
      rows[#rows + 1] = cells
    end
  end
  local out = { "\\begin{tabular}{|" .. ("l|"):rep(ncol) .. "}", "\\hline" }
  for _, r in ipairs(rows) do
    if r == false then
      out[#out + 1] = "\\hline"
    else
      while #r < ncol do r[#r + 1] = "" end
      out[#out + 1] = table.concat(r, " & ") .. " \\\\"
    end
  end
  out[#out + 1] = "\\hline"
  out[#out + 1] = "\\end{tabular}"
  return table.concat(out, "\n")
end

local function scan_org(ctx, raw)
  scan_tex(ctx, mask_org(ctx.text), raw, { strict = true, sections = false })
  local lines, starts = ctx.lines, ctx.starts
  local r, n, in_block = 1, #lines, false
  while r <= n do
    local l = lines[r]
    local low = l:lower()
    if in_block then
      if low:match("^%s*#%+end_") then in_block = false end
      r = r + 1
    elseif low:match("^%s*#%+begin_") then
      in_block = true
      r = r + 1
    elseif l:match("^%*+%s+%S") then
      local stars, title = l:match("^(%*+)%s+(.-)%s*$")
      for _, kw in ipairs(TODO_KW) do
        if title:find("^" .. kw .. "%s") then title = title:sub(#kw + 2) break end
      end
      title = title:gsub("^%[#%u%]%s*", "")
      title = title:gsub("%s+:[%w_@#%%:]+:$", "")
      push(raw, starts[r], starts[r] + #l - 1, "section", { level = math.min(#stars, 4), title = tex_escape(title) })
      r = r + 1
    elseif l:match("^%s*|") then
      local r2 = r
      while r2 < n and lines[r2 + 1]:match("^%s*|") do r2 = r2 + 1 end
      push(raw, starts[r], starts[r2] + #lines[r2] - 1, "table", {
        env = "tabular",
        body = org_table_tex(vim.list_slice(lines, r, r2)),
      })
      r = r2 + 1
    else
      local target = l:match("^%s*%[%[([^%]]+)%]%]%s*$") or l:match("^%s*%[%[([^%]]+)%]%[[^%]]*%]%]%s*$")
      if target then
        target = target:gsub("^file:", "")
        local ext = target:lower():match("%.(%w+)$")
        if ext and IMG_EXT[ext] then
          push(raw, starts[r], starts[r] + #l - 1, "image", { file = target })
        end
      end
      r = r + 1
    end
  end
end

---------------------------------------------------------------------------

--- Returns raw blocks (rows/cols) for buffer lines [lo, hi).
function M.scan(S, lo, hi)
  local lines = api.nvim_buf_get_lines(S.buf, lo, hi, false)
  local ctx = make_ctx(lines, lo)
  local raw = {}
  if S.lang == "typst" then
    scan_typst(ctx, raw)
  elseif S.lang == "org" then
    scan_org(ctx, raw)
  else
    scan_tex(ctx, mask_tex(ctx.text), raw, { strict = false, sections = true })
  end
  for _, b in ipairs(raw) do
    local sri, eri = line_of(ctx.starts, b.s), line_of(ctx.starts, b.e)
    b.srow, b.erow = lo + sri - 1, lo + eri - 1
    b.scol = b.s - ctx.starts[sri]
    b.ecol = b.e - ctx.starts[eri] + 1
    b.s, b.e = nil, nil
  end
  return raw
end

return M
