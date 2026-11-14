--- Text backend: no images. Blocks are rendered as Unicode (see mip/text.lua) and
--- shown through the same conceal + virtual text machinery as the image backends.
--- Works in every terminal (alacritty, linux console, ...) and needs no external tools.
local api = vim.api

local X = { name = "text", positional = false, text = true, max_cells = 200 }

function X.supported() return true end

function X.init()
  local function set(name, link) api.nvim_set_hl(0, name, { link = link, default = true }) end
  set("MIPInline", "Special")
  set("MIPBlock", "Special")
  set("MIPTable", "Normal")
  set("MIPFigure", "Comment")
  for i = 1, 4 do set("MIPHeading" .. i, "Title") end
end

function X.new_id() return 0 end

function X.texts() return {} end

function X.upload() end

function X.free() end

function X.shutdown() end

return X
