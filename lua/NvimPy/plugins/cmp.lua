return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { "hrsh7th/cmp-path" }, -- Completion engine for path
      { "hrsh7th/cmp-buffer" }, -- Completion engine for buffer
      { "hrsh7th/cmp-cmdline" }, -- Completion engine for CMD
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
      { "kdheepak/cmp-latex-symbols" },
      { "saadparwaiz1/cmp_luasnip" },
      {
        "L3MON4D3/LuaSnip",
        build = vim.fn.has("win32") ~= 0 and "make install_jsregexp" or nil,
        dependencies = {
          "rafamadriz/friendly-snippets",
        },
        opts = {
          history = true,
          delete_check_events = "TextChanged",
        },
        config = function(_, opts)
          if opts then
            require("luasnip").config.setup(opts)
          end
          vim.tbl_map(function(type)
            require("luasnip.loaders.from_" .. type).lazy_load()
          end, { "vscode", "snipmate" })
          require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/Snippets/" }) -- friendly-snippets - enable standardized comments snippets
          require("luasnip").filetype_extend("typescript", { "tsdoc" })
          require("luasnip").filetype_extend("javascript", { "jsdoc" })
          require("luasnip").filetype_extend("lua", { "luadoc" })
          require("luasnip").filetype_extend("python", { "pydoc" })
          require("luasnip").filetype_extend("rust", { "rustdoc" })
          require("luasnip").filetype_extend("cs", { "csharpdoc" })
          require("luasnip").filetype_extend("java", { "javadoc" })
          require("luasnip").filetype_extend("c", { "cdoc" })
          require("luasnip").filetype_extend("cpp", { "cppdoc" })
          require("luasnip").filetype_extend("php", { "phpdoc" })
          require("luasnip").filetype_extend("kotlin", { "kdoc" })
          require("luasnip").filetype_extend("ruby", { "rdoc" })
          require("luasnip").filetype_extend("sh", { "shelldoc" })
        end,
        keys = {
          {
            "<tab>",
            function()
              return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
            end,
            expr = true,
            silent = true,
            mode = "i",
          },
          {
            "<tab>",
            function()
              require("luasnip").jump(1)
            end,
            mode = "s",
          },
          {
            "<s-tab>",
            function()
              require("luasnip").jump(-1)
            end,
            mode = { "i", "s" },
          },
        },
      }, -- Snippets manager
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local Icons = require("NvimPy.configs.icons")

      local function borderMenu(hl_name)
        return {
          { "", "CmpBorderIconsLT" },
          { "─", hl_name },
          { "▼", "CmpBorderIconsCT" },
          { "│", hl_name },
          { "╯", hl_name },
          { "─", hl_name },
          { "╰", hl_name },
          { "│", hl_name },
        }
      end

      local function borderDoc(hl_name)
        return {
          { "▲", "CmpBorderIconsCT" },
          { "─", hl_name },
          { "╮", hl_name },
          { "│", hl_name },
          { "╯", hl_name },
          { "─", hl_name },
          { "╰", hl_name },
          { "│", hl_name },
        }
      end

      local function Kinder(item)
        if item == "Function" then
          return "Fnc"
        elseif item == "Text" then
          return "Txt"
        elseif item == "Module" then
          return "Mdl"
        elseif item == "Snippet" then
          return "Snp"
        elseif item == "Variable" then
          return "Var"
        elseif item == "Folder" then
          return "Dir"
        elseif item == "Method" then
          return "Mth"
        elseif item == "Keyword" then
          return "Kwd"
        elseif item == "Constant" then
          return "Cst"
        elseif item == "Property" then
          return "Prp"
        elseif item == "Field" then
          return "Fld"
        else
          return item
        end
      end
      local winhighlightMenu = {
        border = borderMenu("CmpBorder"),
        scrollbar = true,
        scrolloff = 6,
        col_offset = -2,
        side_padding = 0,
        winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
      }

      local winhighlightDoc = {
        border = borderDoc("CmpBorderDoc"),
        col_offset = -1,
        side_padding = 0,
        scrollbar = false,
        max_width = 45,
        max_height = 15,

        winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
      }

      local function has_words_before()
        local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local function jumpable(dir)
        local luasnip_ok, luasnip = pcall(require, "luasnip")
        if not luasnip_ok then
          return false
        end

        local win_get_cursor = vim.api.nvim_win_get_cursor
        local get_current_buf = vim.api.nvim_get_current_buf
        local function seek_luasnip_cursor_node()
          if not luasnip.session.current_nodes then
            return false
          end

          local node = luasnip.session.current_nodes[get_current_buf()]
          if not node then
            return false
          end

          local snippet = node.parent.snippet
          local exit_node = snippet.insert_nodes[0]

          local pos = win_get_cursor(0)
          pos[1] = pos[1] - 1

          -- exit early if we're past the exit node
          if exit_node then
            local exit_pos_end = exit_node.mark:pos_end()
            if (pos[1] > exit_pos_end[1]) or (pos[1] == exit_pos_end[1] and pos[2] > exit_pos_end[2]) then
              snippet:remove_from_jumplist()
              luasnip.session.current_nodes[get_current_buf()] = nil

              return false
            end
          end

          node = snippet.inner_first:jump_into(1, true)
          while node ~= nil and node.next ~= nil and node ~= snippet do
            local n_next = node.next
            local next_pos = n_next and n_next.mark:pos_begin()
            local candidate = n_next ~= snippet and next_pos and (pos[1] < next_pos[1])
                or (pos[1] == next_pos[1] and pos[2] < next_pos[2])

            -- Past unmarked exit node, exit early
            if n_next == nil or n_next == snippet.next then
              snippet:remove_from_jumplist()
              luasnip.session.current_nodes[get_current_buf()] = nil

              return false
            end

            if candidate then
              luasnip.session.current_nodes[get_current_buf()] = node
              return true
            end

            local ok
            ok, node = pcall(node.jump_from, node, 1, true) -- no_move until last stop
            if not ok then
              snippet:remove_from_jumplist()
              luasnip.session.current_nodes[get_current_buf()] = nil

              return false
            end
          end

          -- No candidate, but have an exit node
          if exit_node then
            -- to jump to the exit node, seek to snippet
            luasnip.session.current_nodes[get_current_buf()] = snippet
            return true
          end

          -- No exit node, exit from snippet
          snippet:remove_from_jumplist()
          luasnip.session.current_nodes[get_current_buf()] = nil
          return false
        end

        if dir == -1 then
          return luasnip.in_snippet() and luasnip.jumpable(-1)
        else
          return luasnip.in_snippet() and seek_luasnip_cursor_node() and luasnip.jumpable(1)
        end
      end
      --#endregion
      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noselect",
        },
        preselect = cmp.PreselectMode.None,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
          ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),

          ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
          ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
          ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
          ["<C-y>"] = cmp.config.disable,
          ["<C-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            elseif jumpable(1) then
              luasnip.jump(1)
            elseif has_words_before() then
              fallback()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },

        sources = cmp.config.sources({
          { name = "nvim_lsp",   priority = 3000 },
          { name = "luasnip",    priority = 1000 },
          { name = "buffer",     priority = 500 },
          -- { name = "codeium", priority = 500 },
          { name = "path",       priority = 250 },
          { name = "treesitter", priority = 500 },
          {
            name = "latex_symbols",
            filetype = { "tex", "latex" },
            option = { cache = true, strategy = 2 }, -- avoids reloading each time
            priority = 500,
          },
        }),

        formatting = {
          fields = { "kind", "abbr", "menu" },
          expandable_indicator = true,
          format = function(entry, item)
            item.kind = string.format("%s-{%s}", Icons.kind_icons[item.kind], Kinder(item.kind))
            item.menu = ({
              nvim_lua = "{Lua}",
              nvim_lsp = "{Lsp}",
              luasnip = "{Snip}",
              buffer = "{Buff}",
              path = "{Path}",
              latex_symbols = "{TeX}",
              treesitter = "{TS}",
              -- codeium = "{AI}",
            })[entry.source.name]
            return item
          end,
        },

        view = {
          entries = { name = "custom" },
          docs = {
            auto_open = true,
          },
          separator = "|",
        },
        duplicates = {
          nvim_lsp = 1,
          luasnip = 1,
          cmp_tabnine = 1,
          buffer = 1,
          path = 1,
        },

        -- experimental= {
        -- 	ghost_text = { hl_group = "Ghost" },
        -- },
        window = {
          completion = winhighlightMenu,

          documentation = winhighlightDoc,
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "nvim_lsp_document_symbol" },
          { name = "buffer" },
        },
        view = {
          entries = {
            name = "wildmenu",
            separator = "|",
          },
        },
      })
      --
      -- -- `:` cmdline setup.
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        }),

        view = {
          entries = {
            name = "wildmenu",
            separator = " | ",
          },
        },
      })
    end,
  },
}

