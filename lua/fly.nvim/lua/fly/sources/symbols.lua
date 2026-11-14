local util = require("fly.util")

---@type fly.Source
local M = { title = "symbols", ordered = true }

local function kind_name(k)
  return k and vim.lsp.protocol.SymbolKind[k] or "Symbol"
end

--- Flatten DocumentSymbol[] (nested) or SymbolInformation[] (flat).
local function walk(symbols, prefix, buf, name, out)
  for _, s in ipairs(symbols or {}) do
    local range = s.selectionRange or s.range or (s.location and s.location.range)
    local qualified = prefix and (prefix .. "." .. s.name) or s.name
    if not prefix and s.containerName and s.containerName ~= "" then
      qualified = s.containerName .. "." .. s.name
    end
    out[#out + 1] = {
      label = util.oneline(qualified),
      extra = kind_name(s.kind),
      line = range and (range.start.line + 1) or 1,
      col = range and (range.start.character + 1) or 1,
      path = name ~= "" and name or nil,
      bufnr = buf,
      from_buf = true,
      kind = "symbol",
    }
    walk(s.children, qualified, buf, name, out)
  end
end

function M.start(ctx, push, done)
  local buf = ctx.origin.buf -- NOT the current buffer: that is the prompt
  local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentSymbol" })
  if #clients == 0 then
    util.warn("no LSP client with document symbols attached to this buffer")
    done()
    return
  end
  local cancelled = false
  local name = vim.api.nvim_buf_get_name(buf)
  local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
  vim.lsp.buf_request_all(buf, "textDocument/documentSymbol", params, function(results)
    if cancelled then
      return
    end
    local items = {}
    for _, res in pairs(results or {}) do
      walk(res.result, nil, buf, name, items)
    end
    push(items)
    done()
  end)
  return function()
    cancelled = true
  end
end

return M
