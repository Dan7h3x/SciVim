local opts = vim.opt

opts.autowrite = true -- Enable auto write
opts.clipboard = "unnamedplus" -- Sync with system clipboard
opts.completeopt = "menu,menuone,noselect"
opts.conceallevel = 3 -- Hide * markup for bold and italic
opts.confirm = true -- Confirm to save changes before exiting modified buffer
opts.cursorline = true -- Enable highlighting of the current line
opts.expandtab = true -- Use spaces instead of tabs
opts.formatoptions = "jcroqlnt" -- tcqj
opts.grepformat = "%f:%l:%c:%m"
opts.grepprg = "rg --vimgrep"
opts.ignorecase = true -- Ignore case
opts.inccommand = "nosplit" -- preview incremental substitute
opts.laststatus = 0
opts.mouse = "a" -- Enable mouse mode
opts.number = true -- Print line number
opts.pumblend = 10 -- Popup blend
opts.pumheight = 10 -- Maximum number of entries in a popup
opts.relativenumber = true -- Relative line numbers
opts.scrolloff = 10 -- Lines of context
opts.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opts.shiftround = true -- Round indent
opts.shiftwidth = 2 -- Size of an indent
opts.shortmess:append({ W = true, I = true, c = true })
opts.showmode = false -- Dont show mode since we have a statusline
opts.sidescrolloff = 8 -- Columns of context
opts.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opts.smartcase = true -- Don't ignore case with capitals
opts.smartindent = true -- Insert indents automatically
opts.spelllang = { "en" }
opts.splitbelow = true -- Put new windows below current
opts.splitright = true -- Put new windows right of current
opts.tabstop = 4 -- Number of spaces tabs count for
opts.termguicolors = true -- True color support
opts.timeoutlen = 300
opts.undofile = true
opts.undolevels = 10000
opts.updatetime = 200 -- Save swap file and trigger CursorHold
opts.wildmode = "longest:full,full" -- Command-line completion mode
opts.winminwidth = 8 -- Minimum window width
opts.wrap = false -- Disable line wrap
opts.guicursor = ""
opts.textwidth = 80

vim.loader.enable()
