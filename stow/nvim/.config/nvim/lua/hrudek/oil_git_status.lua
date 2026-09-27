local M = {}

local oil = require 'oil'
local namespace = vim.api.nvim_create_namespace 'oil-git-decorations'
local oil_buffers = {}
local buffer_statuses = {}

local highlights = {
  Added = 'NeoTreeGitAdded',
  Conflict = 'NeoTreeGitConflict',
  Deleted = 'NeoTreeGitDeleted',
  Modified = 'NeoTreeGitModified',
  Renamed = 'NeoTreeGitRenamed',
  Staged = 'NeoTreeGitStaged',
  Untracked = 'NeoTreeGitUntracked',
  Unstaged = 'NeoTreeGitUnstaged',
}

local symbols = {
  added = '✚',
  deleted = '✖',
  modified = '',
  renamed = '󰁕',
  untracked = '',
  unstaged = '󰄱',
  staged = '',
  conflict = '',
}

local function buffer_path(bufnr)
  local url = vim.api.nvim_buf_get_name(bufnr)
  if not vim.startswith(url, 'oil:') then return nil end
  return vim.uri_to_fname((url:gsub('^oil', 'file')))
end

local function status_style(status)
  if status == '??' then
    return 'OilGitStatusUntracked', { { symbols.untracked, 'OilGitStatusUntracked' } }
  end
  local x, y = status:sub(1, 1), status:sub(2, 2)
  local conflicts = { DD = true, AU = true, UD = true, UA = true, DU = true, AA = true, UU = true }
  if conflicts[status] then
    return 'OilGitStatusConflict', { { symbols.conflict, 'OilGitStatusConflict' } }
  end

  local function change(code)
    if code == 'M' or code == 'T' then return symbols.modified, 'OilGitStatusModified' end
    if code == 'R' or code == 'C' then return symbols.renamed, 'OilGitStatusRenamed' end
    if code == 'D' then return symbols.deleted, 'OilGitStatusDeleted' end
    return symbols.added, 'OilGitStatusAdded'
  end

  local chunks = {}
  local name_hl
  if x ~= ' ' then
    local symbol, hl = change(x)
    chunks[#chunks + 1] = { symbol, hl }
    name_hl = hl
  end
  if y ~= ' ' then
    local symbol, hl = change(y)
    chunks[#chunks + 1] = { symbol, hl }
    name_hl = hl
  end

  if #chunks == 1 then
    if y ~= ' ' then
      chunks[#chunks + 1] = { symbols.unstaged, 'OilGitStatusUnstaged' }
    else
      chunks[#chunks + 1] = { symbols.staged, 'OilGitStatusStaged' }
    end
  end

  return name_hl, chunks
end

local function apply(bufnr, statuses)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  for line = 1, vim.api.nvim_buf_line_count(bufnr) do
    local entry = oil.get_entry_on_line(bufnr, line)
    local status = entry and statuses[entry.name]
    if status and entry.name ~= '..' then
      local name_hl, chunks = status_style(status)
      local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
      local start_col = text:find(entry.name, 1, true)
      local end_col
      if start_col then
        end_col = start_col - 1 + #entry.name
        -- Oil renders directories with a trailing slash that is not part of
        -- entry.name. Include it so the Git symbols appear after `dir/`.
        if text:sub(end_col + 1, end_col + 1) == '/' then end_col = end_col + 1 end
      end

      if start_col and name_hl then
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line - 1, start_col - 1, {
          end_col = end_col,
          hl_group = name_hl,
          priority = 150,
        })
      end

      if end_col and #chunks > 0 then
        local virtual_text = {}
        for _, chunk in ipairs(chunks) do
          virtual_text[#virtual_text + 1] = { ' ' .. chunk[1], chunk[2] }
        end
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line - 1, end_col, {
          virt_text = virtual_text,
          virt_text_pos = 'inline',
          priority = 150,
        })
      end
    end
  end
end

local function refresh(bufnr)
  local path = buffer_path(bufnr)
  if not path then return end

  vim.system({
    'git',
    '-c',
    'core.quotepath=false',
    '-c',
    'status.relativePaths=true',
    'status',
    '--short',
    '--no-renames',
    '--untracked-files=all',
    '--',
    '.',
  }, { cwd = path, text = false }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
        end
      end)
      return
    end

    local statuses = {}
    -- Unlike the NUL format, short output respects status.relativePaths. That
    -- makes every path relative to the directory currently displayed by Oil.
    for _, field in ipairs(vim.split(result.stdout or '', '\n', { plain = true, trimempty = true })) do
      local status = field:sub(1, 2)
      local name = field:sub(4):gsub('^%./', '')
      local top_level = name:match '^[^/]+'
      if top_level then
        local old = statuses[top_level]
        if not old or old == '??' then
          statuses[top_level] = status
        elseif old ~= status then
          statuses[top_level] = ' M'
        end
      end
    end

    buffer_statuses[bufnr] = statuses
    vim.schedule(function() apply(bufnr, statuses) end)
  end)
end

function M.setup()
  for suffix, target in pairs(highlights) do
    vim.api.nvim_set_hl(0, 'OilGitStatus' .. suffix, { link = target, default = true })
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'OilEnter',
    callback = function(args)
      local bufnr = args.data.buf
      oil_buffers[bufnr] = true
      refresh(bufnr)
    end,
  })

  vim.api.nvim_create_autocmd('TextChanged', {
    pattern = 'oil:*',
    callback = function(args)
      -- Keep highlights attached to their entry while Oil edits the listing,
      -- without starting a Git process for every keystroke.
      local statuses = buffer_statuses[args.buf]
      if statuses then vim.schedule(function() apply(args.buf, statuses) end) end
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'OilMutationComplete',
    callback = function()
      for bufnr in pairs(oil_buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) then refresh(bufnr) else oil_buffers[bufnr] = nil end
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    pattern = 'oil:*',
    callback = function(args)
      oil_buffers[args.buf] = nil
      buffer_statuses[args.buf] = nil
    end,
  })
end

return M
