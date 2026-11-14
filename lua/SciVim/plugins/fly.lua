return {
  {
    dir = "~/.config/nvim/lua/fly.nvim/",
    lazy = false,
    opts = {
      prompt = "❯ ",
      layout = "default",      -- key of `layouts`
      cycle = true,            -- wrap around when moving past the first/last item
      hidden = false,          -- include dotfiles in file/grep sources
      ignored = false,         -- include git-ignored files in file sources
      follow = false,          -- follow symlinks
      icons = true,            -- use mini.icons / nvim-web-devicons when installed
      limit = 1000,            -- max rows rendered in the list
      history = 100,           -- remembered queries per source
      debounce = 120,          -- ms between keystroke and re-running a *live* source (grep)
      ui_select = true,        -- replace vim.ui.select with fly
      matcher = {
        cwd_bonus = true,      -- prefer shallower paths
        filename_bonus = true, -- prefer matches inside the file name
        sort_empty = true,     -- sort alphabetically on an empty query
        smartcase = true,
      },
      preview = {
        enabled = true,
        wrap = false,
        max_size = 1024 * 1024, -- bytes; larger files are not previewed
        max_lines = 2000,       -- lines kept around the target line
        max_line_length = 400,
        treesitter = true,      -- use treesitter highlighting when a parser exists
        debounce = 15,          -- ms
      },
      image = {
        backend = "auto", -- "auto" | "kitty" | "ueberzug" | "none"
        convert = true,   -- convert jpg/webp/gif/... to png through ImageMagick for kitty
        cell_ratio = 0.5, -- terminal cell width / height, used to keep aspect ratio
        kitty = { zindex = 1 },
        ueberzug = { bin = "ueberzug", scaler = "contain" },
      },
      win = {
        border = nil,  -- nil: use 'winborder' (0.11+) or "rounded"
        backdrop = 60, -- winblend of the dimmed backdrop; false disables
        zindex = 50,
      },
      layouts = {
        default = { preset = "default" },
        ivy = { preset = "ivy" },
        vertical = { preset = "vertical" },
        telescope = { preset = "telescope" },
      },
      --- Prompt keymaps (insert + normal mode). Value: action name, function(picker), or false.
      keys = {
        ["<CR>"] = "confirm",
        ["<C-s>"] = "split",
        ["<C-v>"] = "vsplit",
        ["<C-t>"] = "tab",
        ["<Esc>"] = "close",
        ["<C-c>"] = "close",
        ["<C-n>"] = "next",
        ["<C-p>"] = "prev",
        ["<C-j>"] = "next",
        ["<C-k>"] = "prev",
        ["<Down>"] = "next",
        ["<Up>"] = "prev",
        ["<C-f>"] = "page_down",
        ["<C-b>"] = "page_up",
        ["<Tab>"] = "toggle",
        ["<S-Tab>"] = "toggle_up",
        ["<C-a>"] = "select_all",
        ["<C-q>"] = "quickfix",
        ["<C-d>"] = "preview_down",
        ["<C-u>"] = "preview_up",
        ["<M-p>"] = "toggle_preview",
        ["<C-Down>"] = "history_next",
        ["<C-Up>"] = "history_prev",
        ["<C-r>"] = "refresh",
        ["<M-h>"] = "toggle_hidden",
        ["<M-i>"] = "toggle_ignored",
      },
      --- Extra keymaps used only in normal mode of the prompt.
      normal_keys = {
        q = "close",
        j = "next",
        k = "prev",
        gg = "first",
        G = "last",
      },
      --- Per-source option overrides, e.g. `sources = { files = { hidden = true } }`.
      sources = {},
    },
    config = function(_, opts)
      require("fly").setup(opts)
    end
  },


}
