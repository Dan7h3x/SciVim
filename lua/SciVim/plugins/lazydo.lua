return {
  {
    "Dan7h3x/LazyDo",
    branch = "main",
    event = "VeryLazy",
    cmd = {
      "LazyDoToggle",
      "LazyDoPin",
    },
    keys = {
      {
        "<F2>",
        "<ESC><CMD>LazyDoToggle<CR>",
        desc = "LazyDoToggle panel",
        mode = { "n", "i" },
      },
      {
        "<F3>",
        "<CMD>LazyDoPin<CR>",
        desc = "LazyDoPin panel",
        mode = { "n", "i" },
      },
    },
    opts = {
      title = " My Tasks ",
      layout = {
        width = 0.5,      -- Percentage of screen width
        height = 0.8,     -- Percentage of screen height
        spacing = 1,      -- Lines between tasks
        task_padding = 1, -- Padding around task content
      },
      storage = {
        global_path = vim.fn.stdpath("data") .. "/MyTasks.json",
        project = {
          enabled = false,
          use_git_root = true,
          path_pattern = "%s/.lazydo/MyProjectTasks.json"
        },
      },
      pin_window = {
        enabled = true,
        width = 50,
        max_height = 10,
        position = "topright",   -- "topright", "topleft", "bottomright", "bottomleft"
        title = " My Tasks ",
        show_on_startup = false, -- New option
        auto_sync = true,        -- Enable automatic synchronization with main window
        colors = {
          border = { fg = "#42fbfb" },
          title = { fg = "#19ff0f", bold = true },
        },
      },
      theme = {
        border = "rounded",
        colors = {
          header = { fg = "#7aa2f7", bold = true },
          title = { fg = "#7dcfff", bold = true },
          task = {
            pending = { fg = "#a9b1d6" },
            done = { fg = "#56ff89", italic = true },
            overdue = { fg = "#f7768e", bold = true },
            blocked = { fg = "#f7768e", italic = true },
            in_progress = { fg = "#7aa2f7", bold = true },
            info = { fg = "#78ac99", italic = true },
          },
          priority = {
            high = { fg = "#f7768e", bold = true },
            medium = { fg = "#e0af68" },
            low = { fg = "#9ece6a" },
            urgent = { fg = "#db4b4b", bold = true, undercurl = true },
          },
          -- In config.lua, update the notes colors:
          notes = {
            header = {
              fg = "#7dcfff",
              bold = true,
            },
            body = {
              fg = "#d9a637",
              italic = true,
            },
            border = {
              fg = "#3b4261",
            },
            icon = {
              fg = "#fdcfff",
              bold = true,
            },
          },
          due_date = {
            fg = "#bb9af7",
            near = { fg = "#e0af68", bold = true },
            overdue = { fg = "#f7768e", undercurl = true },
          },
          progress = {
            complete = { fg = "#9ece6a" },
            partial = { fg = "#e0af68" },
            none = { fg = "#f7768e" },
          },
          separator = {
            fg = "#3b4261",
            vertical = { fg = "#3b4261" },
            horizontal = { fg = "#3b4261" },
          },
          help = {
            fg = "#c0caf5",
            key = { fg = "#7dcfff", bold = true },
            text = { fg = "#c0caf5", italic = true },
          },
          fold = {
            expanded = { fg = "#7aa2f7", bold = true },
            collapsed = { fg = "#7aa2f7" },
          },
          indent = {
            line = { fg = "#3b4261" },
            connector = { fg = "#3bf2f1" },
            indicator = { fg = "#fb42f1", bold = true },
          },
          search = {
            match = { fg = "#c0caf5", bg = "#445588", bold = true },
          },
          selection = { fg = "#c0caf5", bg = "#283457", bold = true },
          cursor = { fg = "#c0caf5", bg = "#364a82", bold = true },
        },
        progress_bar = {
          width = 15,
          filled = "█",
          empty = "░",
          enabled = true,
          style = "modern", -- "classic", "modern", "minimal"
        },
        indent = {
          connector = "├─",
          last_connector = "└─",
        },
      },
      icons = {
        task_pending = "",
        task_done = "",
        priority = {
          low = "󰘄",
          medium = "󰁭",
          high = "󰘃",
          urgent = "󰀦",
        },
        created = "󰃰",
        updated = "",
        note = "",
        relations = "󱒖 ",
        due_date = "",
        recurring = {
          daily = "",
          weekly = "",
          monthly = "",
        },
        metadata = "󰂵",
        important = "",
      },
      features = {
        task_info = {
          enabled = true,
        },

        folding = {
          enabled = true,
          default_folded = false,
          icons = {
            folded = "▶",
            unfolded = "▼",
          },
        },
        tags = {
          enabled = true,
          colors = {
            fg = "#7aa2f7",
          },
          prefix = "󰓹 ",
        },
        relations = {
          enabled = true,
        },
        metadata = {
          enabled = true,
          colors = {
            key = { fg = "#f0caf5", bg = "#bb9af7", bold = true },
            value = { fg = "#c0faf5", bg = "#7dcfff" },
            section = { fg = "#00caf5", bg = "#bb9af7", bold = true, italic = true },
          },
        },
      },
    },
    config = function(_, opts)
      require("lazydo").setup(opts)
    end
  },
}
