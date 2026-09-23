vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

require('conform').setup {
  notify_on_error = true,
  format_on_save = function(bufnr)
    local enabled_filetypes = {
      astro = true,
      css = true,
      html = true,
      javascript = true,
      javascriptreact = true,
      json = true,
      jsonc = true,
      lua = true,
      python = true,
      scss = true,
      sh = true,
      sql = true,
      svelte = true,
      terraform = true,
      ['terraform-vars'] = true,
      typescript = true,
      typescriptreact = true,
      yaml = true,
    }

    if enabled_filetypes[vim.bo[bufnr].filetype] then return { timeout_ms = 2000, lsp_format = 'fallback' } end
  end,
  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters_by_ft = {
    astro = { 'prettierd', 'prettier', stop_after_first = true },
    css = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    jsonc = { 'prettierd', 'prettier', stop_after_first = true },
    lua = { 'stylua' },
    python = { 'ruff_format' },
    scss = { 'prettierd', 'prettier', stop_after_first = true },
    sh = { 'shfmt' },
    sql = { 'sqruff' },
    svelte = { 'prettierd', 'prettier', stop_after_first = true },
    terraform = { 'terraform_fmt' },
    ['terraform-vars'] = { 'terraform_fmt' },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    yaml = { 'prettierd', 'prettier', stop_after_first = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
