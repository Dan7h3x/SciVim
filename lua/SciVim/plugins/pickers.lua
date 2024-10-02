return {
  {
    "ibhagwan/fzf-lua",
    enabled = true,
    init = function()
      require("SciVim.extras.fzf")
    end,
    config = function()
      -- calling `setup` is optional for customization
      require("SciVim.extras.fzfsetup").setup()
      require("fzf-lua").register_ui_select(function(_, items)
        local min_h, max_h = 0.15, 0.70
        local h = (#items + 4) / vim.o.lines
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
