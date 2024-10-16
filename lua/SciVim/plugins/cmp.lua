return {

  {
    "hrsh7th/nvim-cmp",
    version = false,
    enabeld = true,
    event = "InsertEnter",
    dependencies = {
      { "hrsh7th/cmp-path" },   -- Completion engine for path
      { "hrsh7th/cmp-buffer" }, -- Completion engine for buffer
      { "hrsh7th/cmp-nvim-lsp", event = "LspAttach" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-cmdline" },
      {
        "garymjr/nvim-snippets",
        enabeld = true,
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = { friendly_snippets = true },
      },
    },

    cmd = { "CmpInfo" },
    config = function()
      local cmp = require("cmp")
      local Icons = require("SciVim.extras.icons")
      -- local LLVim = require("SciVim.chatter")

      local function borderMenu(hl_name)
        return {
          { "", "SciVimBlue" },
          { "─", hl_name },
          { "▼", "SciVimOrange" },
          { "│", hl_name },
          { "╯", hl_name },
          { "─", hl_name },
          { "╰", hl_name },
          { "│", hl_name },
        }
      end
      local function borderDoc(hl_name)
        return {
          { "▲", "SciVimOrange" },
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
        border = borderMenu("Ghost"),
        scrollbar = true,
        scrolloff = 6,
        col_offset = -2,
        side_padding = 0,
        winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
      }
      local winhighlightDoc = {
        border = borderDoc("Ghost"),
        col_offset = -1,
        side_padding = 0,
        scrollbar = false,
        max_width = 40,
        max_height = 15,

        winhighlight = "Normal:CmpNormal,CursorLine:CursorLine",
      }

      --#endregion
      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noselect",
        },
        preselect = cmp.PreselectMode.None,
        snippet = {
          expand = function(args)
            require("SciVim.utils.cmp").expand(args.body)
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
          ["<C-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif vim.snippet.active({ direction = 1 }) then
              vim.snippet.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif vim.snippet.active({ direction = -1 }) then
              vim.snippet.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },

        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            group_index = 1,
            entry_filter = function(entry, _)
              -- using cmp-buffer for this
              return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Text"
            end,
          },
          { name = "nvim_lua" },
          { name = "path",    group_index = 1 },
          {
            name = "lazydev",
            group_index = 0, -- set group index to 0 to skip loading LuaLS completions
          },
          {
            name = "buffer",
            group_index = 1,
            option = {
              -- show completions from all buffers used within the last x minutes
              get_bufnrs = function()
                local mins = 15 -- CONFIG
                local recentBufs = vim.iter(vim.fn.getbufinfo({ buflisted = 1 }))
                    :filter(function(buf)
                      return os.time() - buf.lastused < mins * 60
                    end)
                    :map(function(buf)
                      return buf.bufnr
                    end)
                    :totable()
                return recentBufs
              end,
              max_indexed_line_length = 100, -- no long lines (e.g. base64-encoded things)
            },
            keyword_length = 4,
            max_item_count = 5, -- since searching all buffers results in many results
          },
          { name = "snippets" },

        }),

        formatting = {
          fields = { "kind", "abbr", "menu" },
          expandable_indicator = true,
          format = function(entry, item)
            item.kind = string.format("%s-<%s>", Icons.kind_icons[item.kind], Kinder(item.kind))
            item.menu = ({
              nvim_lua = "[Lua]",
              nvim_lsp = "[Lsp]",
              snippets = "[Snp]",
              buffer = "[Buf]",
              path = "[Dir]",
            })[entry.source.name]

            local widths = {
              abbr = 20,
              menu = 20,
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
          path = 1,
        },

        -- experimental = {
        --   ghost_text = { hl_group = "Ghost" },
        -- },
        window = {
          completion = winhighlightMenu,

          documentation = winhighlightDoc,
        },
      })

      --- additional
      cmp.setup.filetype("lua", {
        enabled = function()
          local line = vim.api.nvim_get_current_line()
          local doubleDashLine = line:find("%s%-%-?$") or line:find("^%-%-?$")
          return not doubleDashLine
        end,
      })
    end,
  },

}
