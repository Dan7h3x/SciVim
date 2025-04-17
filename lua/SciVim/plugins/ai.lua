return {
  {
    "jeangiraldoo/codedocs.nvim",
    -- Remove the 'dependencies' section if you don't plan on using nvim-treesitter
    ft = { "python", "lua" },
    keys = { {
      "<leader>ck",
      "<Cmd>Codedocs<CR>",
      mode = { "n", "i" },
      desc = "Docstring Generator",
    } },
    dependencies = {
      "nvim-treesitter/nvim-treesitter"
    },
    opts = {
      default_styles = {
        python = "Google"
      }
    }
  }
}
