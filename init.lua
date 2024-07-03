-- ╔────────────────────────────────────────────────────────────────────╗
-- │ ██████   █████            ███                ███████████           │
-- │░░██████ ░░███            ░░░                ░░███░░░░░███          │
-- │ ░███░███ ░███ █████ █████████ █████████████  ░███    ░████████ ████│
-- │ ░███░░███░███░░███ ░░███░░███░░███░░███░░███ ░██████████░░███ ░███ │
-- │ ░███ ░░██████ ░███  ░███ ░███ ░███ ░███ ░███ ░███░░░░░░  ░███ ░███ │
-- │ ░███  ░░█████ ░░███ ███  ░███ ░███ ░███ ░███ ░███        ░███ ░███ │
-- │ █████  ░░█████ ░░█████   ██████████░███ ██████████       ░░███████ │
-- │░░░░░    ░░░░░   ░░░░░   ░░░░░░░░░░ ░░░ ░░░░░░░░░░         ░░░░░███ │
-- │                                                           ███ ░███ │
-- │                                                          ░░██████  │
-- ╚────────────────────────────────────────────────────────────────────╝

require("NvimPy.configs.options")
require("NvimPy.configs.autocmds")
require("NvimPy.configs.keymaps")
require("NvimPy.configs.lazy")
vim.cmd([[colorscheme tokyonight-night]])
