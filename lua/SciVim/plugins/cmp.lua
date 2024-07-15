return {

  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "VeryLazy" },
    dependencies = {
      { "hrsh7th/cmp-path" },   -- Completion engine for path
      { "hrsh7th/cmp-buffer" }, -- Completion engine for buffer
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "saadparwaiz1/cmp_luasnip" },
      {
        "L3MON4D3/LuaSnip",
        dependencies = {
          {
            "rafamadriz/friendly-snippets",
            config = function()
              require("luasnip.loaders.from_vscode").lazy_load()
            end,
          },
        },
        opts = {
          history = true,
          delete_check_events = "TextChanged",
        },

      }, },

    cmd = { "CmpInfo" },
    config = function()
      local cmp = require("cmp")
      local Icons = require("SciVim.extras.icons")
      local luasnip = require("luasnip")
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

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
        elseif item == "Enum" then
          return "Enm"
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

      --#endregion
      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noinsert" .. (true and "" or ",noselect"),
        },
        preselect = true or cmp.PreselectMode.Item or cmp.PreselectMode.None,
        snippet = {
          expand = function(args)
            if vim.snippet then
              vim.snippet.expand(args.body)
            else
              require("luasnip").lsp_expand(args.body)
            end
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
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif cmp.visible() then
              cmp.select_next_item()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            elseif cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
        },

        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip",  priority = 500 },
          { name = "nvim_lua", priority = 500 },
          { name = "path",     priority = 500 },
          {
            name = "buffer",
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
              luasnip = "{Snp}",
              buffer = "{Buf}",
              path = "{Dir}",
            })[entry.source.name]

            local widths = {
              abbr = 40,
              menu = 30,
            }

            for key, width in pairs(widths) do
              if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
                item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
              end
            end

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
          buffer = 1,
          luasnip = 1,
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
    end,
  },
}
