--[[
-- Options for SciVim
--]]

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.scivim_statuscolumn = {
	folds_open = false,
	folds_githl = false,
}

local option = vim.opt

option.autowrite = true -- Enable auto write
option.clipboard = "unnamedplus" -- Sync with system clipboard
option.completeopt = "menu,menuone,noselect"
option.conceallevel = 2 -- Hide * markup for bold and italic
option.confirm = true -- Confirm to save changes before exiting modified buffer
option.cursorline = true -- Enable highlighting of the current line
option.expandtab = true -- Use spaces instead of tabs
option.foldlevel = 99
option.formatoptions = "jcroqlnt" -- tcqj
option.grepformat = "%f:%l:%c:%m"
option.grepprg = "rg --vimgrep"
option.guifont = { "CaskaydiaCove_Nerd_Font", "Source_Code_Pro", "Noto_Sans", "Sans_Serif", ":h11" }
option.guicursor = "n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr:hor20,o:hor50"
option.jumpoptions = "view"
option.ignorecase = true -- Ignore case
option.inccommand = "nosplit" -- preview incremental substitute
option.laststatus = 3 -- global statusline
option.list = true -- Show some invisible characters (tabs...
option.linebreak = true
option.mouse = "a" -- Enable mouse mode
option.number = true -- Print line number
option.pumblend = 10 -- Popup blend
option.pumheight = 10 -- Maximum number of entries in a popup
-- opt.relativenumber = true -- Relative line numbers
option.ruler = true
option.scrolloff = 4 -- Lines of context
option.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
option.shiftround = true -- Round indent
option.shiftwidth = 2 -- Size of an indent
option.shortmess:append({ W = true, I = true, c = true, C = true })
option.showmode = false -- Dont show mode since we have a statusline
option.sidescrolloff = 8 -- Columns of context
option.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
option.smartcase = true -- Don't ignore case with capitals
option.smartindent = true -- Insert indents automatically
option.spelllang = { "en" }
option.spelloptions:append("noplainbuffer")
option.splitbelow = true -- Put new windows below current
option.splitkeep = "screen"
option.splitright = true -- Put new windows right of current
option.statuscolumn = [[%!v:lua.require'SciVim.utils.statuscol'.statuscolumn()]]
option.textwidth = 80
option.tabstop = 2 -- Number of spaces tabs count for
option.termguicolors = true -- True color support
option.timeoutlen = 300
option.undofile = true
option.undolevels = 10000
option.updatetime = 200 -- Save swap file and trigger CursorHold
option.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
option.wildmode = "longest:full,full" -- Command-line completion mode
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

if vim.fn.has("nvim-0.10") == 1 then
	option.smoothscroll = true
	option.foldexpr = "v:lua.require'SciVim.utils.statuscol'.foldexpr()"
	option.foldmethod = "expr"
	option.foldtext = ""
else
	option.foldmethod = "indent"
	option.foldtext = "v:lua.require'SciVim.utils.statuscol'.foldtext()"
end

vim.filetype.add({
	extension = {
		tex = "tex",
		typ = "typst",
	},
})

vim.g.markdown_recommended_style = 0

vim.loader.enable()

vim.g.Tex_MultipleCompileFormats = "pdf,bib,pdf"

vim.g.python3_host_prog = "/bin/python"
