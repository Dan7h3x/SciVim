---@class MaculaPalettes
---@field garden table
---@field warm table
---@field amber table
---@field forest table
---@field sky table
---@field meadow table
---@field dusk table
---@field light table
---@field nord table
---@field evergreen table
---@field ocean table
---@field twilight table
---@field dawn table
---@field cream table
---@field paper table
---@field latte table
---@field cloud table
---@field mist table
---@field silk table

local M = {}

-- Export all palettes
M.garden = require("macula.palletes.garden")
M.warm = require("macula.palletes.warm")
M.amber = require("macula.palletes.amber")
M.forest = require("macula.palletes.forest")
M.sky = require("macula.palletes.sky")
M.meadow = require("macula.palletes.meadow")
M.dusk = require("macula.palletes.dusk")
M.light = require("macula.palletes.light")
M.nord = require("macula.palletes.nord")
M.evergreen = require("macula.palletes.evergreen")
M.ocean = require("macula.palletes.ocean")
M.twilight = require("macula.palletes.twilight")
-- Eye-protective light palettes
M.dawn = require("macula.palletes.dawn")
M.cream = require("macula.palletes.cream")
M.paper = require("macula.palletes.paper")
M.latte = require("macula.palletes.latte")
M.cloud = require("macula.palletes.cloud")
M.mist = require("macula.palletes.mist")
M.silk = require("macula.palletes.silk")

return M
