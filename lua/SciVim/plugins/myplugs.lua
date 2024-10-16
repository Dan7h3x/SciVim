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
    -- event = "VeryLazy",
    branch = "stable",
    config = function()
      require("neaterm").setup({
        shell = vim.o.shell,
        float_width = 0.5,
        float_height = 0.4,
        move_amount = 3,
        resize_amount = 2,
        border = 'rounded',
        highlights = {
          normal = 'NormalFloat',
          border = 'Ghost',
        },
        special_terminals = {
          ranger = {
            cmd = 'ranger',
            type = 'vertical',
            keymap = '<leader>rt', -- change by your comfort
          },
        },
        keymaps = {
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
          resize_right = '<C-S-Right>',
          focus_bar = '<C-A-b>',
        },
      })
    end
  }
}
