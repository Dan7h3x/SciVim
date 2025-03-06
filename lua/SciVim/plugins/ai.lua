return {
  {
    dir = "~/.config/nvim/lua/SciVim/chatter/",
    lazy = true,
    dependencies = {
      "ibhagwan/fzf-lua",
      lazy = true,
    },
    keys = { {
      "<leader>cc",
      "<Cmd>ChatterStart<CR>",
      desc = "Chatter Start",
    } },
    config = function()
      require("SciVim.chatter").setup({})
    end,
  },
}
