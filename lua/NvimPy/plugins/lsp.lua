return {
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    config = false,
    init = function()
      -- Disable automatic setup, we are doing it manually
      vim.g.lsp_zero_extend_cmp = 0
      vim.g.lsp_zero_extend_lspconfig = 0
    end,
  },

  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    event = "VeryLazy",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        "black",
        "prettier",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "williamboman/mason-lspconfig.nvim" },
      { "nvimtools/none-ls.nvim" },
      {
        "folke/neoconf.nvim",
        cmd = "Neoconf",
        config = false,
        dependencies = { "nvim-lspconfig" },
      },
    },
    config = function()
      -- This is where all the LSP shenanigans will live
      local lsp_zero = require("lsp-zero")
      local null_ls = require("null-ls")
      local icons = require("NvimPy.configs.icons")
      lsp_zero.extend_lspconfig()

      null_ls.setup({
        debug = true,
        border = "rounded",
        sources = {
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.prettier.with({
            filetypes = { "vue", "typescript", "html", "javascript", "css", "markdown" },
          }),
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.shfmt,
          -- null_ls.builtins.completion.spell,
        },
      })

      lsp_zero.set_sign_icons({
        error = icons.diagnostics.Error,
        warn = icons.diagnostics.Warn,
        hint = icons.diagnostics.Hint,
        info = icons.diagnostics.Info,
      })

      --- if you want to know more about lsp-zero and mason.nvim
      --- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        local opts = { buffer = bufnr, remap = false }

        vim.keymap.set("n", "gd", function()
          vim.lsp.buf.definition()
        end, opts)
        vim.keymap.set("n", "gD", function()
          vim.lsp.buf.declaration()
        end, opts)
        vim.keymap.set("n", "K", function()
          -- vim.lsp.buf.hover()
          vim.lsp.buf.hover()
        end, opts)
        vim.keymap.set("n", "gI", function()
          vim.lsp.buf.implementation()
        end, opts)
        vim.keymap.set("n", "<leader>ld", function()
          vim.diagnostic.open_float()
        end, opts)
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.goto_next()
        end, opts)
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.goto_prev()
        end, opts)
        vim.keymap.set("n", "<leader>lf", function()
          vim.lsp.buf.format()
        end, opts)

        vim.keymap.set({ "n", "i" }, "<A-i>", function()
          vim.lsp.buf.signature_help()
        end, opts)

        vim.keymap.set("n", "<leader>la", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { "source.organizeImports" },
              diagnostics = {},
            },
          })
        end, opts)
        vim.keymap.set("n", "gr", function()
          vim.lsp.buf.references()
        end, opts)
        vim.keymap.set("n", "<leader>lr", function()
          vim.lsp.buf.rename()
        end, opts)

        -- lsp_zero.default_keymaps({ buffer = bufnr })
      end)

      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",
          "lua_ls",
          "pyright",
          "jsonls",
          "texlab",
          "typst_lsp",
        },
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({})
          end,
          lua_ls = function()
            local opts = lsp_zero.nvim_lua_ls()
            require("lspconfig").lua_ls.setup(opts)
          end,
        },
      })
    end,
  },
  {
    "luckasRanarison/clear-action.nvim",
    opts = {
      {
        silent = true, -- dismiss code action requests errors
        signs = {
          enable = true,
          combine = false, -- combines all action kinds into a single sign
          priority = 200, -- extmark priority
          position = "eol", -- "right_align" | "overlay"
          separator = " ", -- signs separator
          show_count = true, -- show the number of each action kind
          show_label = false, -- show the string returned by `label_fmt`
          label_fmt = function(actions)
            return actions[1].title
          end,                 -- actions is an array of `CodeAction`
          update_on_insert = false, -- show and update signs in insert mode
          icons = {
            quickfix = "🔧",
            refactor = "💡",
            source = "🔗",
            combined = "💡", -- used when combine is set to true or as a fallback when there is no action kind
          },
          highlights = { -- highlight groups
            quickfix = "NonText",
            refactor = "NonText",
            source = "NonText",
            combined = "NonText",
            label = "NonText",
          },
        },
        popup = { -- replaces the default prompt when selecting code actions
          enable = true,
          center = false,
          border = "rounded",
          hide_cursor = false,
          hide_client = false, -- hide displaying name of LSP client
          highlights = {
            header = "CodeActionHeader",
            label = "CodeActionLabel",
            title = "CodeActionTitle",
          },
        },
        mappings = {
          -- The values can either be a string or a string tuple (with description)
          -- example: "<leader>aq" | { "<leader>aq", "Quickfix" }
          -- Or if you want more control: { key = "<leader>aq", mode = { "n" }, options = { desc = "Quickfix" } }
          -- `options` accetps the same keys as vim.keymap.set()
          code_action = "<leader>la", -- a modified version of `vim.lsp.buf.code_action`
          apply_first = nil, -- directly applies the first code action
          -- These are just basically `vim.lsp.buf.code_action` with the `apply` option with some filters
          -- If there's only one code action, it gets automatically applied.
          quickfix = "<leader>lq", -- can be filtered with the `quickfix_filter` option bellow
          quickfix_next = nil, -- tries to fix the next diagnostic
          quickfix_prev = nil, -- tries to fix the previous diagnostic
          refactor = nil,
          refactor_inline = nil,
          refactor_extract = nil,
          refactor_rewrite = nil,
          source = nil,
          -- server-specific mappings, server_name = {...}
          -- This is a map of code actions prefixes and keys
          actions = {
            -- example:
            -- ["rust_analyzer"] = {
            --   ["Inline"] = "<leader>ai"
            --   ["Add braces"] = { "<leader>ab", "Add braces" }
            -- }
          },
        },
        -- This is used for filtering actions in the quickfix functions
        -- It's a map of diagnostic codes and the preferred action prefixes
        -- You can check the diagnostic codes by hovering on the diagnostic
        quickfix_filters = {
          -- example:
          -- ["rust_analyzer"] = {
          --   ["E0433"] = "Import",
          -- },
          -- ["lua_ls"] = {
          --   ["unused-local"] = "Disable diagnostics on this line",
          -- },
        },
        action_labels = {
          -- example:
          -- ["dartls"] = {
          --   "Wrap with widget..." = "w",
          --   "Wrap with Padding" = "p",
          --   "Wrap with Center" = "c",
          -- },
        },
      },
    },
  }, -- Lazy
}
