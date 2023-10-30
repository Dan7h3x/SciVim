--[[
███╗|||██╗██╗|||██╗██╗███╗|||███╗██████╗|██╗|||██╗
████╗||██║██║|||██║██║████╗|████║██╔══██╗╚██╗|██╔╝
██╔██╗|██║██║|||██║██║██╔████╔██║██████╔╝|╚████╔╝|
██║╚██╗██║╚██╗|██╔╝██║██║╚██╔╝██║██╔═══╝|||╚██╔╝||
██║|╚████║|╚████╔╝|██║██║|╚═╝|██║██║||||||||██║|||
╚═╝||╚═══╝||╚═══╝||╚═╝╚═╝|||||╚═╝╚═╝||||||||╚═╝|||
||||||||||||||||||||||||||||||||||||||||||||||||||
--]]

require("NvimPy.Lazy")
require("NvimPy.Autocmds")
require("NvimPy.Options")
vim.cmd([[colorscheme carbonfox]])
require("NvimPy.Cmp")
require("NvimPy.TS")
require("NvimPy.Buffer")
require("NvimPy.Search")
require("NvimPy.Keymaps")
require("NvimPy.Tree")
require("NvimPy.Symbols")
require("NvimPy.Lualine")
require("NvimPy.Alpha")
require("NvimPy.Knap")
require("NvimPy.Term")
require("NvimPy.Venn")
require("NvimPy.Iron")
require("NvimPy.Lsp")
require("NvimPy.WinPick")
require("NvimPy.Dress")
-- require("NvimPy.Theme")
require("NvimPy.Winbar")
require("luasnip.loaders.from_vscode").load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/Snippets/" })

vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])
