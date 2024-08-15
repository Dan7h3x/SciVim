return {
  {
    "Vigemus/iron.nvim",
    event = "VeryLazy",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local fts = require("iron.fts")
      iron.setup({
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          -- Your repl definitions come here
          repl_definition = {
            sh = {
              -- Can be a table or a function that
              -- returns a table (see below)
              command = { "zsh" },
            },
            python = fts.python.ipython,
          },
          -- How the repl window will be displayed
          -- See below for more information
          repl_open_cmd = view.split("%30", {
            winfixwidth = true,
            winfixheight = true,
            number = false,
          }),
        },
        -- Iron doesn't set keymaps by default anymore.
        -- You can set them here or manually add keymaps to the functions in iron.core
        keymaps = {
          send_file = "<space>rt",
          send_line = "<space>rl",
          send_until_cursor = "<space>rc",
          exit = "<space>rq",
          send_motion = "<space>re",
        },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = { italic = true },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      })
    end,
  },
  ---[
  --- Treesitter for VimTeX
  ---]
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "bibtex" })
      end
      if type(opts.highlight.disable) == "table" then
        vim.list_extend(opts.highlight.disable, { "latex" })
      else
        opts.highlight.disable = { "latex" }
      end
    end,
  },
  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
    end,
    ft = "tex",
  },
}
