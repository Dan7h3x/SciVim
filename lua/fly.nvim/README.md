# fly.nvim

A fast, async fuzzy picker for Neovim ≥ 0.10 (developed against 0.12): files, live grep, buffers, git, LSP symbols,
help, images and more — with previews, multi-select, history and inline images (Kitty / Ghostty / ueberzugpp).

```lua
-- lazy.nvim
{
  "you/fly.nvim",
  cmd = "Fly",
  keys = {
    { "<leader>ff", function() require("fly").files() end,   desc = "Files" },
    { "<leader>fg", function() require("fly").grep() end,    desc = "Grep" },
    { "<leader>fb", function() require("fly").buffers() end, desc = "Buffers" },
    { "<leader>fs", function() require("fly").symbols() end, desc = "Symbols" },
    { "<leader>fr", function() require("fly").resume() end,  desc = "Resume" },
    { "<leader>fw", function() require("fly").grep_word() end, desc = "Grep word" },
  },
  opts = {},
}
```

`setup()` is optional. `:checkhealth fly` tells you what is available.

## Sources

| source                                                               | what                              | notes                                         |
| -------------------------------------------------------------------- | --------------------------------- | --------------------------------------------- |
| `files`                                                              | files below cwd                   | `fd` → `rg --files` → `find`; streamed, async |
| `recent`                                                             | `v:oldfiles`                      | `cwd_only = true`                             |
| `buffers`                                                            | listed buffers                    | most-recent first; `<C-x>` deletes            |
| `grep`                                                               | live ripgrep (falls back to grep) | `<M-r>` regex ⇄ literal, `args = {...}`       |
| `lines`                                                              | lines of the current buffer       |                                               |
| `git`                                                                | `git status`                      | diff preview, `<M-s>` stage/unstage           |
| `git_files`                                                          | tracked + untracked files         |                                               |
| `git_log`                                                            | commits                           | `current_file = true`, `<C-y>` yanks hash     |
| `help`                                                               | all help tags                     | opens `:help`, previews the doc               |
| `commands`                                                           | all Ex commands                   | runs 0-arg user commands, else pre-fills `:`  |
| `symbols` / `workspace_symbols`                                      | LSP                               | async                                         |
| `diagnostics`                                                        | workspace diagnostics             | `buffer = true` for current buffer            |
| `images`                                                             | image files                       | inline preview                                |
| `colorschemes`, `keymaps`, `marks`, `registers`, `quickfix`, `jumps` |                                   |                                               |

Also: `grep_word()`, `grep_visual()`, `smart()` (git files in a repo, else files), `resume()`.

`:Fly [source] [key=value…] [query words]` — e.g. `:Fly grep hidden=true needle`, `:Fly resume`.

## Query syntax

`foo` fuzzy · `'foo` exact · `^foo` prefix · `foo$` suffix · `^foo$` whole · `!foo` exclude · `a b` AND.
Smart-case: any uppercase letter makes that term case-sensitive.

## Keys (prompt; insert + normal mode)

`<CR>` open · `<C-s>/<C-v>/<C-t>` split/vsplit/tab · `<C-n>/<C-p>/<Up>/<Down>/<C-j>/<C-k>` move ·
`<C-f>/<C-b>` page · `<Tab>/<S-Tab>` multi-select · `<C-a>` select all · `<C-q>` → quickfix (selection, else all) ·
`<C-d>/<C-u>` scroll preview · `<M-p>` toggle preview · `<C-Up>/<C-Down>` query history · `<C-r>` refresh ·
`<M-h>` hidden files · `<M-i>` ignored files · `<Esc>/<C-c>` close. Several selected items + `<CR>` → quickfix.

Rebind with `keys = { ["<C-o>"] = "confirm", ["<C-s>"] = false, ["<C-y>"] = function(picker) ... end }`.

## Configuration

See `lua/fly/config.lua` for every option with comments. Highlights:

```lua
require("fly").setup({
  layout = "default",            -- default | ivy | vertical | telescope | your own in `layouts`
  icons = true,                  -- mini.icons / nvim-web-devicons if installed
  win = { border = nil, backdrop = 60 },   -- border=nil follows 'winborder'
  sources = { files = { hidden = true }, grep = { regex = false } },
  image = { backend = "auto", cell_ratio = 0.5 },
  ui_select = true,              -- use fly for vim.ui.select
  layouts = { wide = { preset = "default", width = 0.95, preview = 0.6 } },
})
```

## Lua API

```lua
require("fly").pick({ source = "files", cwd = "~/notes", query = "todo", layout = "ivy" })

-- any list
require("fly").pick({ items = { { label = "one" }, { label = "two" } }, confirm = function(item) print(item.label) end })

-- vim.ui.select
require("fly").select({ "a", "b" }, { prompt = "Pick" }, function(item, idx) end)

-- custom source (sync `find`, or streaming `start`)
require("fly").register("todo", {
  title = "todo",
  find = function(ctx) return { { label = "write docs", path = ctx.cwd .. "/TODO.md", line = 3 } } end,
  -- start = function(ctx, push, done) ... return cancel end,   -- async / streaming
  -- live = true,                  -- re-run on each query (like grep) instead of fuzzy filtering
  -- preview = function(ctx, item, p) p.set(lines, { ft = "lua", line = 5 }) end,
  -- keys / actions: per-source keymaps and actions
})
require("fly").todo()
```

Item fields: `label` (matched), `display`, `path` (absolute), `line`, `col`, `bufnr`, `extra` (right-aligned text), `hl`, `text`, `data`.
Filetypes of the UI buffers: `fly_input`, `fly_list`, `fly_preview` (disable completion on these if your plugin ignores `vim.b.completion`).

## Images

Kitty and Ghostty (auto-detected; override with `FLY_KITTY=true|false`) and `ueberzugpp`. Non-PNG formats are converted
through ImageMagick (cached under `stdpath("cache")/fly/img`). Inside tmux set `allow-passthrough on`.

## Changes from the original plugin

**Bugs fixed**

- The documented `'exact ^prefix suffix$ !exclude` / AND syntax was never implemented — space matched a literal space. Now real, with smart-case.
- No keymaps existed at all, and highlight groups were never defined. Both added.
- Crash when `nvim_list_uis()` was empty; layouts now use `vim.o.columns/lines`, are border-aware, and the vertical preset no longer puts the preview off-screen.
- Focus ended in the preview window; insert mode was never stopped after confirming; origin window was not restored.
- Every keystroke re-ran a blocking `fd`/`find`/`rg` (twice for grep). Sources are now async, streamed and cancellable; filtering is time-sliced, so typing never blocks (tested with 150k items).
- `grep` leaked the column into the text and let a query like `--pre=cmd` be parsed as an rg option.
- `symbols` queried the picker's own scratch buffer; flat `SymbolInformation` results had no line; the request blocked.
- `commands` and `help` could not be confirmed; `help` ignored duplicates and special tags; `commands` missed built-ins.
- `git` mis-parsed renames/quoted paths and used repo-root paths from the wrong directory.
- Kitty: path not base64-encoded, image never positioned, only PNG, no aspect ratio, stale images on resize.
- Preview crashed on directories, binary and unreadable files; no highlight of the target line.
- Config options that did nothing (`cwd_bonus`, `filename_bonus`, `sort_empty`, `wrap`, `max_line_length`, `backdrop`, `border`, `cycle`, `unicode_placeholders`, `layouts`) now work (or were removed: `unicode_placeholders`).

**Modern API**: `vim.system`, `vim.uv`, `vim.fs`, `vim.base64`, `nvim_ui_send`, `winborder`, window `footer`, extmark signs/virt-text
(instead of deprecated `nvim_buf_add_highlight`), `vim.lsp.get_clients`, `vim.keycode`, treesitter-or-syntax preview highlighting.

**New**: multi-select, quickfix export, query history, `resume`, `:Fly` command with completion, live toggles
(regex / hidden / ignored), file icons, backdrop, resize handling, preview toggle, `vim.ui.select`, custom sources via
`register()`, 20 sources, health check, vimdoc, and an end-to-end test suite (`tests/run.sh`).

## Tests

`bash tests/run.sh` (needs `nvim`, `git`; `rg`, `fd`, ImageMagick optional — the suite passes with and without them).
