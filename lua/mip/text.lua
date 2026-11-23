--- Text-mode rendering (no images): LaTeX / Typst / Org blocks -> Unicode lines.
--- Used by backend/text.lua on terminals that cannot display graphics
--- (alacritty, linux console, ...) or when `backend = "text"`.
---   math      : Greek, operators, super/subscripts, fractions, roots, matrices, align
---   tables    : box-drawing grids (LaTeX tabular, Org tables, Typst #table)
---   figures   : a captioned frame with the image file name
---   sections  : styled heading line
local fn = vim.fn

local T = {}
local UTF8 = "[%z\1-\127\194-\244][\128-\191]*"

---------------------------------------------------------------------------
-- Symbol tables
---------------------------------------------------------------------------

local GREEK = {
  alpha = "α", beta = "β", gamma = "γ", delta = "δ", epsilon = "ϵ", varepsilon = "ε", zeta = "ζ", eta = "η",
  theta = "θ", vartheta = "ϑ", iota = "ι", kappa = "κ", lambda = "λ", mu = "μ", nu = "ν", xi = "ξ", pi = "π",
  varpi = "ϖ", rho = "ρ", varrho = "ϱ", sigma = "σ", varsigma = "ς", tau = "τ", upsilon = "υ", phi = "ϕ",
  varphi = "φ", chi = "χ", psi = "ψ", omega = "ω", Gamma = "Γ", Delta = "Δ", Theta = "Θ", Lambda = "Λ", Xi = "Ξ",
  Pi = "Π", Sigma = "Σ", Upsilon = "Υ", Phi = "Φ", Psi = "Ψ", Omega = "Ω",
}

local SYM = {
  sum = "∑", prod = "∏", coprod = "∐", int = "∫", iint = "∬", iiint = "∭", oint = "∮", infty = "∞",
  partial = "∂", nabla = "∇", leq = "≤", le = "≤", geq = "≥", ge = "≥", neq = "≠", ne = "≠", approx = "≈",
  equiv = "≡", sim = "∼", simeq = "≃", cong = "≅", propto = "∝", to = "→", rightarrow = "→", leftarrow = "←",
  gets = "←", leftrightarrow = "↔", Rightarrow = "⇒", Leftarrow = "⇐", Leftrightarrow = "⇔", iff = "⇔",
  implies = "⟹", impliedby = "⟸", mapsto = "↦", longrightarrow = "⟶", uparrow = "↑", downarrow = "↓",
  cdot = "·", times = "×", div = "÷", pm = "±", mp = "∓", ast = "∗", star = "⋆", circ = "∘", bullet = "•",
  oplus = "⊕", otimes = "⊗", odot = "⊙", ["in"] = "∈", notin = "∉", ni = "∋", subset = "⊂", supset = "⊃",
  subseteq = "⊆", supseteq = "⊇", cup = "∪", cap = "∩", setminus = "∖", emptyset = "∅", varnothing = "∅",
  forall = "∀", exists = "∃", nexists = "∄", neg = "¬", lnot = "¬", land = "∧", wedge = "∧", lor = "∨",
  vee = "∨", ldots = "…", dots = "…", cdots = "⋯", vdots = "⋮", ddots = "⋱", prime = "′", angle = "∠",
  perp = "⊥", parallel = "∥", hbar = "ℏ", ell = "ℓ", Re = "ℜ", Im = "ℑ", aleph = "ℵ", langle = "⟨",
  rangle = "⟩", lfloor = "⌊", rfloor = "⌋", lceil = "⌈", rceil = "⌉", ll = "≪", gg = "≫", mid = "∣",
  vert = "|", Vert = "‖", lVert = "‖", rVert = "‖", lvert = "|", rvert = "|", lbrace = "{", rbrace = "}", degree = "°", top = "⊤", bot = "⊥", dagger = "†",
  ["then"] = "⇒", square = "□", triangle = "△", checkmark = "✓",
}

local FUNCS = {}
for _, n in ipairs({ "sin", "cos", "tan", "cot", "sec", "csc", "arcsin", "arccos", "arctan", "sinh", "cosh", "tanh",
  "log", "ln", "lg", "exp", "lim", "limsup", "liminf", "max", "min", "sup", "inf", "det", "dim", "ker", "deg",
  "gcd", "arg", "Pr", "hom", "tr", "rank" }) do FUNCS[n] = true end

local BB = { R = "ℝ", N = "ℕ", Z = "ℤ", Q = "ℚ", C = "ℂ", P = "ℙ", H = "ℍ", F = "𝔽", E = "𝔼", A = "𝔸" }
local CAL = {
  A = "𝒜", B = "ℬ", C = "𝒞", D = "𝒟", E = "ℰ", F = "ℱ", G = "𝒢", H = "ℋ", I = "ℐ", J = "𝒥", K = "𝒦",
  L = "ℒ", M = "ℳ", N = "𝒩", O = "𝒪", P = "𝒫", Q = "𝒬", R = "ℛ", S = "𝒮", T = "𝒯", U = "𝒰", V = "𝒱",
  W = "𝒲", X = "𝒳", Y = "𝒴", Z = "𝒵",
}
local COMB = { hat = "̂", widehat = "̂", bar = "̄", overline = "̄", vec = "⃗", tilde = "̃", widetilde = "̃", dot = "̇", ddot = "̈" }

local SUP = {
  ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴", ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷",
  ["8"] = "⁸", ["9"] = "⁹", ["+"] = "⁺", ["-"] = "⁻", ["−"] = "⁻", ["="] = "⁼", ["("] = "⁽", [")"] = "⁾",
  a = "ᵃ", b = "ᵇ", c = "ᶜ", d = "ᵈ", e = "ᵉ", f = "ᶠ", g = "ᵍ", h = "ʰ", i = "ⁱ", j = "ʲ", k = "ᵏ", l = "ˡ",
  m = "ᵐ", n = "ⁿ", o = "ᵒ", p = "ᵖ", r = "ʳ", s = "ˢ", t = "ᵗ", u = "ᵘ", v = "ᵛ", w = "ʷ", x = "ˣ", y = "ʸ",
  z = "ᶻ", T = "ᵀ", ["′"] = "′", ["*"] = "*", ["∗"] = "*",
}
local SUB = {
  ["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃", ["4"] = "₄", ["5"] = "₅", ["6"] = "₆", ["7"] = "₇",
  ["8"] = "₈", ["9"] = "₉", ["+"] = "₊", ["-"] = "₋", ["−"] = "₋", ["="] = "₌", ["("] = "₍", [")"] = "₎",
  a = "ₐ", e = "ₑ", h = "ₕ", i = "ᵢ", j = "ⱼ", k = "ₖ", l = "ₗ", m = "ₘ", n = "ₙ", o = "ₒ", p = "ₚ", r = "ᵣ",
  s = "ₛ", t = "ₜ", u = "ᵤ", v = "ᵥ", x = "ₓ", ["β"] = "ᵦ", ["γ"] = "ᵧ", ["ρ"] = "ᵨ", ["φ"] = "ᵩ", ["χ"] = "ᵪ",
}
local FRAC = { ["1/2"] = "½", ["1/3"] = "⅓", ["2/3"] = "⅔", ["1/4"] = "¼", ["3/4"] = "¾", ["1/5"] = "⅕", ["1/6"] = "⅙", ["1/8"] = "⅛" }

local function width(s) return fn.strdisplaywidth(s) end

local function script(kind, str)
  str = vim.trim(str)
  if str == "" then return "" end
  local map, out = kind == "^" and SUP or SUB, {}
  for ch in str:gmatch(UTF8) do
    local m = map[ch]
    if not m then out = nil; break end
    out[#out + 1] = m
  end
  if out then return table.concat(out) end
  if fn.strchars(str) == 1 then return kind .. str end
  return kind .. "(" .. str .. ")"
end

local function simple(s)
  return s ~= "" and not s:find("[%s%+%-/=<>(),]") and not s:find("−", 1, true)
    and not s:find("·", 1, true) and not s:find("×", 1, true)
end

local function fraction(a, b)
  local key = a .. "/" .. b
  if FRAC[key] then return FRAC[key] end
  return (simple(a) and a or "(" .. a .. ")") .. "/" .. (simple(b) and b or "(" .. b .. ")")
end

local function wrap(s) return simple(s) and s or "(" .. s .. ")" end

local function root(n, x)
  if n == "3" then return "∛" .. wrap(x) end
  if n == "4" then return "∜" .. wrap(x) end
  if n and n ~= "" then return script("^", n) .. "√" .. wrap(x) end
  return "√" .. wrap(x)
end

---------------------------------------------------------------------------
-- Delimiter helpers
---------------------------------------------------------------------------

local function close_delim(s, i, open, close)
  local depth = 0
  while i <= #s do
    local c = s:sub(i, i)
    if c == "\\" then
      i = i + 1
    elseif c == open then
      depth = depth + 1
    elseif c == close then
      depth = depth - 1
      if depth == 0 then return i end
    end
    i = i + 1
  end
end

--- one LaTeX argument: {group}, \command, or a single character
local function read_arg(s, i)
  i = s:find("%S", i) or (#s + 1)
  local c = s:sub(i, i)
  if c == "{" then
    local j = close_delim(s, i, "{", "}") or #s
    return s:sub(i + 1, j - 1), j + 1
  elseif c == "\\" then
    local name = s:match("^\\(%a+)", i)
    if name then return "\\" .. name, i + 1 + #name end
    return s:sub(i, i + 1), i + 2
  end
  return c, i + 1
end

local function split_top(str, seps)
  local parts, depth, cur, i, n = {}, 0, {}, 1, #str
  while i <= n do
    local c = str:sub(i, i)
    if c == '"' then
      local j = str:find('"', i + 1, true) or n
      cur[#cur + 1] = str:sub(i, j)
      i = j
    elseif c == "(" or c == "[" or c == "{" then
      depth = depth + 1
      cur[#cur + 1] = c
    elseif c == ")" or c == "]" or c == "}" then
      depth = depth - 1
      cur[#cur + 1] = c
    elseif depth == 0 and seps:find(c, 1, true) then
      parts[#parts + 1] = table.concat(cur)
      cur = {}
    else
      cur[#cur + 1] = c
    end
    i = i + 1
  end
  parts[#parts + 1] = table.concat(cur)
  for k, p in ipairs(parts) do parts[k] = vim.trim(p) end
  return parts
end

local function split_rows(body)
  body = body:gsub("\\\\%[[^%]]*%]", "\\\\")
  local rows, i = {}, 1
  while true do
    local s, e = body:find("\\\\", i, true)
    if not s then
      rows[#rows + 1] = body:sub(i)
      break
    end
    rows[#rows + 1] = body:sub(i, s - 1)
    i = e + 1
  end
  for k, r in ipairs(rows) do rows[k] = vim.trim(r) end
  while #rows > 0 and rows[#rows] == "" do rows[#rows] = nil end
  return rows
end

local function split_cells(row)
  local cells, cur, i = {}, 1, 1
  while true do
    local p = row:find("&", i, true)
    if not p then break end
    if row:sub(p - 1, p - 1) == "\\" then
      i = p + 1
    else
      cells[#cells + 1] = row:sub(cur, p - 1)
      cur, i = p + 1, p + 1
    end
  end
  cells[#cells + 1] = row:sub(cur)
  for k, c in ipairs(cells) do cells[k] = vim.trim(c) end
  return cells
end

---------------------------------------------------------------------------
-- LaTeX math -> Unicode
---------------------------------------------------------------------------

local conv

local MATRIX = {
  pmatrix = { "(", ")" }, bmatrix = { "[", "]" }, Bmatrix = { "{", "}" }, vmatrix = { "|", "|" },
  Vmatrix = { "‖", "‖" }, matrix = { "[", "]" }, smallmatrix = { "[", "]" }, cases = { "{ ", " }" },
}

local function matrix(env, body)
  local rows = {}
  for _, r in ipairs(split_rows(body)) do
    local cells = {}
    for _, c in ipairs(split_cells(r)) do cells[#cells + 1] = conv(c) end
    rows[#rows + 1] = table.concat(cells, env == "cases" and ", " or " ")
  end
  local d = MATRIX[env] or { "", "" }
  return d[1] .. table.concat(rows, "; ") .. d[2]
end

local FORMAT_CMDS = {
  text = 1, mathrm = 1, textrm = 1, mathit = 1, mathbf = 1, boldsymbol = 1, bm = 1, operatorname = 1,
  mathsf = 1, mathtt = 1, textbf = 1, textit = 1, emph = 1, mbox = 1, hbox = 1, textsf = 1, texttt = 1,
  underline = 1, mathnormal = 1, displaystyle = 0, textstyle = 0, scriptstyle = 0, limits = 0, nolimits = 0,
  nonumber = 0, notag = 0, big = 0, Big = 0, bigg = 0, Bigg = 0, left = 0, right = 0, middle = 0, quad = 0,
}

conv = function(s)
  local out, i, n = {}, 1, #s
  while i <= n do
    local c = s:sub(i, i)
    if c == "\\" then
      local name = s:match("^\\(%a+)", i)
      if name then
        i = i + 1 + #name
        if name == "frac" or name == "dfrac" or name == "tfrac" or name == "cfrac" then
          local a, b
          a, i = read_arg(s, i)
          b, i = read_arg(s, i)
          out[#out + 1] = fraction(conv(a), conv(b))
        elseif name == "binom" then
          local a, b
          a, i = read_arg(s, i)
          b, i = read_arg(s, i)
          out[#out + 1] = "(" .. conv(a) .. " choose " .. conv(b) .. ")"
        elseif name == "sqrt" then
          local nth
          if s:sub(i, i) == "[" then
            local j = s:find("]", i, true) or i
            nth, i = s:sub(i + 1, j - 1), j + 1
          end
          local a
          a, i = read_arg(s, i)
          out[#out + 1] = root(nth and conv(nth), conv(a))
        elseif name == "begin" then
          local env = s:match("^{([%w%*]+)}", i)
          local es, ee = nil, nil
          if env then
            i = i + #env + 2
            es, ee = s:find("\\end{" .. env .. "}", i, true)
          end
          if es then
            out[#out + 1] = matrix((env:gsub("%*$", "")), s:sub(i, es - 1))
            i = ee + 1
          end
        elseif name == "end" then
          local _, e = s:find("^{[%w%*]+}", i)
          if e then i = e + 1 end
        elseif name == "mathbb" or name == "mathcal" or name == "mathscr" then
          local a
          a, i = read_arg(s, i)
          local map = name == "mathbb" and BB or CAL
          out[#out + 1] = (a:gsub(".", function(ch) return map[ch] or ch end))
        elseif COMB[name] then
          local a
          a, i = read_arg(s, i)
          local inner = conv(a)
          out[#out + 1] = fn.strchars(inner) == 1 and (inner .. COMB[name]) or inner
        elseif name == "label" or name == "nonumber" or name == "notag" then
          if name == "label" then
            local _drop
            _drop, i = read_arg(s, i)
          end
        elseif name == "tag" then
          local a
          a, i = read_arg(s, i)
          out[#out + 1] = "  (" .. conv(a) .. ")"
        elseif name == "pmod" then
          local a
          a, i = read_arg(s, i)
          out[#out + 1] = " (mod " .. conv(a) .. ")"
        elseif name == "bmod" or name == "mod" then
          out[#out + 1] = " mod "
        elseif name == "left" or name == "right" then
          if s:sub(i, i) == "." then i = i + 1 end
        elseif FORMAT_CMDS[name] == 1 then
          local a
          a, i = read_arg(s, i)
          out[#out + 1] = conv(a)
        elseif FORMAT_CMDS[name] == 0 then
          -- drop
        elseif GREEK[name] then
          out[#out + 1] = GREEK[name]
        elseif SYM[name] then
          out[#out + 1] = SYM[name]
        elseif FUNCS[name] then
          out[#out + 1] = name
        else
          out[#out + 1] = name
        end
      else
        local nx = s:sub(i + 1, i + 1)
        i = i + 2
        if nx == "," or nx == ";" or nx == ":" or nx == " " then
          out[#out + 1] = " "
        elseif nx == "!" then
          -- negative thin space
        elseif nx == "\\" then
          out[#out + 1] = " ⏎ "
        elseif nx == "|" then
          out[#out + 1] = "‖"
        else
          out[#out + 1] = nx
        end
      end
    elseif c == "^" or c == "_" then
      local a
      a, i = read_arg(s, i + 1)
      out[#out + 1] = script(c, conv(a))
    elseif c == "{" then
      local j = close_delim(s, i, "{", "}") or n
      out[#out + 1] = conv(s:sub(i + 1, j - 1))
      i = j + 1
    elseif c == "}" or c == "~" then
      out[#out + 1] = c == "~" and " " or ""
      i = i + 1
    elseif c == "'" then
      out[#out + 1] = "′"
      i = i + 1
    elseif c == "-" and s:sub(i - 1, i - 1) ~= "" and s:sub(i + 1, i + 1) ~= "" and s:sub(i + 1, i + 1) ~= "-" then
      out[#out + 1] = "−"
      i = i + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return (table.concat(out):gsub("%s+", " "))
end

local ALIGN = {
  align = 1, flalign = 1, alignat = 1, xalignat = 1, xxalignat = 1, eqnarray = 1, aligned = 1,
  alignedat = 1, split = 1, IEEEeqnarray = 1,
}
local STACK = { gather = 1, multline = 1, gathered = 1, dgroup = 1, dseries = 1, subequations = 1 }

local function clean_row(r)
  r = r:gsub("\\label%b{}", ""):gsub("\\nonumber", ""):gsub("\\notag", "")
  return r
end

--- rows of an align-like environment, aligned on '&'
local function align_rows(body)
  local rows, ncol = {}, 0
  for _, r in ipairs(split_rows(body)) do
    local cells = split_cells(clean_row(r))
    for k, c in ipairs(cells) do cells[k] = conv(c) end
    ncol = math.max(ncol, #cells)
    rows[#rows + 1] = cells
  end
  local w = {}
  for c = 1, ncol do
    w[c] = 0
    for _, r in ipairs(rows) do w[c] = math.max(w[c], width(r[c] or "")) end
  end
  local lines = {}
  for _, r in ipairs(rows) do
    local parts = {}
    for c = 1, ncol do
      local cell = r[c] or ""
      local pad = (" "):rep(w[c] - width(cell))
      parts[#parts + 1] = (c % 2 == 1) and (pad .. cell) or (cell .. pad)
      if c < ncol then parts[#parts + 1] = (c % 2 == 1) and " " or "    " end
    end
    lines[#lines + 1] = (table.concat(parts):gsub("%s+$", ""))
  end
  return lines
end

local function latex_math(src)
  local s = vim.trim(src)
  local name, body = s:match("^\\begin{([%w%*]+)}(.*)\\end{%1}$")
  if name then
    local base = name:gsub("%*$", "")
    body = vim.trim(body)
    if base == "subequations" then body = body:gsub("\\begin%b{}", ""):gsub("\\end%b{}", "") end
    if ALIGN[base] or base == "subequations" then return align_rows(body), false end
    if STACK[base] then
      local lines = {}
      for _, r in ipairs(split_rows(body)) do lines[#lines + 1] = conv(clean_row(r)) end
      return lines, true
    end
    return { conv(clean_row(body)) }, false
  end
  local inner = s:match("^%$%$(.-)%$%$$") or s:match("^%$(.-)%$$") or s:match("^\\%[(.-)\\%]$") or s:match("^\\%((.-)\\%)$") or s
  return { conv(inner) }, false
end

---------------------------------------------------------------------------
-- Typst math -> Unicode
---------------------------------------------------------------------------

local TYP_SYM = {
  infinity = "∞", sum = "∑", product = "∏", integral = "∫", ["integral.double"] = "∬", ["integral.cont"] = "∮",
  partial = "∂", nabla = "∇", dot = "⋅", times = "×", ["plus.minus"] = "±", ["minus.plus"] = "∓",
  ["arrow.r"] = "→", ["arrow.l"] = "←", ["arrow.r.double"] = "⇒", ["arrow.l.double"] = "⇐",
  ["arrow.l.r"] = "↔", ["arrow.l.r.double"] = "⇔", ["lt.eq"] = "≤", ["gt.eq"] = "≥", ["eq.not"] = "≠",
  approx = "≈", ["in"] = "∈", ["in.not"] = "∉", subset = "⊂", ["subset.eq"] = "⊆", union = "∪", inter = "∩",
  ["forall"] = "∀", exists = "∃", ["not"] = "¬", ["and"] = "∧", ["or"] = "∨", dots = "…", ["dots.h"] = "…",
  ["dots.c"] = "⋯", ["dots.v"] = "⋮", prime = "′", angle = "∠", perp = "⊥", ["compose"] = "∘", emptyset = "∅",
  ["divides"] = "∣", ["tilde.op"] = "∼", ["lt.double"] = "≪", ["gt.double"] = "≫", ["plus.circle"] = "⊕",
  ["times.circle"] = "⊗", ["ell"] = "ℓ", ["planck.reduce"] = "ℏ", ["Re"] = "ℜ", ["Im"] = "ℑ",
}
local TYP_OP3 = { ["<=>"] = "⇔", ["..."] = "…" }
local TYP_OP2 = { ["<="] = "≤", [">="] = "≥", ["!="] = "≠", ["->"] = "→", ["=>"] = "⇒", ["<-"] = "←", ["<<"] = "≪", [">>"] = "≫" }

local typ

local function typ_close(s, pos)
  local depth, i = 0, pos
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      i = (s:find('"', i + 1, true) or #s)
    elseif c == "(" then
      depth = depth + 1
    elseif c == ")" then
      depth = depth - 1
      if depth == 0 then return i end
    end
    i = i + 1
  end
end

local TYP_CALL = {
  sqrt = function(a) return root(nil, typ(a[1] or "")) end,
  root = function(a) return root(typ(a[1] or ""), typ(a[2] or "")) end,
  frac = function(a) return fraction(typ(a[1] or ""), typ(a[2] or "")) end,
  binom = function(a) return "(" .. typ(a[1] or "") .. " choose " .. typ(a[2] or "") .. ")" end,
  abs = function(a) return "|" .. typ(a[1] or "") .. "|" end,
  norm = function(a) return "‖" .. typ(a[1] or "") .. "‖" end,
  floor = function(a) return "⌊" .. typ(a[1] or "") .. "⌋" end,
  ceil = function(a) return "⌈" .. typ(a[1] or "") .. "⌉" end,
  vec = function(a)
    local t = {}
    for _, x in ipairs(a) do t[#t + 1] = typ(x) end
    return "(" .. table.concat(t, ", ") .. ")"
  end,
  bb = function(a) return (a[1] or ""):gsub(".", function(ch) return BB[ch] or ch end) end,
  cal = function(a) return (a[1] or ""):gsub(".", function(ch) return CAL[ch] or ch end) end,
}
for _, n in ipairs({ "upright", "bold", "italic", "display", "inline", "op", "serif", "sans", "mono", "limits", "scripts" }) do
  TYP_CALL[n] = function(a) return typ(a[1] or "") end
end

typ = function(s)
  local out, i, n = {}, 1, #s
  while i <= n do
    local c = s:sub(i, i)
    if c == '"' then
      local j = s:find('"', i + 1, true) or (n + 1)
      out[#out + 1] = s:sub(i + 1, j - 1)
      i = j + 1
    elseif c:match("%a") then
      local w = s:match("^%a[%w%.]*", i):gsub("%.$", "")
      local after = i + #w
      local fnc = TYP_CALL[w]
      local close = (s:sub(after, after) == "(") and typ_close(s, after)
      if close and (fnc or w == "mat" or w == "cases") then
        local inner = s:sub(after + 1, close - 1)
        if w == "mat" or w == "cases" then
          local rows = {}
          for _, r in ipairs(split_top(inner, ";")) do
            local cells = {}
            for _, cell in ipairs(split_top(r, ",")) do cells[#cells + 1] = typ(cell) end
            rows[#rows + 1] = table.concat(cells, w == "cases" and ", " or " ")
          end
          out[#out + 1] = (w == "cases" and "{ " or "[") .. table.concat(rows, "; ") .. (w == "cases" and " }" or "]")
        else
          out[#out + 1] = fnc(split_top(inner, ","))
        end
        i = close + 1
      else
        out[#out + 1] = TYP_SYM[w] or GREEK[w] or w
        i = after
      end
    elseif c == "^" or c == "_" then
      local arg, j
      if s:sub(i + 1, i + 1) == "(" then
        local close = typ_close(s, i + 1) or n
        arg, j = s:sub(i + 2, close - 1), close + 1
      else
        arg = s:match("^[%w]+", i + 1) or s:sub(i + 1, i + 1)
        j = i + 1 + #arg
      end
      out[#out + 1] = script(c, typ(arg))
      i = j
    elseif TYP_OP3[s:sub(i, i + 2)] then
      out[#out + 1] = TYP_OP3[s:sub(i, i + 2)]
      i = i + 3
    elseif TYP_OP2[s:sub(i, i + 1)] then
      out[#out + 1] = TYP_OP2[s:sub(i, i + 1)]
      i = i + 2
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return (table.concat(out):gsub("%s+", " "))
end

local function typst_math(src)
  local inner = src:match("^%$(.*)%$$") or src
  local lines = {}
  for _, l in ipairs(split_top(vim.trim(inner), "\n")) do
    if l ~= "" then lines[#lines + 1] = typ(l) end
  end
  if #lines == 0 then lines[1] = "" end
  return lines, false
end

---------------------------------------------------------------------------
-- Plain text (cells, captions, headings)
---------------------------------------------------------------------------

local function plain(s, lang)
  if lang == "typst" then
    s = s:gsub("%$(.-)%$", function(m) return typ(vim.trim(m)) end)
    return (s:gsub("[*_]", ""))
  end
  if lang == "markdown" then s = s:gsub("%*%*", ""):gsub("`", "") end
  s = s:gsub("%$(.-)%$", function(m) return conv(m) end)
  -- unwrap \textbf{x} style commands, keep their argument
  for _ = 1, 3 do
    s = s:gsub("\\%a+%*?(%b{})", function(g) return g:sub(2, -2) end)
  end
  s = s:gsub("\\([%%&_#$%^{}])", "%1"):gsub("\\%a+", ""):gsub("[{}]", ""):gsub("~", " ")
  return (vim.trim((s:gsub("%s+", " "))))
end

---------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------

local function box(rows, rules)
  local ncol, w = 0, {}
  for _, r in ipairs(rows) do ncol = math.max(ncol, #r) end
  for c = 1, ncol do
    w[c] = 1
    for _, r in ipairs(rows) do w[c] = math.max(w[c], width(r[c] or "")) end
  end
  local function rule(l, m, r)
    local seg = {}
    for c = 1, ncol do seg[c] = ("─"):rep(w[c] + 2) end
    return l .. table.concat(seg, m) .. r
  end
  local lines = { rule("┌", "┬", "┐") }
  for ri, r in ipairs(rows) do
    local seg = {}
    for c = 1, ncol do
      local cell = r[c] or ""
      seg[c] = " " .. cell .. (" "):rep(w[c] - width(cell)) .. " "
    end
    lines[#lines + 1] = "│" .. table.concat(seg, "│") .. "│"
    if rules[ri] and ri < #rows then lines[#lines + 1] = rule("├", "┼", "┤") end
  end
  lines[#lines + 1] = rule("└", "┴", "┘")
  return lines
end

local TABLE_ENVS = { "tabular*", "tabularx", "tabulary", "tabular", "longtable", "xltabular" }
local RULE_PAT = { "\\hline", "\\toprule", "\\midrule", "\\bottomrule", "\\cline%b{}", "\\cmidrule%b()%b{}", "\\cmidrule%b{}" }

local function latex_table(src, lang)
  local body
  for _, env in ipairs(TABLE_ENVS) do
    local s, e = src:find("\\begin{" .. env .. "}", 1, true)
    if s then
      local i = e + 1
      for _ = 1, (env == "tabular" or env == "longtable") and 1 or 2 do
        local _, ge = src:find("^%s*%b[]", i)
        if ge then i = ge + 1 end
        local _, ce = src:find("^%s*%b{}", i)
        if ce then i = ce + 1 end
      end
      local es = src:find("\\end{" .. env .. "}", i, true)
      body = src:sub(i, (es or #src + 1) - 1)
      break
    end
  end
  if not body then return nil end
  local rows, rules = {}, {}
  for _, raw in ipairs(split_rows(body)) do
    local before = false
    for _, pat in ipairs(RULE_PAT) do
      if raw:find("^%s*" .. pat) then before = true end
    end
    local stripped = raw
    for _ = 1, 3 do
      for _, pat in ipairs(RULE_PAT) do stripped = stripped:gsub(pat, "") end
    end
    stripped = vim.trim(stripped)
    if before and #rows > 0 then rules[#rows] = true end
    if stripped ~= "" then
      local cells = {}
      for _, cell in ipairs(split_cells(stripped)) do
        local span, text = cell:match("^\\multicolumn{(%d+)}%b{}(%b{})$")
        if span then
          cells[#cells + 1] = plain(text:sub(2, -2), lang)
          for _ = 2, tonumber(span) do cells[#cells + 1] = "" end
        else
          local mr = cell:match("^\\multirow%b{}%b{}(%b{})$")
          cells[#cells + 1] = plain(mr and mr:sub(2, -2) or cell, lang)
        end
      end
      rows[#rows + 1] = cells
    end
  end
  if #rows == 0 then return nil end
  return box(rows, rules)
end

local function typst_table(src, lang)
  local s, e = src:find("table%s*%(")
  if not s then return nil end
  local close = typ_close(src, e)
  local inner = src:sub(e + 1, (close or #src + 1) - 1)
  local ncol = 1
  local cols = inner:match("columns:%s*(%b())")
  if cols then
    ncol = #split_top(cols:sub(2, -2), ",")
  else
    ncol = tonumber(inner:match("columns:%s*(%d+)")) or 1
  end
  local cells, header = {}, inner:find("table%.header", 1) ~= nil
  local function add(arg)
    arg = vim.trim(arg)
    if arg:sub(1, 1) == "[" then
      cells[#cells + 1] = plain(arg:sub(2, -2), lang)
    elseif arg:sub(1, 1) == '"' then
      cells[#cells + 1] = arg:sub(2, -2)
    elseif arg:match("^table%.header%s*%(") then
      local c2 = typ_close(arg, arg:find("%(")) or #arg
      for _, a in ipairs(split_top(arg:sub(arg:find("%(") + 1, c2 - 1), ",")) do
        if a:sub(1, 1) == "[" or a:sub(1, 1) == '"' then add(a) end
      end
    end
  end
  for _, a in ipairs(split_top(inner, ",")) do add(a) end
  local rows, rules = {}, {}
  for i = 1, #cells, ncol do
    local r = {}
    for c = 0, ncol - 1 do r[#r + 1] = cells[i + c] or "" end
    rows[#rows + 1] = r
  end
  if #rows == 0 then return nil end
  if header then rules[1] = true end
  return box(rows, rules)
end


---------------------------------------------------------------------------
-- User macros (\newcommand, \DeclareMathOperator, \def) from the document preamble
---------------------------------------------------------------------------

local function parse_macros(text)
  local defs = {}
  local function name_at(s, i)
    local n, e = s:match("^%s*{\\(%a+)}()", i)
    if not n then n, e = s:match("^%s*\\(%a+)()", i) end
    return n, e
  end
  for _, cmd in ipairs({ "newcommand", "renewcommand", "providecommand" }) do
    local i = 1
    while true do
      local s0, e0 = text:find("\\" .. cmd .. "%*?", i)
      if not s0 then break end
      local name, p = name_at(text, e0 + 1)
      i = e0 + 1
      if name then
        local nargs = 0
        local n, p2 = text:match("^%s*%[(%d)%]()", p)
        if n then nargs, p = tonumber(n), p2 end
        local opt = text:match("^%s*%b[]()", p) -- default value of #1: not supported, skip it
        if opt then p = opt end
        local bs = text:find("{", p, true)
        local be = bs and close_delim(text, bs, "{", "}")
        if bs and be and text:sub(p, bs - 1):match("^%s*$") then
          defs[name] = { n = nargs, body = text:sub(bs + 1, be - 1) }
          i = be + 1
        end
      end
    end
  end
  local i = 1
  while true do -- \DeclareMathOperator{\name}{text}
    local s0, e0 = text:find("\\DeclareMathOperator%*?", i)
    if not s0 then break end
    local name, p = name_at(text, e0 + 1)
    i = e0 + 1
    local bs = name and text:find("{", p, true)
    local be = bs and close_delim(text, bs, "{", "}")
    if name and be then
      defs[name] = { n = 0, body = "\\operatorname{" .. text:sub(bs + 1, be - 1) .. "}" }
      i = be + 1
    end
  end
  for name, body in text:gmatch("\\def\\(%a+)(%b{})") do defs[name] = defs[name] or { n = 0, body = body:sub(2, -2) } end
  return defs
end

local function expand_macros(src, defs)
  if next(defs) == nil then return src end
  for _ = 1, 6 do
    local changed, out, i = false, {}, 1
    while i <= #src do
      local bs = src:find("\\", i, true)
      if not bs then break end
      local name = src:match("^\\(%a+)", bs)
      local d = name and defs[name]
      if d then
        out[#out + 1] = src:sub(i, bs - 1)
        local j, args = bs + 1 + #name, {}
        for k = 1, d.n do args[k], j = read_arg(src, j) end
        out[#out + 1] = (d.body:gsub("#(%d)", function(k) return args[tonumber(k)] or "" end))
        i, changed = j, true
      else
        out[#out + 1] = src:sub(i, bs + (name and #name or 0))
        i = bs + 1 + (name and #name or 1)
      end
    end
    out[#out + 1] = src:sub(i)
    src = table.concat(out)
    if not changed then break end
  end
  return src
end

---------------------------------------------------------------------------
-- Public: block -> { lines, hl, center, center_each }
---------------------------------------------------------------------------

local function frame(title, body)
  local w = math.max(width(title), width(body or "")) + 2
  local lines = { "╭─ " .. title .. " " .. ("─"):rep(math.max(0, w - width(title) - 3)) .. "╮" }
  if body and body ~= "" then lines[#lines + 1] = "│ " .. body .. (" "):rep(w - width(body) - 1) .. "│" end
  lines[#lines + 1] = "╰" .. ("─"):rep(w) .. "╯"
  return lines
end

--- Render block `b` of state `S` as text, or nil when nothing sensible exists.
function T.render(S, b)
  local lang, k = S.lang, b.kind
  if lang ~= "typst" and type(S.pre) == "table" and S.pre.macros ~= "" then
    if S._macro_src ~= S.pre.macros then
      S._macro_src, S._macros = S.pre.macros, parse_macros(S.pre.macros)
    end
    if next(S._macros) ~= nil then
      b = vim.tbl_extend("force", {}, b, { src = expand_macros(b.src, S._macros) })
      if b.title then b.title = expand_macros(b.title, S._macros) end
    end
  end
  if k == "inline" or k == "display" then
    local lines, each
    if lang == "typst" then lines, each = typst_math(b.src) else lines, each = latex_math(b.src) end
    if b.mode == "inline" then return { lines = { table.concat(lines, " ") }, hl = "MIPInline" } end
    return { lines = lines, hl = "MIPBlock", center = true, center_each = each }
  elseif k == "table" then
    local lines
    if lang == "typst" then lines = typst_table(b.src, lang) else lines = latex_table(b.body or b.src, lang) end
    if b.mode == "inline" then return nil end
    return lines and { lines = lines, hl = "MIPTable", center = true }
  elseif k == "figure" then
    if b.mode == "inline" then return nil end
    local caption, file
    if lang == "typst" then
      caption = b.src:match("caption:%s*%[(.-)%]")
      file = b.src:match('image%s*%(%s*"([^"]+)"')
    else
      local c = b.src:match("\\caption%s*%b[]%s*(%b{})") or b.src:match("\\caption%s*(%b{})")
      caption = c and c:sub(2, -2)
      file = b.src:match("\\includegraphics%s*%b[]%s*{([^}]+)}") or b.src:match("\\includegraphics%s*{([^}]+)}")
    end
    local label = b.env == "tikzpicture" and "TikZ picture" or "Figure"
    local text = {}
    if caption then text[#text + 1] = plain(caption, lang) end
    if file then text[#text + 1] = "(" .. file .. ")" end
    return { lines = frame("󰋩 " .. label, table.concat(text, " ")), hl = "MIPFigure", center = true }
  elseif k == "image" then
    if b.mode == "inline" then return nil end
    local label = (b.alt and b.alt ~= "") and (b.alt .. " (" .. b.file .. ")") or b.file
    return { lines = frame("󰋩 Image", label), hl = "MIPFigure", center = true }
  elseif k == "section" then
    local prefix = ({ "▌ ", "▎ ", "▏ ", "  " })[b.level] or "  "
    return { lines = { prefix .. plain(b.title, lang) }, hl = "MIPHeading" .. math.min(b.level or 1, 4), center = false }
  end
end

return T
