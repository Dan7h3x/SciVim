--[[
-- Keymaps
--]]
local ft_cmds = {
	python = "ipython -i " .. vim.fn.expand("%"),
	markdown = "glow ",
}

vim.g.mapleader = " "
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>a", "<Cmd>Alpha<CR>", { desc = "Dashboard" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Words" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.lsp_document_symbols, { desc = "Tags" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "History" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>ft", builtin.colorscheme, { desc = "Themes" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diags" })
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle reveal_force_cwd<CR>", { desc = "File Explorer" })
vim.keymap.set("n", "<A-1>", '<Cmd>lua require("nvterm.terminal").toggle "float" <CR>', { desc = "Term float" })
vim.keymap.set("n", "<A-2>", '<Cmd>lua require("nvterm.terminal").toggle "vertical" <CR>', { desc = "Term vertical" })
vim.keymap.set(
	"n",
	"<A-3>",
	'<Cmd>lua require("nvterm.terminal").toggle "horizontal" <CR>',
	{ desc = "Term horizontal" }
)
vim.keymap.set("n", "<A-p>", function()
	require("nvterm.terminal").send(ft_cmds[vim.bo.filetype], "vertical")
end, { desc = "Term filetype" })
vim.keymap.set("n", "<A-o>", function()
	require("nvterm.terminal").send(ft_cmds[vim.bo.filetype], "horizontal")
end, { desc = "Term filetype" })
vim.keymap.set({ "n", "i", "v", "s" }, "<C-s>", "<Cmd>w<CR><esc>", { desc = "Save" })

vim.keymap.set("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Quit" })
vim.keymap.set("n", "<C-c>", "<Cmd>bdelete!<CR>", { desc = "Kill Buffer" })
vim.keymap.set("n", "<F10>", "<Cmd>SymbolsOutline<CR>", { desc = "Symbols" })
vim.keymap.set("n", "<F9>", "<Cmd>UndotreeToggle<CR>", { desc = "Undos" })
--[[
-- Latex
--]]
vim.keymap.set("n", "<leader>p", '<Cmd>lua require("nabla").popup()<CR>', { desc = "Nabla Note" })
vim.keymap.set(
	"n",
	"<leader>P",
	'<Cmd>lua require("nabla").enable_virt({autogen=true,silent=true,})<CR>',
	{ desc = "Nabla view" }
)
vim.keymap.set("n", "<leader>L", '<Cmd>lua require("nabla").disable_virt()<CR>', { desc = "Nabla disable" })

vim.keymap.set({ "n", "v", "i" }, "<F2>", function()
	require("knap").process_once()
end, { desc = "Process and refresh latex" })
vim.keymap.set({ "n", "v", "i" }, "<F3>", function()
	require("knap").close_viewer()
end, { desc = "Close viewer" })
vim.keymap.set({ "n", "v", "i" }, "<F4>", function()
	require("knap").toggle_autopreviewing()
end, { desc = "Autoprocessing" })
vim.keymap.set({ "n", "v", "i" }, "<F5>", function()
	require("knap").forward_jump()
end, { desc = "SyncTeX" })
--[[
-- Focusing
--]]
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus Left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus Down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus Up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus Right" })
--[[
-- Resizing
--]]
vim.keymap.set("n", "<C-Up>", "<Cmd> resize +2<CR>", { desc = "Inc Height" })
vim.keymap.set("n", "<C-Down>", "<Cmd> resize -2<CR>", { desc = "Dec Height" })
vim.keymap.set("n", "<C-Left>", "<Cmd> vertical resize +2<CR>", { desc = "Inc Width" })
vim.keymap.set("n", "<C-Right>", "<Cmd> vertical resize -2<CR>", { desc = "Dec Width" })

vim.keymap.set("n", "<leader>S", "<cmd>nohlsearch<CR>", {
	desc = "Exit Search",
})
vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
	desc = "Search current word",
})
vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
	desc = "Search current word",
})
vim.keymap.set("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
	desc = "Search on current file",
})

vim.keymap.set("n", "<leader>bb", "<cmd>BufferLineTogglePin<cr>", { desc = "Buffer Pin" })
vim.keymap.set("n", "<C-b>", "<cmd>BufferLinePick<cr>", { desc = "Buffer Sel" })
