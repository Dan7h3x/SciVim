return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      {
        "williamboman/mason.nvim",
        cmd = "Mason",
        lazy = true,
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        build = ":MasonUpdate",
        opts = {
          ensure_installed = {
            "ruff",
            "prettier",
            "shfmt",
            "black",
            "isort",
          }
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

      }, {
      "folke/neoconf.nvim",
      -- lazy = true,
      event = "VeryLazy",
      cmd = "Neoconf",
      opts = {},
      config = function()
        require("neoconf").setup()
      end,
    }, {
      "VonHeikemen/lsp-zero.nvim",
      event = { "VeryLazy" },
      branch = "v3.x",
      config = false,
      init = function()
        -- Disable automatic setup, we are doing it manually
        vim.g.lsp_zero_extend_cmp = 0
        vim.g.lsp_zero_extend_lspconfig = 0
      end,
    },
      { "williamboman/mason-lspconfig.nvim", opts = {} },
    },
    config = function()
      -- local capabilities = vim.tbl_deep_extend(
      --   "force",
      --   {},
      --   vim.lsp.protocol.make_client_capabilities(),
      --   require("cmp_nvim_lsp").default_capabilities()
      -- )


      local lsp_zero = require("lsp-zero")
      lsp_zero.extend_lspconfig()
      local capabilities = lsp_zero.get_capabilities()
      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        local opts = { buffer = bufnr, remap = false, desc = "{ LSP }" }

        -- vim.keymap.set("n", "gd", function()
        --   vim.lsp.buf.definition()
        -- end, opts)
        vim.keymap.set("n", "gD", function()
          vim.lsp.buf.declaration()
        end, opts)
        vim.keymap.set("n", "K", function()
          -- vim.lsp.buf.hover()
          vim.lsp.buf.hover()
        end, opts)
        -- vim.keymap.set("n", "gI", function()
        --   vim.lsp.buf.implementation()
        -- end, opts)
        vim.keymap.set("n", "<leader>lf", function()
          vim.lsp.buf.format()
        end, opts)

        vim.keymap.set({ "n", "i" }, "<A-i>", function()
          vim.lsp.buf.signature_help()
        end, opts)

        vim.keymap.set("n", "<leader>lA", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              diagnostics = {},
            },
          })
        end, opts)
        vim.keymap.set("n", "<leader>lR", function()
          vim.lsp.buf.rename()
        end, opts)
      end)
      local Myon_attach = lsp_zero.on_attach()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright",
          "bashls",
        },
        handlers = {
          function(server)
            require("lspconfig")[server].setup({
              capabilities = capabilities,
              on_attach = Myon_attach,
            })
          end,
          ["lua_ls"] = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup {
              capabilities = capabilities,
              on_attach = Myon_attach,
              settings = {
                Lua = {
                  runtime = { version = "Lua 5.4" },
                  diagnostics = {
                    globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                  }
                }
              }
            }
          end,

          ["pyright"] = function()
            require("lspconfig").pyright.setup({
              capabilities = capabilities,
              on_attach = Myon_attach,
              settings = {
                pyright = {
                  disableOrganizeImports = true,
                  single_file_support = false,
                },
                python = {
                  analysis = {
                    ignore = { "*" },
                    typeCheckingMode = "off",
                  },
                },
              },
            })
          end,
        }
      })


      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = require("SciVim.extras.icons").diagnostics.Error,
            [vim.diagnostic.severity.WARN] = require("SciVim.extras.icons").diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = require("SciVim.extras.icons").diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = require("SciVim.extras.icons").diagnostics.Info,
          },
        },
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
    end
  },
}
