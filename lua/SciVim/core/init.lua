-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")
-- require("SciVim.extras.wr").setup({})
-- require("SciVim.extras.present").setup()
-- require("SciVim.extras.dashboard")
if vim.g.neovide then
	vim.o.guifont = "Maple Mono Medium:h13"
	vim.o.cmdheight = 1
	vim.g.neovide_opacity = 0.89
	vim.g.neovide_normal_opacity = 0.89
end
