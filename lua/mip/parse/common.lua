local config = require("mip.config")
local api, fn = vim.api, vim.fn

local C = {}

local ENV = {}
local function reg(kind, list)
  for _, n in ipairs(list) do ENV[n] = kind end
end

-- every display-math environment we know about (star variants are implied)
reg("display", {
  "equation", "align", "alignat", "xalignat", "xxalignat", "flalign", "gather", "multline",
  "eqnarray", "displaymath", "subequations", "split", "aligned", "gathered", "alignedat",
  "multlined", "dmath", "dgroup", "dseries", "darray", "empheq", "IEEEeqnarray",
  "IEEEeqnarraybox", "CD", "equ", "eqn",
})
reg("inline", { "math" })
reg("table", { "table", "tabular", "tabularx", "tabulary", "longtable", "longtabu", "tabu", "xltabular", "supertabular", "tblr", "NiceTabular" })
reg("figure", { "figure", "wrapfigure", "tikzpicture", "tikzcd", "pgfpicture", "circuitikz", "forest", "picture", "axis" })

C.SECTION_LEVEL = { part = 1, chapter = 1, section = 1, subsection = 2, subsubsection = 3, paragraph = 4, subparagraph = 4 }

--- kind ("display"|"inline"|"table"|"figure") of a LaTeX environment name, or nil
function C.env_kind(name)
  local base = name:gsub("%*$", "")
  local k = ENV[base]
  if k then return k end
  local cfg = config.values.latex
  if vim.tbl_contains(cfg.math_envs, base) then return "display" end
  if vim.tbl_contains(cfg.table_envs, base) then return "table" end
  if vim.tbl_contains(cfg.figure_envs, base) then return "figure" end
end

local FEATURE = { inline = "inline", display = "math", table = "tables", figure = "figures", section = "sections", image = "figures" }
local LINE_KINDS = { display = true, table = true, figure = true, section = true, image = true }

--- Raw blocks {kind, srow, scol, erow, ecol(exclusive), ...} -> final blocks:
--- feature filtering, overlap removal, `src`, `mode` ("inline" | "line").
function C.finish(buf, raw)
  local feats = config.values.features
  local list = {}
  for _, b in ipairs(raw) do
    if feats[FEATURE[b.kind]] then list[#list + 1] = b end
  end
  table.sort(list, function(a, b)
    if a.srow ~= b.srow then return a.srow < b.srow end
    if a.scol ~= b.scol then return a.scol < b.scol end
    if a.erow ~= b.erow then return a.erow > b.erow end
    return a.ecol > b.ecol
  end)
  local out, lr, lc = {}, -1, -1
  for _, b in ipairs(list) do
    if b.srow > lr or (b.srow == lr and b.scol >= lc) then
      lr, lc = b.erow, b.ecol
      b.src = b.src or table.concat(api.nvim_buf_get_text(buf, b.srow, b.scol, b.erow, b.ecol, {}), "\n")
      local first = api.nvim_buf_get_lines(buf, b.srow, b.srow + 1, false)[1] or ""
      local last = b.erow == b.srow and first or (api.nvim_buf_get_lines(buf, b.erow, b.erow + 1, false)[1] or "")
      local before, after = first:sub(1, b.scol), last:sub(b.ecol + 1)
      -- a trailing Typst label (`$ x $ <eq:a>`) belongs to the block
      local tail_ok = after:match("^%s*$") or after:match("^%s*<[%w_:%.%-]+>%s*$")
      if LINE_KINDS[b.kind] and before:match("^%s*$") and tail_ok then
        b.mode = "line"
        b.indent = fn.strdisplaywidth(before)
        b.scol = 0
      elseif b.srow == b.erow then
        b.mode = "inline"
      end
      if b.mode then out[#out + 1] = b end
    end
  end
  return out
end

return C
