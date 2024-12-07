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
    branch = "devel",
    event = "VeryLazy",
    opts = {
      -- Terminal settings
      shell = vim.o.shell,
      float_width = 0.5,
      float_height = 0.4,
      move_amount = 3,
      resize_amount = 2,
      border = 'solid',

      -- Appearance
      highlights = {
        normal = 'Normal',
        border = 'FloatBorder',
        title = 'Title',
      },

      -- Window management
      min_width = 20,
      min_height = 3,


      -- custom terminals
      terminals = {
        ranger = {
          name = "Ranger",
          cmd = "ranger",
          type = "vertical",
          float_width = 0.8,
          float_height = 0.8,
          keymaps = {
            quit = "q",
            select = "<CR>",
            preview = "p",
          },
          on_exit = function(selected_file)
            if selected_file then
              vim.cmd('edit ' .. selected_file)
            end
          end
        },
        lazygit = {
          name = "LazyGit",
          cmd = "lazygit",
          type = "float",
          float_width = 0.9,
          float_height = 0.9,
          keymaps = {
            quit = "q",
            commit = "c",
            push = "P",
          },
        },
        btop = {
          name = "Btop",
          cmd = "btop",
          type = "float",
          float_width = 0.8,
          float_height = 0.8,
          keymaps = {
            quit = "q",
            help = "h",
          },
        },
        k9s = {
          name = "K9s",
          cmd = "k9s",
          type = "float",
          float_width = 0.9,
          float_height = 0.9,
          keymaps = {
            quit = "q",
            describe = "d",
            logs = "l",
          },
        },
      },

      -- Default keymaps
      use_default_keymaps = true,
      keymaps = {
        toggle = '<A-t>',
        new_vertical = '<C-\\>',
        new_horizontal = '<C-.>',
        new_float = '<C-A-t>',
        close = '<A-d>',
        next = '<C-PageDown>',
        prev = '<C-PageUp>',
        move_up = '<C-A-Up>',
        move_down = '<C-A-Down>',
        move_left = '<C-A-Left>',
        move_right = '<C-A-Right>',
        resize_up = '<C-S-Up>',
        resize_down = '<C-S-Down>',
        resize_left = '<C-S-Left>',
        resize_right = '<C-S-Right>',
        focus_bar = '<C-A-b>',
        repl_toggle = '<leader>rt',
        repl_send_line = '<leader>rl',
        repl_send_selection = '<leader>rs',
        repl_send_buffer = '<leader>rb',
        repl_clear = '<leader>rc',
        repl_history = '<leader>rh',
        repl_variables = '<leader>rv',
        repl_restart = '<leader>rR',
      },

      -- REPL configurations
      repl = {
        float_width = 0.6,
        float_height = 0.4,
        save_history = true,
        history_file = vim.fn.stdpath('data') .. '/neaterm_repl_history.json',
        max_history = 100,
        update_interval = 5000,
      },

      -- REPL language configurations
      repl_configs = {
        python = {
          name = "Python (IPython)",
          cmd = "ipython --no-autoindent --colors='Linux'",
          startup_cmds = {
            -- "import sys",
            -- "sys.ps1 = 'In []: '",
            -- "sys.ps2 = '   ....: '",
          },
          get_variables_cmd = "whos",
          inspect_variable_cmd = "?",
          exit_cmd = "exit()",
        },
        r = {
          name = "R (Radian)",
          cmd = "radian",
          startup_cmds = {
            -- "options(width = 80)",
            -- "options(prompt = 'R> ')",
          },
          get_variables_cmd = "ls.str()",
          inspect_variable_cmd = "str(",
          exit_cmd = "q(save='no')",
        },
        lua = {
          name = "Lua",
          cmd = "lua",
          exit_cmd = "os.exit()",
        },
        node = {
          name = "Node.js",
          cmd = "node",
          get_variables_cmd = "Object.keys(global)",
          exit_cmd = ".exit",
        },
        sh = {
          name = "Shell",
          cmd = vim.o.shell,
          startup_cmds = {
            "PS1='$ '",
            "TERM=xterm-256color",
          },
          get_variables_cmd = "set",
          inspect_variable_cmd = "echo $",
          exit_cmd = "exit",
        },
      },

      -- Terminal features
      features = {
        auto_insert = true,
        auto_close = true,
        restore_layout = true,
        smart_sizing = true,
        persistent_history = true,
        native_search = true,
        clipboard_sync = true,
        shell_integration = true,
      },
    },
    dependencies = {
      -- "nvim-lua/plenary.nvim",
      -- "ibhagwan/fzf-lua",
    },
  }
}
