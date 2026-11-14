--- Pure geometry: turns a layout spec into float configs for input / list / preview.
local M = {}

M.presets = {
  default = { box = "horizontal", width = 0.84, height = 0.78, preview = 0.52 },
  ivy = { box = "horizontal", width = 1, height = 0.42, row = "bottom", preview = 0.5, backdrop = false },
  vertical = { box = "vertical", width = 0.72, height = 0.86, preview = 0.5 },
  telescope = { box = "horizontal", reverse = true, width = 0.8, height = 0.8, preview = 0.45 },
}

---@param name string|table
---@param layouts table<string, fly.LayoutSpec>
---@return fly.LayoutSpec
function M.resolve(name, layouts)
  local spec = type(name) == "table" and name or (layouts or {})[name] or M.presets[name] or {}
  local base = spec.preset and M.presets[spec.preset] or {}
  return vim.tbl_extend("force", M.presets.default, base, spec)
end

local function size(val, total)
  if val <= 1 then
    return math.floor(total * val)
  end
  return math.floor(val)
end

local function clamp(v, lo, hi)
  return math.max(lo, math.min(v, hi))
end

---@class fly.Rect
---@field row integer  outer top-left (border included), 0-based
---@field col integer
---@field width integer  content size (border excluded)
---@field height integer

---@param spec fly.LayoutSpec
---@param show_preview boolean
---@param has_border boolean
---@return { input: fly.Rect, list: fly.Rect, preview?: fly.Rect, flip: boolean, backdrop: boolean|number }
function M.compute(spec, show_preview, has_border)
  local b = has_border and 1 or 0
  local ui_w = vim.o.columns
  local ui_h = vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)

  -- outer box (borders included)
  local W = clamp(size(spec.width, ui_w), math.min(40, ui_w), ui_w)
  local H = clamp(size(spec.height, ui_h), math.min(10, ui_h), ui_h)
  local col = math.floor((ui_w - W) / 2)
  local row = spec.row == "bottom" and (ui_h - H) or math.floor((ui_h - H) / 2)

  local input_outer = 1 + 2 * b
  local left_w, left_h = W, H
  local prev_rect

  if show_preview then
    local frac = spec.preview or 0.5
    if spec.box == "vertical" then
      local ph = clamp(math.floor(H * frac), 3 + 2 * b, H - (input_outer + 3 + 2 * b))
      left_h = H - ph
      prev_rect = { row = row + left_h, col = col, width = W - 2 * b, height = ph - 2 * b }
    else
      local pw = clamp(math.floor(W * frac), 10 + 2 * b, W - 20)
      left_w = W - pw
      prev_rect = { row = row, col = col + left_w, width = pw - 2 * b, height = H - 2 * b }
    end
  end

  local list_outer = math.max(left_h - input_outer, 3 + 2 * b)
  local input, list
  if spec.reverse then
    list = { row = row, col = col, width = left_w - 2 * b, height = list_outer - 2 * b }
    input = { row = row + list_outer, col = col, width = left_w - 2 * b, height = 1 }
  else
    input = { row = row, col = col, width = left_w - 2 * b, height = 1 }
    list = { row = row + input_outer, col = col, width = left_w - 2 * b, height = list_outer - 2 * b }
  end

  local backdrop = spec.backdrop
  return { input = input, list = list, preview = prev_rect, flip = spec.reverse == true, backdrop = backdrop }
end

return M
