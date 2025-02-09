local log = require("translate.util.log")

local M = {}

--- translate.nvim configuration with its default values.
---
---@type table
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
  -- Path to where the dictionary file is located
  dict_path = vim.fn.stdpath("data"),
  -- Language to translate
  language = "Italian",
}

---@private
local defaults = vim.deepcopy(M.options)

--- Defaults translate.nvim options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |translate.nvim.options|.
---
---@private
function M.defaults(options)
  M.options =
      vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

  -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
  assert(
    type(M.options.debug) == "boolean",
    "`debug` must be a boolean (`true` or `false`)."
  )

  M.options.dict_file = string.format("%s/kaikki.org-dictionary-%s.jsonl", M.options.dict_path, M.options.language)

  return M.options
end

--- Define your your-plugin-name setup.
---
---@param options table Module config table. See |YourPluginName.options|.
---
---@usage `require("your-plugin-name").setup()` (add `{}` with your |YourPluginName.options| table)
function M.setup(options)
  M.options = M.defaults(options or {})

  log.warn_deprecation(M.options)

  return M.options
end

return M
