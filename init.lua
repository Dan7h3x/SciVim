--- SciVim

require("SciVim.core")

dofile(vim.fn.expand("~/.config/nvim/theme.lua"))
vim.cmd.colorscheme("catppuccin")

vim.cmd.packadd("nvim.undotree")
-- vim.cmd.packadd('nohlsearch')
-- if vim.o.background == "dark" then
--   vim.cmd.colorscheme("aye")
-- else
--   vim.cmd.colorscheme("aye-light")
-- end
--- Startup times for process: Primary (or UI client) ---
