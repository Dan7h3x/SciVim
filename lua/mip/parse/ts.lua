--- Treesitter based block discovery for LaTeX and Typst.
--- (tree-sitter-org has no math nodes, so Org goes through parse/regex.lua.)
local C = require("mip.parse.common")

local M = {}

local TYP_CALL = { table = "table", figure = "figure", image = "figure" }

local function text_of(node, buf)
  return vim.treesitter.get_node_text(node, buf)
end

local function block(kind, node, extra)
  local sr, sc, er, ec = node:range()
  local b = extra or {}
  b.kind, b.srow, b.scol, b.erow, b.ecol = kind, sr, sc, er, ec
  return b
end

local function walk_latex(buf, node, lo, hi, out)
  for child in node:iter_children() do
    if child:named() then
      local sr, _, er = child:range()
      if er >= lo and sr <= hi then
        local t = child:type()
        if t == "inline_formula" then
          out[#out + 1] = block("inline", child)
        elseif t == "displayed_equation" then
          out[#out + 1] = block("display", child)
        elseif t == "math_environment" or t == "generic_environment" then
          local name = text_of(child, buf):match("^\\begin%s*{([^}]+)}")
          local kind = name and C.env_kind(name)
          if kind then
            out[#out + 1] = block(kind, child, { env = name })
          else
            walk_latex(buf, child, lo, hi, out)
          end
        elseif C.SECTION_LEVEL[t] then
          -- the section node spans its whole body: only the heading is a block
          local tf = child:field("text")[1]
          if not tf then
            for c in child:iter_children() do
              if c:type() == "curly_group" then tf = c break end
            end
          end
          if tf then
            local hs, hc = child:range()
            local _, _, he, hec = tf:range()
            local title = text_of(tf, buf):gsub("^{", ""):gsub("}$", ""):gsub("%s+", " ")
            out[#out + 1] = {
              kind = "section", srow = hs, scol = hc, erow = he, ecol = hec,
              level = C.SECTION_LEVEL[t], title = vim.trim(title),
            }
          end
          walk_latex(buf, child, lo, hi, out)
        else
          walk_latex(buf, child, lo, hi, out)
        end
      end
    end
  end
end

local function walk_typst(buf, node, lo, hi, out)
  for child in node:iter_children() do
    if child:named() then
      local sr, sc, er = child:range()
      if er >= lo and sr <= hi then
        local t = child:type()
        if t == "math" then
          local text = text_of(child, buf)
          local display = text:match("^%$%s") and text:match("%s%$$")
          out[#out + 1] = block(display and "display" or "inline", child)
        elseif t == "heading" then
          local first = text_of(child, buf):match("^[^\n]*")
          local eq, title = first:match("^(=+)%s+(.-)%s*$")
          if eq then
            out[#out + 1] = {
              kind = "section", srow = sr, scol = sc, erow = sr, ecol = sc + #first,
              level = math.min(#eq, 4), title = title,
            }
          end
        elseif t == "call" then
          local name = text_of(child, buf):match("^#?([%a][%w_%-]*)%s*%(")
          local kind = name and TYP_CALL[name]
          if kind then
            local b = block(kind, child)
            if sc > 0 and vim.api.nvim_buf_get_text(buf, sr, sc - 1, sr, sc, {})[1] == "#" then
              b.scol = sc - 1
            end
            out[#out + 1] = b
          else
            walk_typst(buf, child, lo, hi, out)
          end
        else
          walk_typst(buf, child, lo, hi, out)
        end
      end
    end
  end
end

--- Returns raw blocks, or nil when no parser is available for `S.lang`.
function M.scan(S, lo, hi)
  local lang = S.lang
  if lang ~= "latex" and lang ~= "typst" then return nil end
  local ok, parser = pcall(vim.treesitter.get_parser, S.buf, lang, { error = false })
  if not ok or not parser then return nil end
  local ok2, trees = pcall(parser.parse, parser, { lo, hi })
  if not ok2 or not trees or not trees[1] then return nil end
  local out = {}
  local walk = lang == "latex" and walk_latex or walk_typst
  walk(S.buf, trees[1]:root(), lo, hi, out)
  return out
end

return M
