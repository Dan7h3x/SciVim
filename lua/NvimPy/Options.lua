local opts = vim.opt

vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
opts.autowrite = true -- Enable auto write
opts.breakindent = true
opts.copyindent = true
opts.fileencoding = "utf-8"
opts.fillchars = { eob = " " }
opts.history = 100
opts.infercase = true
opts.linebreak = true
opts.preserveindent = true
opts.clipboard = "unnamedplus" -- Sync with system clipboard
opts.conceallevel = 0 -- Hide * markup for bold and italic
opts.confirm = true -- Confirm to save changes before exiting modified buffer
opts.cursorline = true -- Enable highlighting of the current line
opts.expandtab = true -- Use spaces instead of tabs
opts.formatoptions = "jcroqlnt" -- tcqj
opts.grepformat = "%f:%l:%c:%m"
opts.grepprg = "rg --vimgrep"
opts.ignorecase = true -- Ignore case
opts.inccommand = "nosplit" -- preview incremental substitute
opts.laststatus = 3
opts.list = true
opts.mouse = "a" -- Enable mouse mode
opts.number = true -- Print line number
opts.pumblend = 10 -- Popup blend
opts.pumheight = 10 -- Maximum number of entries in a popup
opts.relativenumber = false -- Relative line numbers
opts.scrolloff = 7 -- Lines of context
opts.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opts.shiftround = true -- Round indent
opts.shiftwidth = 2 -- Size of an indent
opts.shortmess:append({ W = true, I = true, c = true })
opts.showmode = false -- Dont show mode since we have a statusline
opts.sidescrolloff = 7 -- Columns of context
opts.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opts.smartcase = true -- Don't ignore case with capitals
opts.smartindent = true -- Insert indents automatically
opts.spelllang = { "en" }
opts.splitbelow = true -- Put new windows below current
opts.splitkeep = "screen"
opts.splitright = true -- Put new windows right of current
opts.tabstop = 4 -- Number of spaces tabs count for
opts.termguicolors = true -- True color support
opts.timeoutlen = 300
opts.undofile = true
opts.undolevels = 10000
opts.updatetime = 200 -- Save swap file and trigger CursorHold
opts.wildmode = "longest:full,full" -- Command-line completion mode
opts.winminwidth = 5 -- Minimum window width
opts.wrap = false -- Disable line wrap
opts.textwidth = 85
opts.hlsearch = true
opts.ruler = false
opts.virtualedit = "block"
opts.title = true
opts.swapfile = false
opts.backup = false

if vim.fn.has("nvim-0.10") == 1 then
	opts.smoothscroll = true
end

vim.loader.enable()

vim.g.python3_host_prog = "/usr/bin/python"

vim.g.Tex_MultipleCompileFormats = "pdf,bib,pdf"
