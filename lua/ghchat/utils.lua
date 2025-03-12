local M = {}

-- Check if a table is empty
function M.is_empty(table)
  return next(table) == nil
end

-- Deep copy a table
function M.deep_copy(table)
  return vim.fn.deepcopy(table)
end

return M
