local M = {}

local help_win
local namespace = vim.api.nvim_create_namespace 'hrudek-keymap-help'

local function trim(value) return value:match '^%s*(.-)%s*$' end

local function render_help(path)
  local rows = {}
  local in_references = false

  local function add(text, kind, highlights)
    table.insert(rows, {
      text = text,
      kind = kind,
      highlights = highlights or {},
    })
  end

  add('  Personal Neovim Keybindings', 'title', { { 2, -1, 'Title' } })
  add('  N Normal   I Insert   V Visual   T Terminal   O Operator', 'legend', { { 2, -1, 'Comment' } })
  add('', 'blank')

  for _, source_line in ipairs(vim.fn.readfile(path)) do
    local line = source_line:gsub('%s+%*[^*]+%*%s*$', '')
    local category = source_line:match '^(.-)%s+%*keymaps%-'
    local mode = source_line:match '^(%u[%u,]*)%s+'
    local key = mode and trim(source_line:sub(#mode + 1, 19)) or nil
    local description = mode and trim(source_line:sub(20)) or nil
    if description == '' then description = nil end

    if source_line:match '^vim:' or source_line:match '^=' or source_line:match '^%*custom%-keymaps' then
      -- Help metadata is not needed in the dashboard.
    elseif trim(line) == 'CUSTOM KEYBINDINGS' or line:match '^This page describes' or line:match '^<Leader> is' or line:match '^I %(Insert%)' then
      -- The popup header and legend replace the introductory help text.
    elseif line:match '^Open this help:' then
      -- The shortcut is already listed directly below this line.
    elseif trim(line) == 'See also:' then
      in_references = true
    elseif in_references then
      -- Keep plugin references in the regular :help document only.
    elseif category then
      if rows[#rows].kind ~= 'blank' then add('', 'blank') end
      local heading = '  ' .. trim(category) .. ' '
      heading = heading .. string.rep('─', math.max(3, 74 - vim.fn.strdisplaywidth(heading)))
      add(heading, 'heading', { { 2, -1, 'DiagnosticInfo' } })
    elseif mode then
      local formatted = string.format('  %-4s  %-22s  %s', mode, key, description)
      add(formatted, 'mapping', {
        { 2, 2 + #mode, 'DiagnosticHint' },
        { 8, 8 + #key, 'Function' },
        { 32, -1, 'NormalFloat' },
      })
    elseif line:match ':$' then
      add('  ' .. trim(line), 'subheading', { { 2, -1, 'Special' } })
    elseif trim(line) == '' then
      if rows[#rows].kind ~= 'blank' then add('', 'blank') end
    else
      add('    ' .. trim(line), 'note', { { 4, -1, 'Comment' } })
    end
  end

  while rows[#rows].kind == 'blank' do table.remove(rows) end
  return rows
end

local function fuzzy_match(text, query)
  local haystack = text:lower()
  local offset = 1

  for _, character in ipairs(vim.fn.split(query:lower(), '\\zs')) do
    local start = haystack:find(character, offset, true)
    if not start then return false end
    offset = start + #character
  end

  return true
end

local function filter_rows(rows, query, editing, query_cursor)
  if query == '' and not editing then return rows end

  local result = { rows[1] }
  local prompt = editing and '  Search: ' or '  Filter: '
  local displayed_query = query
  if editing then
    query_cursor = query_cursor or vim.fn.strchars(query)
    displayed_query = vim.fn.strcharpart(query, 0, query_cursor) .. '▏' .. vim.fn.strcharpart(query, query_cursor)
  end
  table.insert(result, {
    text = prompt .. displayed_query,
    kind = 'search',
    highlights = {
      { 2, #prompt, 'Special' },
      { #prompt, -1, 'IncSearch' },
    },
  })
  table.insert(result, { text = '', kind = 'blank', highlights = {} })

  local sections = { { items = {} } }
  for index = 4, #rows do
    local row = rows[index]
    if row.kind == 'heading' then
      table.insert(sections, { heading = row, items = {} })
    elseif row.kind ~= 'blank' then
      table.insert(sections[#sections].items, row)
    end
  end

  local found = false
  for _, section in ipairs(sections) do
    local heading_matches = section.heading and fuzzy_match(section.heading.text, query)
    local matches = {}
    for _, row in ipairs(section.items) do
      if query == '' or heading_matches or fuzzy_match(row.text, query) then table.insert(matches, row) end
    end

    if #matches > 0 then
      if section.heading then
        if result[#result].kind ~= 'blank' then table.insert(result, { text = '', kind = 'blank', highlights = {} }) end
        table.insert(result, section.heading)
      end
      for _, row in ipairs(matches) do table.insert(result, row) end
      found = true
    end
  end

  if not found then
    table.insert(result, {
      text = '  No matching keymaps',
      kind = 'note',
      highlights = { { 2, -1, 'Comment' } },
    })
  end

  return result
end

local function apply_rows(buffer, rows)
  local lines = vim.tbl_map(function(row) return row.text end, rows)
  vim.bo[buffer].readonly = false
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  for row_index, row in ipairs(rows) do
    for _, highlight in ipairs(row.highlights) do
      local end_col = highlight[2] == -1 and #row.text or highlight[2]
      vim.api.nvim_buf_set_extmark(buffer, namespace, row_index - 1, highlight[1], {
        end_col = end_col,
        hl_group = highlight[3],
      })
    end
  end

  vim.bo[buffer].modifiable = false
  vim.bo[buffer].readonly = true
end

function M.toggle()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_win_close(help_win, true)
    return
  end

  local path = vim.fn.stdpath 'config' .. '/doc/keymaps.txt'
  local rows = render_help(path)
  local buffer = vim.api.nvim_create_buf(false, true)
  apply_rows(buffer, rows)

  vim.bo[buffer].bufhidden = 'wipe'
  vim.bo[buffer].readonly = true

  local width = math.max(1, math.min(100, math.floor(vim.o.columns * 0.85)))
  local height = math.max(1, math.min(40, math.floor(vim.o.lines * 0.8)))
  help_win = vim.api.nvim_open_win(buffer, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    style = 'minimal',
    border = 'rounded',
    title = ' 󰌌  Keymap Help ',
    title_pos = 'center',
  })

  vim.wo[help_win].colorcolumn = ''
  vim.wo[help_win].cursorline = true
  vim.wo[help_win].number = false
  vim.wo[help_win].relativenumber = false
  vim.wo[help_win].signcolumn = 'no'
  vim.wo[help_win].wrap = false
  vim.wo[help_win].winhighlight = 'Normal:NormalFloat,EndOfBuffer:NormalFloat'

  local close = function()
    if help_win and vim.api.nvim_win_is_valid(help_win) then vim.api.nvim_win_close(help_win, true) end
  end

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buffer,
    once = true,
    callback = function() vim.schedule(close) end,
  })

  vim.keymap.set('n', 'q', close, { buffer = buffer, silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buffer, silent = true })
  vim.keymap.set('n', '<C-c>', close, { buffer = buffer, silent = true })

  local help_arrows = {
    ['<Left>'] = 'h',
    ['<Down>'] = 'j',
    ['<Up>'] = 'k',
    ['<Right>'] = 'l',
  }
  for arrow, key in pairs(help_arrows) do
    vim.keymap.set('n', arrow, key, { buffer = buffer, remap = true, silent = true })
  end

  local query = ''
  vim.keymap.set('n', '/', function()
    local original_query = query
    local query_cursor = vim.fn.strchars(query)
    local selected_row
    local cancelled = false

    local function first_mapping(visible_rows)
      for index, row in ipairs(visible_rows) do
        if row.kind == 'mapping' then return index end
      end
      return 2
    end

    local function move_selection(visible_rows, direction)
      local index = selected_row + direction
      while index >= 1 and index <= #visible_rows do
        if visible_rows[index].kind == 'mapping' then
          selected_row = index
          return
        end
        index = index + direction
      end
    end

    while help_win and vim.api.nvim_win_is_valid(help_win) do
      local visible_rows = filter_rows(rows, query, true, query_cursor)
      if not selected_row or not visible_rows[selected_row] or visible_rows[selected_row].kind ~= 'mapping' then
        selected_row = first_mapping(visible_rows)
      end
      apply_rows(buffer, visible_rows)
      vim.api.nvim_win_set_cursor(help_win, { selected_row, 0 })
      vim.cmd.redraw()

      local ok, key = pcall(vim.fn.getcharstr)
      if not ok or key == '\3' then
        close()
        return
      elseif key == '\27' then
        query = original_query
        cancelled = true
        break
      elseif key == '\r' or key == '\n' then
        break
      elseif key == vim.keycode '<Up>' then
        move_selection(visible_rows, -1)
      elseif key == vim.keycode '<Down>' then
        move_selection(visible_rows, 1)
      elseif key == vim.keycode '<Left>' then
        query_cursor = math.max(0, query_cursor - 1)
      elseif key == vim.keycode '<Right>' then
        query_cursor = math.min(vim.fn.strchars(query), query_cursor + 1)
      elseif key == '\b' or key == '\127' or key == vim.keycode '<BS>' then
        if query_cursor > 0 then
          query = vim.fn.strcharpart(query, 0, query_cursor - 1) .. vim.fn.strcharpart(query, query_cursor)
          query_cursor = query_cursor - 1
          selected_row = nil
        end
      elseif key == vim.keycode '<C-u>' then
        query = ''
        query_cursor = 0
        selected_row = nil
      elseif #key > 0 and key:byte() >= 32 and key:byte() ~= 127 and key:byte() ~= 128 then
        query = vim.fn.strcharpart(query, 0, query_cursor) .. key .. vim.fn.strcharpart(query, query_cursor)
        query_cursor = query_cursor + vim.fn.strchars(key)
        selected_row = nil
      end
    end

    if not help_win or not vim.api.nvim_win_is_valid(help_win) then return end
    local visible_rows = filter_rows(rows, query, false)
    apply_rows(buffer, visible_rows)
    if cancelled or not visible_rows[selected_row] or visible_rows[selected_row].kind ~= 'mapping' then
      selected_row = first_mapping(visible_rows)
    end
    vim.api.nvim_win_set_cursor(help_win, { selected_row, 0 })
    if cancelled then vim.cmd.redraw() end
  end, { buffer = buffer, silent = true, desc = 'Fuzzily filter keymap help' })

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(help_win),
    once = true,
    callback = function() help_win = nil end,
  })
end

return M
