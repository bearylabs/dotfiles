require 'hrudek.plugins'
require 'hrudek.lsp'
require 'hrudek.formatting'
require 'hrudek.keymaps'
require 'hrudek.copy_file_path_to_clipboard'

if vim.fn.has 'win32' == 1 or vim.env.WSL_DISTRO_NAME then
  require 'hrudek.win'
end
