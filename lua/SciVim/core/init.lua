-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")

require("SciVim.extras.present").setup()
if vim.g.neovide then
	vim.o.guifont = "IntoneMono Nerd Font:h12"
	vim.o.cmdheight = 1
	vim.g.neovide_opacity = 0.8
	vim.g.neovide_normal_opacity = 0.8
end
