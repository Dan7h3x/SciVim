return {
  {
    dir = "~/.config/nvim/lua/highme/",
    event = { "BufReadPost", "VeryLazy" },
    opts = {
      highlight_color = "guibg=#2f2f3f", -- Default highlight color
      highlight_enabled = true,          -- Enable highlighting by default
      highlight_on_cursor_move = true,   -- Automatically highlight on cursor move
      clear_highlights_on_exit = true,   -- Clear highlights when exiting buffer
      highlight_multiple_words = true,   -- Highlight multiple words under cursor
      use_search_register = true,        -- Update search register (/)
      add_to_jumplist = true,            -- Add matches to jumplist
      -- Exclude specific filetypes
      excluded_filetypes = {
        "neo-tree",
        "Outline",
        "undotree",
        "TelescopePrompt",
        "TelescopeResults",
        -- "help",
        "dap-repl",
        "quickfix",
        "trouble",
        "mason",
        "notify",
        "toggleterm",
        "lazy",
        "Alpha",
      },
    },
    config = function(_, opts)
      require("highme").setup(opts)
    end
  }
}
