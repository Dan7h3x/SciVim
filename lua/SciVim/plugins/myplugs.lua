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
