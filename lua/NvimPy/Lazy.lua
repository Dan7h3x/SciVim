local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
require("lazy").setup({

  { import = "NvimPy.BufferLazy" },
  { import = "NvimPy.AlphaLazy" },
  { import = "NvimPy.LspLazy" },
  { import = "NvimPy.EditorLazy" },
  { import = "NvimPy.IDELazy" },
  { import = "NvimPy.FormatLazy" },
  { import = "NvimPy.FolkeLazy" },
  { import = "NvimPy.LuaLineLazy" },
  { import = "NvimPy.TelescopeLazy" },
  { import = "NvimPy.UILazy" },
  { import = "NvimPy.MiniLazy" },
  { import = "NvimPy.ThemeLazy" },
  { import = "NvimPy.TSLazy" },
  { import = "NvimPy.SciLazy" },
  { import = "NvimPy.LuaLineLazy" },
  { import = "NvimPy.AdditionalLazy" },

  { import = "NvimPy.Extra.debug" },
})
