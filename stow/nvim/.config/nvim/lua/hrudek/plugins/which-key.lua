vim.pack.add { 'https://github.com/folke/which-key.nvim' }

require('which-key').setup {
  delay = 400,
  icons = { mappings = vim.g.have_nerd_font },
  sort = { 'alphanum' },
  spec = {
    { '<leader>b', group = '[B]uffer' },
    { '<leader>c', group = '[C]ode / Quickfix', mode = { 'n', 'v' } },
    { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
  },
}
