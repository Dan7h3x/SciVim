return {
  {
    dir = "~/.config/nvim/SciVim/chatter", -- Your chat plugin
    lazy = true,
    dependencies = {
      "ibhagwan/fzf-lua", lazy = true,
    },
    keys = { {
      "<leader>cc", "<Cmd>ChatterStart<CR>", desc = "Chatter Start"
    }, },
    config = function()
      require('SciVim.chatter').setup({
        offline_api_url = os.getenv("OLLAMA_HOST") or "http://localhost:11434",
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
  --   dir = "~/.config/nvim/lua/SciVim/gptvim/init.lua",
  --   config = function()
  --     require("SciVim.gptvim").setup({
  --       api_key = "",
  --       model = "gpt-4",
  --     })
  --   end
  -- },

  -- {
  --   "Dan7h3x/chatter.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     "ibhagwan/fzf-lua",
  --   },
  --   keys = { {
  --     "<leader>cc", "<Cmd>ChatterStart<CR>", desc = "Chatter Start"
  --   }, },
  --   config = function()
  --     require('chatter').setup({
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
  --   end,
  -- }

}
