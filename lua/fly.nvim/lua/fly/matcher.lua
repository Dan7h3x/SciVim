-- fzf-lite matcher.
--
--   foo      fuzzy match
--   'foo     exact (substring) match
--   ^foo     prefix match
--   foo$     suffix match
--   ^foo$    whole-string match
--   !foo     exclude items containing foo (also !^foo, !foo$)
--   a b      space-separated terms must ALL match (AND)
--
-- Smart-case: a term containing an uppercase letter is matched case-sensitively.
local M = {}

local find, sub, byte, lower = string.find, string.sub, string.byte, string.lower
local min = math.min

---@class fly.matcher.Config
---@field cwd_bonus boolean   prefer shallower paths
---@field filename_bonus boolean  prefer matches inside the file name
---@field sort_empty boolean  sort alphabetically when the query is empty
---@field smartcase boolean

---@class fly.Term
---@field kind "fuzzy"|"exact"|"prefix"|"suffix"|"equal"
---@field neg boolean
---@field text string
---@field cs boolean
---@field chars string[]?
---@field bytes integer[]?

---@class fly.Query
---@field terms fly.Term[]
---@field has_query boolean
---@field opts fly.matcher.Config

---@param token string
---@param smartcase boolean
---@return fly.Term
local function parse_token(token, smartcase)
  local neg, kind, text = false, "fuzzy", token
  if #text > 1 and text:sub(1, 1) == "!" then
    neg, kind, text = true, "exact", text:sub(2)
  end
  if #text > 1 and text:sub(1, 1) == "'" then
    kind, text = "exact", text:sub(2)
  elseif #text > 1 and text:sub(1, 1) == "^" then
    kind, text = "prefix", text:sub(2)
    if #text > 1 and text:sub(-1) == "$" then
      kind, text = "equal", text:sub(1, -2)
    end
  elseif #text > 1 and text:sub(-1) == "$" then
    kind, text = "suffix", text:sub(1, -2)
  end
  local cs = smartcase and text:find("%u") ~= nil or false
  if not cs then
    text = lower(text)
  end
  local term = { kind = kind, neg = neg, text = text, cs = cs }
  if kind == "fuzzy" then
    term.chars, term.bytes = {}, {}
    for i = 1, #text do
      term.chars[i] = sub(text, i, i)
      term.bytes[i] = byte(text, i)
    end
  end
  return term
end

---@param query string
---@param opts? fly.matcher.Config
---@return fly.Query
function M.parse(query, opts)
  opts = opts or {}
  local terms = {}
  for token in query:gmatch("%S+") do
    terms[#terms + 1] = parse_token(token, opts.smartcase ~= false)
  end
  return { terms = terms, has_query = #terms > 0, opts = opts }
end

--- Score bonus for a match starting at byte `p` of the original text `t`.
local function boundary(t, p)
  if p == 1 then
    return 10
  end
  local prev = byte(t, p - 1)
  if prev == 47 then -- /
    return 9
  elseif prev == 95 or prev == 45 or prev == 46 or prev == 32 or prev == 58 then -- _ - . space :
    return 7
  end
  local cur = byte(t, p)
  if cur and cur >= 65 and cur <= 90 and prev >= 97 and prev <= 122 then -- camelCase
    return 6
  end
  return 0
end

--- Start index of the file name inside `label`.
local function basename_start(item)
  local bs = item._bs
  if not bs then
    local last = 0
    local label = item.label
    local i = 0
    while true do
      i = find(label, "/", i + 1, true)
      if not i then
        break
      end
      last = i
    end
    bs = last + 1
    item._bs = bs
  end
  return bs
end

local function fuzzy(term, orig, hay, want_pos, item, mopts)
  local chars = term.chars
  local n = #chars
  if n == 0 or n > #hay then
    return nil
  end
  -- forward pass: earliest end position of any subsequence match
  local from, e = 1, 0
  for i = 1, n do
    local f = find(hay, chars[i], from, true)
    if not f then
      return nil
    end
    from, e = f + 1, f
  end
  -- backward pass: tighten to the shortest window ending at `e`
  local pos = {}
  pos[n] = e
  local j = e - 1
  local qb = term.bytes
  for i = n - 1, 1, -1 do
    local c = qb[i]
    while j >= 1 and byte(hay, j) ~= c do
      j = j - 1
    end
    if j < 1 then
      return nil
    end
    pos[i] = j
    j = j - 1
  end
  local score, prev = 0, -1
  for i = 1, n do
    local p = pos[i]
    score = score + 16 + boundary(orig, p)
    if prev > 0 then
      if p == prev + 1 then
        score = score + 12
      else
        score = score - 3 - min(p - prev - 2, 8)
      end
    end
    prev = p
  end
  score = score - min(pos[1] - 1, 10) * 0.5
  if mopts.filename_bonus ~= false then
    local bs = basename_start(item)
    if pos[1] >= bs then
      score = score + 24
      if pos[1] == bs then
        score = score + 8
      end
    end
  end
  return score, want_pos and pos or nil
end

local function contiguous(s, len)
  local pos = {}
  for i = 1, len do
    pos[i] = s + i - 1
  end
  return pos
end

local function substring(term, orig, hay, want_pos, item, mopts)
  local kind, text = term.kind, term.text
  local len = #text
  local s
  if kind == "exact" then
    s = find(hay, text, 1, true)
  elseif kind == "prefix" then
    s = sub(hay, 1, len) == text and 1 or nil
  elseif kind == "suffix" then
    s = (#hay >= len and sub(hay, -len) == text) and (#hay - len + 1) or nil
  else -- equal
    s = hay == text and 1 or nil
  end
  if not s then
    return nil
  end
  local score = 16 * len + 12 * (len - 1) + 8 + boundary(orig, s) - min(s - 1, 10) * 0.5
  if kind ~= "exact" then
    score = score + 12
  end
  if mopts.filename_bonus ~= false and s >= basename_start(item) then
    score = score + 24
  end
  return score, want_pos and contiguous(s, len) or nil
end

---@return number? score, integer[]? positions
local function match_term(term, item, want_pos, mopts)
  local orig = item.label
  local hay = orig
  if not term.cs then
    hay = item._ll
    if not hay then
      hay = lower(orig)
      item._ll = hay
    end
  end
  if term.neg then
    local s = substring(term, orig, hay, false, item, mopts)
    if s then
      return nil
    end
    return 0
  end
  if term.kind == "fuzzy" then
    return fuzzy(term, orig, hay, want_pos, item, mopts)
  end
  return substring(term, orig, hay, want_pos, item, mopts)
end

--- Match an item against a parsed query.
---@param parsed fly.Query
---@param item fly.Item
---@param want_pos? boolean also return highlight positions (1-based byte offsets of `item.label`)
---@return number? score, integer[]? positions
function M.match(parsed, item, want_pos)
  local total = 0
  local all = want_pos and {} or nil
  for _, term in ipairs(parsed.terms) do
    local s, pos = match_term(term, item, want_pos, parsed.opts)
    if not s then
      return nil
    end
    total = total + s
    if pos and all then
      for _, p in ipairs(pos) do
        all[#all + 1] = p
      end
    end
  end
  if parsed.opts.cwd_bonus ~= false and item.path then
    local depth = item._depth
    if not depth then
      depth = select(2, item.label:gsub("/", ""))
      item._depth = depth
    end
    total = total - depth * 1.5
  end
  total = total - #item.label * 0.05
  if all then
    table.sort(all)
    local out, last = {}, 0
    for _, p in ipairs(all) do
      if p ~= last then
        out[#out + 1] = p
        last = p
      end
    end
    all = out
  end
  return total, all
end

--- Highlight positions of `item` for `parsed` (nil if it does not match).
---@param parsed fly.Query
---@param item fly.Item
function M.positions(parsed, item)
  if not parsed.has_query then
    return nil
  end
  local _, pos = M.match(parsed, item, true)
  return pos
end

--- Sort comparator for scored items: best score first, then shorter, then source order.
function M.compare(a, b)
  if a._score ~= b._score then
    return a._score > b._score
  end
  if #a.label ~= #b.label then
    return #a.label < #b.label
  end
  return (a._idx or 0) < (b._idx or 0)
end

return M
