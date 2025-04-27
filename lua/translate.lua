local Translate = {}
local H = {}

Translate.setup = function(config)
  -- Export module
  _G.Translate = Translate

  -- Setup config
  config = H.setup_config(config)

  -- Apply config
  H.apply_config(config)

  -- Create default highlighting
  H.create_default_hl()
end

--- Module config
Translate.config = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
  -- Path to where the dictionary file is located
  dict_path = nil,
  -- Configuration options for the floating window that is created
  window = {
    width = 80,
    height = 10,
    border = "rounded",
  }
}


-- Helper data ================================================================
-- Module default config
H.default_config = vim.deepcopy(Translate.config)

H.current = {
  buf_id = nil,
  win_id = nil
}

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
H.setup_config = function(config)
  -- Check that a config has been passed in
  H.check_type('config', config, 'table', true)
  -- Extend default config with options passed in from setup
  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

  H.check_type('window', config.window, 'table')

  return config
end

H.apply_config = function(config)
  Translate.config = config

end

H.get_config = function(config)
  return vim.tbl_deep_extend('force', Translate.config, vim.b.translate_config or {}, config or {})
end

H.create_default_hl = function()
  local hi = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end

  hi('TranslateBorder', { link = 'FloatBorder' })
  hi('TranslateNormal', { link = 'NormalFloat' })
  hi('TranslateTitle',  { link = 'FloatTitle'  })
end


H.create_user_commands = function()
  local callback = function(input)
    local name, local_opts = H.command_parse_fargs(input.fargs)
    local f = MiniPick.registry[name]
    if f == nil then H.error(string.format('There is no picker named "%s" in registry.', name)) end
    f(local_opts)
  end
  local opts = { nargs = '+', complete = H.command_complete, desc = "Pick from 'mini.pick' registry" }
  vim.api.nvim_create_user_command('Translate', callback, opts)
end


-- Buffer ---------------------------------------------------------------------
H.buffer_create = function()
  local buf_id = vim.api.nvim_create_buf(false, true)
  H.set_buf_name(buf_id, 'content')
  vim.bo[buf_id].filetype = 'markdown'
  return buf_id
end

-- Window ---------------------------------------------------------------------
H.window_open = function(buf_id)

end

H.window_scroll = function(direction) 
  if not (direction == 'down' or direction == 'up') then
    H.error('`direction` should be one of "up" or "down"')
  end

  local win_id = H.is_valid_win(H.info.win_id) and H.info.win_id
    or (H.is_valid_win(H.signature.win_id) and H.signature.win_id or nil)
  if win_id == nil then return false end

  -- Schedule execution as scrolling is not allowed in expression mappings
  local key = direction == 'down' and '\6' or '\2'
  vim.schedule(function()
    if not H.is_valid_win(win_id) then return end
    vim.api.nvim_win_call(win_id, function() vim.cmd('noautocmd normal! ' .. key) end)
  end)
  
  return true
end

H.window_close = function()

end

-- Utilities ------------------------------------------------------------------
H.error = function(msg) error('(translate) ' .. msg, 0) end

H.check_type = function(name, val, ref, allow_nil)
  if type(val) == ref or (ref == 'callable' and vim.is_callable(val)) or (allow_nil and val == nil) then return end
  H.error(string.format('`%s` should be %s, not %s', name, ref, type(val)))
end

H.set_buf_name = function(buf_id, name) vim.api.nvim_buf_set_name(buf_id, 'translate://' .. buf_id .. '/' .. name) end

H.is_valid_buf = function(buf_id) return type(buf_id) == 'number' and vim.api.nvim_buf_is_valid(buf_id) end

H.is_valid_win = function(win_id) return type(win_id) == 'number' and vim.api.nvim_win_is_valid(win_id) end