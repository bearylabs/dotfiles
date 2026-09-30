vim.pack.add { 'https://github.com/tpope/vim-fugitive' }

vim.keymap.set('n', '<leader>gs', '<cmd>Git<cr>', { desc = 'Git status' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'fugitive',
  callback = function(args)
    vim.keymap.set('n', '<Tab>', '=', {
      buffer = args.buf,
      remap = true,
      silent = true,
      desc = 'Toggle inline diff',
    })
  end,
})
