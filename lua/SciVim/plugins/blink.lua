local function borderMenu(hl_name)
  return {
    { "", "Special" },
    { "─", hl_name },
    { "▲", "WarningMsg" },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end


local function borderDoc(hl_name)
  return {
    { "▼", "WarningMsg" },
    { "─", hl_name },
    { "╮", hl_name },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end
return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    dependencies = {
      -- { "rafamadriz/friendly-snippets" },
      { "saghen/blink.lib" },
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
        end,
      },
      {
        "saghen/blink.compat",
        optional = true,
        opts = {},
        version = "*",
      },
      { "garymjr/nvim-snippets", enabled = true },
    },

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        ["<CR>"] = { "accept", "fallback" },
        ["<Esc>"] = { "hide", "fallback" },
        -- ["<C-c>"] = { "cancel", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Tab>"] = {
          function(cmp)
            if not cmp.is_visible() and cmp.snippet_active() then
              return cmp.snippet_forward()
            else
              return cmp.select_next()
            end
          end,
          "fallback",
        },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<S-up>"] = { "scroll_documentation_up", "fallback" },
        ["<S-down>"] = { "scroll_documentation_down", "fallback" },
      },
      cmdline = {
        enabled = false,
        keymap = { preset = "inherit" },
        completion = { menu = { auto_show = false } },
      },
      appearance = {
        nerd_font_variant = "mono",
        kind_icons = require("SciVim.extras.icons").kind_icons,
      },
      snippets = {
        preset = "luasnip",
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      completion = {
        accept = {
          auto_brackets = { enabled = false },
        },
        menu = {
          border = borderMenu("FloatBorder"),
          max_height = 10,
          draw = {
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
            treesitter = { "lsp" },
            cursorline_priority = 0,
          },
        },
        documentation = {
          window = {
            max_height = 15,
            max_width = 40,
            border = borderDoc("FloatBorder"),
          },
          auto_show = true,
          auto_show_delay_ms = 100,
          treesitter_highlighting = true,
        },
        ghost_text = { enabled = false },
      },
      signature = {
        enabled = false,
      },
      sources = {
        default = { "lsp", "snippets", "path", "buffer", "lazydev", "omni" },
        providers = {
          lsp = {
            name = "[Lsp]",
            module = "blink.cmp.sources.lsp",
            opts = {},                -- Passed to the source directly, varies by source

            enabled = true,           -- Whether or not to enable the provider
            async = true,             -- Whether we should wait for the provider to return before showing the completions
            timeout_ms = 1000,        -- How long to wait for the provider to return before showing completions and treating it as asynchronous
            transform_items = nil,    -- Function to transform the items before they're returned
            should_show_items = true, -- Whether or not to show the items
            max_items = nil,          -- Maximum number of items to display in the menu
            min_keyword_length = 0,   -- Minimum number of characters in the keyword to trigger the provider
            -- If this provider returns 0 items, it will fallback to these providers.
            -- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
            fallbacks = {},
            score_offset = 14, -- Boost/penalize the score of the items
            override = nil,    -- Override the source's functions
          },
          path = {
            name = "[Path]",
            module = "blink.cmp.sources.path",
            fallbacks = { "buffer" },
            score_offset = 10,
            opts = {
              trailing_slash = true,
              label_trailing_slash = true,
              get_cwd = function(context)
                return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
              end,
              show_hidden_files_by_default = true,
            },
          },

          snippets = {
            name = "[snip]",
            module = "blink.cmp.sources.snippets",
            score_offset = 15, -- boost/penalize the score of the items
            -- opts = {
            -- 	use_show_condition = true,
            -- 	show_autosnippets = true,
            -- },
            -- from the final inserted text
          },
          lazydev = {
            name = "[Lazy]",
            module = "lazydev.integrations.blink",
            score_offset = 12,
          },
          omni = {
            name = "[omni]",
            module = "blink.cmp.sources.complete_func",
            enabled = function()
              return vim.bo.omnifunc ~= 'v:lua.vim.lsp.omnifunc'
            end,
            opts = {
              complete_func = function()
                return vim.bo.omnifunc
              end
            }
          },

          buffer = {
            name = "[Buff]",
            module = "blink.cmp.sources.buffer",
            score_offset = 3,
            opts = {},
          },
        },
      },
    },
    config = function(_, opts)
      local enabled = opts.sources.default
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
          table.insert(enabled, source)
        end
      end
      opts.sources.compat = nil
      require("blink.cmp").setup(opts)
    end,
  },
  {
    'saghen/blink.pairs',
    event = "InsertEnter",
    dependencies = 'saghen/blink.lib',
    version = '*', -- must be on a versioned release to download

    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        -- you can call require("blink.pairs.mappings").enable()
        -- and require("blink.pairs.mappings").disable()
        -- to enable/disable mappings at runtime
        enabled = true,
        cmdline = true,
        -- or disable with `vim.g.pairs = false` (global) and `vim.b.pairs = false` (per-buffer)
        -- and/or with `vim.g.blink_pairs = false` and `vim.b.blink_pairs = false`
        disabled_filetypes = {},
        wrap = {
          -- move closing pair via motion
          ['<C-b>'] = 'motion',
          -- move opening pair via motion
          ['<C-S-b>'] = 'motion_reverse',
          -- set to 'treesitter' or 'treesitter_reverse' to use treesitter instead of motions
          -- set to nil, '' or false to disable the mapping
          -- normal_mode = {} <- for normal mode mappings, only supports 'motion' and 'motion_reverse'
        },
        -- see the defaults:
        -- https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua#L52
        pairs = {},
      },
      highlights = {
        enabled = true,
        -- requires require('vim._core.ui2').enable({}), otherwise has no effect
        cmdline = true,
        -- set to { 'BlinkPairs' } to disable rainbow highlighting
        groups = { 'BlinkPairsOrange', 'BlinkPairsPurple', 'BlinkPairsBlue' },
        unmatched_group = 'BlinkPairsUnmatched',

        -- highlights matching pairs under the cursor
        matchparen = {
          enabled = true,
          -- known issue where typing won't update matchparen highlight, disabled by default
          cmdline = false,
          -- also include pairs not on top of the cursor, but surrounding the cursor
          include_surrounding = false,
          group = 'BlinkPairsMatchParen',
          priority = 250,
        },
      },
      debug = false,
    }
  }
}
