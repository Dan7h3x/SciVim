--[[
-- Keymaps
--]]

local opts = { noremap = true, silent = true }
local Tel = require("NvimPy.Util").telescope
vim.g.mapleader = " "
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>a", "<Cmd>Alpha<CR>", { desc = "Dashboard" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Files" })
vim.keymap.set("n", "<leader>fg", Tel("live_grep", { cwd = false }), { desc = "Words" })
vim.keymap.set("n", "<leader>fb", "<Cmd> Telescope buffers sort_mru=true sort_lastused=true <CR>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Tags" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "History" })
vim.keymap.set("n", "<leader>fy", "<Cmd> Telescope registers <CR>", { desc = "Yankies" })
vim.keymap.set("n", "<leader>fm", "<Cmd> Telescope man_pages <CR>", { desc = "Manuals" })
vim.keymap.set("n", "<leader>fs", "<Cmd> Telescope luasnip <CR>", { desc = "Snippets" })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>ft", builtin.colorscheme, { desc = "Themes" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diags" })
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle reveal_force_cwd<CR>", { desc = "File Explorer" })
vim.keymap.set("n", "<leader>fe", "<Cmd>Neotree float reveal_force_cwd<CR>", { desc = "File Explorer float" })
vim.keymap.set("n", "<leader>E", function()
	require("neo-tree.command").execute({ source = "git_status", toggle = true })
end, { desc = "Git Status" })
vim.keymap.set("n", "<leader>be", function()
	require("neo-tree.command").execute({ source = "buffers", toggle = true })
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>w", "<Cmd> lua print(require('window-picker').pick_window())<CR>", { desc = "Win Picker" })
vim.keymap.set("n", "<A-1>", "<Cmd>ToggleTerm direction=float name=Term <CR>", { desc = "Term float" })
vim.keymap.set("n", "<A-2>", "<Cmd>ToggleTerm size=45 direction=vertical name=Term  <CR>", { desc = "Term vertical" })
vim.keymap.set(
	"n",
	"<A-3>",
	"<Cmd>ToggleTerm size=19 direction=horizontal name=Term  <CR>",
	{ desc = "Term horizontal" }
)

vim.keymap.set({ "n", "i", "v", "s" }, "<C-s>", "<Cmd>w<CR><esc>", { desc = "Save" })

vim.keymap.set("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Quit" })
vim.keymap.set("n", "<C-c>", "<Cmd>bdelete!<CR>", { desc = "Kill Buffer" })
vim.keymap.set("n", "<F9>", "<Cmd>UndotreeToggle<CR>", { desc = "Undos" })
--[[
-- Latex
--]]
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
vim.keymap.set("n", "<leader>bb", "<cmd>BufferLineTogglePin<cr>", { desc = "Buffer Pin" })
vim.keymap.set("n", "<A-b>", "<cmd>BufferLinePick<cr>", { desc = "Buffer Sel" })
-- Normal-mode commands
vim.keymap.set("n", "<S-Up>", ":MoveLine -1<CR>", { desc = "Move Line up" })
vim.keymap.set("n", "<S-Down>", ":MoveLine 1<CR>", { desc = "Move Line down" })
vim.keymap.set("n", "<S-Left>", ":MoveWord -1<CR>", { desc = "Move word left" })
vim.keymap.set("n", "<S-Right>", ":MoveWord 1<CR>", { desc = "Move word right" })

-- Visual-mode commands
vim.keymap.set("x", "<S-Up>", ":MoveBlock -1<CR>", { desc = "Move Block up" })
vim.keymap.set("x", "<S-Down>", ":MoveBlock 1<CR>", { desc = "Move Block up" })
vim.keymap.set("v", "<S-Left>", ":MoveHBlock -1<CR>", { desc = "Move Block left" })
vim.keymap.set("v", "<S-Right>", ":MoveHBlock 1<CR>", { desc = "Move Block right" })

--[[
-- Neogen
--]]
vim.keymap.set(
	"n",
	"<leader>nfg",
	"<Cmd> lua require('neogen').generate({type = 'func',annotation_convention = {python = 'google_docstrings'}})<CR>",
	{ desc = "Doc Func" }
)
vim.keymap.set(
	"n",
	"<leader>ncg",
	"<Cmd> lua require('neogen').generate({type = 'class',annotation_convention = {python = 'google_docstrings'}})<CR>",
	{ desc = "Doc Class" }
)
vim.keymap.set(
	"n",
	"<leader>ntg",
	"<Cmd> lua require('neogen').generate({type = 'type',annotation_convention = {python = 'google_docstrings'}})<CR>",
	{ desc = "Doc Type" }
)
vim.keymap.set(
	"n",
	"<leader>nfn",
	"<Cmd> lua require('neogen').generate({type = 'func',annotation_convention = {python = 'numpydoc'}})<CR>",
	{ desc = "Doc Func" }
)
vim.keymap.set(
	"n",
	"<leader>ncn",
	"<Cmd> lua require('neogen').generate({type = 'class',annotation_convention = {python = 'numpydoc'}})<CR>",
	{ desc = "Doc Class" }
)
vim.keymap.set(
	"n",
	"<leader>ntn",
	"<Cmd> lua require('neogen').generate({type = 'type',annotation_convention = {python = 'numpydoc'}})<CR>",
	{ desc = "Doc Type" }
)
