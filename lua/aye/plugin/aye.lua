if vim.g.loaded_aye then
  return
end
vim.g.loaded_aye = true

-- Register the colorschemes
vim.api.nvim_create_augroup('aye', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = 'aye',
  pattern = { 'aye', 'aye-light' },
  callback = function(ev)
    if ev.match == 'aye-light' then
      vim.o.background = 'light'
    else
      vim.o.background = 'dark'
    end
    require('aye').setup()
  end,
})

