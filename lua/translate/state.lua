local log = require("translate.util.log")

-- Local state with default values
local state = {
  float = nil,
  selection = nil,
  main_buf_id = nil
}

-- Initialize state from global if it exists
function state:init()
  if _G.Translate and _G.Translate.state then
    -- Copy values from global state
    for k, v in pairs(_G.Translate.state) do
      self[k] = v
    end
  end
  return self
end

-- Save state to global
function state:save()
  -- log.debug("state.save", "saving state globally to _G.Translate.state")
  _G.Translate.state = self
end

-- Getter for float
function state:get_float()
  return self.float
end

-- Setter for float
function state:set_float(value)
  self.float = value
  self:save()
end

-- Getter for selection
function state:get_selection()
  return self.selection
end

-- Setter for selection
function state:set_selection(value)
  self.selection = value
  self:save()
end

-- Getter for main_buf_id
function state:get_main_buf_id()
  return self.main_buf_id
end

-- Setter for main_buf_id
function state:set_main_buf_id(value)
  self.main_buf_id = value
  self:save()
end

-- Initialize on module load
state:init()

return state
