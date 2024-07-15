return {
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            "alpha",
            "dashboard",
            "starter",
            "cmp_menu",
            "neo-tree",
            "Outline",
            "terminal",
            "lazy",
            "undotree",
            "Telescope",
            "dapui*",
            "dapui_scopes",
            "dapui_watches",
            "dapui_console",
            "dapui_breakpoints",
            "dapui_stacks",
            "dap-repl",
            "term",
            "zsh*",
            "bash",
            "shell",
            "terminal",
            "toggleterm",
            "termim",
            "REPL",
            "repl",
            "Iron",
            "Ipython",
            "ipython*",
            "diff",
            "qf",
            "spectre_panel",
            "Trouble",
            "help",
            "hoversplit",
            "which_key",
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      }
    end
  }
}
