local M = {}

function M.load(colors, opts)
  local h = {}

  -- Load core highlights
  h = vim.tbl_deep_extend("force", h, require("aye.plugins.core").highlights(colors, opts))

  -- Load plugin highlights based on config
  for plugin, enabled in pairs(opts.plugins) do
    if enabled then
      local ok, plugin_highlights = pcall(require, "aye.plugins." .. plugin)
      if ok then
        h = vim.tbl_deep_extend("force", h, plugin_highlights.highlights(colors, opts))
      end
    end
  end

  return h
end

return M 