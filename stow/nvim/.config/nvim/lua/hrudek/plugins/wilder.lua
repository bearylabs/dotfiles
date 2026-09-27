vim.pack.add { 'https://github.com/gelguy/wilder.nvim' }

local wilder = require 'wilder'
local palette = require('catppuccin.palettes').get_palette 'macchiato'

local text_highlight = wilder.make_hl('WilderText', {
  { a = 1 },
  { a = 1 },
  { foreground = palette.text },
})
local accent_highlight = wilder.make_hl('WilderMauve', {
  { a = 1 },
  { a = 1 },
  { foreground = palette.mauve },
})

vim.opt.wildoptions:remove 'pum'

wilder.setup {
  modes = { ':', '/', '?' },
  next_key = '<C-j>',
  previous_key = '<C-k>',
  accept_key = '<Tab>',
  reject_key = '<S-Tab>',
}

-- Arrow keys select entries while Wilder is active and retain command-line
-- history navigation otherwise.
vim.cmd [[cnoremap <expr> <Down> wilder#in_context() ? wilder#next() : "\<Down>"]]
vim.cmd [[cnoremap <expr> <Up> wilder#in_context() ? wilder#previous() : "\<Up>"]]

wilder.set_option('use_python_remote_plugin', 0)

wilder.set_option('pipeline', {
  wilder.branch(
    wilder.cmdline_pipeline { fuzzy = 1 },
    wilder.vim_search_pipeline { fuzzy = 1 }
  ),
})

wilder.set_option(
  'renderer',
  wilder.popupmenu_renderer(wilder.popupmenu_border_theme {
    highlighter = wilder.basic_highlighter(),
    highlights = {
      default = text_highlight,
      border = accent_highlight,
      accent = accent_highlight,
    },
    pumblend = 5,
    min_width = '100%',
    min_height = 0,
    max_height = 10,
    border = 'rounded',
    left = { ' ' },
    right = { ' ', wilder.popupmenu_scrollbar() },
  })
)
