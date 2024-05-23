--[[
-- Keymaps
--]]

local Tel = require("NvimPy.utils.init").telescope
vim.g.mapleader = " "
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>a", "<Cmd>Alpha<CR>", { desc = "Dashboard", noremap = true, silent = true })
vim.keymap.set("n", "<leader>ff", Tel("files", { cwd = false }), { desc = "Files", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fg", Tel("live_grep", { cwd = false }), { desc = "Words", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>fb",
  "<Cmd> Telescope buffers sort_mru=true sort_lastused=true <CR>",
  { desc = "Buffers", noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Tags", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fo", Tel("oldfiles", { cwd = true }), { desc = "History", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>fy",
  "<Cmd> Telescope registers  <CR>",
  { desc = "Yankies", noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>fm", "<Cmd> Telescope man_pages <CR>", { desc = "Manuals", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fs", "<Cmd> Telescope luasnip <CR>", { desc = "Snippets", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>ft",
  Tel("colorscheme", { enable_preview = true }),
  { desc = "Themes", noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diags", noremap = true, silent = true })
vim.keymap.set("n", "<leader>fl", builtin.lsp_definitions, { desc = "Lsp_Definitions", noremap = true, silent = true })
vim.keymap.set("n", "[b", "<Cmd>BufferPrevious<CR>", { desc = "BufferPrevious", noremap = true, silent = true })
vim.keymap.set("n", "]b", "<Cmd>BufferNext<CR>", { desc = "BufferNext", noremap = true, silent = true })
vim.keymap.set("n", "<A-p>", "<Cmd>BufferPin<CR>", { desc = "BufferPin", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>e",
  "<Cmd>Neotree toggle reveal_force_cwd<CR>",
  { desc = "File Explorer", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>fe",
  "<Cmd>Neotree float reveal_force_cwd<CR>",
  { desc = "File Explorer float", noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>E", function()
  require("neo-tree.command").execute({ source = "git_status", toggle = true })
end, { desc = "Git Status", noremap = true, silent = true })
vim.keymap.set("n", "<leader>be", function()
  require("neo-tree.command").execute({ source = "buffers", toggle = true })
end, { desc = "Buffers", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>w",
  "<Cmd> lua print(require('window-picker').pick_window())<CR>",
  { desc = "Win Picker", noremap = true, silent = true }
)
vim.keymap.set("n", "<A-1>", "<Cmd> Fterm <CR>", { desc = "Term float", noremap = true, silent = true })
vim.keymap.set("n", "<A-2>", "<Cmd> Vterm  <CR>", { desc = "Term vertical", noremap = true, silent = true })
vim.keymap.set("n", "<A-3>", "<Cmd> Sterm <CR>", { desc = "Term horizontal", noremap = true, silent = true })

vim.keymap.set({ "n", "i", "v", "s" }, "<C-s>", "<Cmd>w<CR><esc>", { desc = "Save", noremap = true, silent = true })

vim.keymap.set("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Quit", noremap = true, silent = true })
vim.keymap.set("n", "<C-c>", "<Cmd>bdelete!<CR>", { desc = "Kill Buffer", noremap = true, silent = true })
vim.keymap.set("n", "<F9>", "<Cmd>UndotreeToggle<CR>", { desc = "Undos", noremap = true, silent = true })
--[[
-- Latex
--]]
vim.keymap.set({ "n", "v", "i" }, "<F2>", function()
  require("knap").process_once()
end, { desc = "Process and refresh latex", noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i" }, "<F3>", function()
  require("knap").close_viewer()
end, { desc = "Close viewer", noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i" }, "<F4>", function()
  require("knap").toggle_autopreviewing()
end, { desc = "Autoprocessing", noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i" }, "<F5>", function()
  require("knap").forward_jump()
end, { desc = "SyncTeX", noremap = true, silent = true })
--[[
-- Focusing
--]]
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus Left", noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus Down", noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus Up", noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus Right", noremap = true, silent = true })
--[[
-- Resizing
--]]
vim.keymap.set("n", "<C-Up>", "<Cmd> resize +2<CR>", { desc = "Inc Height", noremap = true, silent = true })
vim.keymap.set("n", "<C-Down>", "<Cmd> resize -2<CR>", { desc = "Dec Height", noremap = true, silent = true })
vim.keymap.set("n", "<C-Left>", "<Cmd> vertical resize +2<CR>", { desc = "Inc Width", noremap = true, silent = true })
vim.keymap.set("n", "<C-Right>", "<Cmd> vertical resize -2<CR>", { desc = "Dec Width", noremap = true, silent = true })

vim.keymap.set("n", "<leader>S", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", {
  desc = "Exit Search",
  noremap = true,
  silent = true,
})
-- Normal-mode commands
vim.keymap.set("n", "<S-Up>", "<Cmd>MoveLine -1<CR>", { desc = "Move Line up", noremap = true, silent = true })
vim.keymap.set("n", "<S-Down>", "<Cmd>MoveLine 1<CR>", { desc = "Move Line down", noremap = true, silent = true })
vim.keymap.set("n", "<S-Left>", "<Cmd>MoveWord -1<CR>", { desc = "Move word left", noremap = true, silent = true })
vim.keymap.set("n", "<S-Right>", "<Cmd>MoveWord 1<CR>", { desc = "Move word right", noremap = true, silent = true })

-- Visual-mode commands
vim.keymap.set("x", "<S-Up>", "<Cmd>MoveBlock -1<CR>", { desc = "Move Block up", noremap = true, silent = true })
vim.keymap.set("x", "<S-Down>", "<Cmd>MoveBlock 1<CR>", { desc = "Move Block up", noremap = true, silent = true })
vim.keymap.set("v", "<S-Left>", "<Cmd>MoveHBlock -1<CR>", { desc = "Move Block left", noremap = true, silent = true })
vim.keymap.set("v", "<S-Right>", "<Cmd>MoveHBlock 1<CR>", { desc = "Move Block right", noremap = true, silent = true })

--[[
-- Neogen
--]]
vim.keymap.set(
  "n",
  "<leader>nfg",
  "<Cmd> lua require('neogen').generate({type = 'func',annotation_convention = {python = 'google_docstrings'}})<CR>",
  { desc = "Doc Func", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>ncg",
  "<Cmd> lua require('neogen').generate({type = 'class',annotation_convention = {python = 'google_docstrings'}})<CR>",
  { desc = "Doc Class", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>ntg",
  "<Cmd> lua require('neogen').generate({type = 'type',annotation_convention = {python = 'google_docstrings'}})<CR>",
  { desc = "Doc Type", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>nfn",
  "<Cmd> lua require('neogen').generate({type = 'func',annotation_convention = {python = 'numpydoc'}})<CR>",
  { desc = "Doc Func", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>ncn",
  "<Cmd> lua require('neogen').generate({type = 'class',annotation_convention = {python = 'numpydoc'}})<CR>",
  { desc = "Doc Class", noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>ntn",
  "<Cmd> lua require('neogen').generate({type = 'type',annotation_convention = {python = 'numpydoc'}})<CR>",
  { desc = "Doc Type", noremap = true, silent = true }
)

vim.keymap.set("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keyword help", noremap = true, silent = true })
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })
