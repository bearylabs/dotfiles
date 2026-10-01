-- Windows Terminal cannot set a separate foreground color for the character
-- underneath its cursor, so highlight that cell in Neovim instead.
vim.api.nvim_set_hl(0, 'ReadableCursor', {
  fg = '#24273a', -- Catppuccin Macchiato base
  bg = '#f4dbd6', -- Catppuccin Macchiato rosewater
})

vim.opt.guicursor = {
  'n-v-c:block-ReadableCursor',
  'i-ci-ve:ver25',
  'r-cr:hor20',
  'o:hor50',
}

local cursor_namespace = vim.api.nvim_create_namespace 'readable_cursor'
local previous_buffer

local function highlight_cursor_cell()
  if previous_buffer and vim.api.nvim_buf_is_valid(previous_buffer) then
    vim.api.nvim_buf_clear_namespace(previous_buffer, cursor_namespace, 0, -1)
  end

  if vim.api.nvim_get_mode().mode ~= 'n' then
    previous_buffer = nil
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local column = cursor[2]
  local character = vim.fn.strcharpart(line:sub(column + 1), 0, 1)

  if character == '' then
    previous_buffer = nil
    return
  end

  vim.api.nvim_buf_set_extmark(buffer, cursor_namespace, cursor[1] - 1, column, {
    end_col = column + #character,
    hl_group = 'ReadableCursor',
    hl_mode = 'replace',
    priority = 10000,
  })
  previous_buffer = buffer
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved', 'ModeChanged', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('readable_cursor', { clear = true }),
  callback = highlight_cursor_cell,
})
