return {
  {
    "ibhagwan/fzf-lua",
    enabled = true,
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    init = function()
      vim.ui.select = function(items, opts, on_choice)
        local ui_select = require 'fzf-lua.providers.ui_select'

        -- Register the fzf-lua picker the first time we call select.
        if not ui_select.is_registered() then
          ui_select.register(function(ui_opts)
            if ui_opts.kind == 'luasnip' then
              ui_opts.prompt = 'Snippet choice: '
              ui_opts.winopts = {
                relative = 'cursor',
                height = 0.35,
                width = 0.3,
              }
            elseif ui_opts.kind == 'lsp_message' then
              ui_opts.winopts = { height = 0.4, width = 0.4 }
            else
              ui_opts.winopts = { height = 0.6, width = 0.5 }
            end

            return ui_opts
          end)
        end

        -- Don't show the picker if there's nothing to pick.
        if #items > 0 then
          return vim.ui.select(items, opts, on_choice)
        end
      end
      require("SciVim.extras.fzf")
    end,
    config = function()
      -- calling `setup` is optional for customization
      require("SciVim.extras.fzfsetup").setup()
      require("fzf-lua").register_ui_select(function(o, items)
        local min_h, max_h = 0.15, 0.70
        local preview = o.kind == "codeaction" and 0.20 or 0
        local h = (#items + 4) / vim.o.lines + preview
        if h < min_h then
          h = min_h
        elseif h > max_h then
          h = max_h
        end
        return { winopts = { height = h, width = 0.60, row = 0.40 } }
      end)
    end,
  },
}
