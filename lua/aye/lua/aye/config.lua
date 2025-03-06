local M = {}

M.defaults = {
  -- Style configurations
  styles = {
    comments = { italic = true },
    keywords = { italic = false, bold = false },
    functions = { bold = false },
    variables = {},
    strings = { italic = false },
    types = { italic = false, bold = true },
  },
  -- Plugin specific configurations
  plugins = {
    alpha = true,
    bufferline = true,
    cmp = true,
    dap = true,
    gitsigns = true,
    indent_blankline = true,
    lsp = true,
    lualine = false,
    mini = true,
    navic = true,
    neotree = true,
    noice = true,
    notify = true,
    telescope = true,
    treesitter = true,
    which_key = true,
  },
}

function M.extend(opts)
  return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M