return {
  -- {
  --   "Dan7h3x/signup.nvim",
  --   branch = "devel",
  --   event = "LspAttach",
  --   opts = {
  --     config = {
  --       silent = false,
  --       number = true,
  --       icons = {
  --         parameter = "",
  --         method = "󰡱",
  --         documentation = "󱪙",
  --       },
  --       colors = {
  --         parameter = "#86e1fc",
  --         method = "#c099ff",
  --         documentation = "#4fd6be",
  --         default_value = "#888888",
  --       },
  --       active_parameter_colors = {
  --         bg = "#86e1fc",
  --         fg = "#1a1a1a",
  --       },
  --       border = "solid",
  --       winblend = 10,
  --       auto_close = true,
  --       trigger_chars = { "(", "," },
  --       max_height = 10,
  --       max_width = 40,
  --       floating_window_above_cur_line = true,
  --       preview_parameters = true,
  --       debounce_time = 30,
  --       dock_mode = {
  --         enabled = false,
  --         position = "bottom", -- "bottom" | "top"
  --         height = 3,          -- number of lines
  --         padding = 1,         -- padding from edges
  --       },
  --       render_style = {
  --         separator = true,   -- Show separators between sections
  --         compact = true,     -- Compact mode removes empty lines
  --         align_icons = true, -- Align icons in separate column
  --       },
  --     }
  --   }
  --
  -- },
  {
    "Dan7h3x/neaterm.nvim",
    branch = "stable",
    event = "VeryLazy",
    opts = {
      -- Your custom options here (optional)
      repl_configs = {
        lisp = {
          name = "Lisp",
          cmd = "sbcl",
          exit_cmd = "(quit)",
        },

      }
    },
    dependencies = {
      -- "nvim-lua/plenary.nvim",
      -- "ibhagwan/fzf-lua",
    },
  }
}
