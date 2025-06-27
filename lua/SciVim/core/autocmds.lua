--[[
-- AutoCmds for SciVim
--]]
local function augroup(name)
    return vim.api.nvim_create_augroup("SciVim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = augroup("opening"),
    pattern = "*",
    command = [[%s/\s\+$//e]],
})
vim.api.nvim_create_autocmd('FileType', {
    group = augroup('treesitter_folding'),
    desc = 'Enable Treesitter folding',
    callback = function(args)
        local bufnr = args.buf

        -- Enable Treesitter folding when not in huge files and when Treesitter
        -- is working.
        if vim.bo[bufnr].filetype ~= 'bigfile' and pcall(vim.treesitter.start, bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                vim.wo[0][0].foldmethod = 'expr'
                vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                vim.cmd.normal 'zx'
            end)
        else
            -- Else just fallback to using indentation.
            vim.wo[0][0].foldmethod = 'indent'
        end
    end,
})
-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = augroup("checktime"),
    callback = function()
        if vim.o.buftype ~= "nofile" then
            vim.cmd("checktime")
        end
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = augroup("help_window_right"),
    pattern = { "*.txt" },
    callback = function()
        if vim.o.filetype == "help" then
            vim.cmd.wincmd("L")
        end
    end,
    desc = "Help page at right",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        (vim.hl or vim.highlight).on_yank()
    end,
})
-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd("tabdo wincmd =")
        vim.cmd("tabnext " .. current_tab)
    end,
})
-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function(event)
        local exclude = { "gitcommit" }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_location then
            return
        end
        vim.b[buf].last_location = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "PlenaryTestPopup",
        "help",
        "lspinfo",
        "man",
        "notify",
        "qf",
        "query",
        "spectre_panel",
        "startuptime",
        "tsplayground",
        "bookmarks",
        "neotest-output",
        "checkhealth",
        "neotest-summary",
        "neotest-output-panel",
        "dbout",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "text", "plaintex", "tex", "typst", "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        vim.opt_local.colorcolumn = "0"
    end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = augroup("auto_create_dir"),
    callback = function(event)
        if event.match:match("^%w%w+:[\\/][\\/]") then
            return
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = augroup("SciVimColors"),
    callback = function()
        -- Alpha
        vim.api.nvim_set_hl(0, "SciVim18", { fg = "#14067E", ctermfg = 18 })
        vim.api.nvim_set_hl(0, "SciVimPy1", { fg = "#15127B", ctermfg = 18 })
        vim.api.nvim_set_hl(0, "SciVim17", { fg = "#171F78", ctermfg = 18 })
        vim.api.nvim_set_hl(0, "SciVim16", { fg = "#182B75", ctermfg = 18 })
        vim.api.nvim_set_hl(0, "SciVimPy2", { fg = "#193872", ctermfg = 23 })
        vim.api.nvim_set_hl(0, "SciVim15", { fg = "#1A446E", ctermfg = 23 })
        vim.api.nvim_set_hl(0, "SciVim14", { fg = "#1C506B", ctermfg = 23 })
        vim.api.nvim_set_hl(0, "SciVimPy3", { fg = "#1D5D68", ctermfg = 23 })
        vim.api.nvim_set_hl(0, "SciVim13", { fg = "#1E6965", ctermfg = 23 })
        vim.api.nvim_set_hl(0, "SciVim12", { fg = "#1F7562", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVimPy4", { fg = "#21825F", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVim11", { fg = "#228E5C", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVim10", { fg = "#239B59", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVim9", { fg = "#24A755", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVim8", { fg = "#26B352", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVimPy5", { fg = "#27C04F", ctermfg = 29 })
        vim.api.nvim_set_hl(0, "SciVim7", { fg = "#28CC4C", ctermfg = 41 })
        vim.api.nvim_set_hl(0, "SciVim6", { fg = "#47D326", ctermfg = 41 })
        vim.api.nvim_set_hl(0, "SciVim5", { fg = "#ECCF05", ctermfg = 214 })
        vim.api.nvim_set_hl(0, "SciVim4", { fg = "#F0AC04", ctermfg = 208 })
        vim.api.nvim_set_hl(0, "SciVimPy6", { fg = "#F39E03", ctermfg = 208 })
        vim.api.nvim_set_hl(0, "SciVim3", { fg = "#F77909", ctermfg = 202 })
        vim.api.nvim_set_hl(0, "SciVim2", { fg = "#FB5D01", ctermfg = 202 })
        vim.api.nvim_set_hl(0, "SciVim1", { fg = "#FF4E00", ctermfg = 202 })
    end,
})


-- Create augroup once to avoid duplication
-- local python_config_group = vim.api.nvim_create_augroup("PythonConfig", { clear = true })
-- local function create_project_structure(cwd)
--     local dirs = { "src", "tests", "docs" }
--
--
--     -- Create directories
--     for _, dir in ipairs(dirs) do
--         local dir_path = cwd .. "/" .. dir
--         if vim.fn.isdirectory(dir_path) == 0 then
--             vim.fn.mkdir(dir_path, "p")
--         end
--     end
--
--     -- Create .gitignore if it doesn't exist
--     local gitignore_path = cwd .. "/.gitignore"
--     if vim.fn.filereadable(gitignore_path) == 0 then
--         local gitignore_content = [[
-- # Python
-- __pycache__/
-- *.py[cod]
-- *$py.class
-- *.so
-- .Python
-- build/
-- develop-eggs/
-- dist/
-- downloads/
-- eggs/
-- .eggs/
-- lib/
-- lib64/
-- parts/
-- sdist/
-- var/
-- wheels/
-- *.egg-info/
-- .installed.cfg
-- *.egg
--
-- # Virtual environments
-- .env
-- .venv
-- env/
-- venv/
-- ENV/
-- env.bak/
-- venv.bak/
--
-- # IDE
-- .vscode/
-- .idea/
-- *.swp
-- *.swo
-- *~
--
-- # Testing
-- .coverage
-- .pytest_cache/
-- .tox/
-- .nox/
-- htmlcov/
--
-- # MyPy
-- .mypy_cache/
-- .dmypy.json
-- dmypy.json
--
-- # Ruff
-- .ruff_cache/
--
-- # OS
-- .DS_Store
-- Thumbs.db
-- ]]
--
--         local gitignore_file = io.open(gitignore_path, "w")
--         if gitignore_file then
--             gitignore_file:write(gitignore_content)
--             gitignore_file:close()
--         end
--     end
-- end

-- Enhanced configuration function
-- local function setup_python_config()
--     local cwd = vim.fn.getcwd()
--     local pyproject_path = cwd .. "/pyproject.toml"
--
--     -- Check if pyproject.toml already exists
--     local file_stat = vim.loop.fs_stat(pyproject_path)
--     if file_stat then
--         -- File exists, just print a message if needed
--         return
--     end
--
--     -- Enhanced pyproject.toml template with comprehensive configuration
--     local pyproject_template = [[
-- # Enhanced Pyright configuration for better LSP experience
-- [tool.pyright]
-- include = ["src", "tests", "scripts", "."]
-- exclude = [
--     "**/node_modules",
--     "**/__pycache__",
--     ".venv",
--     "venv",
--     "env",
--     ".env",
--     "build",
--     "dist",
--     ".git",
--     ".pytest_cache",
--     ".mypy_cache",
--     ".ruff_cache"
-- ]
-- defineConstant = { DEBUG = true }
-- stubPath = "typings"
-- venvPath = "."
-- venv = ".venv"
--
-- # Type checking settings
-- strictListInference = true
-- strictDictionaryInference = true
-- reportMissingImports = "warning"
-- reportMissingTypeStubs = "warning"
-- reportMissingParameterType = "warning"
-- reportMissingReturnType = "warning"
-- reportUnusedVariable = "warning"
-- reportUnusedImport = "warning"
--
--
-- # Enhanced Ruff configuration
-- [tool.ruff]
-- indent-width = 2
--
-- exclude = [
--     ".bzr", ".direnv", ".eggs", ".git", ".git-rewrite", ".hg",
--     ".ipynb_checkpoints", ".mypy_cache", ".nox", ".pants.d",
--     ".pyenv", ".pytest_cache", ".pytype", ".ruff_cache", ".svn",
--     ".tox", ".venv", ".vscode", "__pypackages__", "_build",
--     "buck-out", "build", "dist", "node_modules", "site-packages",
--     "venv", "env", ".env"
-- ]
--
-- [tool.ruff.lint]
-- select = [
--     "E", "W",    # pycodestyle
--     "F",         # pyflakes
--     "I",         # isort
--     "N",         # pep8-naming
--     "UP",        # pyupgrade
--     "B",         # flake8-bugbear
--     "A",         # flake8-builtins
--     "C4",        # flake8-comprehensions
--     "SIM",       # flake8-simplify
--     "PTH",       # flake8-use-pathlib
--     "RUF",       # ruff-specific rules
-- ]
--
-- ignore = [
--     "E501",      # Line too long (handled by formatter)
--     "D100", "D101", "D102", "D103", "D104", "D105", "D107",  # Missing docstrings
-- ]
--
-- fixable = ["ALL"]
-- unfixable = []
-- dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"
--
-- [tool.ruff.lint.per-file-ignores]
-- "tests/**/*" = ["S101", "PLR2004"]  # Allow assert and magic values in tests
-- "__init__.py" = ["F401"]            # Allow unused imports in __init__.py
--
-- [tool.ruff.lint.isort]
-- force-sort-within-sections = true
-- split-on-trailing-comma = true
--
-- [tool.ruff.format]
-- quote-style = "double"
-- indent-style = "tab"
-- skip-magic-trailing-comma = false
-- line-ending = "auto"
-- docstring-code-format = true
-- ]]
--
--     -- Write the file with proper error handling
--     local file, err = io.open(pyproject_path, "w")
--     if not file then
--         vim.notify("Failed to create pyproject.toml: " .. tostring(err), vim.log.levels.ERROR)
--         return
--     end
--
--     file:write(pyproject_template)
--     file:close()
--
--     vim.notify("Python project configured with pyproject.toml", vim.log.levels.INFO)
--
--     -- Optionally create additional project structure
--     create_project_structure(cwd)
-- end

-- Function to create basic project structure


-- Enhanced autocmd with better pattern matching and conditions
-- vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
--     group = python_config_group,
--     pattern = { "*.py" },
--     callback = function(args)
--         -- Only run once per project (check if we're in the root of a Python project)
--         local buf_dir = vim.fn.expand("%:p:h")
--         local current_dir = buf_dir
--
--         -- Walk up the directory tree to find project root
--         while current_dir ~= "/" do
--             local pyproject_exists = vim.fn.filereadable(current_dir .. "/pyproject.toml") == 1
--             local setup_py_exists = vim.fn.filereadable(current_dir .. "/setup.py") == 1
--             local requirements_exists = vim.fn.filereadable(current_dir .. "/requirements.txt") == 1
--
--             if pyproject_exists or setup_py_exists or requirements_exists then
--                 -- We're in a Python project, don't create another config
--                 return
--             end
--
--             -- Check if we're at a reasonable project root (has .git or is the cwd)
--             local git_exists = vim.fn.isdirectory(current_dir .. "/.git") == 1
--             local is_cwd = current_dir == vim.fn.getcwd()
--
--             if git_exists or is_cwd then
--                 -- This looks like a project root, set up configuration
--                 vim.fn.chdir(current_dir)
--                 setup_python_config()
--                 return
--             end
--
--             current_dir = vim.fn.fnamemodify(current_dir, ":h")
--         end
--
--         -- If we reach here, we're not in an obvious project structure
--         -- Only create config in the current working directory
--         if vim.fn.getcwd() == buf_dir or vim.startswith(buf_dir, vim.fn.getcwd()) then
--             setup_python_config()
--         end
--     end,
-- })

-- Additional autocmd for Python-specific settings
vim.api.nvim_create_autocmd({ "FileType", "BufReadPost", "BufNewFile" }, {
    pattern = "python",
    callback = function()
        -- Python-specific buffer settings
        vim.opt_local.tabstop = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = true
        vim.cmd("silent! retab")
    end,
})

-- Command to manually trigger Python configuration
-- vim.api.nvim_create_user_command("PythonSetup", function()
--     setup_python_config()
-- end, {
--     desc = "Create pyproject.toml and Python project structure"
-- })

local openPDF = augroup("openPDF")
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = {
        "*.pdf",
    },
    callback = function()
        vim.fn.jobstart({ "zathura", vim.fn.expand("%:p") }, { detach = true })
    end,
    group = openPDF,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif" },
    callback = function()
        vim.fn.jobstart({ "feh", vim.fn.expand("%:p") }, { detach = true })
    end,
})
vim.api.nvim_create_user_command("TypstPdf", function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if not filepath:match("%.typ$") then
        vim.notify("Can't open pdf related to .typ file", vim.log.levels.WARN)
        return
    end
    if filepath:match("%.typ$") then
        -- os.execute("open " .. vim.fn.shellescape(filepath:gsub("%.typ$", ".pdf")))
        -- replace open with your preferred pdf viewer
        os.execute("zathura " .. vim.fn.shellescape(filepath:gsub("%.typ$", ".pdf")) .. " &>/dev/null &")
    end
end, { force = true })

vim.api.nvim_create_autocmd(
    "BufWritePre",
    {
        pattern = { "typst", "*.typ" },
        callback = function()
            local fn = vim.fn.expand('%:p')
            vim.fn.system("typst compile " .. vim.fn.shellescape(fn))
        end
    }
)

vim.api.nvim_create_user_command('Todos', function()
    require('fzf-lua').grep { search = [[TODO:|todo!\(.*\)]], no_esc = true }
end, { desc = 'Grep TODOs', nargs = 0 })
