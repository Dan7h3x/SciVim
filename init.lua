--- SciVim

require("SciVim.core")

dofile(vim.fn.expand("~/.config/nvim/theme.lua"))
if vim.o.background == "dark" then
	vim.cmd.colorscheme("aye")
else
	vim.cmd.colorscheme("aye-light")
end
