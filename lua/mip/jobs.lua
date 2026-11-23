--- Builds render tasks (see render.lua) from blocks.
---
--- LaTeX pipelines (picked automatically, best first):
---   dvisvgm  : latex -> DVI -> dvisvgm --no-fonts   (vector SVG, exact bboxes, tikz/pgf native)
---   pdf-svg  : pdflatex|lualatex|xelatex|tectonic -> PDF -> pdftocairo -svg
---   pdf-png  : same engines -> pdftocairo -png       (no SVG rasteriser installed; not scalable)
--- Typst: `typst compile --format svg` (png when no SVG rasteriser is installed).
local config = require("mip.config")
local util = require("mip.util")
local TF = require("mip.typst_file")
local fn = vim.fn

local J = {}

---------------------------------------------------------------------------
-- Preambles
---------------------------------------------------------------------------

local TEX_PKGS = {}
for _, n in ipairs({
  "amsmath", "amssymb", "amsfonts", "amsthm", "mathtools", "bm", "physics", "siunitx", "braket",
  "mathrsfs", "cancel", "tikz", "pgfplots", "tikz-cd", "xfrac", "stmaryrd", "bbm", "dsfont",
  "mathdots", "esint", "centernot", "booktabs", "array", "multirow", "xcolor", "graphicx",
}) do TEX_PKGS[n] = true end

local MACRO_PFX = {
  "\\newcommand", "\\renewcommand", "\\providecommand", "\\DeclareMathOperator",
  "\\DeclarePairedDelimiter", "\\def", "\\let", "\\newtheorem",
}

local function count(s, ch)
  local _, n = s:gsub("%" .. ch, "")
  return n
end

local function balance(s, o, c)
  s = s:gsub("\\%" .. o, ""):gsub("\\%" .. c, "")
  return count(s, o) - count(s, c)
end

local function head_lines(S, max)
  local nl = vim.api.nvim_buf_line_count(S.buf)
  return vim.api.nvim_buf_get_lines(S.buf, 0, math.min(nl, max or 300), false)
end

--- { pkgs, macros, extra, full }: pieces reused from the buffer / config.
---   full   = the document's own preamble (\documentclass .. before \begin{document})
---   pkgs   = whitelisted math packages, macros = \newcommand-style definitions (safe mode)
local function tex_preamble(S)
  local cfg = config.values.latex
  local pkgs, macros, full = {}, {}, nil
  local function add_header(h)
    if h:find("\\usepackage", 1, true) then pkgs[#pkgs + 1] = h else macros[#macros + 1] = h end
  end
  if S.lang == "org" then
    for _, l in ipairs(head_lines(S)) do
      local h = l:match("^#%+[Ll][Aa][Tt][Ee][Xx]_[Hh][Ee][Aa][Dd][Ee][Rr]%S*:%s*(.*)$")
      if h then add_header(h) end
    end
  elseif S.lang == "markdown" then
    -- YAML front matter: header-includes / any line that is raw LaTeX
    local lines = head_lines(S, 300)
    if lines[1] == "---" then
      for i = 2, #lines do
        local l = lines[i]
        if l == "---" or l == "..." then break end
        local t = l:match("^%s*%-?%s*|?%s*(\\%a.*)$")
        if t then add_header(t) end
      end
    end
  elseif cfg.buffer_preamble then
    local lines = head_lines(S, 4000)
    local doc_at
    for i, l in ipairs(lines) do
      if l:find("\\begin{document}", 1, true) then doc_at = i break end
    end
    if doc_at and cfg.preamble_mode == "full" and lines[1] ~= nil then
      full = table.concat(vim.list_slice(lines, 1, doc_at - 1), "\n")
      if not full:find("\\documentclass", 1, true) then full = nil end
    end
    local pend, depth
    for i, l in ipairs(lines) do
      if doc_at and i >= doc_at then break end
      if pend then
        pend = pend .. "\n" .. l
        depth = depth + balance(l, "{", "}")
        if depth <= 0 then macros[#macros + 1] = pend pend = nil end
      else
        local t, keep = vim.trim(l), false
        for _, pfx in ipairs(MACRO_PFX) do
          if vim.startswith(t, pfx) then keep = true break end
        end
        if keep then
          depth = balance(l, "{", "}")
          if depth <= 0 then macros[#macros + 1] = l else pend = l end
        else
          local pk = l:match("^%s*\\usepackage[^{]*{([^}]+)}")
          if pk then
            local all = true
            for name in pk:gmatch("[^,%s]+") do
              if not TEX_PKGS[name] then all = false end
            end
            if all then pkgs[#pkgs + 1] = l end
          end
        end
      end
    end
  end
  return {
    pkgs = table.concat(pkgs, "\n"), macros = table.concat(macros, "\n"),
    extra = cfg.preamble or "", full = full,
  }
end

local function typst_preamble(S)
  local cfg = config.values.typst
  local out = { cfg.preamble or "" }
  if cfg.buffer_preamble then
    local pend, depth
    for _, l in ipairs(head_lines(S, 4000)) do
      if pend then
        pend = pend .. "\n" .. l
        depth = depth + balance(l, "(", ")") + balance(l, "[", "]") + balance(l, "{", "}")
        if depth <= 0 then out[#out + 1] = pend pend = nil end
      elseif l:match("^#let%s") or l:match("^#import%s") or l:match("^#set%s")
        or l:match("^#show%s+[^:%s]") then -- top-level directives; `#show:` templates are skipped
        depth = balance(l, "(", ")") + balance(l, "[", "]") + balance(l, "{", "}")
        if depth <= 0 then out[#out + 1] = l else pend = l end
      end
    end
  end
  return table.concat(out, "\n")
end

function J.preamble(S)
  return S.lang == "typst" and typst_preamble(S) or tex_preamble(S)
end

---------------------------------------------------------------------------
-- LaTeX
---------------------------------------------------------------------------

local SIZES = { "\\LARGE", "\\Large", "\\large", "\\normalsize" }

--- strip float wrappers (they would be placed by the float algorithm)
local function unfloat(src, env)
  local base = env:gsub("%*$", "")
  local s = src:gsub("^\\begin%b{}", "", 1)
  s = s:gsub("^%s*%b[]", "", 1)
  s = s:gsub("\\end%b{}%s*$", "", 1)
  s = s:gsub("\\caption([%s%[{])", "\\captionof{" .. base .. "}%1")
  return s
end

local function tex_body(b)
  if b.body then return b.body end
  if b.kind == "section" then
    return ("{\\bfseries%s\\strut %s}"):format(SIZES[b.level] or "\\normalsize", b.title)
  end
  if (b.kind == "table" or b.kind == "figure") and b.env and (b.env:find("^table") or b.env:find("^figure")) then
    return "\\centering\n" .. unfloat(b.src, b.env)
  end
  return b.src
end

local function tex_pipeline()
  local cfg = config.values.latex
  local rast = util.rasterizer()
  local want = cfg.backend
  if (want == "auto" or want == "dvisvgm") and util.exe(cfg.dvi_engine) and util.exe("dvisvgm") and rast then
    return "dvisvgm"
  end
  if want == "dvisvgm" then
    return nil, "latex.backend = 'dvisvgm' needs latex, dvisvgm and an SVG rasteriser (rsvg-convert/resvg/inkscape/magick)"
  end
  if util.exe(cfg.engine) then
    if util.exe("pdftocairo") then return rast and "pdf-svg" or "pdf-png" end
    if util.exe("magick") then return "pdf-png" end
  end
  return nil, ("no LaTeX pipeline: install latex+dvisvgm, or %s+pdftocairo"):format(cfg.engine)
end

--- `mode` "full": the document's own preamble; "safe": minimal article + extracted macros
local function tex_doc(S, b, pipe, mode)
  local pre, cfg = S.pre, config.values.latex
  local dvi, inline = pipe == "dvisvgm", b.kind == "inline"
  local full = mode == "full" and dvi and pre.full ~= nil
  local body = tex_body(b)
  local all = body .. pre.macros .. pre.pkgs .. pre.extra .. (full and pre.full or "")
  local L = {}
  local function add(s) L[#L + 1] = s end

  if dvi then
    add("\\PassOptionsToPackage{dvisvgm}{graphicx}")
    if full then add(pre.full) else add("\\documentclass[12pt]{article}") end
  elseif inline then
    add("\\documentclass[preview,border=2pt,12pt]{standalone}")
  else
    add("\\documentclass[preview,border=2pt,varwidth=45cm,12pt]{standalone}")
  end
  if not full then add(pre.pkgs) end
  add("\\usepackage{amsmath,amssymb,amsfonts,graphicx,array,xcolor}")
  add("\\IfFileExists{mathtools.sty}{\\usepackage{mathtools}}{}")
  add("\\IfFileExists{booktabs.sty}{\\usepackage{booktabs}}{}")
  add("\\IfFileExists{capt-of.sty}{\\usepackage{capt-of}}{}")
  add("\\providecommand{\\captionof}[2]{\\par\\textbf{#1.} #2\\par}")
  if all:find("tikz", 1, true) then
    if dvi then add("\\def\\pgfsysdriver{pgfsys-dvisvgm.def}") end
    add("\\IfFileExists{tikz.sty}{\\usepackage{tikz}}{}")
  end
  if all:find("pgfplots", 1, true) then
    add("\\IfFileExists{pgfplots.sty}{\\usepackage{pgfplots}\\pgfplotsset{compat=newest}}{}")
  end
  if not cfg.numbering then
    add("\\makeatletter\\def\\tagform@#1{\\maketag@@@{}}\\def\\@eqnnum{}\\makeatother")
  end
  if not full then add(pre.macros) end
  add(pre.extra)
  add("\\newsavebox{\\mipb}")
  if dvi then
    add("\\pagestyle{empty}\\setlength{\\parindent}{0pt}")
    if not full then add((("\\setlength{\\textwidth}{%s}")):format(cfg.numbering and "20cm" or "45cm")) end
    if inline then add("\\usepackage[active,tightpage]{preview}\\setlength\\PreviewBorder{0.5pt}") end
  end
  add("\\begin{document}")
  add("\\color[HTML]{" .. S.fg .. "}")
  if inline then
    local save = "\\savebox{\\mipb}{" .. body .. "}\\typeout{MIPDP:\\the\\dp\\mipb}\\usebox{\\mipb}"
    add(dvi and ("\\begin{preview}" .. save .. "\\end{preview}") or save)
  else
    add(body)
  end
  add("\\end{document}")
  return table.concat(L, "\n"), body
end

function J.tex_master(S, b)
  local cfg = config.values.latex
  local pipe, err = tex_pipeline()
  if not pipe then
    util.warn_once("tex-pipe", err)
    return nil
  end
  local primary = (pipe == "dvisvgm" and cfg.preamble_mode == "full" and S.pre.full) and "full" or "safe"
  local doc, body = tex_doc(S, b, pipe, primary)
  local safe_doc = primary == "full" and (tex_doc(S, b, pipe, "safe")) or nil
  local dpi = math.floor(S.pxpt * 72 + 0.5)
  local dep = ""
  if b.kind == "figure" or b.kind == "table" or b.kind == "image" then
    dep = S.dir .. util.stamp(S, body, { "\\includegraphics%s*%b[]%s*{([^}]+)}", "\\includegraphics%s*{([^}]+)}" })
  end
  local ext = pipe == "pdf-png" and "png" or "svg"
  local hash = fn.sha256(table.concat({ "tex", pipe, cfg.engine, primary, doc, ext == "png" and dpi or 0, dep }, "\0"))
  local border = (pipe == "dvisvgm") and 0.5 or 2

  -- "." first: the generated file must win over a same-named file in the document directory
  local env = { TEXINPUTS = ".:" .. S.dir .. ":" .. (vim.env.TEXINPUTS or "") }
  local have_pdftocairo = util.exe("pdftocairo")

  local function make_steps(dir, meta, text)
    util.write_file(dir .. "/mipdoc.tex", text)
    local function capture(out)
      local dp = out:match("MIPDP:([%-%d%.]+)pt")
      if dp then meta.base = tonumber(dp) + border end
    end
    local flags = { "-interaction=nonstopmode", "-halt-on-error", "-no-shell-escape", "mipdoc.tex" }
    if pipe == "dvisvgm" then
      local compile = { cfg.dvi_engine }
      vim.list_extend(compile, flags)
      local svg = { "dvisvgm", "--no-fonts", "-o", "out.svg", "mipdoc.dvi" }
      table.insert(svg, 2, b.kind == "inline" and "--bbox=preview" or "--exact-bbox")
      return {
        { cmd = compile, cwd = dir, env = env, capture = capture },
        { cmd = svg, cwd = dir },
      }
    end
    local compile = cfg.engine == "tectonic" and { "tectonic", "mipdoc.tex" } or { cfg.engine }
    if cfg.engine ~= "tectonic" then vim.list_extend(compile, flags) end
    local conv
    if pipe == "pdf-svg" then
      conv = { "pdftocairo", "-svg", "mipdoc.pdf", "out.svg" }
    elseif have_pdftocairo then
      conv = { "pdftocairo", "-png", "-r", tostring(dpi), "-singlefile", "-transp", "mipdoc.pdf", "out" }
    else
      conv = { "magick", "-background", "none", "-density", tostring(dpi), "mipdoc.pdf", "-alpha", "on", "out.png" }
    end
    return {
      { cmd = compile, cwd = dir, env = env, capture = capture },
      { cmd = conv, cwd = dir },
    }
  end

  return {
    hash = hash, ext = ext,
    steps = function(dir, meta) return make_steps(dir, meta, doc) end,
    alt = safe_doc and function(dir, meta) return make_steps(dir, meta, safe_doc) end or nil,
  }
end

---------------------------------------------------------------------------
-- Typst
---------------------------------------------------------------------------

function J.typst_master(S, b)
  local cfg = config.values.typst
  if cfg.mode ~= "snippet" then
    local r = TF.lookup(S, b)
    if r == "pending" then return { pending = true } end
    if r then return { hash = r.hash, entry = r } end
    if cfg.mode == "file" then return nil end
  end
  if not util.exe(cfg.cmd) then
    util.warn_once("typst", ("typst executable '%s' not found"):format(cfg.cmd))
    return nil
  end
  local inline = b.kind == "inline"
  local ext = util.rasterizer() and "svg" or "png"
  local dpi = math.floor(S.pxpt * 72 + 0.5)
  -- the file's own directives first, then ours (so the page stays auto-sized)
  local size = S.pre:find("size%s*:") and "" or "size: 12pt, "
  local head = ('#set page(width: auto, height: auto, margin: (x: 1pt, y: %s), fill: none)\n'
    .. '#set text(%sfill: rgb("#%s"), top-edge: "%s", bottom-edge: "%s")\n'
    .. "#set heading(numbering: none)\n"):format(
    inline and "4pt" or "2pt", size, S.fg, inline and "ascender" or "bounds", inline and "descender" or "bounds")
  local doc = S.pre .. "\n" .. head .. b.src .. "\n"
  local needs_dir = b.kind == "figure" or b.kind == "table"
  local dep = needs_dir and (S.dir .. util.stamp(S, b.src, { 'image%s*%(%s*"([^"]+)"' })) or ""
  local hash = fn.sha256(table.concat({ "typ", cfg.cmd, doc, ext, ext == "png" and dpi or 0, dep }, "\0"))

  return {
    hash = hash, ext = ext,
    steps = function(dir)
      local infile, cleanup = dir .. "/doc.typ", nil
      if needs_dir then -- relative image paths resolve against the source file's directory
        local alt = ("%s/.mip-%s.typ"):format(S.dir, hash:sub(1, 12))
        if util.write_file(alt, doc) then
          infile = alt
          cleanup = function() fn.delete(alt) end
        end
      end
      if not cleanup then util.write_file(infile, doc) end
      local cmd = { cfg.cmd, "compile", "--format", ext }
      if ext == "png" then vim.list_extend(cmd, { "--ppi", tostring(dpi) }) end
      vim.list_extend(cmd, { infile, dir .. "/out." .. ext })
      return { { cmd = cmd, cwd = dir } }, cleanup
    end,
  }
end

---------------------------------------------------------------------------
-- Existing image files (Org [[file:...]])
---------------------------------------------------------------------------

function J.image_master(S, b)
  local path = util.resolve_path(S, b.file)
  local st = (vim.uv or vim.loop).fs_stat(path)
  if not st then return nil end
  local key = path .. st.mtime.sec
  if path:lower():match("%.png$") then
    return { hash = fn.sha256("img\0" .. key), direct = path }
  end
  local im = (util.exe("magick") and "magick") or (util.exe("convert") and "convert")
  if not im then return nil end
  return {
    hash = fn.sha256("conv\0" .. key), ext = "png",
    steps = function(dir)
      return { { cmd = { im, path .. "[0]", "-background", "none", "out.png" }, cwd = dir } }
    end,
  }
end

---------------------------------------------------------------------------

function J.master(S, b)
  if b.kind == "image" then return J.image_master(S, b) end
  if S.lang == "typst" then return J.typst_master(S, b) end
  return J.tex_master(S, b)
end

--- Rasterise an SVG master into a W x H canvas laid out as `spec` says.
function J.raster(m, spec)
  local cmd = util.rasterizer()
  if not cmd then return nil end
  local hash = fn.sha256(("%s|%d|%d|%.1f|%.1f|%.1f|%.1f"):format(m.hash, spec.W, spec.H, spec.tx, spec.ty, spec.w, spec.h))
  local sp = spec
  if m.crop then -- block cut out of a compiled page
    sp = vim.tbl_extend("force", spec, { vb = ("%.3f %.3f %.3f %.3f"):format(m.crop[1], m.crop[2], m.crop[3], m.crop[4]), strip_bg = true })
  end
  return {
    hash = hash, ext = "png", volatile = m.volatile,
    steps = function(dir)
      util.write_file(dir .. "/in.svg", util.svg_wrap(util.read_file(m.path) or "", sp))
      return { { cmd = cmd, cwd = dir } }
    end,
  }
end

--- png -> sixel (sixel backend). Transparent pixels are composited on Normal's background.
function J.encode(ent, spec)
  local enc = util.sixel_encoder()
  if not enc then return nil end
  local bg = util.sixel_bg()
  local hash = fn.sha256(("six|%s|%s|%s|%dx%d|%dx%d"):format(
    ent.key, enc.name, bg, spec.cols, spec.rows, spec.W, spec.H))
  return {
    hash = hash, ext = "six",
    steps = function(dir)
      return { { cmd = enc.cmd(ent.path, bg, spec), cwd = dir, stdout = "out.six", binary = true } }
    end,
  }
end

function J.describe()
  local lt = tex_pipeline()
  return {
    latex = lt or "unavailable",
    rasterizer = (util.rasterizer() or { "none" })[1],
    typst = util.exe(config.values.typst.cmd) and (util.rasterizer() and "svg" or "png") or "unavailable",
    sixel = (util.sixel_encoder() or { name = "none" }).name,
    ueberzug = require("mip.backend.ueberzug").cmd() or "none",
  }
end

return J
