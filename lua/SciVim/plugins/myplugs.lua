return {
  {
    "Dan7h3x/signup.nvim",
    branch = "devel",
    event = "LspAttach",
    config = function()
      require("signup").setup(
      -- Your configuration options here
        {
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
          border = "shadow",
          winblend = 10,
          override = false, -- Override default LSP handler for signatureHelp
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
