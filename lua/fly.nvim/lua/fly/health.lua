local M = {}

function M.check()
  local h = vim.health
  h.start("fly.nvim")
  if vim.fn.has("nvim-0.10") == 1 then
    h.ok("Neovim " .. tostring(vim.version()))
  else
    h.error("Neovim >= 0.10 is required")
  end
  if vim.api.nvim_ui_send then
    h.ok("nvim_ui_send available (ordered image output)")
  else
    h.warn("nvim_ui_send missing (Neovim < 0.11): images are written to /dev/tty")
  end

  h.start("fly: external tools")
  local function tool(bin, purpose, required)
    if vim.fn.executable(bin) == 1 then
      h.ok(bin .. " — " .. purpose)
      return true
    elseif required then
      h.error(bin .. " not found — " .. purpose)
    else
      h.info(bin .. " not found — " .. purpose)
    end
  end
  if not (tool("fd", "fast file listing") or tool("fdfind", "fast file listing")) then
    h.warn("no fd: falling back to " .. (vim.fn.executable("rg") == 1 and "rg --files" or "find (slow)"))
  end
  tool("rg", "live grep (falls back to grep)")
  tool("git", "git sources")

  h.start("fly: images")
  local detect = require("fly.image.detect")
  local backend = require("fly.image").name()
  h.info("selected backend: " .. backend)
  if detect.kitty() then
    h.ok("Kitty graphics protocol terminal detected")
    if detect.converter() then
      h.ok("ImageMagick found: jpg/webp/gif/... previews work")
    else
      h.warn("ImageMagick missing: only PNG can be previewed with kitty")
    end
    if vim.env.TMUX then
      h.warn("inside tmux: needs `set -g allow-passthrough on`")
    end
  end
  if detect.ueberzug() then
    h.ok("ueberzugpp found")
  end
  if backend == "none" then
    h.info("no image backend: image files show a text placeholder")
  end

  h.start("fly: optional integrations")
  if _G.MiniIcons then
    h.ok("mini.icons")
  elseif pcall(require, "nvim-web-devicons") then
    h.ok("nvim-web-devicons")
  else
    h.info("no icon provider (mini.icons / nvim-web-devicons): icons are skipped")
  end
end

return M
