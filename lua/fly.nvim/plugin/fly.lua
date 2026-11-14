if vim.g.loaded_fly then
  return
end
vim.g.loaded_fly = true

if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("fly.nvim requires Neovim >= 0.10", vim.log.levels.ERROR)
  return
end

require("fly.highlights").setup()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("fly.highlights", { clear = true }),
  callback = function()
    require("fly.highlights").setup()
  end,
})

local function parse_value(v)
  if v == "true" then
    return true
  elseif v == "false" then
    return false
  end
  return tonumber(v) or v
end

-- :Fly [source] [key=value ...] [query words]    |    :Fly resume
vim.api.nvim_create_user_command("Fly", function(cmd)
  local args = cmd.fargs
  local source = table.remove(args, 1) or "files"
  if source == "resume" then
    return require("fly").resume()
  end
  local opts, query = { source = source }, {}
  for _, a in ipairs(args) do
    local k, v = a:match("^(%a[%w_]*)=(.*)$")
    if k then
      opts[k] = parse_value(v)
    else
      query[#query + 1] = a
    end
  end
  if #query > 0 then
    opts.query = table.concat(query, " ")
  end
  require("fly").pick(opts)
end, {
  nargs = "*",
  desc = "Open a fly picker",
  complete = function(lead, line)
    local nargs = #vim.split(vim.trim(line), "%s+")
    if nargs <= 1 or (nargs == 2 and not line:match("%s$")) then
      local names = require("fly.sources").names()
      table.insert(names, 1, "resume")
      return vim.tbl_filter(function(n)
        return vim.startswith(n, lead)
      end, names)
    end
    return vim.tbl_filter(function(n)
      return vim.startswith(n, lead)
    end, { "cwd=", "query=", "hidden=", "ignored=", "layout=", "regex=", "buffer=", "current_file=" })
  end,
})
