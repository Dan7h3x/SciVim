return {
  -- "Dan7h3x/signup.nvim",
  -- branch = "devel",
  dir = "~/.config/nvim/lua/SciVim/signup/",
  event = "LspAttach", -- or "InsertEnter" if you only want it in insert normal_mode
  opts = {
    silent = false,
    number = true,
    icons = {
      parameter = "",
      method = "󰡱",
      documentation = "󱪙",
    },
    colors = {
      parameter = "#86e1fc",
      method = "#c099ff",
      documentation = "#4fd6be",
      default_value = "#a80888",
    },
    active_parameter_colors = {
      bg = "#a1a1a1",
      fg = "#faea4a",
    },
    border = "rounded",
    winblend = 5,
    auto_close = true,
    trigger_chars = { "(", "," },
    max_height = 10,
    max_width = 40,
    floating_window_above_cur_line = true,
    preview_parameters = true,
    debounce_time = 30,
    dock_toggle_key = "<Leader>sd",
    toggle_key = "<C-k>",
    dock_mode = {
      enabled = false,
      position = "bottom",
      height = 3,
      padding = 10,
    },
    render_style = {
      separator = true,
      compact = true,
      align_icons = true,
    },
  },
  config = function(_, opts)
    require("SciVim.signup").setup(opts)
  end,

  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- Optional, for better syntax highlighting
  },
}
