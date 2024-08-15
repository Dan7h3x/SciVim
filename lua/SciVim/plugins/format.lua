return {
  {
    "stevearc/conform.nvim",
    enabled = true,
    event = { "BufReadPost" },
    config = function()
      -- code
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = function(bufnr)
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
              return { "ruff_format", "isort" }
            else
              return { "isort", "black" }
            end
          end,
          -- Use the "*" filetype to run formatters on all filetypes.
          markdown = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          typst = { "typstyle" },
          css = { "prettier" },
        },
        -- If this is set, Conform will run the formatter on save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.

        format = {
          timeout_ms = 3000,
          async = false,
          quiet = false,
          lsp_fallback = "fallback",
        },
        format_on_save = {
          -- I recommend these options. See :help conform.format for details.
          lsp_fallback = true,
          timeout_ms = 500,
        },
        -- If this is set, Conform will run the formatter asynchronously after save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_after_save = {
          lsp_fallback = true,
        },
        -- Set the log level. Use `:ConformInfo` to see the location of the log file.
        log_level = vim.log.levels.ERROR,
        -- Conform will notify you when a formatter errors
        notify_on_error = true,
        -- Custom formatters and overrides for built-in formatters
      })
    end,
  },
}
