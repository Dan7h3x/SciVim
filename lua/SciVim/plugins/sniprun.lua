return {
  {
    "michaelb/sniprun",
    branch = "master",

    build = "sh install.sh",
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

    opts = {
      selected_interpreters = { "Python3_fifo" }, --# use those instead of the default for the current filetype
      repl_enable = { "Python3_fifo" },           --# enable REPL-like behavior for the given interpreters
      repl_disable = {},                          --# disable REPL-like behavior for the given interpreters

      interpreter_options = {                     --# interpreter-specific options, see doc / :SnipInfo <name>

        --# use the interpreter name as key
        GFM_original = {
          use_on_filetypes = { "markdown.pandoc" } --# the 'use_on_filetypes' configuration key is
          --# available for every interpreter
        },
        Python3_original = {
          error_truncate = "auto" --# Truncate runtime errors 'long', 'short' or 'auto'
          --# the hint is available for every interpreter
          --# but may not be always respected
        }
      },

      --# you can combo different display modes as desired and with the 'Ok' or 'Err' suffix
      --# to filter only sucessful runs (or errored-out runs respectively)
      display = {
        -- "Classic",       --# display results in the command-line  area
        -- "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)
        "VirtualLine", --# display results as virtual lines

        -- "VirtualText",             --# display results as virtual text
        -- "TempFloatingWindow",      --# display results in a floating window
        -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
        -- "Terminal",                --# display results in a vertical split
        -- "TerminalWithCode",        --# display results and code history in a vertical split
        -- "NvimNotify",              --# display with the nvim-notify plugin
        -- "Api"                      --# return output to a programming interface
      },

      live_display = { "VirtualTextOk" }, --# display mode used in live_mode

      display_options = {
        terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
        terminal_line_number = false,           --# whether show line number in terminal window
        terminal_signcolumn = false,            --# whether show signcolumn in terminal window
        terminal_position = "vertical",         --# or "horizontal", to open as horizontal split instead of vertical split
        terminal_width = 45,                    --# change the terminal display option width (if vertical)
        terminal_height = 20,                   --# change the terminal display option height (if horizontal)
        notification_timeout = 5,               --# timeout for nvim_notify output
        max_fw_width = 80,                      --# max width for floating windows, longer lines will wrap
      },

      --# You can use the same keys to customize whether a sniprun producing
      --# no output should display nothing or '(no output)'
      show_no_output = {
        "Classic",
        "TempFloatingWindow", --# implies LongTempFloatingWindow, which has no effect on its own
      },

      cwd = '.', --# set the working directory for build/run processes. By default or if set to '.',
      --# is neovim's current working directory. Can be overwritten by interpreter-options

      --# customize highlight groups (setting this overrides colorscheme)
      --# any parameters of nvim_set_hl() can be passed as-is
      snipruncolors = {
        SniprunVirtualTextOk  = { bg = "#66eeff", fg = "#000000", ctermbg = "Cyan", ctermfg = "Black" },
        SniprunFloatingWinOk  = { fg = "#66eeff", ctermfg = "Cyan" },
        SniprunVirtualTextErr = { bg = "#881515", fg = "#000000", ctermbg = "DarkRed", ctermfg = "Black" },
        SniprunFloatingWinErr = { fg = "#881515", ctermfg = "DarkRed", bold = true },
      },

      live_mode_toggle = 'off', --# live mode toggle, see Usage - Running for more info

      --# miscellaneous compatibility/adjustement settings
      ansi_escape = true,      --# Remove ANSI escapes (usually color) from outputs
      inline_messages = false, --# boolean toggle for a one-line way to display output
      --# to workaround sniprun not being able to display anything

      borders = 'single', --# display borders around floating windows
      --# possible values are 'none', 'single', 'double', or 'shadow'
    },
    config = function(_, opts)
      require("sniprun").setup(opts)
    end,
  },
}
