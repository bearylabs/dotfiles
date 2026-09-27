-- Override Kickstart's Gitsigns symbols with VS Code-style gutter bars.
require('gitsigns').setup {
  signs = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '‾' },
    untracked = { text = '│' },
  },
}
