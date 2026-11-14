local M = {}

local links = {
  FlyNormal = "NormalFloat",
  FlyBorder = "FloatBorder",
  FlyTitle = "FloatTitle",
  FlyFooter = "FloatFooter",
  FlyPrompt = "Special",
  FlyCursorLine = "CursorLine",
  FlyMatch = "Special",
  FlyDir = "Comment",
  FlyExtra = "Comment",
  FlyEmpty = "Comment",
  FlySelected = "DiagnosticOk",
  FlyPreviewLine = "Visual",
  FlyPreviewMatch = "Search",
  FlyIcon = "Special",
}

--- Define default highlight groups (`default = true`, so colorschemes/users win).
function M.setup()
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
  vim.api.nvim_set_hl(0, "FlyBackdrop", { bg = "#000000", default = true })
end

return M
