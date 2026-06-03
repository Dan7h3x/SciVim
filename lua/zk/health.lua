-- lua/zk/health.lua
-- Run with :checkhealth zk

local M     = {}

-- Neovim 0.10+ uses vim.health directly; older uses require("health")
local h     = vim.health or require("health")
local ok    = h.ok or h.report_ok
local warn  = h.warn or h.report_warn
local error = h.error or h.report_error
local start = h.start or h.report_start
local info  = h.info or h.report_info

function M.check()
  start("zk.nvim")

  -- ── Neovim version ───────────────────────────────────────────────────────
  start("Neovim version")
  local v = vim.version()
  if v.major > 0 or v.minor >= 9 then
    ok(string.format("Neovim %d.%d.%d (≥ 0.9 required)", v.major, v.minor, v.patch))
  else
    error(string.format("Neovim %d.%d.%d is too old — zk.nvim requires 0.9+", v.major, v.minor, v.patch))
  end

  -- ── Config ───────────────────────────────────────────────────────────────
  start("Configuration")
  local ok_cfg, cfg = pcall(function() return require("zk").config end)
  if not ok_cfg then
    error("zk.setup() has not been called — add require('zk').setup({}) to your config")
    return
  end

  local dir = cfg.dir
  if vim.fn.isdirectory(dir) == 1 then
    ok("Notes directory exists: " .. dir)
    local count = #vim.fn.globpath(dir, "**/*.md", false, true)
    info(string.format("Found %d markdown files", count))
  else
    warn("Notes directory does not exist: " .. dir .. " (will be created on first use)")
  end

  -- ── Pickers ──────────────────────────────────────────────────────────────
  start("Pickers")
  local found_picker = false

  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks.picker then
    ok("snacks.nvim found (preferred picker)")
    found_picker = true
  else
    warn("snacks.nvim not found — install folke/snacks.nvim for best experience")
  end

  local ok_fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    ok("fzf-lua found")
    found_picker = true
  else
    warn("fzf-lua not found — install ibhagwan/fzf-lua for fzf integration")
  end

  local ok_tele = pcall(require, "telescope")
  if ok_tele then
    ok("telescope.nvim found")
    found_picker = true
  else
    warn("telescope.nvim not found")
  end

  if not found_picker then
    warn("No picker found — falling back to vim.ui.select (limited UX)")
  end

  -- ── Completion ───────────────────────────────────────────────────────────
  start("Completion")
  local ok_cmp = pcall(require, "cmp")
  if ok_cmp then
    ok("nvim-cmp found — zk source will register automatically")
  else
    warn("nvim-cmp not found")
  end

  local ok_blink = pcall(require, "blink.cmp")
  if ok_blink then
    ok("blink.cmp found — zk source will register automatically")
  else
    warn("blink.cmp not found")
  end

  if not ok_cmp and not ok_blink then
    warn("No completion engine found — falling back to omnifunc (<C-x><C-o>)")
  end

  -- ── Treesitter ───────────────────────────────────────────────────────────
  start("Treesitter")
  local ok_ts = pcall(require, "nvim-treesitter")
  if ok_ts then
    ok("nvim-treesitter found")
    local ok_md = pcall(vim.treesitter.language.inspect, "markdown")
    if ok_md then
      ok("markdown parser installed")
    else
      warn("markdown treesitter parser not installed — run :TSInstall markdown")
    end
  else
    warn("nvim-treesitter not found — syntax highlighting will use regex fallback")
  end

  -- ── External tools ───────────────────────────────────────────────────────
  start("External tools")
  if vim.fn.executable("rg") == 1 then
    ok("ripgrep (rg) found — used for grep")
  else
    warn("ripgrep not found — grep will use vimgrep (slower). Install: https://github.com/BurntSushi/ripgrep")
  end

  if vim.fn.executable("fzf") == 1 then
    ok("fzf binary found")
  else
    warn("fzf binary not found — install: https://github.com/junegunn/fzf")
  end

  -- Graph viewer
  local browser = vim.fn.has("mac") == 1 and vim.fn.executable("open") == 1
      or vim.fn.executable("xdg-open") == 1
      or vim.fn.executable("start") == 1
  if browser then
    ok("Browser launcher available for graph view")
  else
    warn("No browser launcher found — use graph_viewer='float' in setup()")
  end

  -- ── Index ────────────────────────────────────────────────────────────────
  start("Index")
  local idx = require("zk.index")
  if idx._built then
    local count = vim.tbl_count(idx._notes)
    ok(string.format("Index built — %d notes tracked", count))
  else
    info("Index not yet built (lazy — built on first use)")
  end
end

return M
