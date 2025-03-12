return {
  -- {
  --   dir = "~/.config/nvim/lua/SciVim/chatter/",
  --   lazy = true,
  --   dependencies = {
  --     "ibhagwan/fzf-lua",
  --     lazy = true,
  --   },
  --   keys = { {
  --     "<leader>cc",
  --     "<Cmd>ChatterStart<CR>",
  --     desc = "Chatter Start",
  --   } },
  --   config = function()
  --     require("SciVim.chatter").setup({})
  --   end,
  -- },
  {
    dir = "~/.config/nvim/lua/ghchat/",
    lazy = true,
    opts = {},
    config = function(_, opts)
      require("ghchat").setup(opts)
    end,

  }
}
