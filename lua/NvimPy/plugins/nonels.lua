local M = {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim"
    }
  }
  
  function M.config()
    local null_ls = require "null-ls"
    local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
  
    local formatting = null_ls.builtins.formatting
    local diagnostics =  null_ls.builtins.diagnostics



local function ruff_fix()
    return helpers.make_builtin({
        name = "ruff",
        meta = {
            url = "https://github.com/charliermarsh/ruff/",
            description = "An extremely fast Python linter, written in Rust.",
        },
        method = methods.internal.FORMATTING,
        filetypes = { "python" },
        generator_opts = {
            command = "ruff",
            args = { "--fix", "-e", "-n", "--stdin-filename", "$FILENAME", "-" },
            to_stdin = true
        },
        factory = helpers.formatter_factory
    })
end
  
    null_ls.setup {
      debug = false,
      sources = {
        formatting.stylua,
        formatting.prettier,
        -- formatting.black,
        ruff_fix(),
        null_ls.builtins.diagnostics.ruff,
        -- formatting.prettier.with {
        --   extra_filetypes = { "toml" },
        --   -- extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
        -- },
        -- formatting.eslint,
        -- null_ls.builtins.diagnostics.flake8,
        -- diagnostics.flake8,
        null_ls.builtins.completion.spell,
      },
    }
  end
  
  return M
