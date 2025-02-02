return {
  -- Mason for managing LSP servers, DAP servers, linters, and formatters
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "prettier",
        "shfmt",
        "isort",
        "ruff",
        "debugpy",
      },
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
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

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    enabled = true,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      -- { "folke/neodev.nvim", opts = {} }, -- Adds LSP support for Neovim lua API
      "saghen/blink.cmp",
    },
    config = function()
      -- Import icons for diagnostics
      local icons = require("SciVim.extras.icons")

      -- Setup diagnostics
      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
          header = "",
          prefix = "",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
          },
        },
      })

      -- Configure LSP UI elements
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
      })

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
      })

      -- LSP Attach function with keymaps and capabilities
      local on_attach = function(client, bufnr)
        -- Enable inlay hints if supported
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(false, { bufnr })
        end

        -- Enable codelens if supported
        if client.server_capabilities.codeLensProvider then
          vim.lsp.codelens.refresh()
          -- Auto refresh codelens
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = bufnr,
            callback = vim.lsp.codelens.refresh,
          })
        end

        -- LSP Keymaps
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, desc = desc })
        end

        -- Navigation
        map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
        map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        map("n", "gr", vim.lsp.buf.references, "Go to References")
        map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
        map("n", "gt", vim.lsp.buf.type_definition, "Go to Type Definition")

        -- Workspace management
        map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
        map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
        map("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "List Workspace Folders")

        -- Actions
        map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
        -- map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
        map({ "n", "v" }, "<leader>cf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format")

        -- Diagnostics
        map("n", "gl", vim.diagnostic.open_float, "Line Diagnostics")
        map("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
        map("n", "<leader>q", vim.diagnostic.setloclist, "Set Diagnostic List")

        -- Inlay hints toggle
        if client.server_capabilities.inlayHintProvider then
          map("n", "<leader>ci", function()
            vim.lsp.inlay_hint.enable(false)
          end, "Inlay Hints off")
          map("n", "<leader>co", function()
            vim.lsp.inlay_hint.enable(true)
          end, "Inlay Hints on")
        end

        -- Codelens
        if client.server_capabilities.codeLensProvider then
          map("n", "<leader>cl", vim.lsp.codelens.run, "Run Codelens")
          map("n", "<leader>cL", vim.lsp.codelens.refresh, "Refresh Codelens")
        end
      end

      -- Configure capabilities
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities()
      )

      -- Enable folding capabilities
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      -- Setup mason-lspconfig
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = {
          "lua_ls",
          "pyright",
          "bashls",
          "texlab",
        },
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
              on_attach = on_attach,
            })
          end,

          -- Lua LSP configuration
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                Lua = {
                  runtime = { version = "LuaJIT" },
                  workspace = {
                    checkThirdParty = false,
                    library = {
                      vim.env.VIMRUNTIME,
                      "${3rd}/luv/library",
                    },
                  },
                  completion = {
                    callSnippet = "Replace",
                  },
                  hint = { -- Inlay hints
                    enable = true,
                    arrayIndex = "Enable",
                    setType = true,
                    paramName = "All",
                    paramType = true,
                  },
                },
              },
            })
          end,

          -- Python configuration with Pyright
          ["pyright"] = function()
            require("lspconfig").pyright.setup({
              capabilities = capabilities,
              settings = {
                pyright = {
                  disableOrganizeImports = true,
                },
                python = {
                  analysis = {
                    inlayHints = {
                      variableTypes = true,
                      functionReturnTypes = true,
                    },
                    ignore = { "*" },
                    typeCheckingMode = "off",
                  },
                },
              },
            })
          end,

          -- Ruff LSP configuration
          ["ruff"] = function()
            require("lspconfig").ruff.setup({
              -- cmd = { "ruff", "server", "--preview" },
              cmd_env = { RUFF_TRACE = "messages" },
              init_option = {
                settings = {
                  loglevel = "error",
                },
              },
            })
          end,

          -- LaTeX configuration
          ["texlab"] = function()
            require("lspconfig").texlab.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                texlab = {
                  build = {
                    executable = "latexmk",
                    args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                    onSave = true,
                    forwardSearchAfter = false,
                  },
                  chktex = {
                    onOpenAndSave = true,
                    onEdit = false,
                  },
                  diagnosticsDelay = 300,
                  latexFormatter = "latexindent",
                  latexindent = {
                    modifyLineBreaks = false,
                  },
                },
              },
            })
          end,
        },
      })

      -- Create LSP autocmds
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        end,
      })
    end,
  },
}
