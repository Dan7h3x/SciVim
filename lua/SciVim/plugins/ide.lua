return {
  {
    "cshuaimin/ssr.nvim",
    lazy = true,
    keys = {
      {
        "<leader>sr",
        function()
          require("ssr").open()
        end,
        desc = "TS Search/Replace",
        mode = { "n", "x" },
      },
    },
    config = function()
      require("ssr").setup({
        border = "rounded",
        max_height = 25,
        max_width = 100,
        adjust_window = true,
        keymaps = {
          close = "q",
          next_match = "n",
          prev_match = "N",
          replace_confirm = "<cr>",
          replace_all = "<leader><cr>",
        },
      })
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "^4.0.0",
    event = { "BufNewFile", "BufReadPost", "BufWritePre", "VeryLazy" },
    opts = {},
  },
  { -- color previews & color picker
    "uga-rosa/ccc.nvim",
    keys = {
      { "#", vim.cmd.CccPick, desc = " Color Picker" },
    },
    ft = { "css", "scss", "sh", "zsh", "lua", "python", "c", "cpp", "json", "conf" },
    config = function(spec)
      local ccc = require("ccc")

      ccc.setup({
        win_opts = { border = vim.g.borderStyle },
        highlight_mode = "background",
        highlighter = {
          auto_enable = true,
          filetypes = spec.ft,   -- uses lazy.nvim's ft spec
          max_byte = 200 * 1024, -- 200kb
          update_insert = false,
        },
        pickers = {
          ccc.picker.css_rgb,
          ccc.picker.hex_long, -- only long hex to not pick issue numbers like #123
          ccc.picker.css_hsl,
          ccc.picker.css_name,
          ccc.picker.ansi_escape(),
        },
        alpha_show = "hide",           -- needed when highlighter.lsp is set to true
        recognize = { output = true }, -- automatically recognize color format under cursor
        inputs = { ccc.input.hsl },
        outputs = {
          ccc.output.css_hsl,
          ccc.output.css_rgb,
          ccc.output.hex,
        },
        mappings = {
          ["<Esc>"] = ccc.mapping.quit,
          ["q"] = ccc.mapping.quit,
          ["L"] = ccc.mapping.increase10,
          ["H"] = ccc.mapping.decrease10,
          ["o"] = ccc.mapping.cycle_output_mode, -- = change output format
        },
      })
    end,
  },
  { "kevinhwang91/nvim-bqf", ft = "qf" },
}
