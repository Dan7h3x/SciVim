-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")

if vim.g.neovide then
	vim.o.guifont = "JetBrainsMono Nerd Font:h11"
end
