return {
  {
    dir = "~/.config/nvim/lua/signup/",
    -- "Dan7h3x/signup.nvim",
    -- branch = "main",
    lazy = true,
    event = "LspAttach",
    opts = {},
    config = function(_, opts)
      require("signup").setup(opts)
    end
  }
}
