return {

  -- {
  -- 	"hinell/move.nvim",
  -- 	event = "VeryLazy",
  -- 	keys = {
  -- 		{
  -- 			"<S-Up>",
  -- 			"<Cmd> MoveLine -1<CR>",
  -- 			desc = "Move Line up",
  -- 		},
  -- 		{
  -- 			"<S-Down>",
  -- 			"<Cmd> MoveLine 1<CR>",
  -- 			desc = "Move Line down",
  -- 		},
  -- 	},
  -- },
  {
    "cshuaimin/ssr.nvim",
    lazy = true,
    -- Calling setup is optional.
    config = function()
      require("ssr").setup({
        border = "rounded",
        min_width = 50,
        min_height = 5,
        max_width = 120,
        max_height = 25,
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
    keys = {
      {
        "<leader>sr",
        function()
          require("ssr").open()
        end,
        desc = "Search and Replace Structural",
      },
    },
  },
  {
    "chrisgrieser/nvim-rip-substitute",
    lazy = true,
    keys = {
      {
        "<leader>fs",
        function()
          require("rip-substitute").sub()
        end,
        mode = { "n", "x" },
        desc = " rip substitute",
      },
    },
  },

  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = { -- Example mapping to toggle outline
      { "<F10>", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    config = function()
      local cfg = require("SciVim.extras.outline")
      require("outline").setup(cfg)
    end,
  },
  {
    "wthollingsworth/pomodoro.nvim",
    lazy = true,
    dependencies = { "MunifTanjim/nui.nvim", event = "VeryLazy" },
    config = function()
      require("pomodoro").setup({
        time_work = 30,
        time_break_short = 3,
        time_break_long = 10,
        timers_to_long_break = 5,
      })
    end,
    keys = {
      { "<leader>ps", "<CMD>PomodoroStart <CR>", desc = "pomodoro start" },
      { "<leader>pd", "<CMD> PomodoroStop <CR>", desc = "pomodoro stop" },
      {
        "<leader>po",
        "<CMD> PomodoroStatus <CR>",
        desc = "pomodoro status",
      },
    },
  },
  { "jbyuki/venn.nvim", lazy = true },
  {
    "ellisonleao/glow.nvim",
    lazy = true,
    config = function()
      require("glow").setup({
        border = "rounded",
        style = "dark",
        width = 100,
        height = 120,
        width_ratio = 0.85,
        height_ratio = 0.85,
      })
    end,
    cmd = "Glow",
  },
  {
    "2kabhishek/termim.nvim",
    lazy = true,
    cmd = { "Fterm", "FTerm", "Sterm", "STerm", "Vterm", "VTerm" },
    keys = {
      {
        "<A-1>",
        "<Cmd> Fterm <CR>",
        desc = "Terminal Full",
      },
      {
        "<A-2>",
        "<Cmd> Vterm <CR>",
        desc = "Terminal Vert",
      },
      {
        "<A-3>",
        "<Cmd> Sterm <CR>",
        desc = "Terminal Horz",
      },
    },
  }, -- Commenting tools
  {
    "altermo/ultimate-autopair.nvim",
    lazy = false,
    event = { "VeryLazy", "InsertEnter", "CmdlineEnter" },
    branch = "v0.6", -- recomended as each new version will have breaking changes
    opts = {
      -- Config goes here
    },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  {
    "karb94/neoscroll.nvim",
    lazy = true,
    config = function()
      require("neoscroll").setup({
        easing = "cubic",
        mappings = { "<C-u>", "<C-d>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
      })
    end,
  },
  { -- color previews & color picker
    "uga-rosa/ccc.nvim",
    lazy = true,
    keys = {
      { "#", vim.cmd.CccPick, desc = " Color Picker" },
    },
    ft = { "css", "scss", "sh", "zsh", "lua" },
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
          ccc.picker.hex_long, -- only long hex to not pick issue numbers like #123
          ccc.picker.css_rgb,
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
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
    main = "ibl",
  },
  {
    "rcarriga/nvim-notify",
    lazy = true,
    keys = {
      {
        "<leader>un",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Dismiss All Notifications",
      },
    },
    opts = {
      stages = "static",
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.55)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.55)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    },
    init = function()
      -- when noice is not enabled, install notify on VeryLazy
      if not require("SciVim.utils").has("noice.nvim") then
        require("SciVim.utils").on_very_lazy(function()
          vim.notify = require("notify")
        end)
      end
    end,
  },
}
