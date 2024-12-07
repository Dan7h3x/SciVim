return {
  {
    "Dan7h3x/chatter.nvim",
    branch = "devel",
    lazy = true,
    dependencies = {
      "ibhagwan/fzf-lua", lazy = true,
    },
    keys = { {
      "<leader>cc", "<Cmd>ChatterStart<CR>", desc = "Chatter Start"
    }, },
    config = function()
      require('SciVim.chatter').setup(
        {
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
            loading = "WarningMsg", -- New highlight group for loading animation

          },
          features = {
            inline_completion = true,
            code_actions = true,
            context_awareness = true,
            auto_import_suggestions = true,
          },
          keymaps = {
            inline_completion = '<C-space>',
            code_actions = '<leader>ca',
            explain_code = '<leader>ce',
            generate_docs = '<leader>cd',
          }
        })
    end,
  },
}
