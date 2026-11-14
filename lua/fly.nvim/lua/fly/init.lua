---@class fly
local M = {}

M.config = vim.deepcopy(require("fly.config").defaults)

require("fly.image").setup(M.config.image)

--- Built-in sources exposed as `require("fly").<name>(opts)`.
local source_names = {
  "files", "recent", "buffers", "grep", "lines", "git", "git_files", "git_log", "help", "commands",
  "symbols", "workspace_symbols", "diagnostics", "images", "colorschemes", "keymaps", "marks",
  "registers", "quickfix", "jumps",
}

---@param opts? table  see fly.config
function M.setup(opts)
  opts = opts or {}
  if opts.layout ~= nil then
    local t = type(opts.layout)
    assert(t == "string" or t == "table", "fly: `layout` must be a string or a table")
  end
  -- migrate: preview.image used to hold image options
  if type(opts.preview) == "table" and opts.preview.image then
    opts.image = vim.tbl_deep_extend("force", opts.preview.image, opts.image or {})
    opts.preview.image = nil
  end
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  require("fly.highlights").setup()
  require("fly.image").setup(M.config.image)
  if M.config.ui_select then
    vim.ui.select = M.select
  end
end

--- Open a picker. `opts.source` is a source name or table; `opts.items` builds a static list.
---@param opts? table
function M.pick(opts)
  return require("fly.picker").open(opts)
end

function M.resume()
  return require("fly.picker").resume()
end

--- `vim.ui.select` replacement.
function M.select(items, opts, on_choice)
  return require("fly.picker").select(items, opts, on_choice)
end

--- Register a custom source: `require("fly").register("todo", { title = ..., find = function(ctx) ... end })`.
---@param name string
---@param source fly.Source
function M.register(name, source)
  require("fly.sources").register(name, source)
  M[name] = M[name] or function(opts)
    return M.pick(vim.tbl_extend("force", opts or {}, { source = name }))
  end
end

M.actions = require("fly.picker").actions

for _, name in ipairs(source_names) do
  M[name] = function(opts)
    return M.pick(vim.tbl_extend("force", opts or {}, { source = name }))
  end
end

--- Grep for the word under the cursor.
function M.grep_word(opts)
  return M.grep(vim.tbl_extend("force", { query = vim.fn.expand("<cword>") }, opts or {}))
end

--- Grep for the current visual selection.
function M.grep_visual(opts)
  local old = vim.fn.getreg("v")
  vim.cmd('noautocmd normal! "vy')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", old)
  return M.grep(vim.tbl_extend("force", { query = vim.trim((text:gsub("\n.*", ""))), regex = false }, opts or {}))
end

--- Files from the git repo when inside one, otherwise all files.
function M.smart(opts)
  local root = require("fly.util").git_root(vim.fn.getcwd())
  return root and M.git_files(opts) or M.files(opts)
end

return M
