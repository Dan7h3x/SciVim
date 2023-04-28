--[[


NNNNNNNN        NNNNNNNN                           iiii                          PPPPPPPPPPPPPPPPP
N:::::::N       N::::::N                          i::::i                         P::::::::::::::::P
N::::::::N      N::::::N                           iiii                          P::::::PPPPPP:::::P
N:::::::::N     N::::::N                                                         PP:::::P     P:::::P
N::::::::::N    N::::::Nvvvvvvv           vvvvvvviiiiiii    mmmmmmm    mmmmmmm     P::::P     P:::::Pyyyyyyy           yyyyyyy
N:::::::::::N   N::::::N v:::::v         v:::::v i:::::i  mm:::::::m  m:::::::mm   P::::P     P:::::P y:::::y         y:::::y
N:::::::N::::N  N::::::N  v:::::v       v:::::v   i::::i m::::::::::mm::::::::::m  P::::PPPPPP:::::P   y:::::y       y:::::y
N::::::N N::::N N::::::N   v:::::v     v:::::v    i::::i m::::::::::::::::::::::m  P:::::::::::::PP     y:::::y     y:::::y
N::::::N  N::::N:::::::N    v:::::v   v:::::v     i::::i m:::::mmm::::::mmm:::::m  P::::PPPPPPPPP        y:::::y   y:::::y
N::::::N   N:::::::::::N     v:::::v v:::::v      i::::i m::::m   m::::m   m::::m  P::::P                 y:::::y y:::::y
N::::::N    N::::::::::N      v:::::v:::::v       i::::i m::::m   m::::m   m::::m  P::::P                  y:::::y:::::y
N::::::N     N:::::::::N       v:::::::::v        i::::i m::::m   m::::m   m::::m  P::::P                   y:::::::::y
N::::::N      N::::::::N        v:::::::v        i::::::im::::m   m::::m   m::::mPP::::::PP                  y:::::::y
N::::::N       N:::::::N         v:::::v         i::::::im::::m   m::::m   m::::mP::::::::P                   y:::::y
N::::::N        N::::::N          v:::v          i::::::im::::m   m::::m   m::::mP::::::::P                  y:::::y
NNNNNNNN         NNNNNNN           vvv           iiiiiiiimmmmmm   mmmmmm   mmmmmmPPPPPPPPPP                 y:::::y
                                                                                                           y:::::y
                                                                                                          y:::::y
                                                                                                         y:::::y
                                                                                                        y:::::y
                                                                                                       yyyyyyy


--]]
require("NvimPy.Lazy")
require("NvimPy.lsp")
require("NvimPy.Lsp-colors")
require("NvimPy.Cmp")
require("NvimPy.Options")
require("NvimPy.TS")
require("NvimPy.Clip")
require("NvimPy.Buffer")
require("NvimPy.Search")
require("NvimPy.Keymaps")
require("NvimPy.Tree")
require("NvimPy.Symbols")
require("NvimPy.Lualine")
vim.cmd([[colorscheme nightfly]])
require("NvimPy.Cursor")
require("NvimPy.Alpha")
require("NvimPy.Noice")
require("NvimPy.Brackets")
require("NvimPy.Pairs")
require("NvimPy.Indent")
require("NvimPy.Knap")
require("NvimPy.Winbar")
require("NvimPy.Autocmds")
require("NvimPy.Term")
require("colorizer").setup()
require("window-picker").setup()

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/Snippets/" })
