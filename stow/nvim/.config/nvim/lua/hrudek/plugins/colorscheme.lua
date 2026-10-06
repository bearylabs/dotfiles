vim.pack.add {
  {
    src = 'https://github.com/catppuccin/nvim',
    name = 'catppuccin',
  },
}

require('catppuccin').setup {
  flavour = 'macchiato',
  integrations = {
    render_markdown = true,
    treesitter = true,
  },
}

vim.cmd.colorscheme 'catppuccin'
