-- Seamless C-h/j/k/l navigation between Neovim windows and Herdr panes.
-- Herdr must leave these keys unbound so they reach Neovim first.

local directions = {
  ["<C-h>"] = { wincmd = "h", herdr = "left" },
  ["<C-j>"] = { wincmd = "j", herdr = "down" },
  ["<C-k>"] = { wincmd = "k", herdr = "up" },
  ["<C-l>"] = { wincmd = "l", herdr = "right" },
}

local function navigate(wincmd, direction)
  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)

  if vim.api.nvim_get_current_win() ~= previous_window then
    return
  end

  local pane_id = vim.env.HERDR_PANE_ID
  if not pane_id or pane_id == "" then
    vim.notify("No Neovim window or Herdr pane in that direction", vim.log.levels.INFO)
    return
  end

  local herdr = vim.env.HERDR_BIN_PATH
  if not herdr or herdr == "" then
    herdr = vim.fn.exepath("herdr")
  end
  if herdr == "" then
    vim.notify("Cannot focus Herdr pane: herdr executable not found", vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart({
    herdr,
    "pane",
    "focus",
    "--direction",
    direction,
    "--pane",
    pane_id,
  }, { detach = true })
end

for key, target in pairs(directions) do
  vim.keymap.set("n", key, function()
    navigate(target.wincmd, target.herdr)
  end, {
    silent = true,
    noremap = true,
    desc = "Navigate " .. target.herdr .. " (Neovim/Herdr)",
  })
end
