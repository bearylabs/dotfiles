vim.pack.add {
  'https://github.com/nvim-pack/nvim-spectre',
  'https://github.com/nvim-lua/plenary.nvim',
  {
    src = 'https://github.com/catppuccin/nvim',
    name = 'catppuccin',
  },
}

local palette = require('catppuccin.palettes').get_palette 'macchiato'

vim.api.nvim_set_hl(0, 'SpectreSearch', { bg = palette.red, fg = palette.base })
vim.api.nvim_set_hl(0, 'SpectreReplace', { bg = palette.green, fg = palette.base })

require('spectre').setup {
  highlight = {
    search = 'SpectreSearch',
    replace = 'SpectreReplace',
  },
  mapping = {
    send_to_qf = {
      map = '<C-q>',
      cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
      desc = 'send all items to quickfix',
    },
  },
}
