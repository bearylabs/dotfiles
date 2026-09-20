-- Normal Mode --

-- Jump to start/end of line
vim.keymap.set('n', 'H', '^', { desc = 'Jump to beginning of line' })
vim.keymap.set('n', 'L', '$', { desc = 'Jump to end of line' })

-- Insert a blank line below without entering insert mode
vim.keymap.set('n', '<S-CR>', 'o<Esc>', { desc = 'Insert blank line below' })

-- Toggle NeoTree file explorer
vim.keymap.set('n', '<leader>e', '<Cmd>Neotree toggle reveal<CR>', {
  desc = 'Toggle NeoTree file explorer',
  silent = true,
})

vim.keymap.set('n', 'S', function()
  local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = 'Quick find/replace word under cursor' })

-- Save and Quit
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { silent = false, desc = 'Save current buffer' })
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { silent = false, desc = 'Quit current buffer' })

-- Diagnostic float and quickfix
vim.keymap.set('n', '<leader>d', function() vim.diagnostic.open_float { border = 'rounded' } end, { desc = 'Open diagnostic float with rounded border' })

-- vim.keymap.set('n', '<leader>cd', copy_line_diagnostics_to_clipboard, { desc = '[C]opy line [D]iagnostics' })

vim.keymap.set('n', '<leader>ld', vim.diagnostic.setqflist, { desc = 'Populate quickfix list with diagnostics' })

-- Quickfix navigation
vim.keymap.set('n', '<leader>cn', ':cnext<cr>zz', { desc = 'Go to next quickfix item and center' })
vim.keymap.set('n', '<leader>cp', ':cprevious<cr>zz', { desc = 'Go to previous quickfix item and center' })
vim.keymap.set('n', '<leader>co', ':copen<cr>zz', { desc = 'Open quickfix list and center' })
vim.keymap.set('n', '<leader>cc', ':cclose<cr>zz', { desc = 'Close quickfix list' })
-- Center buffer while navigating
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center cursor' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center cursor' })
vim.keymap.set('n', '{', '{zz', { desc = 'Jump to previous paragraph and center' })
vim.keymap.set('n', '}', '}zz', { desc = 'Jump to next paragraph and center' })
vim.keymap.set('n', 'N', 'Nzz', { desc = 'Search previous and center' })
vim.keymap.set('n', 'n', 'nzz', { desc = 'Search next and center' })
vim.keymap.set('n', 'G', 'Gzz', { desc = 'Go to end of file and center' })
vim.keymap.set('n', 'gg', 'ggzz', { desc = 'Go to beginning of file and center' })
vim.keymap.set('n', 'gd', 'gdzz', { desc = 'Go to definition and center' })
vim.keymap.set('n', '<C-i>', '<C-i>zz', { desc = 'Jump forward in jump list and center' })
vim.keymap.set('n', '<C-o>', '<C-o>zz', { desc = 'Jump backward in jump list and center' })
vim.keymap.set('n', '%', '%zz', { desc = 'Jump to matching bracket and center' })
vim.keymap.set('n', '*', '*zz', { desc = 'Search for word under cursor and center' })
vim.keymap.set('n', '#', '#zz', { desc = 'Search backward for word under cursor and center' })

-- Insert Mode --

-- Exit insert mode
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode' })
vim.keymap.set('i', 'kk', '<Esc>', { desc = 'Exit insert mode' })

-- Visual Mode --

-- Jump to start/end of line
vim.keymap.set('x', 'H', '^', { desc = 'Jump to beginning of line' })
vim.keymap.set('x', 'L', '$', { desc = 'Jump to end of line' })
