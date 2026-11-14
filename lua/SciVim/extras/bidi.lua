-- ~/.config/nvim/lua/bidi.lua
-- Neovim side of the st bidi patch (v2).
--
-- The patched st reorders/shapes RTL text itself, so Neovim must not:
-- 'termbidi' on, 'rightleft' off, 'arabicshape' off.  On top of that this
-- module gives you:
--   * a Persian keymap (<C-^> toggles it) and a ZWNJ key (<C-\> in insert),
--   * st mode control: :Bidi, :NoBidi, :BidiToggle, :BidiMode spans|rows|auto|uba,
--   * the "next character is RTL" hint, so the insert cursor (bar) is drawn
--     where the next Persian letter will appear,
--   * optional visual h/l inside RTL text, and ZWNJ highlighting.
--
-- Usage:
--   require("bidi").setup({
--     keymap = "persian-iranian",  -- or "persian"
--     visual_hl = false,           -- true: h/l move visually over RTL chars
--     show_zwnj = true,            -- highlight U+200C (half-space) cells
--     mode = "spans",              -- "spans" | "rows" | "auto" | "uba"
--   })
local M = { enabled = false, hint = false }

local function send(seq)
  seq = "\27[" .. seq
  if vim.api.nvim_ui_send then -- newer Neovim: goes to the TUI
    pcall(vim.api.nvim_ui_send, seq)
  else                         -- older: write to the tty via stderr
    pcall(vim.fn.chansend, vim.v.stderr, seq)
  end
end

local mode_seq = {
  spans = "?7702l", -- RTL stretches only (default)
  rows = "?7702h",  -- whole rows, LTR paragraphs
  auto = "?7703h",  -- whole rows, auto direction
  uba = "?7705h",   -- pure UAX #9 (explicit controls honoured; testing only)
}

function M.set_mode(name)
  local seq = mode_seq[name]
  if seq then send(seq) end
end

local function is_rtl(cp)
  return (cp >= 0x0590 and cp <= 0x08FF) or cp == 0x200F
      or (cp >= 0xFB1D and cp <= 0xFDFF) or (cp >= 0xFE70 and cp <= 0xFEFF)
end

-- "next character typed will be RTL": insert mode with a Persian keymap on
local function update_hint()
  if not M.enabled then return end
  local want = vim.fn.mode():sub(1, 1) == "i" and vim.bo.iminsert == 1
  if want ~= M.hint then
    M.hint = want
    send(want and "?7704h" or "?7704l")
  end
end

function M.enable(opts)
  opts = opts or {}
  M.enabled = true
  pcall(function() vim.o.termbidi = true end) -- terminal does bidi + shaping
  vim.o.rightleft = false                     -- would reverse twice
  vim.o.rightleftcmd = ""
  pcall(function() vim.o.arabicshape = false end)
  send("?7701h")
  M.set_mode(opts.mode or "spans")
end

function M.disable()
  M.enabled = false
  M.hint = false
  send("?7704l")
  send("?7701l")
  pcall(function() vim.o.termbidi = false end)
end

local function visual_hl_maps()
  local function under_cursor_is_rtl()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local ch = vim.fn.matchstr(line, "\\%" .. (col + 1) .. "c.")
    return ch ~= "" and is_rtl(vim.fn.char2nr(ch))
  end
  for key, other in pairs({ h = "l", l = "h" }) do
    vim.keymap.set({ "n", "x" }, key, function()
      return under_cursor_is_rtl() and other or key
    end, { expr = true, desc = "bidi: visual " .. key })
  end
end

function M.setup(opts)
  opts = opts or {}
  -- Persian typing: toggle Latin/Persian in insert/cmdline with <C-^>
  pcall(function() vim.o.keymap = opts.keymap or "persian-iranian" end)
  vim.o.iminsert = 0
  vim.o.imsearch = -1
  -- ZWNJ (half-space), needed constantly in Persian
  vim.keymap.set("i", "<C-\\>", "<C-v>u200c", { desc = "insert ZWNJ" })

  if opts.show_zwnj ~= false then
    vim.api.nvim_set_hl(0, "BidiZWNJ", { bg = "#5c6370", default = true })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
      callback = function()
        if not vim.w.bidi_zwnj then
          vim.w.bidi_zwnj = vim.fn.matchadd("BidiZWNJ", "\\%u200c")
        end
      end,
    })
  end
  if opts.visual_hl then visual_hl_maps() end

  local is_st = (vim.env.TERM or ""):match("^st") ~= nil
  if not (is_st or opts.force) then return end

  local group = vim.api.nvim_create_augroup("StBidi", { clear = true })
  local function on() M.enable(opts) end
  vim.api.nvim_create_autocmd({ "VimEnter", "VimResume", "FocusGained" },
    { group = group, callback = on })
  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" },
    { group = group, callback = M.disable })
  vim.api.nvim_create_autocmd(
    { "InsertEnter", "InsertLeave", "ModeChanged", "CursorMovedI", "BufEnter" },
    { group = group, callback = update_hint })
  -- <C-^> flips 'iminsert' without moving the cursor: refresh the hint
  vim.keymap.set({ "i", "c" }, "<C-^>", function()
    vim.schedule(update_hint)
    return "<C-^>"
  end, { expr = true, desc = "toggle keymap (bidi hint aware)" })

  vim.api.nvim_create_user_command("Bidi", on, {})
  vim.api.nvim_create_user_command("NoBidi", M.disable, {})
  vim.api.nvim_create_user_command("BidiToggle", function()
    if M.enabled then M.disable() else on() end
  end, {})
  vim.api.nvim_create_user_command("BidiMode", function(a) M.set_mode(a.args) end, {
    nargs = 1,
    complete = function() return { "spans", "rows", "auto", "uba" } end,
  })
end

return M
