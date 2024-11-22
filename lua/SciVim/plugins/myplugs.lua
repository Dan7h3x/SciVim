return {
  {
    "Dan7h3x/signup.nvim",
    -- branch = "main",
    event = "LspAttach",
    config = function()
      require('signup').setup(
        {
          win = nil,
          buf = nil,
          timer = nil,
          visible = false,
          current_signatures = nil,
          enabled = false,
          normal_mode_active = false,
          config = {
            silent = false,
            number = true,
            icons = {
              parameter = " ",
              method = " ",
              documentation = " ",
            },
            colors = {
              parameter = "#86e1fc",
              method = "#c099ff",
              documentation = "#4fd6be",
            },
            active_parameter_colors = {
              bg = "#1af1fc",
              fg = "#1a1a1a",
            },
            border = "solid",
            winblend = 10,
          }
        }
      )
    end
  },
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
