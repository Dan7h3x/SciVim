---@class MipConfig
local M = {}

M.defaults = {
  -- filetype -> language
  filetypes = {
    tex = "latex", plaintex = "latex", latex = "latex", typst = "typst", org = "org",
    markdown = "markdown", rmd = "markdown", quarto = "markdown", mdx = "markdown", ["markdown.mdx"] = "markdown",
  },

  backend = "auto", -- "auto" | "kitty" | "sixel" | "ueberzug" | "text" (unicode, no images)
  fallback = true, -- auto: use the text backend when no image backend is usable
  parser = "auto", -- "auto" (treesitter, regex fallback) | "treesitter" | "regex"
  raster = "auto", -- SVG rasteriser: "auto" | "rsvg-convert" | "resvg" | "inkscape" | "magick"

  features = { math = true, inline = true, tables = true, figures = true, sections = true },

  edit_modes = { "i", "R" }, -- modes in which the block under the cursor shows its source
  reveal_on_cursor = false, -- also reveal the block under the cursor in normal mode
  show_errors = true, -- eol marker when a block fails to compile

  debounce = 80, -- ms before re-rendering after a normal-mode edit
  margin = 60, -- extra lines scanned above/below the viewport

  align = "center", -- block images: "center" | "left"
  scale = 1.0, -- global size multiplier (1.0 == 12pt text fits the cell height)
  baseline = 0.8, -- where the text baseline sits inside a cell (0 top .. 1 bottom)
  max_width = 0.9, -- max block width  (fraction of window text width)
  max_height = 0.6, -- max block height (fraction of window height)

  concurrency = 4,
  max_images = 400, -- images kept uploaded to the terminal
  cell_size = nil, -- { w, h } pixels, overrides detection
  fg = nil, -- "#rrggbb"; defaults to Normal's foreground
  cache_dir = vim.fn.stdpath("cache") .. "/mip",
  cache_days = 14, -- cache files older than this are removed at startup

  latex = {
    backend = "auto", -- "auto" | "dvisvgm" (latex+dvisvgm, vector) | "pdf" (engine below + pdftocairo)
    dvi_engine = "latex",
    engine = "pdflatex", -- pdf backend: pdflatex | lualatex | xelatex | tectonic
    preamble = "",
    -- "full": compile every block with the document's own \documentclass + whole preamble (all packages,
    --         macros, fonts, theorem setups), retrying with the minimal preamble if that fails.
    --         "safe": only reuse macros and a whitelist of math packages. (latex+dvisvgm backend)
    preamble_mode = "full",
    buffer_preamble = true, -- safe mode: reuse \newcommand / \usepackage{math pkgs} from the buffer
    numbering = false, -- show equation numbers
    math_envs = {}, -- extra environment names rendered as display math
    table_envs = {},
    figure_envs = {},
  },
  typst = {
    cmd = "typst",
    -- "auto": compile the real document and crop blocks out of its pages (keeps all #set/#show/
    --         #let/imports/numbering), falling back to isolated snippets; "file": in-file only;
    --         "snippet": always compile blocks separately
    mode = "auto",
    root = nil, -- passed as --root (projects importing from a parent directory)
    args = {}, -- extra typst flags, e.g. { "--font-path", "fonts" }
    debounce = 400, -- ms after the last edit before the document is recompiled
    preamble = "", -- snippet mode: extra source before every block
    buffer_preamble = true, -- snippet mode: reuse the file's top-level #let/#import/#set/#show
  },
  -- sixel: native backend (st, foot, mlterm, wezterm, ...); needs img2sixel, magick or chafa
  sixel = { encoder = "auto", bg = nil }, -- encoder: "auto" | "img2sixel" | "magick" | "chafa"; bg: "#rrggbb" fill (default: detected)
  -- ueberzug: cmd = nil auto-detects `ueberzugpp` then `ueberzug` (ueberzugpp 2.9 installs `ueberzug`)
  ueberzug = { cmd = nil, output = nil }, -- output: nil | "sixel" | "kitty" | "iterm2" | "x11" | ...
}

M.values = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.values
end

return M
