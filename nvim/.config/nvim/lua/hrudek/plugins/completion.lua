vim.pack.add {
  { src = 'https://github.com/L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
  'https://github.com/rafamadriz/friendly-snippets',
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' },
}

local luasnip = require 'luasnip'

luasnip.setup {
  region_check_events = 'CursorMoved,CursorHold,InsertEnter',
  delete_check_events = 'TextChanged',
  update_events = 'TextChanged,TextChangedI',
  history = true,
  enable_autosnippets = true,
}

require('luasnip.loaders.from_vscode').lazy_load()

require('blink.cmp').setup {
  keymap = {
    ['<C-k>'] = { 'select_prev', 'show_signature', 'hide_signature', 'fallback' },
    ['<C-j>'] = { 'select_next', 'fallback' },
    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-c>'] = { 'cancel', 'fallback' },
    ['<CR>'] = { 'select_and_accept', 'fallback' },
    ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-Space>'] = { 'show', 'fallback' },
    ['<Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then return cmp.snippet_forward() end
        return cmp.select_next()
      end,
      'fallback',
    },
    ['<S-Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then return cmp.snippet_backward() end
        return cmp.select_prev()
      end,
      'fallback',
    },
  },

  appearance = {
    nerd_font_variant = 'mono',
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lsp = {
        score_offset = 1000,
      },
      path = {
        score_offset = 3,
      },
      snippets = {
        score_offset = -100,
        max_items = 2,
        min_keyword_length = 3,
      },
      buffer = {
        score_offset = -150,
        min_keyword_length = 3,
      },
    },
  },

  snippets = {
    preset = 'luasnip',
  },

  signature = {
    enabled = true,
    trigger = {
      show_on_trigger_character = false,
      show_on_insert_on_trigger_character = false,
    },
    window = {
      border = 'rounded',
      show_documentation = true,
    },
  },

  completion = {
    trigger = {
      show_in_snippet = false,
      show_on_trigger_character = true,
    },
    menu = {
      auto_show = true,
      border = 'rounded',
      max_height = 10,
      draw = {
        columns = {
          { 'kind_icon' },
          { 'label', 'label_description', gap = 1 },
          { 'source_name' },
        },
        components = {
          source_name = {
            text = function(ctx)
              local names = {
                lsp = '[LSP]',
                buffer = '[Buffer]',
                path = '[Path]',
                snippets = '[Snippet]',
              }
              return names[ctx.source_name] or ('[' .. ctx.source_name .. ']')
            end,
            highlight = 'CmpItemMenu',
          },
        },
      },
    },
    documentation = {
      auto_show = true,
      window = {
        border = 'rounded',
      },
    },
    ghost_text = {
      enabled = true,
    },
    list = {
      selection = {
        preselect = true,
      },
    },
    accept = {
      auto_brackets = {
        enabled = true,
      },
    },
  },

  fuzzy = {
    implementation = 'lua',
  },
}
