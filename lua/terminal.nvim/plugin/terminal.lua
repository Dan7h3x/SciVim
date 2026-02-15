-- Terminal.nvim - High-performance terminal plugin for Neovim
-- This file is loaded automatically by Neovim when the plugin is installed

if vim.fn.has('nvim-0.10.0') == 0 then
  vim.api.nvim_err_writeln('terminal.nvim requires Neovim >= 0.10.0')
  return
end

-- Prevent loading the plugin twice
if vim.g.loaded_terminal_nvim then
  return
end
vim.g.loaded_terminal_nvim = true

-- The plugin is lazy-loaded, actual setup happens when terminal module is required
