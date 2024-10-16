--[[
-- Theme related plugins
--]]
--
--

return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "moon",
    },
  }, {
  "yorik1984/newpaper.nvim",
  lazy = true,
  style = "light",
  priority = 1000,
  config = true,
}, {
  "eldritch-theme/eldritch.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    transparent = false,    -- Enable this to disable setting the background color
    terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
    styles = {
      -- Style to be applied to different syntax groups
      -- Value is any valid attr-list value for `:help nvim_set_hl`
      comments = { italic = true },
      keywords = { italic = true },
      -- Background styles. Can be "dark", "transparent" or "normal"
      sidebars = "dark",                                            -- style for sidebars, see below
      floats = "dark",                                              -- style for floating windows
    },
    sidebars = { "qf", "help", "neo-tree", "terminal", "neaterm" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
    hide_inactive_statusline = false,                               -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
    dim_inactive = false,                                           -- dims inactive windows, transparent must be false for this to work
    lualine_bold = true,                                            -- When `true`, section headers in the lualine theme will be bold

    --- You can override specific color groups to use other groups or a hex color
    --- function will be called with a ColorScheme table
    ---@param colors ColorScheme
    on_colors = function(colors) end,

    --- You can override specific highlights to use other groups or a hex color
    --- function will be called with a Highlights and ColorScheme table
    ---@param highlights Highlights
    ---@param colors ColorScheme
    on_highlights = function(highlights, colors) end,
  },
}

}
