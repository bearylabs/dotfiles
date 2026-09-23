local plugins = {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
}

if vim.fn.executable 'make' == 1 then table.insert(plugins, 'https://github.com/nvim-telescope/telescope-fzf-native.nvim') end

vim.pack.add(plugins)

local actions = require 'telescope.actions'
local telescope = require 'telescope'

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ['<C-k>'] = actions.move_selection_previous,
        ['<C-j>'] = actions.move_selection_next,
        ['<Up>'] = actions.move_selection_previous,
        ['<Down>'] = actions.move_selection_next,
        ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
        ['<C-x>'] = actions.delete_buffer,
      },
      n = {
        ['<Up>'] = actions.move_selection_previous,
        ['<Down>'] = actions.move_selection_next,
      },
    },
    file_ignore_patterns = {
      'node_modules',
      'yarn.lock',
      '.git',
      '.sl',
      '_build',
      '.next',
    },
    path_display = { 'filename_first' },
  },
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}

pcall(telescope.load_extension, 'fzf')
pcall(telescope.load_extension, 'ui-select')

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() builtin.find_files { hidden = true } end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    vim.keymap.set('n', 'gr', builtin.lsp_references, { buffer = buf, desc = 'LSP: Go to references' })
    vim.keymap.set('n', 'gi', builtin.lsp_implementations, { buffer = buf, desc = 'LSP: Go to implementations' })
    vim.keymap.set('n', '<leader>bs', builtin.lsp_document_symbols, { buffer = buf, desc = 'LSP: Document symbols' })
    vim.keymap.set('n', '<leader>ps', builtin.lsp_workspace_symbols, { buffer = buf, desc = 'LSP: Workspace symbols' })
  end,
})

vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>s/', function()
  builtin.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, { desc = '[S]earch [/] in Open Files' })

vim.keymap.set('n', '<leader>sn', function()
  builtin.find_files {
    cwd = vim.fn.stdpath 'config',
    follow = true,
    hidden = true,
  }
end, { desc = '[S]earch [N]eovim files' })
