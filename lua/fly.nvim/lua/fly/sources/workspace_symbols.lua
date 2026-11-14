local util = require("fly.util")

---@type fly.Source
local M = { title = "workspace symbols", live = true, defaults = { min_query = 1 } }

function M.start(ctx, push, done)
  if #ctx.query < (ctx.opts.min_query or 1) then
    done()
    return
  end
  local buf = ctx.origin.buf
  if #vim.lsp.get_clients({ bufnr = buf, method = "workspace/symbol" }) == 0 then
    util.warn("no LSP client with workspace symbols attached to this buffer")
    done()
    return
  end
  local cancelled = false
  vim.lsp.buf_request_all(buf, "workspace/symbol", { query = ctx.query }, function(results)
    if cancelled then
      return
    end
    local items = {}
    for _, res in pairs(results or {}) do
      for _, s in ipairs(res.result or {}) do
        local loc = s.location
        if loc and loc.uri then
          local path = vim.uri_to_fname(loc.uri)
          local range = loc.range
          items[#items + 1] = {
            label = util.oneline(s.name),
            display = util.oneline(s.name),
            extra = ("%s  %s"):format(vim.lsp.protocol.SymbolKind[s.kind] or "Symbol", util.relpath(path, ctx.cwd)),
            path = path,
            line = range and (range.start.line + 1) or 1,
            col = range and (range.start.character + 1) or 1,
            kind = "symbol",
          }
        end
      end
    end
    push(items)
    done()
  end)
  return function()
    cancelled = true
  end
end

return M
