return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ["javascript"] = { "prettier" },
          ["javascriptreact"] = { "prettier" },
          ["typescript"] = { "prettier" },
          ["typescriptreact"] = { "prettier" },
          ["vue"] = { "prettier" },
          ["css"] = { "prettier" },
          ["scss"] = { "prettier" },
          ["less"] = { "prettier" },
          ["html"] = { "prettier" },
          ["json"] = { "prettier" },
          ["jsonc"] = { "prettier" },
          ["yaml"] = { "prettier" },
          ["markdown"] = { "prettier" },
          ["markdown.mdx"] = { "prettier" },
          ["graphql"] = { "prettier" },
          ["handlebars"] = { "prettier" },
          ["lua"] = { "stylua" },
          ["python"] = { "isort", "ruff_format" },
          ["typst"] = { "typstfmt" },
          ["latex"] = { "latexindent" },
        },

        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
  },
}
