vim.bo.makeprg = 'python %'
vim.opt_local.textwidth = 88
vim.opt_local.colorcolumn = '88'
---@param node_text string
---@return string
local function construct_pydoc_query(node_text)
  return ([[
[
;; import <dotted_name>
;; import <dotted_name> as <alias>
((import_statement
  name: [
    (dotted_name) @import
    (aliased_import
      name: (_) @alias
      alias: (_) @import)
  ]
  (#eq? @import "%s")))

;; from <module_name> import <dotted_name>
;; from <module_name> import <dotted_name> as <alias>
((import_from_statement
  module_name: (_) @module
  name: [
    (dotted_name) @import
    (aliased_import
      name: (_) @alias
      alias: (_) @import)
  ]
  (#eq? @import "%s")))
]
]]):format(node_text, node_text)
end

-- Return the fully qualified name of the given import name. The returned value
-- will be a table of strings where each string is a part of the import which
-- can be concatenated with a dot ('.').
---@param import_name string
---@return string[]
local function fully_qualified_name(import_name)
  local parser = vim.treesitter.get_parser(0)
  local tree = parser and parser:parse()[1]
  if not tree then
    vim.notify('Failed to parse the tree', vim.log.levels.ERROR)
    return {}
  end

  local ok, pydoc_query =
      pcall(vim.treesitter.query.parse, 'python', construct_pydoc_query(import_name))
  if not ok then
    vim.notify('Failed to parse the PyDoc query', vim.log.levels.ERROR)
    return {}
  end

  local root = tree:root()
  local start_row, _, end_row, _ = root:range()
  local qualname = {}
  for id, node in pydoc_query:iter_captures(root, 0, start_row, end_row) do
    local name = pydoc_query.captures[id]
    if name == 'module' then
      table.insert(qualname, vim.treesitter.get_node_text(node, 0))
    elseif name == 'alias' then
      table.insert(qualname, vim.treesitter.get_node_text(node, 0))
    end
  end

  return qualname
end

vim.api.nvim_buf_create_user_command(0, 'PyDoc', function(opts)
  local word = opts.args

  -- Extract the 'word' at the cursor {{{
  --
  -- By expanding leftwards across identifiers and the '.' operator, and
  -- rightwards across the identifier only.
  --
  -- For example:
  --   `import xml.dom.minidom`
  --            ^   !
  --
  -- With the cursor at ^ this returns 'xml'; at ! it returns 'xml.dom'.
  -- }}}
  if word == '' then
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local names = vim.split(
      line:sub(0, col):match '[%w_.]*$' .. line:match('^[%w_]*', col + 1),
      '.',
      { plain = true, trimempty = true }
    )
    local import_name = table.remove(names, 1)
    local qualname = fully_qualified_name(import_name)
    if vim.tbl_isempty(qualname) then
      table.insert(qualname, import_name)
    end
    vim.list_extend(qualname, names)
    word = table.concat(qualname, '.')
  end

  local ok, process = pcall(vim.system, { 'python', '-m', 'pydoc', word }, { text = true })
  if not ok then
    vim.notify(process, vim.log.levels.ERROR, { title = "PyDoc" })
    return
  end

  local result = process:wait()
  if result.code ~= 0 then
    vim.notify(result.stderr, vim.log.levels.ERROR, { title = "PyDoc" })
    return
  end

  local lines = vim.split(result.stdout or '', '\n', { plain = true, trimempty = true })

  -- In case `pydoc` cannot find the documentation for `word` {{{
  --
  -- The output is:
  --
  --     > No Python documentation found for '<word>'.
  --     > Use help() to get the interactive help utility.
  --     > Use help(str) for help on the str class.
  --
  -- We are only interested in the first line.
  -- }}}
  if #lines < 5 then
    vim.notify(lines[1], vim.log.levels.WARN, { title = "PyDoc" })
    return
  end

  vim.cmd(opts.mods .. ' split __doc__')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.readonly = true
  vim.bo.modifiable = false
  vim.bo.buftype = 'nofile'
  vim.bo.filetype = 'man'
  vim.bo.bufhidden = 'wipe'
end, {
  nargs = '?',
  desc = 'Provide documentation for the Python object at the cursor',
})

-- }}}

-- Similar to how `gf` works with a different keymap of `gK` for vertical split.
vim.keymap.set('n', 'gk', '<Cmd>PyDoc<CR>', { buffer = true })
vim.keymap.set('n', 'gK', '<Cmd>vertical PyDoc<CR>', { buffer = true })
vim.keymap.set('n', '<C-w>gk', '<Cmd>tab PyDoc<CR>', { buffer = true })
