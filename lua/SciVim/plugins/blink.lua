local function borderMenu(hl_name)
    return {
        { "", "Blue" },
        { "─", hl_name },
        { "▲", "Orange" },
        { "│", hl_name },
        { "╯", hl_name },
        { "─", hl_name },
        { "╰", hl_name },
        { "│", hl_name },
    }
end

local function borderDoc(hl_name)
    return {
        { "▼", "Orange" },
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
        dependencies = {
            { "saghen/blink.compat", optional = true, opts = {}, version = "*" },
            {
                "rafamadriz/friendly-snippets",
            },
        },
        event = "InsertEnter",
        version = "*",

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                ["<CR>"] = { "accept", "fallback" },
                ["<Esc>"] = { "hide", "fallback" },
                -- ["<C-c>"] = { "cancel", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-e>"] = { "cancel", "show", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-y>"] = { "select_and_accept" },

                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<Tab>"] = {
                    function(cmp)
                        if cmp.snippet_active() then
                            return cmp.snippet_forward()
                        else
                            return cmp.select_next()
                        end
                    end,
                    "snippet_forward",
                    "fallback",
                },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<S-up>"] = { "scroll_documentation_up", "fallback" },
                ["<S-down>"] = { "scroll_documentation_down", "fallback" },
            },
            cmdline = {
                enabled = false,
            },
            appearance = {
                nerd_font_variant = "normal",
                kind_icons = require("SciVim.extras.icons").kind_icons,
            },
            snippets = {
                preset = "default",
            },
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
            sources = {
                default = { "lsp", "path", "snippets", "buffer", "lazydev" },
                providers = {
                    lsp = {
                        name = "[Lsp]",
                        module = "blink.cmp.sources.lsp",
                        opts = {},                -- Passed to the source directly, varies by source

                        enabled = true,           -- Whether or not to enable the provider
                        async = false,            -- Whether we should wait for the provider to return before showing the completions
                        timeout_ms = 2000,        -- How long to wait for the provider to return before showing completions and treating it as asynchronous
                        transform_items = nil,    -- Function to transform the items before they're returned
                        should_show_items = true, -- Whether or not to show the items
                        max_items = nil,          -- Maximum number of items to display in the menu
                        min_keyword_length = 0,   -- Minimum number of characters in the keyword to trigger the provider
                        -- If this provider returns 0 items, it will fallback to these providers.
                        -- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
                        fallbacks = {},
                        score_offset = 0, -- Boost/penalize the score of the items
                        override = nil,   -- Override the source's functions
                    },
                    path = {
                        name = "[Path]",
                        module = "blink.cmp.sources.path",
                        score_offset = 3,
                        fallbacks = { "buffer" },
                        opts = {
                            trailing_slash = true,
                            label_trailing_slash = true,
                            get_cwd = function(context)
                                return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                            end,
                            show_hidden_files_by_default = false,
                        },
                    },

                    snippets = {
                        name = "[Snip]",
                        module = "blink.cmp.sources.snippets",

                        opts = {
                            friendly_snippets = true,
                            search_paths = { vim.fn.stdpath("config") .. "/snippets" },
                            global_snippets = { "all" },
                            extended_filetypes = {},
                            ignored_filetypes = {},
                            get_filetype = function(context)
                                return vim.bo.filetype
                            end,
                            -- Set to '+' to use the system clipboard, or '"' to use the unnamed register
                            clipboard_register = "+",
                        },

                        -- For `snippets.preset == 'mini_snippets'`
                    },

                    buffer = {
                        name = "[Buff]",
                        module = "blink.cmp.sources.buffer",
                        opts = {
                            -- default to all visible buffers
                            get_bufnrs = function()
                                return vim.iter(vim.api.nvim_list_wins())
                                    :map(function(win)
                                        return vim.api.nvim_win_get_buf(win)
                                    end)
                                    :filter(function(buf)
                                        return vim.bo[buf].buftype ~= "nofile"
                                    end)
                                    :totable()
                            end,
                        },
                    },
                    lazydev = {
                        name = "[Lazy]",
                        module = "lazydev.integrations.blink",
                        score_offset = 100, -- show at a higher priority than lsp
                    },
                },
            },
        },
    },
}
