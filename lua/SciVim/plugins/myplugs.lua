return {
  -- {
  --   "Dan7h3x/signup.nvim",
  --   event = "LspAttach",
  --   config = function()
  --     require("signup").setup(
  --     -- Your configuration options here
  --       {
  --         silent = true,
  --         number = true,
  --         icons = {
  --           parameter = " ",
  --           method = " ",
  --           documentation = " ",
  --         },
  --         colors = {
  --           parameter = "#86e1fc",
  --           method = "#c099ff",
  --           documentation = "#4fd6be",
  --         },
  --         border = "rounded",
  --         winblend = 5,
  --         override = true, -- Override default LSP handler for signatureHelp
  --       }
  --     )
  --   end
  -- }
  {
    "Dan7h3x/neaterm.nvim",
    lazy = false,
    branch = "stable",
    dependencies = {
      "ibhagwan/fzf-lua", -- Required for variable inspection
    },
    opts = {
      shell = vim.o.shell,
      float_width = 0.6,
      float_height = 0.4,
      border = "rounded",
      highlights = {
        normal = "Normal",
        border = "FloatBorder",
      },
      special_terminals = {
        ranger = {
          cmd = "ranger",
          type = "float",
          keymap = "<C-A-r>",
        },
        htop = {
          cmd = "htop",
          type = "float",
          keymap = "<C-A-h>",
        },
      },
      repl_configs = {
        -- Override default Python config
        python = {
          name = "Python (IPython)",
          cmd = "ipython3 --no-autoindent --colors='Linux'",
          -- startup_cmds = {
          --   -- "import numpy as np",
          --   -- "import pandas as pd",
          --   -- "import matplotlib.pyplot as plt",
          -- },
        },
        -- Add R configuration
        r = {
          name = "R Statistical Computing",
          cmd = "radian",
          -- startup_cmds = {
          --   "library(tidyverse)",
          --   "library(ggplot2)",
          -- },
          get_variables_cmd = "ls()",
          inspect_variable_cmd = "str(", -- Will be appended with ")"
          exit_cmd = "q()",
          parse_variables = function(output)
            local vars = {}
            for name in output:gmatch("[%w_]+") do
              local type_cmd = string.format("class(%s)", name)
              -- You might want to implement a way to get the actual type
              vars[name] = { type = "unknown", size = "N/A" }
            end
            return vars
          end
        },
        -- Add Julia configuration
        julia = {
          name = "Julia",
          cmd = "julia",
          startup_cmds = {
            "using Pkg",
            "using Statistics",
          },
          get_variables_cmd = "names(Main)",
          exit_cmd = "exit()",
        },
        -- Add Scala configuration
        scala = {
          name = "Scala REPL",
          cmd = "scala",
          startup_cmds = {
            "import scala.collection.mutable._",
          },
          exit_cmd = ":quit",
        },
      },

      -- REPL-specific settings
      repl = {
        auto_close = true,       -- Automatically close REPL when leaving buffer
        auto_update_vars = true, -- Automatically update variables list
        update_interval = 5,     -- Update variables every 5 seconds
        float_width = 0.6,       -- Wider REPL window
        float_height = 0.4,
      },
      -- Default keymaps (can be overridden)
      keymaps = {
        -- REPL-specific keymaps--
        toggle = '<A-t>',
        new_vertical = '<C-\\>',
        new_horizontal = '<C-.>',
        new_float = '<C-A-t>',
        close = '<C-d>',
        next = '<C-PageDown>',
        prev = '<C-PageUp>',
        move_up = '<C-A-Up>',
        move_down = '<C-A-Down>',
        move_left = '<C-A-Left>',
        move_right = '<C-A-Right>',
        resize_up = '<C-S-Up>',
        resize_down = '<C-S-Down>',
        resize_left = '<C-S-Left>',
        resize_right = '<C-S-Right>', -- REPL keymaps
        repl_toggle = "<leader>rt",
        repl_send_line = "<leader>rl",
        repl_send_selection = "<leader>rs",
        repl_send_buffer = "<leader>rb",
        repl_clear = "<leader>rc",
        repl_history = "<leader>rh",
        repl_variables = "<leader>rv",
        repl_restart = "<leader>rR",
        repl_start = "<leader>rs",
        repl_close = "<leader>rc",
      },
    },
    config = function(_, opts)
      require("neaterm").setup(opts)
    end,
  }
}
