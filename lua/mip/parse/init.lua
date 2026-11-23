local config = require("mip.config")
local util = require("mip.util")
local C = require("mip.parse.common")
local ts = require("mip.parse.ts")
local regex = require("mip.parse.regex")

local P = {}

--- Find renderable blocks in buffer lines [lo, hi).
--- Treesitter first (LaTeX, Typst); regex scanner for Org or if no parser.
function P.parse(S, lo, hi)
  local mode = config.values.parser
  local raw
  if mode ~= "regex" then
    raw = ts.scan(S, lo, hi)
    if not raw and mode == "treesitter" and S.lang ~= "org" then
      util.warn_once("ts-" .. S.lang, ("no tree-sitter parser for '%s'; using regex scanner"):format(S.lang))
    end
  end
  raw = raw or regex.scan(S, lo, hi)
  return C.finish(S.buf, raw)
end

function P.using_ts(S)
  if (S.lang ~= "latex" and S.lang ~= "typst") or config.values.parser == "regex" then return false end
  local ok, parser = pcall(vim.treesitter.get_parser, S.buf, S.lang, { error = false })
  return ok and parser ~= nil
end

return P
