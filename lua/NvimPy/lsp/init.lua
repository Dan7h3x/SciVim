local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "NvimPy.lsp.mason"
require("NvimPy.lsp.handlers").setup()
require "NvimPy.lsp.null-ls"
