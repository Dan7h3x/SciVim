---@type fly.Source
local M = { title = "images", icons = true }

function M.start(ctx, push, done)
  local image = require("fly.image")
  return require("fly.sources.files").start(ctx, push, done, function(rel)
    return image.is_image(rel)
  end)
end

return M
