--[[
███╗|||██╗██╗|||██╗██╗███╗|||███╗██████╗|██╗|||██╗
████╗||██║██║|||██║██║████╗|████║██╔══██╗╚██╗|██╔╝
██╔██╗|██║██║|||██║██║██╔████╔██║██████╔╝|╚████╔╝|
██║╚██╗██║╚██╗|██╔╝██║██║╚██╔╝██║██╔═══╝|||╚██╔╝||
██║|╚████║|╚████╔╝|██║██║|╚═╝|██║██║||||||||██║|||
╚═╝||╚═══╝||╚═══╝||╚═╝╚═╝|||||╚═╝╚═╝||||||||╚═╝|||
||||||||||||||||||||||||||||||||||||||||||||||||||
--]]
--

require("NvimPy.Lazy")
require("NvimPy.Options")
require("NvimPy.Autocmds")
require("NvimPy.Cmp")
require("NvimPy.Buffer")
require("NvimPy.Keymaps")
require("NvimPy.Tree")
require("NvimPy.Symbols")
require("NvimPy.Lualine")
require("NvimPy.Alpha")
require("NvimPy.Knap")
require("NvimPy.Venn")
require("NvimPy.Iron")
require("NvimPy.Lsp")
require("NvimPy.Dress")
require("NvimPy.Winbar")
require("NvimPy.Typst")
vim.cmd([[colorscheme tokyonight-night]])
require("NvimPy.Highlights")
require("luasnip.loaders.from_vscode").load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/Snippets/" })

vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])
