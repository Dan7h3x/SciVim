-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")

if vim.g.neovide then
  vim.o.guifont = "M+CodeLat60 Nerd Font:h11"
end


require("SciVim.extras.scratch").setup({})
