local api = vim.api
local backdropWin = -1
local backdropBufnr = -1

-- open backdrop window like modal
function open_backdrop()
  local backdropName = "Lazygit"
  backdropBufnr = vim.api.nvim_create_buf(false, true)
  backdropWin = vim.api.nvim_open_win(backdropBufnr, false, {
    relative = "editor",
    border = "none",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines,
    focusable = false,
    style = "minimal",
    zindex = 50,
  })

  local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local backdropBg = hl.bg
  if vim.o.background == 'light' then
    backdropBg = "Black"
  end
  vim.api.nvim_set_hl(0, backdropName, { bg = backdropBg, default = true })
  vim.wo[backdropWin].winhighlight = "Normal:" .. backdropName
  vim.wo[backdropWin].winblend = 50
  vim.bo[backdropBufnr].buftype = "nofile"
end

-- close backdrop window
function close_backdrop()
  if vim.api.nvim_win_is_valid(backdropWin) then
    vim.api.nvim_win_close(backdropWin, true)
  end

  if vim.api.nvim_buf_is_valid(backdropBufnr) then
    vim.api.nvim_buf_delete(backdropBufnr, { force = true })
  end

  backdropWin = -1
  backdropBufnr = -1
end

local function get_window_pos()
  local floating_window_scaling_factor = vim.g.lazygit_floating_window_scaling_factor

  -- Why is this required?
  -- vim.g.lazygit_floating_window_scaling_factor returns different types if the value is an integer or float
  if type(floating_window_scaling_factor) == 'table' then
    floating_window_scaling_factor = floating_window_scaling_factor[false]
  end

  local status, plenary = pcall(require, 'plenary.window.float')
  if status and vim.g.lazygit_floating_window_use_plenary and vim.g.lazygit_floating_window_use_plenary ~= 0 then
    local ret = plenary.percentage_range_window(
      floating_window_scaling_factor,
      floating_window_scaling_factor,
      { winblend = vim.g.lazygit_floating_window_winblend }
    )
    return nil, nil, nil, nil, ret.win_id, ret.bufnr
  end

  local height = math.ceil(vim.o.lines * 0.85) - 1
  local width = math.ceil(vim.o.columns * 0.9)
  local row = math.ceil(vim.o.lines - height) / 3
  local col = math.ceil(vim.o.columns - width) / 2
  return width, height, row, col
end

--- open floating window with nice borders
local function open_floating_window()
  local width, height, row, col, plenary_win, plenary_buf = get_window_pos()
  if plenary_win and plenary_buf then
    return plenary_win, plenary_buf
  end

  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = vim.g.lazygit_floating_window_border_chars,
  }

  -- create a unlisted scratch buffer
  if LAZYGIT_BUFFER == nil or vim.fn.bufwinnr(LAZYGIT_BUFFER) == -1 then
    LAZYGIT_BUFFER = api.nvim_create_buf(false, true)
  else
    LAZYGIT_LOADED = true
  end

  -- create file window, enter the window, and use the options defined in opts
  local win = api.nvim_open_win(LAZYGIT_BUFFER, true, opts)

  vim.bo[LAZYGIT_BUFFER].filetype = 'lazygit'

  vim.bo.bufhidden = 'hide'
  vim.wo.cursorcolumn = false
  vim.wo.signcolumn = 'no'
  vim.api.nvim_set_hl(0, "LazyGitBorder", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "LazyGitFloat", { link = "Normal", default = true })
  vim.wo.winhl = 'FloatBorder:LazyGitBorder,NormalFloat:LazyGitFloat'
  vim.wo.winblend = vim.g.lazygit_floating_window_winblend

  vim.api.nvim_create_autocmd('VimResized', {
    callback = function()
      vim.defer_fn(function()
        if not vim.api.nvim_win_is_valid(backdropWin) then
          return
        end
        api.nvim_win_set_config(backdropWin, {
          relative = "editor",
          row = 0,
          col = 0,
          width = vim.o.columns,
          height = vim.o.lines,
          focusable = false,
          style = "minimal",
          zindex = 50,
        })

        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        local new_width, new_height, new_row, new_col = get_window_pos()
        api.nvim_win_set_config(
          win,
          {
            width = new_width,
            height = new_height,
            relative = "editor",
            row = new_row,
            col = new_col,
          }
        )
      end, 20)
    end,
  })

  return win, LAZYGIT_BUFFER
end

return {
  open_floating_window = open_floating_window,
  open_backdrop = open_backdrop,
  close_backdrop = close_backdrop,
}
