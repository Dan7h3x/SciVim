--[[
-- Options for SciVim
--]]

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.winborder = "rounded"
vim.o.breakindent = true
vim.o.previewheight = 8
vim.o.linebreak = true
local option = vim.opt

option.autowrite = true -- Enable auto write

option.clipboard = "unnamedplus" -- Sync with system clipboard
option.completeopt = "menu,menuone,noselect"
option.conceallevel = 2 -- Hide * markup for bold and italic
option.confirm = true -- Confirm to save changes before exiting modified buffer
option.colorcolumn = "+1"
option.cursorline = true -- Enable highlighting of the current line
-- option.cursorlineopt = "both"
option.expandtab = true -- Use spaces instead of tabs
option.foldlevel = 99
option.formatexpr = "v:lua.require'SciVim.utils'.formatexpr()"
option.foldmethod = "expr"
option.foldexpr = "v:lua.require('nvim-treesitter').foldexpr()"
option.foldlevelstart = 99 -- Start with all folds open
option.foldminlines = 1 -- Allow folding of single lines
option.foldnestmax = 10 -- Maximum fold depth
option.foldcolumn = "0"
option.foldtext = "v:lua.require('SciVim.utils.fold').custom_fold_text()"
option.foldenable = true
option.formatoptions = "jcroqlnt" -- tcqj
option.grepformat = "%f:%l:%c:%m"
option.grepprg = "rg --vimgrep"
option.jumpoptions = "view"
option.ignorecase = true -- Ignore case
option.inccommand = "nosplit" -- preview incremental substitute
option.laststatus = 3 -- global statusline
option.list = true -- Show some invisible characters (tabs...
option.linebreak = true
option.mouse = "a" -- Enable mouse mode
option.number = true -- Print line number
option.pumblend = 0 -- Popup blend
option.pumheight = 10 -- Maximum number of entries in a popup
-- opt.relativenumber = true -- Relative line numbers
option.ruler = false
option.scrolloff = 4 -- Lines of context
option.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
option.shiftround = true -- Round indent
option.shiftwidth = 2 -- Size of an indent
option.shortmess:append({ W = true, I = true, c = true, C = true })
option.showmode = false -- Dont show mode since we have a statusline
option.showmatch = true
option.matchtime = 1
option.sidescrolloff = 8 -- Columns of context
option.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
option.smartcase = true -- Don't ignore case with capitals
option.smartindent = true -- Insert indents automatically
option.spelllang = { "en" }
option.splitbelow = true -- Put new windows below current
option.splitkeep = "screen"
-- option.statuscolumn = [[%!v:lua.require'SciVim.utils'.formatstc()]]
option.splitright = true -- Put new windows right of current
option.tabstop = 2 -- Number of spaces tabs count for
option.termguicolors = true -- True color support
option.textwidth = 79
option.timeoutlen = 300
option.undofile = true
option.undolevels = 10000
option.updatetime = 200 -- Save swap file and trigger CursorHold
option.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
option.wildmode = "longest,full,full" -- Command-line completion mode
option.wildoptions = "fuzzy"
option.winblend = 0
option.winminwidth = 5 -- Minimum window width
option.wrap = false -- Disable line wrap
option.fillchars = {
	foldopen = "▼",
	foldclose = "▶",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
	stlnc = "—",
}

vim.filetype.add({
	extension = {
		tex = "tex",
		typ = "typst",
	},
})

pcall(function()
	vim.loader.enable()
end)

vim.g.loaded_python_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.python3_host_prog = "/bin/python"

local disabled_built_ins = {
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"logipat",
	"rrhelper",
	"spellfile_plugin",
	-- 'matchit',
	-- 'matchparen',
}

for _, plugin in pairs(disabled_built_ins) do
	vim.g["loaded_" .. plugin] = 1
end

vim.g.markdown_recommended_style = 0
vim.g.markdown_fenced_languages = {
	"vim",
	"lua",
	"cpp",
	"sql",
	"python",
	"bash=sh",
	"console=sh",
	"javascript",
	"typescript",
	"js=javascript",
	"ts=typescript",
	"yaml",
	"json",
}

require("SciVim.utils.fold").init()
