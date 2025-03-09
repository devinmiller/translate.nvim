local log = require("translate.util.log")
local config = require("translate.config")

local M = {}

-- Get the state from the state module
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
  local float = state:get_float()
  if float and float.win and vim.api.nvim_win_is_valid(float.win) then
    vim.api.nvim_win_close(float.win, true)
  end

  -- Remove the buffer-local mappings in the main buffer
  local main_buf_id = state:get_main_buf_id()
  if main_buf_id and vim.api.nvim_buf_is_valid(main_buf_id) then
    pcall(vim.api.nvim_buf_del_keymap, main_buf_id, 'n', '<leader>tw')
    pcall(vim.api.nvim_buf_del_keymap, main_buf_id, { 'n', 'i' }, '<C-P>')
    pcall(vim.api.nvim_buf_del_keymap, main_buf_id, { 'n', 'i' }, '<C-N>')
  end
  state:set_main_buf_id(nil)

  -- Reset the selection state
  state:set_selection(nil)
end

function M.scroll_up()
  -- Only scroll if float is valid
  local float = state:get_float()
  if float and float.win and vim.api.nvim_win_is_valid(float.win) then
    vim.api.nvim_win_call(float.win, function()
      vim.cmd([[normal!]] .. [[]])
    end)
  end
end

function M.scroll_down()
  -- Only scroll if float is valid
  local float = state:get_float()
  if float and float.win and vim.api.nvim_win_is_valid(float.win) then
    vim.api.nvim_win_call(float.win, function()
      vim.cmd([[normal! ]] .. [[]])
    end)
  end
end

--- @param entries string[]: A list of dictionary entries
M.display_entries = function(entries)
  state:set_main_buf_id(vim.api.nvim_get_current_buf())

  local float = create_floating_window({
    relative = 'cursor',
    row = 1,                               -- how many lines below the cursor
    col = 1,                               -- how many columns to the right of the cursor
    width = config.options.window.width,   -- window width
    height = config.options.window.height, -- window height
    style = "minimal",                     -- minimal style (no line numbers, statusline, etc.)
    border = config.options.window.border, -- add a border : single, double, rounded, etc.
  }, false)
  
  state:set_float(float)

  -- Create buffer-local mappings (in the main buffer) to close/scroll the float
  -- so that these only exist while the float is open
  local main_buf_id = state:get_main_buf_id()
  local opts = { silent = true, noremap = true, nowait = true, buffer = main_buf_id }

  -- vim.keymap.set('n', '<leader>tw', M.close_float, opts)
  vim.keymap.set({ 'n', 'i' }, '<C-P>', M.scroll_up, opts)
  vim.keymap.set({ 'n', 'i' }, '<C-N>', M.scroll_down, opts)

  -- vim.keymap.set("n", "q", function()
  --   vim.api.nvim_win_close(state.float.win, true)
  -- end, { buffer = state.float.buf })

  -- change buffer type to markdown for nicer formatting
  vim.bo[float.buf].filetype = "markdown"
  -- set the buffer contents to the dictionary entries
  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, entries)
  -- set the background to match the float border
  -- this is a very specific fix for the catppuccin styling
  -- TODO: Maybe add an option so this can be done by configuration
  vim.api.nvim_set_option_value("winhighlight", "Normal:FloatBorder,FloatBorder:FloatBorder", {
    win = float.win
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
  -- Initialize the config
  _G.Translate = {}
  _G.Translate.config = config.setup(opts)
  
  -- Assign the module to the global variable
  _G.Translate = M
end

M.translate = function()
  local dict = require("translate.dict")
  local mode = vim.fn.mode()
  local current_selection = ""

  -- Get the current selection
  if mode == "v" then
    current_selection = get_visual_selection()
  else
    current_selection = vim.fn.expand("<cword>")
  end

  -- Check if window is open and selection is unchanged
  local float = state:get_float()
  local selection = state:get_selection()
  if float and float.win and
      vim.api.nvim_win_is_valid(float.win) and
      selection == current_selection then
    -- Toggle off - close the window
    M.close_float()
    return
  end

  -- If window is already open but selection is different, close it first
  if float and float.win and vim.api.nvim_win_is_valid(float.win) then
    -- We need to close the window without resetting the selection state
    -- so we can compare it with the new selection
    local temp_selection = selection
    
    -- Close the window but preserve the selection
    if float.win and vim.api.nvim_win_is_valid(float.win) then
      vim.api.nvim_win_close(float.win, true)
    end
    
    -- Remove the buffer-local mappings in the main buffer
    local main_buf_id = state:get_main_buf_id()
    if main_buf_id and vim.api.nvim_buf_is_valid(main_buf_id) then
      pcall(vim.api.nvim_buf_del_keymap, main_buf_id, 'n', '<leader>tw')
      pcall(vim.api.nvim_buf_del_keymap, main_buf_id, { 'n', 'i' }, '<C-P>')
      pcall(vim.api.nvim_buf_del_keymap, main_buf_id, { 'n', 'i' }, '<C-N>')
    end
    state:set_main_buf_id(nil)
    
    -- Restore the selection state
    state:set_selection(temp_selection)
  end

  -- Store the new selection
  state:set_selection(current_selection)

  -- Get and display entries
  local entries = dict.find_entries(current_selection)

  -- Display the new entries
  M.display_entries(entries)
end

_G.Translate = M

return _G.Translate
