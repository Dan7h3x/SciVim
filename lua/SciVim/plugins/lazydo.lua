return {
  {
    dir = "~/.config/nvim/lua/lazydo/",
    event = "VeryLazy",
    cmd = {
      "LazyDo",
      "LazyDoToggle",
      "LazyDoKanban",
      "LazyDoStorage",
    },
    keys = {
      {
        "<F2>",
        "<ESC><CMD>LazyDoToggle<CR>",
        desc = "Toggle LazyDo panel",
        mode = { "n", "i" },
      },
      {
        "<F3>",
        "<CMD>LazyDoPin<CR>",
        desc = "Toggle LazyDo Pin view",
        mode = { "n", "i" },
      },
    },
    opts = {},
    config = function(_, opts)
      require("lazydo").setup(opts)
    end,
  },
}
