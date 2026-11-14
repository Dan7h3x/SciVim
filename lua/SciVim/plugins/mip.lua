return {
  {
    dir = "~/.config/nvim/lua/mip/",
    ft = { "tex", "typst", "org" },
    opts = {
      -- filetype -> language
      filetypes = { tex = "latex", plaintex = "latex", latex = "latex", typst = "typst", org = "org" },

      backend = "auto", -- "auto" | "kitty" | "sixel" | "ueberzug" | "text"
      fallback = true,
      parser = "auto",  -- "auto" (treesitter, regex fallback) | "treesitter" | "regex"
      raster = "resvg", -- SVG rasteriser: "auto" | "rsvg-convert" | "resvg" | "inkscape" | "magick"

      features = { math = true, inline = true, tables = true, figures = true, sections = true },

      edit_modes = { "i", "R" }, -- modes in which the block under the cursor shows its source
      reveal_on_cursor = true,   -- also reveal the block under the cursor in normal mode
      show_errors = true,        -- eol marker when a block fails to compile

      debounce = 80,             -- ms before re-rendering after a normal-mode edit
      margin = 60,               -- extra lines scanned above/below the viewport

      align = "left",            -- block images: "center" | "left"
      scale = 1.4,               -- global size multiplier (1.0 == 12pt text fits the cell height)
      baseline = 0.8,            -- where the text baseline sits inside a cell (0 top .. 1 bottom)
      max_width = 0.9,           -- max block width  (fraction of window text width)
      max_height = 0.6,          -- max block height (fraction of window height)

      concurrency = 4,
      max_images = 400, -- images kept uploaded to the terminal
      cell_size = nil,  -- { w, h } pixels, overrides detection
      fg = nil,         -- "#rrggbb"; defaults to Normal's foreground
      cache_dir = vim.fn.stdpath("cache") .. "/mip",
      cache_days = 4,   -- cache files older than this are removed at startup

      latex = {
        backend = "dvisvgm",    -- "auto" | "dvisvgm" (latex+dvisvgm, vector) | "pdf" (engine below + pdftocairo)
        dvi_engine = "latex",
        engine = "xelatex",     -- pdf backend: pdflatex | lualatex | xelatex | tectonic
        preamble = "",
        buffer_preamble = true, -- reuse \newcommand / \usepackage{math pkgs} from the buffer
        numbering = false,      -- show equation numbers
        math_envs = {},         -- extra environment names rendered as display math
        table_envs = {},
        figure_envs = {},
      },
      typst = { cmd = "typst", preamble = "", buffer_preamble = true },
      -- sixel: native backend (st, foot, mlterm, wezterm, ...); needs img2sixel, magick or chafa
      sixel = { encoder = "img2sixel", bg = nil }, -- "auto" | "img2sixel" | "magick" | "chafa"
      -- ueberzug: cmd = nil auto-detects `ueberzugpp` then `ueberzug` (ueberzugpp 2.9 installs `ueberzug`)
      ueberzug = { cmd = "kitty", output = nil },  -- output: nil | "sixel" | "kitty" | "iterm2" | "x11" | ...
    },
    config = function(_, opts)
      require("mip").setup(opts)
    end
  }
}
