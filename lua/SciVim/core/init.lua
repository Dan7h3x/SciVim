-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")

require("SciVim.extras.present").setup()
if vim.g.neovide then
	vim.o.guifont = "JetBrainsMono Nerd Font:h11"
end
