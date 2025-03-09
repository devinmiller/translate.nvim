local log = require("translate.util.log")
local config = require("translate.config")

local M = {}

local state = require("translate.state")

local function create_floating_window(win_config, enter)
  if enter == nil then
    enter = false
  end
  -- Create a (scratch) buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, enter, win_config)

  return { buf = buf, win = win }
end

function M.close_float()
  -- If the float is still open, close it
  if state.float.win and vim.api.nvim_win_is_valid(state.float.win) then
    vim.api.nvim_win_close(state.float.win, true)
  end

  -- Remove the buffer-local mappings in the main buffer
  if state.main_buf_id and vim.api.nvim_buf_is_valid(state.main_buf_id) then
    pcall(vim.api.nvim_buf_del_keymap, state.main_buf_id, 'n', '<leader>tw')
    pcall(vim.api.nvim_buf_del_keymap, state.main_buf_id, { 'n', 'i' }, '<C-P>')
    pcall(vim.api.nvim_buf_del_keymap, state.main_buf_id, { 'n', 'i' }, '<C-N>')
  end
  state.main_buf_id = nil
end

function M.scroll_up()
  -- Only scroll if float is valid
  if state.float.win and vim.api.nvim_win_is_valid(state.float.win) then
    vim.api.nvim_win_call(state.float.win, function()
      vim.cmd([[normal!]] .. [[]])
    end)
  end
end

function M.scroll_down()
  -- Only scroll if float is valid
  if state.float.win and vim.api.nvim_win_is_valid(state.float.win) then
    vim.api.nvim_win_call(state.float.win, function()
      vim.cmd([[normal! ]] .. [[]])
    end)
  end
end

--- @param entries string[]: A list of dictionary entries
M.display_entries = function(entries)
  state.main_buf_id = vim.api.nvim_get_current_buf()

  state.float = create_floating_window({
    relative = 'cursor',
    row = 1,                               -- how many lines below the cursor
    col = 1,                               -- how many columns to the right of the cursor
    width = config.options.window.width,   -- window width
    height = config.options.window.height, -- window height
    style = "minimal",                     -- minimal style (no line numbers, statusline, etc.)
    border = config.options.window.border, -- add a border : single, double, rounded, etc.
  }, false)

  -- Create buffer-local mappings (in the main buffer) to close/scroll the float
  -- so that these only exist while the float is open
  local opts = { silent = true, noremap = true, nowait = true, buffer = state.main_buf_id }

  vim.keymap.set('n', '<leader>tw', M.close_float, opts)
  vim.keymap.set({ 'n', 'i' }, '<C-P>', M.scroll_up, opts)
  vim.keymap.set({ 'n', 'i' }, '<C-N>', M.scroll_down, opts)

  -- vim.keymap.set("n", "q", function()
  --   vim.api.nvim_win_close(state.float.win, true)
  -- end, { buffer = state.float.buf })

  -- change buffer type to markdown for nicer formatting
  vim.bo[state.float.buf].filetype = "markdown"
  -- set the buffer contents to the dictionary entries
  vim.api.nvim_buf_set_lines(state.float.buf, 0, -1, false, entries)
  -- set the background to match the float border
  -- this is a very specific fix for the catppuccin styling
  -- TODO: Maybe add an option so this can be done by configuration
  vim.api.nvim_set_option_value("winhighlight", "Normal:FloatBorder,FloatBorder:FloatBorder", {
    win = state.float.win
  })
end


local function get_visual_selection()
  -- Save the current register contents so we don't lose them
  local original_reg = vim.fn.getreg('"')
  local original_regtype = vim.fn.getregtype('"')

  -- Yank the selection into the default register
  vim.cmd('normal! ""y')

  -- Get the text that was just yanked
  local selection = vim.fn.getreg('"')

  -- Restore original register contents
  vim.fn.setreg('"', original_reg, original_regtype)

  return selection
end

M.setup = function(opts)
  _G.Translate.config = config.setup(opts)
end

M.translate = function()
  local dict = require("translate.dict")
  local mode = vim.fn.mode()

  if mode == "v" then
    local selection = get_visual_selection()
    local entries = dict.find_entries(selection)
    M.display_entries(entries)
  else
    local word = vim.fn.expand("<cword>")
    local entries = dict.find_entries(word)
    M.display_entries(entries)
  end
end

_G.Translate = M

return _G.Translate
