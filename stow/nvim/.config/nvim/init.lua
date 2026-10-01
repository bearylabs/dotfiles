if vim.fn.has 'win32' == 1 then
  vim.env.CC = vim.env.CC or 'gcc'
  vim.env.CXX = vim.env.CXX or 'g++'
end

require 'kickstart'
require 'hrudek'
