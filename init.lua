--- SciVim

require("SciVim.core")

dofile(vim.fn.expand(vim.fn.stdpath("config") .. "/theme.lua"))

vim.cmd.packadd("nvim.undotree")
-- vim.cmd.colorscheme("catppuccin")
-- vim.cmd.packadd('nohlsearch')
if vim.o.background == "dark" then
  vim.cmd.colorscheme("aye")
else
  vim.cmd.colorscheme("aye-light")
end
