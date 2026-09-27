local Path = require 'plenary.path'

vim.api.nvim_create_user_command('CopyFilePathToClipboard', function()
  local file_path = vim.api.nvim_buf_get_name(0)
  local project_root_parent_dir = Path:new(vim.fn.getcwd()):parent():absolute()
  local relative_path = Path:new(file_path):make_relative(project_root_parent_dir)

  vim.fn.setreg('+', relative_path)
end, {})

vim.api.nvim_create_user_command('CFP', function()
  vim.cmd 'CopyFilePathToClipboard'
end, {})
