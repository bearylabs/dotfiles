vim.pack.add {
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/refractalize/oil-git-status.nvim',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  callback = function() vim.opt_local.colorcolumn = '' end,
})

require('oil').setup {
  win_options = {
    signcolumn = 'yes:2',
  },
  confirmation = {
    border = 'rounded',
  },
  float = {
    border = 'rounded',
  },
  keymaps = {
    ['<C-l>'] = false,
    ['<C-r>'] = 'actions.refresh',
  },
  view_options = {
    show_hidden = true,
  },
}

require('oil-git-status').setup()
