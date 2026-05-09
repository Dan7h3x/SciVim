-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")
require("SciVim.extras.notifs").setup()
-- local golden = require("SciVim.extras.golden")
-- golden.setup({
-- 	golden_ratio_value = 1.618,
-- 	exclude_filetypes = { "help", "netrw", "qf", "NvimTree", "neo-tree" },
-- 	exclude_buffer_names = { "[Quickfix List]", "[Trouble]" },
-- 	exclude_buffer_regexp = { ".*%.git/.*", ".*%.log$" },
-- 	recenter = true,
-- 	adjust_factor = 0.85,
-- 	wide_adjust_factor = 0.7,
-- 	auto_scale = true,
-- 	max_width = 120,
-- 	minimal_width_change = 2,
-- 	minimal_height_change = 2,
-- 	debounce_delay = 100,
-- 	debug = false,
-- })
-- vim.keymap.set("n", "<leader>gr", golden.toggle, { desc = "Toggle golden ratio" })
-- vim.keymap.set("n", "<leader>gw", golden.toggle_widescreen, { desc = "Toggle widescreen mode" })

-- require("SciVim.extras.wr").setup({})
-- require("SciVim.extras.present").setup()
-- require("SciVim.extras.dashboard")
if vim.g.neovide then
	vim.o.guifont = "Maple Mono:h12"
	vim.o.cmdheight = 1
	vim.g.neovide_opacity = 0.89
	vim.g.neovide_normal_opacity = 0.89
end
