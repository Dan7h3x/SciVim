return {

  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    config = function()
      -- code
      require("telescope").setup({ defualts = { prompt_prefix = ">_< ", entry_prefix = "}=> " } })
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "benfowler/telescope-luasnip.nvim",
    event = "VeryLazy",
    config = function()
      require("telescope").load_extension("luasnip")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    lazy = true,
  },
}
