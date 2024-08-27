--[[
-- Theme related plugins
--]]
--
return {
  {
    "folke/tokyonight.nvim",
    event = { "VeryLazy" },
    priority = 1000,
    opts = {
      style = "moon",
    },
  },
  { "nyoom-engineering/oxocarbon.nvim", lazy = true },
  { "bluz71/vim-nightfly-colors",       name = "nightfly", event = "VeryLazy", priority = 1000 },
}
