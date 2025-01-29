--[[
-- Theme related plugins
--]]
--
--

return {

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = {     -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = true, -- disables setting the background color.
      show_end_of_buffer = false,    -- shows the '~' characters after the end of buffers
      term_colors = false,           -- sets terminal colors (e.g. `g:terminal_color_0`)
      dim_inactive = {
        enabled = false,             -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15,           -- percentage of the shade to apply to the inactive window
      },
      no_italic = false,             -- Force no italic
      no_bold = false,               -- Force no bold
      no_underline = false,          -- Force no underline
      styles = {                     -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { "italic" },     -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = { "bold" },
        numbers = {},
        booleans = {},
        properties = {},
        types = { "bold" },
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      color_overrides = {},
      custom_highlights = {},
      default_integrations = true,
      integrations = {
        blink_cmp = true,
        dropbar = {
          enabled = true,
          color_mode = true, -- enable color for kind's texts, not just kind's icons
        },
        symbols_outline = true,
        lsp_trouble = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mason = true,
        nvim_surround = true,
        which_key = true,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    }
  },
  {
    "yorik1984/newpaper.nvim",
    lazy = true,
    style = "light",
    priority = 1000,
    config = true,
  },
}
