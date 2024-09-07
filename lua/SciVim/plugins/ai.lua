return {
  {
    dir = "~/.config/nvim/SciVim/chatter", -- Your chat plugin
    event = "VeryLazy",
    dependencies = {
      'nvim-lua/plenary.nvim',
      "ibhagwan/fzf-lua",
    },
    keys = { {
      "<leader>cc", "<Cmd>ChatterStart<CR>", desc = "Chatter Start"
    }, },
    config = function()
      require('SciVim.chatter').setup({
        offline_api_url = os.getenv("OLLAMA_HOST") or "http://localhost:8888",
        sidebar_width = 60,
        sidebar_height = vim.o.lines - 12,
        models = {},
        highlight = {
          title = "Title",
          user = "Comment",
          assistant = "String",
          system = "Type",
          error = "ErrorMsg",
          loading = "WarningMsg",

        }
      })
    end,
  },
  -- {
  --   "Dan7h3x/chatter.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "ibhawgn/fzf-lua",
  --     "nvim-lua/plenary.nvim"
  --   },
  --   config = function()
  --     require("chatter").setup({
  --       offline_api_url = os.getenv("OLLAMA_HOST") or "http://localhost:8888",
  --       sidebar_width = 60,
  --       sidebar_height = vim.o.lines - 12,
  --       models = {},
  --       highlight = {
  --         title = "Title",
  --         user = "Comment",
  --         assistant = "String",
  --         system = "Type",
  --         error = "ErrorMsg",
  --         loading = "WarningMsg",
  --
  --       }
  --     })
  --   end
  -- }
}
