return {
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    keys = {
      {
        "<leader>pb",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Dropbar select",
      },
    },
    config = function()
      local ver = vim.version()
      if ver.minor == "10" then
        local cfg = require("SciVim.extras.winbar")
        require("dropbar").setup(cfg)
      end
    end,
  },
}
